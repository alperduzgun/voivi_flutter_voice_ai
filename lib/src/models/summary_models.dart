import 'dart:developer' as developer;

import 'package:meta/meta.dart';

/// Request model for batch summary generation
@immutable
class GenerateSummariesRequest {
  const GenerateSummariesRequest({
    required this.maxCalls,
    this.organizationId,
    this.startDate,
    this.endDate,
    this.callIds,
    this.onlyMissingSummaries = true,
  }) : assert(
          maxCalls >= 1 && maxCalls <= 500,
          'maxCalls must be between 1 and 500',
        );

  factory GenerateSummariesRequest.fromJson(Map<String, dynamic> json) {
    return GenerateSummariesRequest(
      maxCalls: json['maxCalls'] as int,
      organizationId: json['organizationId'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      callIds: json['callIds'] != null
          ? List<String>.from(json['callIds'] as List)
          : null,
      onlyMissingSummaries: json['onlyMissingSummaries'] as bool? ?? true,
    );
  }

  /// Target organization ID. If not provided, JWT's organization will be used
  final String? organizationId;

  /// Start date filter (ISO 8601 format)
  final DateTime? startDate;

  /// End date filter (ISO 8601 format)
  final DateTime? endDate;

  /// Specific call IDs to process. If provided, other filters are ignored
  final List<String>? callIds;

  /// If true, only process calls without summaries (default: true)
  final bool onlyMissingSummaries;

  /// Maximum number of calls to process (1-500)
  final int maxCalls;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'maxCalls': maxCalls,
      'onlyMissingSummaries': onlyMissingSummaries,
    };

    if (organizationId != null) {
      json['organizationId'] = organizationId;
    }
    if (startDate != null) {
      json['startDate'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      json['endDate'] = endDate!.toIso8601String();
    }
    if (callIds != null && callIds!.isNotEmpty) {
      json['callIds'] = callIds;
    }

    return json;
  }

  GenerateSummariesRequest copyWith({
    String? organizationId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? callIds,
    bool? onlyMissingSummaries,
    int? maxCalls,
  }) {
    return GenerateSummariesRequest(
      organizationId: organizationId ?? this.organizationId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      callIds: callIds ?? this.callIds,
      onlyMissingSummaries: onlyMissingSummaries ?? this.onlyMissingSummaries,
      maxCalls: maxCalls ?? this.maxCalls,
    );
  }

  @override
  String toString() {
    return 'GenerateSummariesRequest(organizationId: $organizationId, maxCalls: $maxCalls)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerateSummariesRequest &&
        other.organizationId == organizationId &&
        other.maxCalls == maxCalls &&
        other.onlyMissingSummaries == onlyMissingSummaries;
  }

  @override
  int get hashCode {
    return Object.hash(organizationId, maxCalls, onlyMissingSummaries);
  }
}

/// Successful summary generation result
@immutable
class SuccessfulSummary {
  const SuccessfulSummary({
    required this.callId,
    required this.summary,
    required this.tokensUsed,
    required this.cost,
    required this.processingTimeMs,
  });

  factory SuccessfulSummary.fromJson(Map<String, dynamic> json) {
    return SuccessfulSummary(
      callId: json['callId'] as String,
      summary: json['summary'] as String,
      tokensUsed: json['tokensUsed'] as int,
      cost: (json['cost'] as num).toDouble(),
      processingTimeMs: json['processingTimeMs'] as int,
    );
  }

  /// Call ID
  final String callId;

  /// Generated summary text
  final String summary;

  /// Total tokens used (input + output)
  final int tokensUsed;

  /// Cost in USD
  final double cost;

  /// Processing time in milliseconds
  final int processingTimeMs;

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'summary': summary,
        'tokensUsed': tokensUsed,
        'cost': cost,
        'processingTimeMs': processingTimeMs,
      };

  @override
  String toString() {
    return 'SuccessfulSummary('
        'callId: $callId, tokens: $tokensUsed, cost: \$$cost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuccessfulSummary &&
        other.callId == callId &&
        other.summary == summary &&
        other.tokensUsed == tokensUsed;
  }

  @override
  int get hashCode {
    return Object.hash(callId, summary, tokensUsed);
  }
}

