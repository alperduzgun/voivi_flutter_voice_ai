import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:voivi_voice_ai/src/core/voivi_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'resilience_service.dart';
import 'tool_registry_service.dart';

class WebSocketService {
  static WebSocketService? _instance;

  factory WebSocketService() {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<ChatMessage>? _messageController;
  StreamController<ConversationState>? _stateController;

  ConversationState _currentState = const ConversationState();
  VoiviConfig? _config;

  // Tool Registry for client-side tool execution
  ToolRegistry? _toolRegistry;

  // Resilience services
  CircuitBreakerService? _circuitBreaker;
  RetryService? _retryService;
  HealthCheckService? _healthCheckService;
  MessageQueueService? _messageQueue;

  Stream<ChatMessage> get messageStream {
    developer.log('📡 WebSocket: messageStream requested, controller exists: ${_messageController != null}');
    // Ensure controller is initialized
    _messageController ??= StreamController<ChatMessage>.broadcast();
    return _messageController!.stream;
  }

  Stream<ConversationState> get stateStream {
    developer.log('📡 WebSocket: stateStream requested, controller exists: ${_stateController != null}');
    // Ensure controller is initialized
    _stateController ??= StreamController<ConversationState>.broadcast();
    return _stateController!.stream;
  }

  ConversationState get currentState => _currentState;

  /// Set the tool registry for client-side tool execution
  void setToolRegistry(ToolRegistry registry) {
    _toolRegistry = registry;
    developer.log(
      '🔧 WebSocket: Tool registry set (${registry.toolCount} tools registered)',
    );
  }

  Future<void> connect(VoiviConfig config) async {
    _config = config;
    _initializeResilienceServices(config.resilienceConfig);

    developer.log('🔧 WebSocket: Creating stream controllers...');
    _messageController ??= StreamController<ChatMessage>.broadcast();
    _stateController ??= StreamController<ConversationState>.broadcast();
    developer.log('✅ WebSocket: Controllers created - Message: ${_messageController != null}, State: ${_stateController != null}');

    // Use retry service with circuit breaker for connection
    await _retryService!.execute(() async {
      return await _circuitBreaker!.execute(() async {
        await _connectWithResilience(config);
      });
    }, shouldRetry: (error) {
      final classified = ErrorClassifier.classify(error);
      return classified.isRetryable;
    });
  }

  Future<void> _connectWithResilience(VoiviConfig config) async {
    try {
      // Construct WebSocket URL for text chat
      final wsUrl = _buildWebSocketUrl(config);
      developer.log('🔌 Voivi WebSocket: Connecting to: $wsUrl');

      // Use adaptive timeout
      final timeout = config.resilienceConfig.timeoutConfig.connectionTimeout;
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for connection with timeout
      await _channel!.ready.timeout(timeout);

      _updateState(_currentState.copyWith(isConnected: true));
      developer.log('✅ Voivi WebSocket: Connection established');

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Start health checks
      _healthCheckService?.start(() async {
        return _channel != null && _currentState.isConnected;
      });

      // Process any queued messages
      _processQueuedMessages();

    } catch (e) {
      final classified = ErrorClassifier.classify(e);
      developer.log('❌ Voivi WebSocket: Connection error: ${classified.type} - ${classified.message}');

      _updateState(
        _currentState.copyWith(
          isConnected: false,
          error: classified.message,
        ),
      );

      throw classified;
    }
  }

  void _initializeResilienceServices(VoiviResilienceConfig config) {
    _circuitBreaker = CircuitBreakerService(config: config.circuitBreakerConfig);
    _retryService = RetryService(config: config.retryConfig);
    _healthCheckService = HealthCheckService(config: config.healthCheckConfig);
    _messageQueue = MessageQueueService();

    developer.log('🛡️ Resilience services initialized');
  }

  String _buildWebSocketUrl(VoiviConfig config) {
    final baseWsUrl = config.baseUrl.replaceFirst('http', 'ws');
    final params = config.toWebSocketParams();

    final queryParams = params.entries
        .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');

    return '$baseWsUrl/ws/conversation?$queryParams';
  }

  void _handleMessage(dynamic data) {
    try {
      if (data is String) {
        final messageData = json.decode(data) as Map<String, dynamic>;
        developer.log(
          '📨 Voivi WebSocket: Received message type: ${messageData['type']}',
        );
        developer.log('📨 Voivi WebSocket: Full message data: $messageData');

        _processMessage(messageData);
      }
    } catch (e) {
      developer.log('❌ Voivi WebSocket: Error processing message: $e');
    }
  }

  void _processMessage(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;

    switch (messageType) {
      case 'assistant_message':
        _handleAssistantMessage(data);
      case 'sentiment_analysis':
        _handleSentimentAnalysis(data);
      case 'conversation_started':
        _handleConversationStarted(data);
      case 'connection_confirmed':
        _handleConnectionConfirmed(data);
      case 'assistantresponse':
        _handleAssistantResponse(data);
      case 'error':
        _handleServerError(data);
      case 'usertranscript':
        _handleUserTranscript(data);
      case 'errormessage':
        _handleErrorMessage(data);
      case 'tool_execution_request':
        _handleToolExecutionRequest(data);
      default:
        developer.log('🤷 Unknown message type: $messageType');
        developer.log('🔍 Full message data: $data');
    }
  }

  void _handleAssistantMessage(Map<String, dynamic> data) {
    final content = data['content'] as String?;
    if (content != null) {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _currentState.currentConversationId ?? '',
        timestamp: DateTime.now(),
        type: ChatMessageType.assistantText,
        content: content,
        metadata: data,
      );

      _addMessage(message);
      developer.log(
        '🤖 Received assistant text message: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}',
      );
    }
  }

