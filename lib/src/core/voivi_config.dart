/// Configuration class for Voivi Chat package
class VoiviConfig {
  const VoiviConfig({
    required this.apiKey,
    required this.organizationId,
    required this.assistantId,
    required this.baseUrl,
    this.userId,
    this.llmModel = 'gpt-4o',
    this.enableTTS = false,
    this.ttsProvider = 'ai-services',
    this.ttsProviderType = 'azureopenaitts',
    this.ttsVoice = 'alloy',
    this.enableCustomerDetection = true,
    this.minCustomerConfidence = 0.75,
    this.backgroundNoiseThreshold = 0.3,
    this.enableSentimentAnalysis = true,
    this.enableRealTimeAnalysis = true,
    this.enableConversationContext = false,
    this.defaultUserId = 'client-user',
    this.connectionTimeoutMs = 30000,
    this.reconnectAttempts = 3,
    this.reconnectDelayMs = 1000,
    this.resilienceConfig = const VoiviResilienceConfig(),
  });

  /// Factory for development environment (localhost backend)
  ///
  /// Example:
  /// ```dart
  /// final config = VoiviConfig.development(
  ///   organizationId: 'your-org-id',
  ///   apiKey: 'your-api-key',
  ///   assistantId: 'your-assistant-id',
  /// );
  /// ```
  factory VoiviConfig.development({
    required String organizationId,
    required String apiKey,
    required String assistantId,
    String? userId,
    String baseUrl = 'http://localhost:5065',
    String llmModel = 'gpt-4o',
    bool enableTTS = false,
    String ttsProvider = 'ai-services',
    String ttsProviderType = 'azureopenaitts',
    String ttsVoice = 'alloy',
    bool enableCustomerDetection = true,
    double minCustomerConfidence = 0.75,
    double backgroundNoiseThreshold = 0.3,
    bool enableSentimentAnalysis = true,
    bool enableRealTimeAnalysis = true,
    bool enableConversationContext = false,
    String defaultUserId = 'client-user',
    int connectionTimeoutMs = 30000,
    int reconnectAttempts = 3,
    int reconnectDelayMs = 1000,
    VoiviResilienceConfig resilienceConfig = const VoiviResilienceConfig(),
  }) {
    return VoiviConfig(
      organizationId: organizationId,
      apiKey: apiKey,
      assistantId: assistantId,
      userId: userId,
      baseUrl: baseUrl,
      llmModel: llmModel,
      enableTTS: enableTTS,
      ttsProvider: ttsProvider,
      ttsProviderType: ttsProviderType,
      ttsVoice: ttsVoice,
      enableCustomerDetection: enableCustomerDetection,
      minCustomerConfidence: minCustomerConfidence,
      backgroundNoiseThreshold: backgroundNoiseThreshold,
      enableSentimentAnalysis: enableSentimentAnalysis,
      enableRealTimeAnalysis: enableRealTimeAnalysis,
      enableConversationContext: enableConversationContext,
      defaultUserId: defaultUserId,
      connectionTimeoutMs: connectionTimeoutMs,
      reconnectAttempts: reconnectAttempts,
      reconnectDelayMs: reconnectDelayMs,
      resilienceConfig: resilienceConfig,
    );
  }