/// Failed summary generation result
@immutable
class FailedSummary {
  const FailedSummary({
    required this.callId,
    required this.error,
  });

  factory FailedSummary.fromJson(Map<String, dynamic> json) {
    return FailedSummary(
      callId: json['callId'] as String,
      error: json['error'] as String,
    );
  }

  /// Call ID
  final String callId;

  /// Error message
  final String error;

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'error': error,
      };

  @override
  String toString() {
    return 'FailedSummary(callId: $callId, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FailedSummary &&
        other.callId == callId &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(callId, error);
  }
}

/// Request model for text summarization
@immutable
class SummarizeTextRequest {
  const SummarizeTextRequest({
    required this.text,
    this.customInstructions,
    this.maxSummaryTokens = 500,
    this.temperature = 0.3,
    this.modelId,
  })  : assert(text.length >= 10, 'Text must be at least 10 characters'),
        assert(
          maxSummaryTokens >= 50 && maxSummaryTokens <= 2000,
          'maxSummaryTokens must be between 50 and 2000',
        ),
        assert(
          temperature >= 0.0 && temperature <= 2.0,
          'temperature must be between 0.0 and 2.0',
        );

  factory SummarizeTextRequest.fromJson(Map<String, dynamic> json) {
    return SummarizeTextRequest(
      text: json['text'] as String,
      customInstructions: json['customInstructions'] as String?,
      maxSummaryTokens: json['maxSummaryTokens'] as int? ?? 500,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      modelId: json['modelId'] as String?,
    );
  }

  /// The text to summarize (minimum 10 characters)
  final String text;

  /// Optional custom instructions for summarization style
  final String? customInstructions;

  /// Maximum tokens for the summary (50-2000, default: 500)
  final int maxSummaryTokens;

  /// Temperature for AI generation (0.0-2.0, default: 0.3)
  final double temperature;

  /// Optional AI model ID (default: gpt-4o-mini)
  final String? modelId;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'text': text,
      'maxSummaryTokens': maxSummaryTokens,
      'temperature': temperature,
    };

    if (customInstructions != null) {
      json['customInstructions'] = customInstructions;
    }
    if (modelId != null) {
      json['modelId'] = modelId;
    }

    return json;
  }

  SummarizeTextRequest copyWith({
    String? text,
    String? customInstructions,
    int? maxSummaryTokens,
    double? temperature,
    String? modelId,
  }) {
    return SummarizeTextRequest(
      text: text ?? this.text,
      customInstructions: customInstructions ?? this.customInstructions,
      maxSummaryTokens: maxSummaryTokens ?? this.maxSummaryTokens,
      temperature: temperature ?? this.temperature,
      modelId: modelId ?? this.modelId,
    );
  }

  @override
  String toString() {
    return 'SummarizeTextRequest(textLength: ${text.length}, maxTokens: $maxSummaryTokens)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SummarizeTextRequest &&
        other.text == text &&
        other.customInstructions == customInstructions &&
        other.maxSummaryTokens == maxSummaryTokens;
  }

  @override
  int get hashCode {
    return Object.hash(text, customInstructions, maxSummaryTokens);
  }
}

/// Response model for text summarization
@immutable
class SummarizeTextResponse {
  const SummarizeTextResponse({
    required this.summary,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.cost,
    required this.model,
    required this.processingTimeMs,
    required this.generatedAt,
  });

  factory SummarizeTextResponse.fromJson(Map<String, dynamic> json) {
    try {
      return SummarizeTextResponse(
        summary: json['summary'] as String,
        inputTokens: json['inputTokens'] as int,
        outputTokens: json['outputTokens'] as int,
        totalTokens: json['totalTokens'] as int,
        cost: (json['cost'] as num).toDouble(),
        model: json['model'] as String,
        processingTimeMs: json['processingTimeMs'] as int,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
    } catch (e) {
      developer.log('❌ Error parsing SummarizeTextResponse: $e');
      rethrow;
    }
  }

  /// The generated summary text
  final String summary;

  /// Number of input tokens used
  final int inputTokens;

  /// Number of output tokens generated
  final int outputTokens;

  /// Total tokens used (input + output)
  final int totalTokens;

  /// Cost in USD
  final double cost;

  /// AI model used for summarization
  final String model;

  /// Processing time in milliseconds
  final int processingTimeMs;

  /// Timestamp when the summary was generated
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'totalTokens': totalTokens,
        'cost': cost,
        'model': model,
        'processingTimeMs': processingTimeMs,
        'generatedAt': generatedAt.toIso8601String(),
      };

