import 'package:test/test.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

void main() {
  group('GenerateSummariesRequest', () {
    test('creates instance with required maxCalls parameter', () {
      final request = GenerateSummariesRequest(maxCalls: 10);

      expect(request.maxCalls, 10);
      expect(request.onlyMissingSummaries, true);
      expect(request.organizationId, isNull);
      expect(request.startDate, isNull);
      expect(request.endDate, isNull);
      expect(request.callIds, isNull);
    });

    test('creates instance with all parameters', () {
      final startDate = DateTime(2025, 10, 1);
      final endDate = DateTime(2025, 10, 31);
      final callIds = ['call1', 'call2'];

      final request = GenerateSummariesRequest(
        maxCalls: 50,
        organizationId: 'org123',
        startDate: startDate,
        endDate: endDate,
        callIds: callIds,
        onlyMissingSummaries: false,
      );

      expect(request.maxCalls, 50);
      expect(request.organizationId, 'org123');
      expect(request.startDate, startDate);
      expect(request.endDate, endDate);
      expect(request.callIds, callIds);
      expect(request.onlyMissingSummaries, false);
    });

    test('throws assertion error when maxCalls is less than 1', () {
      expect(
        () => GenerateSummariesRequest(maxCalls: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error when maxCalls is greater than 500', () {
      expect(
        () => GenerateSummariesRequest(maxCalls: 501),
        throwsA(isA<AssertionError>()),
      );
    });

    test('serializes to JSON correctly', () {
      final request = GenerateSummariesRequest(
        maxCalls: 10,
        organizationId: 'org123',
        onlyMissingSummaries: false,
      );

      final json = request.toJson();

      expect(json['maxCalls'], 10);
      expect(json['organizationId'], 'org123');
      expect(json['onlyMissingSummaries'], false);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'maxCalls': 20,
        'organizationId': 'org456',
        'startDate': '2025-10-01T00:00:00.000Z',
        'endDate': '2025-10-31T23:59:59.000Z',
        'callIds': ['call1', 'call2', 'call3'],
        'onlyMissingSummaries': true,
      };

      final request = GenerateSummariesRequest.fromJson(json);

      expect(request.maxCalls, 20);
      expect(request.organizationId, 'org456');
      expect(request.startDate, isNotNull);
      expect(request.endDate, isNotNull);
      expect(request.callIds, hasLength(3));
      expect(request.onlyMissingSummaries, true);
    });

    test('copyWith creates new instance with updated values', () {
      final original = GenerateSummariesRequest(
        maxCalls: 10,
        organizationId: 'org123',
      );

      final updated = original.copyWith(
        maxCalls: 20,
        onlyMissingSummaries: false,
      );

      expect(updated.maxCalls, 20);
      expect(updated.organizationId, 'org123');
      expect(updated.onlyMissingSummaries, false);
    });
  });

  group('SuccessfulSummary', () {
    test('creates instance with all required fields', () {
      final summary = SuccessfulSummary(
        callId: 'call123',
        summary: 'This is a test summary',
        tokensUsed: 1500,
        cost: 0.0003,
        processingTimeMs: 2000,
      );

      expect(summary.callId, 'call123');
      expect(summary.summary, 'This is a test summary');
      expect(summary.tokensUsed, 1500);
      expect(summary.cost, 0.0003);
      expect(summary.processingTimeMs, 2000);
    });

    test('serializes to JSON correctly', () {
      final summary = SuccessfulSummary(
        callId: 'call123',
        summary: 'Test summary',
        tokensUsed: 1000,
        cost: 0.0002,
        processingTimeMs: 1500,
      );

      final json = summary.toJson();

      expect(json['callId'], 'call123');
      expect(json['summary'], 'Test summary');
      expect(json['tokensUsed'], 1000);
      expect(json['cost'], 0.0002);
      expect(json['processingTimeMs'], 1500);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'callId': 'call456',
        'summary': 'Another test summary',
        'tokensUsed': 2000,
        'cost': 0.0004,
        'processingTimeMs': 2500,
      };

      final summary = SuccessfulSummary.fromJson(json);

      expect(summary.callId, 'call456');
      expect(summary.summary, 'Another test summary');
      expect(summary.tokensUsed, 2000);
      expect(summary.cost, 0.0004);
      expect(summary.processingTimeMs, 2500);
    });
  });

  group('FailedSummary', () {
    test('creates instance with required fields', () {
      final failed = FailedSummary(
        callId: 'call789',
        error: 'Call not found',
      );

      expect(failed.callId, 'call789');
      expect(failed.error, 'Call not found');
    });

    test('serializes to JSON correctly', () {
      final failed = FailedSummary(
        callId: 'call789',
        error: 'No transcript available',
      );

      final json = failed.toJson();

      expect(json['callId'], 'call789');
      expect(json['error'], 'No transcript available');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'callId': 'call999',
        'error': 'Transcript too short',
      };

      final failed = FailedSummary.fromJson(json);

      expect(failed.callId, 'call999');
      expect(failed.error, 'Transcript too short');
    });
  });

  group('GenerateSummariesResponse', () {
    test('creates instance with all required fields', () {
      final successfulSummaries = [
        SuccessfulSummary(
          callId: 'call1',
          summary: 'Summary 1',
          tokensUsed: 1000,
          cost: 0.0002,
          processingTimeMs: 1500,
        ),
      ];

      final failedSummaries = [
        FailedSummary(callId: 'call2', error: 'Error'),
      ];

      final response = GenerateSummariesResponse(
        successfulSummaries: successfulSummaries,
        failedSummaries: failedSummaries,
        totalProcessed: 2,
        successCount: 1,
        failureCount: 1,
        totalCost: 0.0002,
        totalTokensUsed: 1000,
        totalProcessingTimeMs: 1500,
        startedAt: DateTime(2025, 10, 31, 12, 0),
        completedAt: DateTime(2025, 10, 31, 12, 0, 2),
      );

      expect(response.successfulSummaries, hasLength(1));
      expect(response.failedSummaries, hasLength(1));
      expect(response.totalProcessed, 2);
      expect(response.successCount, 1);
      expect(response.failureCount, 1);
      expect(response.totalCost, 0.0002);
      expect(response.totalTokensUsed, 1000);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'successfulSummaries': [
          {
            'callId': 'call1',
            'summary': 'Summary 1',
            'tokensUsed': 1000,
            'cost': 0.0002,
            'processingTimeMs': 1500,
          },
        ],
        'failedSummaries': [
          {
            'callId': 'call2',
            'error': 'Error message',
          },
        ],
        'totalProcessed': 2,
        'successCount': 1,
        'failureCount': 1,
        'totalCost': 0.0002,
        'totalTokensUsed': 1000,
        'totalProcessingTimeMs': 1500,
        'startedAt': '2025-10-31T12:00:00.000Z',
        'completedAt': '2025-10-31T12:00:02.000Z',
      };

      final response = GenerateSummariesResponse.fromJson(json);

      expect(response.successfulSummaries, hasLength(1));
      expect(response.failedSummaries, hasLength(1));
      expect(response.totalProcessed, 2);
      expect(response.successCount, 1);
      expect(response.failureCount, 1);
    });

    test('calculates success rate correctly', () {
      final response = GenerateSummariesResponse(
        successfulSummaries: [],
        failedSummaries: [],
        totalProcessed: 10,
        successCount: 8,
        failureCount: 2,
        totalCost: 0.001,
        totalTokensUsed: 5000,
        totalProcessingTimeMs: 15000,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      expect(response.successRate, 0.8);
    });

    test('calculates average cost per call correctly', () {
      final response = GenerateSummariesResponse(
        successfulSummaries: [],
        failedSummaries: [],
        totalProcessed: 10,
        successCount: 5,
        failureCount: 5,
        totalCost: 0.001,
        totalTokensUsed: 5000,
        totalProcessingTimeMs: 15000,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      expect(response.averageCostPerCall, 0.0002);
    });

    test('calculates average tokens per call correctly', () {
      final response = GenerateSummariesResponse(
        successfulSummaries: [],
        failedSummaries: [],
        totalProcessed: 10,
        successCount: 5,
        failureCount: 5,
        totalCost: 0.001,
        totalTokensUsed: 5000,
        totalProcessingTimeMs: 15000,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      expect(response.averageTokensPerCall, 1000.0);
    });

    test('calculates processing duration correctly', () {
      final startedAt = DateTime(2025, 10, 31, 12, 0, 0);
      final completedAt = DateTime(2025, 10, 31, 12, 0, 5);

      final response = GenerateSummariesResponse(
        successfulSummaries: [],
        failedSummaries: [],
        totalProcessed: 10,
        successCount: 10,
        failureCount: 0,
        totalCost: 0.001,
        totalTokensUsed: 5000,
        totalProcessingTimeMs: 15000,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      expect(response.processingDuration.inSeconds, 5);
    });

    test('handles empty summaries lists', () {
      final json = {
        'successfulSummaries': [],
        'failedSummaries': [],
        'totalProcessed': 0,
        'successCount': 0,
        'failureCount': 0,
        'totalCost': 0.0,
        'totalTokensUsed': 0,
        'totalProcessingTimeMs': 0,
        'startedAt': '2025-10-31T12:00:00.000Z',
        'completedAt': '2025-10-31T12:00:00.000Z',
      };

      final response = GenerateSummariesResponse.fromJson(json);

      expect(response.successfulSummaries, isEmpty);
      expect(response.failedSummaries, isEmpty);
      expect(response.totalProcessed, 0);
      expect(response.successRate, 0.0);
    });
  });
}