  /// Factory for production environment (Azure backend)
  ///
  /// Example:
  /// ```dart
  /// final config = VoiviConfig.production(
  ///   organizationId: 'your-org-id',
  ///   apiKey: 'your-api-key',
  ///   assistantId: 'your-assistant-id',
  /// );
  /// ```
  factory VoiviConfig.production({
    required String organizationId,
    required String apiKey,
    required String assistantId,
    String? userId,
    String baseUrl = 'https://voivi-engineering.azurewebsites.net',
    String llmModel = 'gpt-4o',
    bool enableTTS = false,
    String ttsProvider = 'ai-services',
    String ttsProviderType = 'azureopenaitts',
    String ttsVoice = 'alloy',
    bool enableCustomerDetection = true,
    double minCustomerConfidence = 0.75,
    double backgroundNoiseThreshold = 0.3,
    bool enableSentimentAnalysis = true,
    bool enableRealTimeAnalysis = true,
    bool enableConversationContext = false,
    String defaultUserId = 'client-user',
    int connectionTimeoutMs = 30000,
    int reconnectAttempts = 3,
    int reconnectDelayMs = 1000,
    VoiviResilienceConfig resilienceConfig = const VoiviResilienceConfig(),
  }) {
    return VoiviConfig(
      organizationId: organizationId,
      apiKey: apiKey,
      assistantId: assistantId,
      userId: userId,
      baseUrl: baseUrl,
      llmModel: llmModel,
      enableTTS: enableTTS,
      ttsProvider: ttsProvider,
      ttsProviderType: ttsProviderType,
      ttsVoice: ttsVoice,
      enableCustomerDetection: enableCustomerDetection,
      minCustomerConfidence: minCustomerConfidence,
      backgroundNoiseThreshold: backgroundNoiseThreshold,
      enableSentimentAnalysis: enableSentimentAnalysis,
      enableRealTimeAnalysis: enableRealTimeAnalysis,
      enableConversationContext: enableConversationContext,
      defaultUserId: defaultUserId,
      connectionTimeoutMs: connectionTimeoutMs,
      reconnectAttempts: reconnectAttempts,
      reconnectDelayMs: reconnectDelayMs,
      resilienceConfig: resilienceConfig,
    );
  }

  /// Factory for demo/testing purposes
  ///
  /// ⚠️ Do not use in production! This uses placeholder credentials.
  ///
  /// Example:
  /// ```dart
  /// final config = VoiviConfig.demo(
  ///   assistantId: 'demo-assistant-id',
  /// );
  /// ```
  factory VoiviConfig.demo({
    String organizationId = 'demo-organization',
    String apiKey = 'demo-api-key',
    required String assistantId,
    String? userId,
    String baseUrl = 'http://localhost:5065',
    String llmModel = 'gpt-4o',
    bool enableTTS = false,
  }) {
    return VoiviConfig(
      organizationId: organizationId,
      apiKey: apiKey,
      assistantId: assistantId,
      userId: userId,
      baseUrl: baseUrl,
      llmModel: llmModel,
      enableTTS: enableTTS,
    );
  }

  factory VoiviConfig.fromJson(Map<String, dynamic> json) => VoiviConfig(
    apiKey: json['apiKey'] as String,
    organizationId: json['organizationId'] as String,
    assistantId: json['assistantId'] as String,
    baseUrl: json['baseUrl'] as String,
    userId: json['userId'] as String?,
    llmModel: json['llmModel'] as String? ?? 'gpt-4o',
    enableTTS: json['enableTTS'] as bool? ?? false,
    ttsProvider: json['ttsProvider'] as String? ?? 'ai-services',
    ttsProviderType: json['ttsProviderType'] as String? ?? 'azureopenaitts',
    ttsVoice: json['ttsVoice'] as String? ?? 'alloy',
    enableCustomerDetection: json['enableCustomerDetection'] as bool? ?? true,
    minCustomerConfidence:
        (json['minCustomerConfidence'] as num?)?.toDouble() ?? 0.75,
    backgroundNoiseThreshold:
        (json['backgroundNoiseThreshold'] as num?)?.toDouble() ?? 0.3,
    enableSentimentAnalysis: json['enableSentimentAnalysis'] as bool? ?? true,
    enableRealTimeAnalysis: json['enableRealTimeAnalysis'] as bool? ?? true,
    enableConversationContext:
        json['enableConversationContext'] as bool? ?? false,
    defaultUserId: json['defaultUserId'] as String? ?? 'client-user',
    connectionTimeoutMs: json['connectionTimeoutMs'] as int? ?? 30000,
    reconnectAttempts: json['reconnectAttempts'] as int? ?? 3,
    reconnectDelayMs: json['reconnectDelayMs'] as int? ?? 1000,
  );

  // Core required configuration
  final String apiKey;
  final String organizationId;
  final String assistantId;
  final String baseUrl;
  final String? userId;

  // AI & Language Model settings
  final String llmModel;
  final bool enableTTS;
  final String ttsProvider;
  final String ttsProviderType;
  final String ttsVoice;

  // Audio & Detection settings
  final bool enableCustomerDetection;
  final double minCustomerConfidence;
  final double backgroundNoiseThreshold;

  // Analysis settings
  final bool enableSentimentAnalysis;
  final bool enableRealTimeAnalysis;
  final bool enableConversationContext;