  @override
  String toString() {
    return 'SummarizeTextResponse('
        'tokens: $totalTokens, cost: \$${cost.toStringAsFixed(6)}, '
        'time: ${processingTimeMs}ms)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SummarizeTextResponse &&
        other.summary == summary &&
        other.totalTokens == totalTokens &&
        other.cost == cost;
  }

  @override
  int get hashCode {
    return Object.hash(summary, totalTokens, cost);
  }
}

/// Response model for batch summary generation
@immutable
class GenerateSummariesResponse {
  const GenerateSummariesResponse({
    required this.successfulSummaries,
    required this.failedSummaries,
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
    required this.totalCost,
    required this.totalTokensUsed,
    required this.totalProcessingTimeMs,
    required this.startedAt,
    required this.completedAt,
  });

  factory GenerateSummariesResponse.fromJson(Map<String, dynamic> json) {
    try {
      final successfulList = json['successfulSummaries'] as List? ?? [];
      final failedList = json['failedSummaries'] as List? ?? [];

      return GenerateSummariesResponse(
        successfulSummaries: successfulList
            .map(
              (item) =>
                  SuccessfulSummary.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        failedSummaries: failedList
            .map(
              (item) => FailedSummary.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        totalProcessed: json['totalProcessed'] as int,
        successCount: json['successCount'] as int,
        failureCount: json['failureCount'] as int,
        totalCost: (json['totalCost'] as num).toDouble(),
        totalTokensUsed: json['totalTokensUsed'] as int,
        totalProcessingTimeMs: json['totalProcessingTimeMs'] as int,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
    } catch (e) {
      developer.log('❌ Error parsing GenerateSummariesResponse: $e');
      rethrow;
    }
  }

  /// List of successfully generated summaries
  final List<SuccessfulSummary> successfulSummaries;

  /// List of failed summary generations
  final List<FailedSummary> failedSummaries;

  /// Total number of calls processed
  final int totalProcessed;

  /// Number of successful summaries
  final int successCount;

  /// Number of failed summaries
  final int failureCount;

  /// Total cost in USD
  final double totalCost;

  /// Total tokens used across all summaries
  final int totalTokensUsed;

  /// Total processing time in milliseconds
  final int totalProcessingTimeMs;

  /// Processing start timestamp
  final DateTime startedAt;

  /// Processing completion timestamp
  final DateTime completedAt;

  /// Calculate success rate (0.0 - 1.0)
  double get successRate =>
      totalProcessed > 0 ? successCount / totalProcessed : 0.0;

  /// Calculate average cost per call
  double get averageCostPerCall =>
      successCount > 0 ? totalCost / successCount : 0.0;

  /// Calculate average tokens per call
  double get averageTokensPerCall =>
      successCount > 0 ? totalTokensUsed / successCount : 0.0;

  /// Calculate average processing time per call (ms)
  double get averageProcessingTimeMs =>
      successCount > 0 ? totalProcessingTimeMs / successCount : 0.0;

  /// Get total processing duration
  Duration get processingDuration => completedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'successfulSummaries':
            successfulSummaries.map((s) => s.toJson()).toList(),
        'failedSummaries': failedSummaries.map((f) => f.toJson()).toList(),
        'totalProcessed': totalProcessed,
        'successCount': successCount,
        'failureCount': failureCount,
        'totalCost': totalCost,
        'totalTokensUsed': totalTokensUsed,
        'totalProcessingTimeMs': totalProcessingTimeMs,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
      };

  @override
  String toString() {
    return 'GenerateSummariesResponse('
        'success: $successCount/$totalProcessed, '
        'cost: \$${totalCost.toStringAsFixed(6)}, '
        'tokens: $totalTokensUsed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerateSummariesResponse &&
        other.totalProcessed == totalProcessed &&
        other.successCount == successCount &&
        other.failureCount == failureCount;
  }

  @override
  int get hashCode {
    return Object.hash(totalProcessed, successCount, failureCount);
  }
}
