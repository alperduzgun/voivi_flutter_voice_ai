import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:voivi_voice_ai/src/core/voivi_config.dart';

/// Circuit Breaker service for managing connection failures
class CircuitBreakerService {
  CircuitBreakerService({required this.config});

  final CircuitBreakerConfig config;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  int _halfOpenAttempts = 0;

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;

  /// Execute an operation with circuit breaker protection
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (!config.enabled) {
      return operation();
    }

    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
        _halfOpenAttempts = 0;
        developer.log('🔄 Circuit Breaker: Transitioning to HALF-OPEN state');
      } else {
        throw const ConnectionError(
          type: ConnectionErrorType.circuitBreakerOpen,
          message: 'Circuit breaker is OPEN - blocking requests',
          isRetryable: false,
        );
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _halfOpenAttempts = 0;
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.closed;
      developer.log('✅ Circuit Breaker: Transitioning to CLOSED state');
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitBreakerState.halfOpen) {
      _halfOpenAttempts++;
      if (_halfOpenAttempts >= config.halfOpenRetryCount) {
        _state = CircuitBreakerState.open;
        developer.log(
            '❌ Circuit Breaker: Transitioning to OPEN state (half-open failed)');
      }
    } else if (_state == CircuitBreakerState.closed &&
        _failureCount >= config.failureThreshold) {
      _state = CircuitBreakerState.open;
      developer.log('❌ Circuit Breaker: Transitioning to OPEN state '
          '(threshold reached: $_failureCount/${config.failureThreshold})');
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) >=
        config.recoveryTimeout;
  }

  void reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
    _halfOpenAttempts = 0;
    developer.log('🔄 Circuit Breaker: Manual reset to CLOSED state');
  }
}

/// Retry service with exponential backoff
class RetryService {
  RetryService({required this.config});

  final RetryConfig config;
  final math.Random _random = math.Random();

  /// Execute an operation with retry logic
  Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(Object error)? shouldRetry,
  }) async {
    if (!config.enabled) {
      return operation();
    }

    Object? lastError;

    for (var attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        developer.log('🔄 Retry attempt $attempt/${config.maxAttempts}');
        return await operation();
      } catch (error) {
        lastError = error;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          developer.log('❌ Error not retryable: $error');
          rethrow;
        }

        // Don't retry on last attempt
        if (attempt == config.maxAttempts) {
          developer.log('❌ Max retry attempts reached, giving up');
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(attempt);
        developer.log('⏳ Retry delay: ${delay.inMilliseconds}ms '
            'before attempt ${attempt + 1}');

        await Future.delayed(delay);
      }
    }

    throw lastError!;
  }

  Duration _calculateDelay(int attemptNumber) {
    final baseDelay = config.initialDelay.inMilliseconds;
    final exponentialDelay =
        baseDelay * math.pow(config.backoffMultiplier, attemptNumber - 1);

    // Apply maximum delay limit
    final cappedDelay =
        math.min(exponentialDelay, config.maxDelay.inMilliseconds.toDouble());

    // Apply jitter if enabled
    final finalDelay = config.jitter
        ? cappedDelay * (0.5 + _random.nextDouble() * 0.5)
        : cappedDelay;

    return Duration(milliseconds: finalDelay.round());
  }
}

/// Health check service for monitoring connection health
class HealthCheckService {
  HealthCheckService({required this.config});

  final HealthCheckConfig config;
  Timer? _healthCheckTimer;
  ConnectionHealth? _lastHealth;
  int _consecutiveFailures = 0;

  final StreamController<ConnectionHealth> _healthController =
      StreamController<ConnectionHealth>.broadcast();

  Stream<ConnectionHealth> get healthStream => _healthController.stream;
  ConnectionHealth? get lastHealth => _lastHealth;

  /// Start periodic health checks
  void start(Future<bool> Function() healthCheck) {
    if (!config.enabled) return;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(config.interval, (_) async {
      await _performHealthCheck(healthCheck);
    });

    developer.log('🏥 Health checks started '
        '(interval: ${config.interval.inSeconds}s)');
  }