  // Connection settings
  final String defaultUserId;
  final int connectionTimeoutMs;
  final int reconnectAttempts;
  final int reconnectDelayMs;
  final VoiviResilienceConfig resilienceConfig;

  /// Gets the effective user ID (userId if provided, otherwise defaultUserId)
  String get effectiveUserId => userId ?? defaultUserId;

  /// Converts config to WebSocket URL parameters
  /// Generates a unique clientSessionId for this connection
  Map<String, String> toWebSocketParams() {
    // Generate unique clientSessionId for this WebSocket connection
    final clientSessionId = 'flutter_${DateTime.now().millisecondsSinceEpoch}_${effectiveUserId}';

    return {
      'assistantId': assistantId,
      'organizationId': organizationId,
      'userId': effectiveUserId,
      'clientSessionId': clientSessionId,
      'llmModel': llmModel,
      'enableTTS': enableTTS.toString(),
      'ttsProvider': ttsProvider,
      'ttsProviderType': ttsProviderType,
      'ttsVoice': ttsVoice,
      'enableCustomerDetection': enableCustomerDetection.toString(),
      'minCustomerConfidence': minCustomerConfidence.toString(),
      'backgroundNoiseThreshold': backgroundNoiseThreshold.toString(),
      'enableSentimentAnalysis': enableSentimentAnalysis.toString(),
      'enableRealTimeAnalysis': enableRealTimeAnalysis.toString(),
      'enableConversationContext': enableConversationContext.toString(),
    };
  }

  VoiviConfig copyWith({
    String? apiKey,
    String? organizationId,
    String? assistantId,
    String? baseUrl,
    String? userId,
    String? llmModel,
    bool? enableTTS,
    String? ttsProvider,
    String? ttsProviderType,
    String? ttsVoice,
    bool? enableCustomerDetection,
    double? minCustomerConfidence,
    double? backgroundNoiseThreshold,
    bool? enableSentimentAnalysis,
    bool? enableRealTimeAnalysis,
    bool? enableConversationContext,
    String? defaultUserId,
    int? connectionTimeoutMs,
    int? reconnectAttempts,
    int? reconnectDelayMs,
    VoiviResilienceConfig? resilienceConfig,
  }) {
    return VoiviConfig(
      apiKey: apiKey ?? this.apiKey,
      organizationId: organizationId ?? this.organizationId,
      assistantId: assistantId ?? this.assistantId,
      baseUrl: baseUrl ?? this.baseUrl,
      userId: userId ?? this.userId,
      llmModel: llmModel ?? this.llmModel,
      enableTTS: enableTTS ?? this.enableTTS,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      ttsProviderType: ttsProviderType ?? this.ttsProviderType,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      enableCustomerDetection:
          enableCustomerDetection ?? this.enableCustomerDetection,
      minCustomerConfidence:
          minCustomerConfidence ?? this.minCustomerConfidence,
      backgroundNoiseThreshold:
          backgroundNoiseThreshold ?? this.backgroundNoiseThreshold,
      enableSentimentAnalysis:
          enableSentimentAnalysis ?? this.enableSentimentAnalysis,
      enableRealTimeAnalysis:
          enableRealTimeAnalysis ?? this.enableRealTimeAnalysis,
      enableConversationContext:
          enableConversationContext ?? this.enableConversationContext,
      defaultUserId: defaultUserId ?? this.defaultUserId,
      connectionTimeoutMs: connectionTimeoutMs ?? this.connectionTimeoutMs,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      reconnectDelayMs: reconnectDelayMs ?? this.reconnectDelayMs,
      resilienceConfig: resilienceConfig ?? this.resilienceConfig,
    );
  }

  Map<String, dynamic> toJson() => {
    'apiKey': apiKey,
    'organizationId': organizationId,
    'assistantId': assistantId,
    'baseUrl': baseUrl,
    'userId': userId,
    'llmModel': llmModel,
    'enableTTS': enableTTS,
    'ttsProvider': ttsProvider,
    'ttsProviderType': ttsProviderType,
    'ttsVoice': ttsVoice,
    'enableCustomerDetection': enableCustomerDetection,
    'minCustomerConfidence': minCustomerConfidence,
    'backgroundNoiseThreshold': backgroundNoiseThreshold,
    'enableSentimentAnalysis': enableSentimentAnalysis,
    'enableRealTimeAnalysis': enableRealTimeAnalysis,
    'enableConversationContext': enableConversationContext,
    'defaultUserId': defaultUserId,
    'connectionTimeoutMs': connectionTimeoutMs,
    'reconnectAttempts': reconnectAttempts,
    'reconnectDelayMs': reconnectDelayMs,
  };