  void _handleSentimentAnalysis(Map<String, dynamic> data) {
    _updateState(_currentState.copyWith(sentimentData: data));
    developer.log('😊 Received sentiment analysis data');
  }

  void _handleConversationStarted(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    if (conversationId != null) {
      _updateState(
        _currentState.copyWith(currentConversationId: conversationId),
      );
      developer.log('🚀 Conversation started: $conversationId');
    }
  }

  void _handleServerError(Map<String, dynamic> data) {
    final error = data['message'] as String? ?? 'Unknown server error';
    _updateState(_currentState.copyWith(error: error));
    developer.log('❌ Server error: $error');
  }

  void _handleConnectionConfirmed(Map<String, dynamic> data) {
    developer.log('✅ WebSocket connection confirmed');
    _updateState(_currentState.copyWith(isConnected: true));
  }

  void _handleAssistantResponse(Map<String, dynamic> data) {
    final content = data['content'] as String? ?? data['response'] as String?;

    if (content != null) {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _currentState.currentConversationId ?? '',
        timestamp: DateTime.now(),
        type: ChatMessageType.assistantText,
        content: content,
        metadata: data,
      );

      _addMessage(message);
      developer.log(
        '🤖 Received assistant response: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}',
      );
    }
  }

  void _addMessage(ChatMessage message) {
    final updatedMessages = [..._currentState.messages, message];
    _updateState(_currentState.copyWith(messages: updatedMessages));
    _messageController?.add(message);
  }

  void _updateState(ConversationState newState) {
    developer.log('🔄 WebSocket State Update: Connected=${newState.isConnected}, Messages=${newState.messages.length}, Error=${newState.error}');
    _currentState = newState;
    _stateController?.add(newState);
    developer.log('📤 WebSocket State Broadcasted: ${newState.isConnected ? "Connected" : "Disconnected"}');
  }

  void _handleError(Object error) {
    developer.log('❌ WebSocket error: $error');
    _updateState(
      _currentState.copyWith(
        isConnected: false,
        error: error.toString(),
      ),
    );
  }

  void _handleDisconnection() {
    developer.log('🔌 WebSocket connection closed');
    _updateState(_currentState.copyWith(isConnected: false));
  }

  void _handleUserTranscript(Map<String, dynamic> data) {
    final transcript =
        data['transcript'] as String? ?? data['content'] as String?;
    developer.log(
      '📝 User transcript: ${transcript ?? "No transcript content"}',
    );
    developer.log('🔍 Full user transcript data: $data');
  }

  void _handleErrorMessage(Map<String, dynamic> data) {
    final errorMessage =
        data['message'] as String? ??
        data['error'] as String? ??
        data['content'] as String? ??
        'Unknown error';
    developer.log('❌ Backend error message: $errorMessage');
    developer.log('🔍 Full error message data: $data');
    _updateState(_currentState.copyWith(error: errorMessage));
  }

  /// Handle tool execution request from backend
  /// Backend delegates tool execution to client (platform-specific tools)
  ///
  /// Chaos Engineering Safeguards:
  /// - Validates required fields (toolCallId, toolName)
  /// - Checks tool registry availability
  /// - Checks if tool is bound before execution
  /// - Sends error response for fallback if tool not available
  /// - Handles execution errors gracefully
  void _handleToolExecutionRequest(Map<String, dynamic> data) async {
    final toolCallId = data['toolCallId'] as String?;
    final toolName = data['toolName'] as String?;
    final arguments = data['arguments'] as Map<String, dynamic>?;

    developer.log(
      '🔧 [TOOL REQUEST] Received tool execution request: {toolCallId: $toolCallId, toolName: $toolName, args: $arguments}',
    );

    // Safeguard 1: Validate required fields
    if (toolCallId == null || toolCallId.isEmpty) {
      developer.log('❌ [TOOL REQUEST] Invalid tool request: missing or empty toolCallId');
      return;
    }

    if (toolName == null || toolName.isEmpty) {
      developer.log('❌ [TOOL REQUEST] Invalid tool request: missing or empty toolName');
      _sendToolResult(
        toolCallId: toolCallId,
        success: false,
        error: 'Tool name is required',
      );
      return;
    }

    // Check if tool registry is available
    if (_toolRegistry == null) {
      developer.log('❌ [TOOL REQUEST] Tool registry not set, cannot execute tool');
      _sendToolResult(
        toolCallId: toolCallId,
        success: false,
        error: 'Tool registry not configured',
      );
      return;
    }

    // Check if tool is bound (has a handler registered)
    if (!_toolRegistry!.has(toolName)) {
      developer.log(
        '⚠️ [TOOL WARNING] Tool not bound on client: $toolName. Backend may fallback to server-side execution.',
      );
      _sendToolResult(
        toolCallId: toolCallId,
        success: false,
        error: 'Tool not available on client',
      );
      return;
    }

    try {
      // Execute tool via registry
      final result = await _toolRegistry!.execute(
        toolName,
        arguments ?? {},
      );

      // Send successful result back to backend
      _sendToolResult(
        toolCallId: toolCallId,
        success: true,
        result: result,
      );

      developer.log(
        '✅ [TOOL RESULT] Tool executed successfully, sent result to backend: {toolCallId: $toolCallId, toolName: $toolName}',
      );
    } catch (error) {
      developer.log(
        '❌ [TOOL ERROR] Tool execution failed: {toolCallId: $toolCallId, toolName: $toolName, error: $error}',
      );

      // Send error result back to backend
      _sendToolResult(
        toolCallId: toolCallId,
        success: false,
        error: error.toString(),
      );
    }
  }

  /// Send tool execution result back to backend via WebSocket
  void _sendToolResult({
    required String toolCallId,
    required bool success,
    dynamic result,
    String? error,
  }) {
    if (_channel == null) {
      developer.log('❌ [TOOL RESULT] Cannot send tool result: WebSocket not connected');
      return;
    }

    final message = {
      'type': 'tool_execution_result',
      'toolCallId': toolCallId,
      'success': success,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
    };

    _channel!.sink.add(json.encode(message));
    developer.log('📤 [TOOL RESULT] Sent tool execution result: $message');
  }

  Future<void> sendTextMessage(String text) async {
    // If not connected, queue the message
    if (_channel == null || _currentState.isConnected == false) {
      final queuedMessage = QueuedMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        timestamp: DateTime.now(),
        priority: MessagePriority.normal,
      );

      _messageQueue?.enqueue(queuedMessage);
      developer.log('📤 Message queued (offline): ${text.length > 50 ? '${text.substring(0, 50)}...' : text}');
      return;
    }

    await _sendMessageWithResilience(text);
  }

  Future<void> _sendMessageWithResilience(String text) async {
    final message = {
      'type': 'text',
      'content': text,
    };

    // Use timeout for message sending
    final timeout = _config?.resilienceConfig.timeoutConfig.messageTimeout ??
                    const Duration(seconds: 15);

    try {
      _channel!.sink.add(json.encode(message));
      // Add a small delay to ensure message is sent
      await Future.delayed(Duration.zero).timeout(timeout);

      developer.log(
        '📤 Voivi WebSocket: Sent text message: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}',
      );
      developer.log(
        '📤 Voivi WebSocket: Message format: ${json.encode(message)}',
      );

      // Add user message to local state
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _currentState.currentConversationId ?? '',
        timestamp: DateTime.now(),
        type: ChatMessageType.userText,
        content: text,
      );

      _addMessage(userMessage);
    } catch (e) {
      final classified = ErrorClassifier.classify(e);
      developer.log('❌ Failed to send message: ${classified.message}');

      // Queue message for retry if it's a retryable error
      if (classified.isRetryable) {
        final queuedMessage = QueuedMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text,
          timestamp: DateTime.now(),
          priority: MessagePriority.high,
        );

        _messageQueue?.enqueue(queuedMessage);
        developer.log('📤 Message queued for retry: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}');
      } else {
        rethrow;
      }
    }
  }

  Future<void> _processQueuedMessages() async {
    if (_messageQueue == null || _messageQueue!.queueLength == 0) return;

    developer.log('📤 Processing ${_messageQueue!.queueLength} queued messages...');

    await _messageQueue!.processQueue((queuedMessage) async {
      await _sendMessageWithResilience(queuedMessage.content);
    });
  }

  Future<void> initializeConversation({
    List<Map<String, dynamic>>? chatHistory,
    Map<String, dynamic>? context,
  }) async {
    if (_channel == null || _currentState.isConnected == false) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'type': 'initialize_conversation',
      'chatHistory': chatHistory ?? [],
      'context': context ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(json.encode(message));
    developer.log(
      '🚀 Initialized conversation with ${chatHistory?.length ?? 0} history messages',
    );
  }

  Future<void> disconnect() async {
    try {
      // Stop health checks
      _healthCheckService?.stop();

      // Close WebSocket connection
      await _channel?.sink.close(1000); // Normal closure code
      _channel = null;

      _updateState(_currentState.copyWith(isConnected: false));
      developer.log('👋 WebSocket disconnected');
    } catch (e) {
      developer.log('❌ Error disconnecting: $e');
    }
  }

  void dispose() {
    disconnect();

    // Dispose resilience services
    _healthCheckService?.dispose();
    _messageQueue?.dispose();

    // Close stream controllers
    _messageController?.close();
    _stateController?.close();
    _messageController = null;
    _stateController = null;

    // Clear resilience services
    _circuitBreaker = null;
    _retryService = null;
    _healthCheckService = null;
    _messageQueue = null;
  }

  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
    developer.log('🔄 WebSocketService singleton reset');
  }
}