  /// Stop health checks
  void stop() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    developer.log('🏥 Health checks stopped');
  }

  Future<void> _performHealthCheck(Future<bool> Function() healthCheck) async {
    final stopwatch = Stopwatch()..start();
    var isHealthy = false;

    try {
      isHealthy = await healthCheck().timeout(config.timeout);
      if (isHealthy) {
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }
    } catch (error) {
      isHealthy = false;
      _consecutiveFailures++;
      developer.log('🏥 Health check failed: $error');
    }

    stopwatch.stop();

    final health = ConnectionHealth(
      isHealthy: isHealthy && _consecutiveFailures < config.failureThreshold,
      latency: stopwatch.elapsed,
      lastCheck: DateTime.now(),
      consecutiveFailures: _consecutiveFailures,
      errorRate: _calculateErrorRate(),
    );

    _lastHealth = health;
    _healthController.add(health);

    developer.log('🏥 Health check result: '
        '${health.isHealthy ? "HEALTHY" : "UNHEALTHY"} '
        '(latency: ${health.latency.inMilliseconds}ms, '
        'failures: $_consecutiveFailures)');
  }

  double _calculateErrorRate() {
    // Simple error rate calculation based on consecutive failures
    if (_consecutiveFailures == 0) return 0;
    return math.min(1, _consecutiveFailures / config.failureThreshold);
  }

  void dispose() {
    stop();
    _healthController.close();
  }
}

/// Message queue service for offline scenarios
class MessageQueueService {
  final List<QueuedMessage> _queue = [];
  final StreamController<QueuedMessage> _sentController =
      StreamController<QueuedMessage>.broadcast();

  Stream<QueuedMessage> get sentStream => _sentController.stream;
  List<QueuedMessage> get queuedMessages => List.unmodifiable(_queue);
  int get queueLength => _queue.length;

  /// Add a message to the queue
  void enqueue(QueuedMessage message) {
    _queue.add(message);
    _queue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    developer.log('📤 Message queued: '
        '${message.content.substring(0, math.min(50, message.content.length))} '
        '(priority: ${message.priority})');
  }

  /// Process all queued messages
  Future<void> processQueue(Future<void> Function(QueuedMessage) sender) async {
    if (_queue.isEmpty) return;

    developer.log('📤 Processing ${_queue.length} queued messages...');

    final messages = List<QueuedMessage>.from(_queue);
    _queue.clear();

    for (final message in messages) {
      try {
        await sender(message);
        _sentController.add(message);
        developer.log('✅ Queued message sent: ${message.id}');
      } catch (error) {
        developer.log('❌ Failed to send queued message: '
            '${message.id}, re-queuing...');
        _queue.add(message);
      }
    }

    // Re-sort queue if we re-added any messages
    if (_queue.isNotEmpty) {
      _queue.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    }
  }

  /// Clear all queued messages
  void clear() {
    _queue.clear();
    developer.log('📤 Message queue cleared');
  }

  void dispose() {
    _sentController.close();
  }
}

/// Error classifier for connection errors
class ErrorClassifier {
  static ConnectionError classify(Object error) {
    if (error is ConnectionError) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // Network-related errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection refused') ||
        errorString.contains('no route to host')) {
      return ConnectionError(
        type: ConnectionErrorType.networkError,
        message: 'Network connectivity issue',
        suggestedDelay: const Duration(seconds: 2),
        originalError: error,
      );
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return ConnectionError(
        type: ConnectionErrorType.timeoutError,
        message: 'Connection timeout',
        suggestedDelay: const Duration(seconds: 5),
        originalError: error,
      );
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return ConnectionError(
        type: ConnectionErrorType.authenticationError,
        message: 'Authentication failed',
        isRetryable: false,
        originalError: error,
      );
    }

    // Server errors
    if (errorString.contains('server error') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return ConnectionError(
        type: ConnectionErrorType.serverError,
        message: 'Server error',
        suggestedDelay: const Duration(seconds: 10),
        originalError: error,
      );
    }

    // Rate limiting
    if (errorString.contains('rate limit') ||
        errorString.contains('429') ||
        errorString.contains('too many requests')) {
      return ConnectionError(
        type: ConnectionErrorType.rateLimitError,
        message: 'Rate limit exceeded',
        suggestedDelay: const Duration(seconds: 30),
        originalError: error,
      );
    }

    // Default to unknown
    return ConnectionError(
      type: ConnectionErrorType.unknown,
      message: error.toString(),
      suggestedDelay: const Duration(seconds: 1),
      originalError: error,
    );
  }

  static bool isRetryable(ConnectionErrorType type) {
    switch (type) {
      case ConnectionErrorType.networkError:
      case ConnectionErrorType.timeoutError:
      case ConnectionErrorType.serverError:
      case ConnectionErrorType.rateLimitError:
      case ConnectionErrorType.unknown:
        return true;
      case ConnectionErrorType.authenticationError:
      case ConnectionErrorType.circuitBreakerOpen:
        return false;
    }
  }
}