  @override
  String toString() {
    return 'VoiviConfig(apiKey: ${apiKey.length > 8 ? '${apiKey.substring(0, 8)}***' : '***'}, '
        'organizationId: $organizationId, assistantId: $assistantId, baseUrl: $baseUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiviConfig &&
        other.apiKey == apiKey &&
        other.organizationId == organizationId &&
        other.assistantId == assistantId &&
        other.baseUrl == baseUrl &&
        other.userId == userId &&
        other.llmModel == llmModel &&
        other.enableTTS == enableTTS &&
        other.enableSentimentAnalysis == enableSentimentAnalysis;
  }

  @override
  int get hashCode {
    return Object.hash(
      apiKey,
      organizationId,
      assistantId,
      baseUrl,
      userId,
      llmModel,
      enableTTS,
      enableSentimentAnalysis,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.timestamp,
    required this.type,
    this.content,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: ChatMessageType.values.firstWhere((e) => e.name == json['type']),
    content: json['content'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  final String id;
  final String conversationId;
  final DateTime timestamp;
  final ChatMessageType type;
  final String? content;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'content': content,
    'metadata': metadata,
  };
}

enum ChatMessageType {
  userText,
  assistantText,
  system,
  error,
}

class ConversationState {
  const ConversationState({
    this.isConnected = false,
    this.isProcessing = false,
    this.messages = const [],
    this.currentConversationId,
    this.error,
    this.sentimentData,
  });

  factory ConversationState.fromJson(Map<String, dynamic> json) =>
      ConversationState(
        isConnected: json['isConnected'] as bool? ?? false,
        isProcessing: json['isProcessing'] as bool? ?? false,
        messages:
            (json['messages'] as List?)
                ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        currentConversationId: json['currentConversationId'] as String?,
        error: json['error'] as String?,
        sentimentData: json['sentimentData'] as Map<String, dynamic>?,
      );

  final bool isConnected;
  final bool isProcessing;
  final List<ChatMessage> messages;
  final String? currentConversationId;
  final String? error;
  final Map<String, dynamic>? sentimentData;

  ConversationState copyWith({
    bool? isConnected,
    bool? isProcessing,
    List<ChatMessage>? messages,
    String? currentConversationId,
    String? error,
    Map<String, dynamic>? sentimentData,
  }) => ConversationState(
    isConnected: isConnected ?? this.isConnected,
    isProcessing: isProcessing ?? this.isProcessing,
    messages: messages ?? this.messages,
    currentConversationId: currentConversationId ?? this.currentConversationId,
    error: error ?? this.error,
    sentimentData: sentimentData ?? this.sentimentData,
  );

  Map<String, dynamic> toJson() => {
    'isConnected': isConnected,
    'isProcessing': isProcessing,
    'messages': messages.map((m) => m.toJson()).toList(),
    'currentConversationId': currentConversationId,
    'error': error,
    'sentimentData': sentimentData,
  };
}

/// Enhanced resilience configuration for Chaos Engineering
class VoiviResilienceConfig {
  const VoiviResilienceConfig({
    this.circuitBreakerConfig = const CircuitBreakerConfig(),
    this.retryConfig = const RetryConfig(),
    this.timeoutConfig = const TimeoutConfig(),
    this.healthCheckConfig = const HealthCheckConfig(),
  });

  final CircuitBreakerConfig circuitBreakerConfig;
  final RetryConfig retryConfig;
  final TimeoutConfig timeoutConfig;
  final HealthCheckConfig healthCheckConfig;
}

/// Circuit Breaker pattern configuration
class CircuitBreakerConfig {
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(seconds: 30),
    this.halfOpenRetryCount = 3,
    this.enabled = true,
  });

  final int failureThreshold;
  final Duration recoveryTimeout;
  final int halfOpenRetryCount;
  final bool enabled;
}

/// Retry configuration with exponential backoff
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitter = true,
    this.enabled = true,
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool jitter;
  final bool enabled;
}

