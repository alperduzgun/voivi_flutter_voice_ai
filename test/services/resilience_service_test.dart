import 'dart:async';

import 'package:test/test.dart';
import 'package:voivi_voice_ai/src/core/voivi_config.dart';
import 'package:voivi_voice_ai/src/services/resilience_service.dart';

void main() {
  group('CircuitBreakerService', () {
    late CircuitBreakerService circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreakerService(
        config: CircuitBreakerConfig(
          enabled: true,
          failureThreshold: 3,
          recoveryTimeout: Duration(seconds: 2),
          halfOpenRetryCount: 2,
        ),
      );
    });

    test('should start in closed state', () {
      expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
      expect(circuitBreaker.failureCount, equals(0));
    });

    test('should execute operation successfully when closed', () async {
      final result = await circuitBreaker.execute(() async => 'success');

      expect(result, equals('success'));
      expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
      expect(circuitBreaker.failureCount, equals(0));
    });

    test('should count failures', () async {
      for (int i = 0; i < 2; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(circuitBreaker.failureCount, equals(2));
      expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
    });

    test('should transition to open state after threshold', () async {
      // Cause 3 failures
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(circuitBreaker.state, equals(CircuitBreakerState.open));
      expect(circuitBreaker.failureCount, equals(3));
    });

    test('should block requests when open', () async {
      // Cause failures to open circuit
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(circuitBreaker.state, equals(CircuitBreakerState.open));

      // Next request should be blocked
      expect(
        () => circuitBreaker.execute(() async => 'success'),
        throwsA(isA<ConnectionError>()),
      );
    });

    test('should transition to half-open after recovery timeout', () async {
      // Open the circuit
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(circuitBreaker.state, equals(CircuitBreakerState.open));

      // Wait for recovery timeout
      await Future.delayed(Duration(seconds: 3));

      // Next request should transition to half-open
      final result = await circuitBreaker.execute(() async => 'success');

      expect(result, equals('success'));
      expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
    });

    test('should reset to closed on successful half-open attempt', () async {
      // Open the circuit
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      await Future.delayed(Duration(seconds: 3));

      // Successful attempt should close circuit
      await circuitBreaker.execute(() async => 'success');

      expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
      expect(circuitBreaker.failureCount, equals(0));
    });

    test('should return to open on failed half-open attempts', () async {
      // Open the circuit
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      await Future.delayed(Duration(seconds: 3));

      // Fail half-open attempts
      for (int i = 0; i < 2; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(circuitBreaker.state, equals(CircuitBreakerState.open));
    });

    test('should reset manually', () async {
      // Open the circuit
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(circuitBreaker.state, equals(CircuitBreakerState.open));

      circuitBreaker.reset();

      expect(circuitBreaker.state, equals(CircuitBreakerState.closed));
      expect(circuitBreaker.failureCount, equals(0));
    });

    test('should bypass when disabled', () async {
      final disabledCircuitBreaker = CircuitBreakerService(
        config: CircuitBreakerConfig(
          enabled: false,
          failureThreshold: 3,
          recoveryTimeout: Duration(seconds: 2),
          halfOpenRetryCount: 2,
        ),
      );

      final result = await disabledCircuitBreaker.execute(() async => 'success');

      expect(result, equals('success'));
    });
  });

  group('RetryService', () {
    late RetryService retryService;

    setUp(() {
      retryService = RetryService(
        config: RetryConfig(
          enabled: true,
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 100),
          maxDelay: Duration(seconds: 5),
          backoffMultiplier: 2.0,
          jitter: false,
        ),
      );
    });

    test('should succeed on first attempt', () async {
      int attempts = 0;

      final result = await retryService.execute(() async {
        attempts++;
        return 'success';
      });

      expect(result, equals('success'));
      expect(attempts, equals(1));
    });

    test('should retry on failure', () async {
      int attempts = 0;

      final result = await retryService.execute(() async {
        attempts++;
        if (attempts < 3) {
          throw Exception('fail');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(attempts, equals(3));
    });

    test('should throw after max attempts', () async {
      int attempts = 0;

      expect(
        () => retryService.execute(() async {
          attempts++;
          throw Exception('fail');
        }),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 500));
      expect(attempts, equals(3));
    });

    test('should respect shouldRetry predicate', () async {
      int attempts = 0;

      expect(
        () => retryService.execute(
          () async {
            attempts++;
            throw Exception('non-retryable');
          },
          shouldRetry: (error) => false,
        ),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 100));
      expect(attempts, equals(1)); // Should not retry
    });

    test('should use exponential backoff', () async {
      final delays = <Duration>[];
      int attempts = 0;

      final stopwatch = Stopwatch()..start();
      DateTime? lastAttempt;

      try {
        await retryService.execute(() async {
          attempts++;
          final now = DateTime.now();
          if (lastAttempt != null) {
            delays.add(now.difference(lastAttempt!));
          }
          lastAttempt = now;
          throw Exception('fail');
        });
      } catch (_) {}

      stopwatch.stop();

      expect(attempts, equals(3));
      expect(delays.length, equals(2)); // 2 delays between 3 attempts

      // First delay should be ~100ms
      expect(
        delays[0].inMilliseconds,
        greaterThanOrEqualTo(90),
      );
      expect(
        delays[0].inMilliseconds,
        lessThanOrEqualTo(150),
      );

      // Second delay should be ~200ms (2x multiplier)
      expect(
        delays[1].inMilliseconds,
        greaterThanOrEqualTo(180),
      );
      expect(
        delays[1].inMilliseconds,
        lessThanOrEqualTo(250),
      );
    });

    test('should bypass when disabled', () async {
      final disabledRetry = RetryService(
        config: RetryConfig(
          enabled: false,
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 100),
          maxDelay: Duration(seconds: 5),
          backoffMultiplier: 2.0,
        ),
      );

      int attempts = 0;

      expect(
        () => disabledRetry.execute(() async {
          attempts++;
          throw Exception('fail');
        }),
        throwsException,
      );

      await Future.delayed(Duration(milliseconds: 100));
      expect(attempts, equals(1)); // Should not retry
    });

    test('should apply jitter when enabled', () async {
      final jitterRetry = RetryService(
        config: RetryConfig(
          enabled: true,
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 100),
          maxDelay: Duration(seconds: 5),
          backoffMultiplier: 2.0,
          jitter: true,
        ),
      );

      final delays = <Duration>[];
      DateTime? lastAttempt;

      try {
        await jitterRetry.execute(() async {
          final now = DateTime.now();
          if (lastAttempt != null) {
            delays.add(now.difference(lastAttempt!));
          }
          lastAttempt = now;
          throw Exception('fail');
        });
      } catch (_) {}

      expect(delays.length, equals(2));

      // With jitter, delays should vary but stay within expected range
      // Jitter applies 0.5-1.0 multiplier to base delay
      expect(delays[0].inMilliseconds, greaterThanOrEqualTo(50));
      expect(delays[0].inMilliseconds, lessThanOrEqualTo(150));
    });
  });

  group('HealthCheckService', () {
    late HealthCheckService healthCheck;

    setUp(() {
      healthCheck = HealthCheckService(
        config: HealthCheckConfig(
          enabled: true,
          interval: Duration(milliseconds: 100),
          timeout: Duration(seconds: 1),
          failureThreshold: 3,
        ),
      );
    });

    tearDown(() {
      healthCheck.dispose();
    });

    test('should perform periodic health checks', () async {
      final healthResults = <ConnectionHealth>[];
      int checkCount = 0;

      healthCheck.healthStream.listen((health) {
        healthResults.add(health);
      });

      healthCheck.start(() async {
        checkCount++;
        return true;
      });

      await Future.delayed(Duration(milliseconds: 350));

      healthCheck.stop();

      expect(checkCount, greaterThanOrEqualTo(2));
      expect(healthResults.length, greaterThanOrEqualTo(2));
      expect(healthResults.every((h) => h.isHealthy), isTrue);
    });

    test('should detect unhealthy state after failures', () async {
      ConnectionHealth? lastHealth;

      healthCheck.healthStream.listen((health) {
        lastHealth = health;
      });

      healthCheck.start(() async {
        return false; // Always fail
      });

      await Future.delayed(Duration(milliseconds: 350));

      healthCheck.stop();

      expect(lastHealth, isNotNull);
      expect(lastHealth!.isHealthy, isFalse);
      expect(lastHealth!.consecutiveFailures, greaterThanOrEqualTo(3));
    });

    test('should reset consecutive failures on success', () async {
      final healthResults = <ConnectionHealth>[];
      int checkCount = 0;

      healthCheck.healthStream.listen((health) {
        healthResults.add(health);
      });

      healthCheck.start(() async {
        checkCount++;
        // Fail first 2 checks, then succeed
        return checkCount > 2;
      });

      await Future.delayed(Duration(milliseconds: 350));

      healthCheck.stop();

      expect(healthResults.length, greaterThanOrEqualTo(3));

      // Last health check should have 0 consecutive failures
      final lastHealth = healthResults.last;
      expect(lastHealth.consecutiveFailures, equals(0));
    });

    test('should calculate error rate', () async {
      ConnectionHealth? lastHealth;
      int checkCount = 0;

      healthCheck.healthStream.listen((health) {
        lastHealth = health;
      });

      healthCheck.start(() async {
        checkCount++;
        // Fail first check, succeed second
        return checkCount > 1;
      });

      await Future.delayed(Duration(milliseconds: 250));

      healthCheck.stop();

      expect(lastHealth, isNotNull);
      expect(lastHealth!.errorRate, greaterThanOrEqualTo(0.0));
    });

    test('should measure latency', () async {
      ConnectionHealth? lastHealth;

      healthCheck.healthStream.listen((health) {
        lastHealth = health;
      });

      healthCheck.start(() async {
        await Future.delayed(Duration(milliseconds: 50));
        return true;
      });

      await Future.delayed(Duration(milliseconds: 200));

      healthCheck.stop();

      expect(lastHealth, isNotNull);
      expect(lastHealth!.latency.inMilliseconds, greaterThanOrEqualTo(40));
    });

    test('should stop health checks', () async {
      int checkCount = 0;

      healthCheck.start(() async {
        checkCount++;
        return true;
      });

      await Future.delayed(Duration(milliseconds: 150));

      healthCheck.stop();

      final countAfterStop = checkCount;

      await Future.delayed(Duration(milliseconds: 150));

      // Count should not increase after stop
      expect(checkCount, equals(countAfterStop));
    });
  });

  group('MessageQueueService', () {
    late MessageQueueService queue;

    setUp(() {
      queue = MessageQueueService();
    });

    tearDown(() {
      queue.dispose();
    });

    test('should enqueue messages', () {
      final message = QueuedMessage(
        id: 'msg-1',
        content: 'Hello',
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      );

      queue.enqueue(message);

      expect(queue.queueLength, equals(1));
      expect(queue.queuedMessages.first.id, equals('msg-1'));
    });

    test('should sort by priority', () {
      queue.enqueue(QueuedMessage(
        id: 'msg-1',
        content: 'Normal',
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      ));

      queue.enqueue(QueuedMessage(
        id: 'msg-2',
        content: 'High',
        timestamp: DateTime.now(),
        priority: MessagePriority.high,
      ));

      queue.enqueue(QueuedMessage(
        id: 'msg-3',
        content: 'Low',
        timestamp: DateTime.now(),
        priority: MessagePriority.low,
      ));

      final messages = queue.queuedMessages;

      expect(messages[0].priority, equals(MessagePriority.high));
      expect(messages[1].priority, equals(MessagePriority.normal));
      expect(messages[2].priority, equals(MessagePriority.low));
    });

    test('should process queue successfully', () async {
      final sentMessages = <String>[];

      queue.enqueue(QueuedMessage(
        id: 'msg-1',
        content: 'Message 1',
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      ));

      queue.enqueue(QueuedMessage(
        id: 'msg-2',
        content: 'Message 2',
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      ));

      await queue.processQueue((message) async {
        sentMessages.add(message.id);
      });

      expect(queue.queueLength, equals(0));
      expect(sentMessages.length, equals(2));
      expect(sentMessages, contains('msg-1'));
      expect(sentMessages, contains('msg-2'));
    });

    test('should re-queue failed messages', () async {
      int attempts = 0;

      queue.enqueue(QueuedMessage(
        id: 'msg-1',
        content: 'Message 1',
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      ));

      await queue.processQueue((message) async {
        attempts++;
        if (attempts == 1) {
          throw Exception('Send failed');
        }
      });

      // Message should be re-queued
      expect(queue.queueLength, equals(1));
      expect(queue.queuedMessages.first.id, equals('msg-1'));
    });

    test('should emit sent messages', () async {
      final sentMessages = <QueuedMessage>[];
      final completer = Completer<void>();

      queue.sentStream.listen((message) {
        sentMessages.add(message);
        if (sentMessages.length == 1) {
          completer.complete();
        }
      });

      queue.enqueue(QueuedMessage(
        id: 'msg-1',
        content: 'Message 1',
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      ));

      await queue.processQueue((message) async {});

      // Wait for stream event
      await completer.future.timeout(
        Duration(milliseconds: 100),
        onTimeout: () {},
      );

      expect(sentMessages.length, equals(1));
      expect(sentMessages.first.id, equals('msg-1'));
    });

    test('should clear queue', () {
      queue.enqueue(QueuedMessage(
        id: 'msg-1',
        content: 'Message 1',
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      ));

      expect(queue.queueLength, equals(1));

      queue.clear();

      expect(queue.queueLength, equals(0));
    });
  });

  group('ErrorClassifier', () {
    test('should classify network errors', () {
      final error = Exception('socket connection refused');

      final classified = ErrorClassifier.classify(error);

      expect(classified.type, equals(ConnectionErrorType.networkError));
      expect(classified.isRetryable, isTrue);
    });

    test('should classify timeout errors', () {
      final error = Exception('connection timed out');

      final classified = ErrorClassifier.classify(error);

      expect(classified.type, equals(ConnectionErrorType.timeoutError));
      expect(classified.isRetryable, isTrue);
    });

    test('should classify authentication errors', () {
      final error = Exception('401 unauthorized');

      final classified = ErrorClassifier.classify(error);

      expect(classified.type, equals(ConnectionErrorType.authenticationError));
      expect(classified.isRetryable, isFalse);
    });

    test('should classify server errors', () {
      final error = Exception('500 server error');

      final classified = ErrorClassifier.classify(error);

      expect(classified.type, equals(ConnectionErrorType.serverError));
      expect(classified.isRetryable, isTrue);
    });

    test('should classify rate limit errors', () {
      final error = Exception('429 rate limit exceeded');

      final classified = ErrorClassifier.classify(error);

      expect(classified.type, equals(ConnectionErrorType.rateLimitError));
      expect(classified.isRetryable, isTrue);
    });

    test('should classify unknown errors', () {
      final error = Exception('some random error');

      final classified = ErrorClassifier.classify(error);

      expect(classified.type, equals(ConnectionErrorType.unknown));
      expect(classified.isRetryable, isTrue);
    });

    test('should preserve ConnectionError type', () {
      final originalError = ConnectionError(
        type: ConnectionErrorType.networkError,
        message: 'Network issue',
        isRetryable: true,
      );

      final classified = ErrorClassifier.classify(originalError);

      expect(identical(classified, originalError), isTrue);
    });

    test('should check if error types are retryable', () {
      expect(
        ErrorClassifier.isRetryable(ConnectionErrorType.networkError),
        isTrue,
      );
      expect(
        ErrorClassifier.isRetryable(ConnectionErrorType.timeoutError),
        isTrue,
      );
      expect(
        ErrorClassifier.isRetryable(ConnectionErrorType.serverError),
        isTrue,
      );
      expect(
        ErrorClassifier.isRetryable(ConnectionErrorType.rateLimitError),
        isTrue,
      );
      expect(
        ErrorClassifier.isRetryable(ConnectionErrorType.authenticationError),
        isFalse,
      );
      expect(
        ErrorClassifier.isRetryable(ConnectionErrorType.circuitBreakerOpen),
        isFalse,
      );
    });

    test('should include suggested delay for retryable errors', () {
      final timeoutError = ErrorClassifier.classify(
        Exception('timeout'),
      );
      final rateLimitError = ErrorClassifier.classify(
        Exception('rate limit'),
      );

      expect(timeoutError.suggestedDelay, isNotNull);
      expect(rateLimitError.suggestedDelay, isNotNull);

      // Rate limit should suggest longer delay
      expect(
        rateLimitError.suggestedDelay!.inSeconds,
        greaterThan(timeoutError.suggestedDelay!.inSeconds),
      );
    });
  });
}