/// Dynamic timeout configuration
class TimeoutConfig {
  const TimeoutConfig({
    this.connectionTimeout = const Duration(seconds: 30),
    this.messageTimeout = const Duration(seconds: 15),
    this.adaptiveTimeouts = true,
    this.timeoutMultiplier = 1.5,
  });

  final Duration connectionTimeout;
  final Duration messageTimeout;
  final bool adaptiveTimeouts;
  final double timeoutMultiplier;
}

/// Health check configuration
class HealthCheckConfig {
  const HealthCheckConfig({
    this.interval = const Duration(seconds: 30),
    this.timeout = const Duration(seconds: 5),
    this.enabled = true,
    this.failureThreshold = 3,
  });

  final Duration interval;
  final Duration timeout;
  final bool enabled;
  final int failureThreshold;
}

/// Connection error classification
enum ConnectionErrorType {
  networkError,
  authenticationError,
  serverError,
  timeoutError,
  rateLimitError,
  circuitBreakerOpen,
  unknown,
}

/// Connection error with classification and recovery strategy
class ConnectionError {
  const ConnectionError({
    required this.type,
    required this.message,
    this.isRetryable = true,
    this.suggestedDelay,
    this.originalError,
  });

  final ConnectionErrorType type;
  final String message;
  final bool isRetryable;
  final Duration? suggestedDelay;
  final Object? originalError;

  @override
  String toString() => 'ConnectionError(type: $type, message: $message)';
}

/// Circuit breaker states
enum CircuitBreakerState {
  closed,
  open,
  halfOpen,
}

/// Message queue item for offline scenarios
class QueuedMessage {
  const QueuedMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.priority = MessagePriority.normal,
  });

  final String id;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final MessagePriority priority;
}

enum MessagePriority {
  low,
  normal,
  high,
  critical,
}

/// Connection health metrics
class ConnectionHealth {
  const ConnectionHealth({
    required this.isHealthy,
    required this.latency,
    required this.lastCheck,
    this.consecutiveFailures = 0,
    this.errorRate = 0.0,
  });

  final bool isHealthy;
  final Duration latency;
  final DateTime lastCheck;
  final int consecutiveFailures;
  final double errorRate;
}

/// Assistant model representing a Voivi AI assistant
class AssistantModel {
  const AssistantModel({
    required this.id,
    required this.name,
    this.description,
    this.firstMessage,
    this.endCallMessage,
    this.toolIds,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory AssistantModel.fromJson(Map<String, dynamic> json) {
    // Parse toolIds from model.toolIds path
    List<String>? toolIds;
    try {
      if (json['model'] != null && json['model']['toolIds'] != null) {
        final toolIdsData = json['model']['toolIds'];
        if (toolIdsData is List) {
          toolIds = toolIdsData.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      // Silently ignore toolIds parsing errors
      toolIds = null;
    }

    return AssistantModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['Name'] as String,
      description:
          json['description'] as String? ?? json['Description'] as String?,
      firstMessage: json['firstMessage'] as String? ??
          json['FirstMessage'] as String?,
      endCallMessage: json['endCallMessage'] as String? ??
          json['EndCallMessage'] as String?,
      toolIds: toolIds,
      metadata: json['metadata'] as Map<String, dynamic>? ??
          json['Metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['CreatedAt'] != null
              ? DateTime.parse(json['CreatedAt'] as String)
              : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['UpdatedAt'] != null
              ? DateTime.parse(json['UpdatedAt'] as String)
              : null),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? firstMessage;
  final String? endCallMessage;
  final List<String>? toolIds;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AssistantModel copyWith({
    String? id,
    String? name,
    String? description,
    String? firstMessage,
    String? endCallMessage,
    List<String>? toolIds,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssistantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      firstMessage: firstMessage ?? this.firstMessage,
      endCallMessage: endCallMessage ?? this.endCallMessage,
      toolIds: toolIds ?? this.toolIds,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (firstMessage != null) 'firstMessage': firstMessage,
        if (endCallMessage != null) 'endCallMessage': endCallMessage,
        if (toolIds != null) 'toolIds': toolIds,
        if (metadata != null) 'metadata': metadata,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  @override
  String toString() {
    return 'AssistantModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssistantModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.firstMessage == firstMessage &&
        other.endCallMessage == endCallMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      firstMessage,
      endCallMessage,
    );
  }
}
