import 'dart:async';
import 'dart:developer' as developer;

import 'package:voivi_voice_ai/src/core/voivi_config.dart';
import 'package:voivi_voice_ai/src/models/tool_definition_models.dart';
import 'package:voivi_voice_ai/src/services/tool_registry_service.dart';
import 'package:voivi_voice_ai/src/services/voivi_api_service.dart';
import 'package:voivi_voice_ai/src/services/websocket_service.dart';

/// Pure chat engine for Voivi Chat without any UI dependencies
///
/// This engine provides a clean, framework-agnostic API for integrating
/// Voivi Chat functionality into any application. It handles WebSocket
/// connections, message management, and state without any UI or Flutter-specific
/// dependencies.
///
/// Example usage:
/// ```dart
/// final engine = VoiviChatEngine();
/// await engine.initialize(config);
/// await engine.connect();
///
/// // Register client-side tools
/// engine.toolRegistry.register('get_device_info', (args) async {
///   return {'platform': Platform.operatingSystem};
/// });
///
/// // Listen to messages
/// engine.messageStream.listen((message) {
///   print('New message: ${message.content}');
/// });
///
/// // Send a message
/// await engine.sendMessage('Hello AI!');
/// ```
class VoiviChatEngine {
  VoiviChatEngine();

  final WebSocketService _webSocketService = WebSocketService();
  final ToolRegistry _toolRegistry = ToolRegistry();
  final VoiviApiService _apiService = VoiviApiService();

  VoiviConfig? _config;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<ConversationState>? _stateSubscription;

  // Stream controllers for external listening
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ConversationState> _stateController =
      StreamController<ConversationState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  ConversationState _currentState = const ConversationState();

  /// Stream of incoming chat messages
  Stream<ChatMessage> get messageStream => _messageController.stream;

  /// Stream of conversation state changes
  Stream<ConversationState> get stateStream => _stateController.stream;

  /// Stream of error messages
  Stream<String> get errorStream => _errorController.stream;

  /// Current conversation state
  ConversationState get currentState => _currentState;

  /// Whether the engine is initialized
  bool get isInitialized => _config != null;

  /// Whether connected to the chat service
  bool get isConnected => _currentState.isConnected;

  /// Current configuration
  VoiviConfig? get config => _config;

  /// List of current messages
  List<ChatMessage> get messages => _currentState.messages;

  /// Current conversation ID
  String? get conversationId => _currentState.currentConversationId;

  /// Get sentiment analysis data for the current conversation
  Map<String, dynamic>? get sentimentData => _currentState.sentimentData;

  /// Whether the assistant is currently typing/processing
  bool get isTyping => _currentState.isProcessing;

  /// Any current error message
  String? get error => _currentState.error;

  /// Access to tool registry for registering client-side tools
  ///
  /// Register custom tools that can be executed by the AI assistant:
  /// ```dart
  /// engine.toolRegistry.register('my_tool', (args) async {
  ///   return {'result': 'success'};
  /// });
  /// ```
  ToolRegistry get toolRegistry => _toolRegistry;

  /// Fetch available client-side tools from the backend
  ///
  /// This method fetches all tools marked with executionLocation="client"
  /// from the backend and stores them in the tool registry.
  ///
  /// Returns a list of [ClientToolDefinition] objects representing available tools.
  ///
  /// Example:
  /// ```dart
  /// final tools = await engine.fetchClientTools();
  /// print('Available tools: ${tools.map((t) => t.name).toList()}');
  /// ```
  ///
  /// Throws an exception if the engine is not initialized or if the API call fails.
  Future<List<ClientToolDefinition>> fetchClientTools() async {
    if (_config == null) {
      throw Exception(
        'VoiviChatEngine not initialized. Call initialize() first.',
      );
    }

    try {
      final tools = await _apiService.fetchClientTools(
        baseUrl: _config!.baseUrl,
        organizationId: _config!.organizationId,
        apiKey: _config!.apiKey,
      );

      _toolRegistry.setAvailableTools(tools);

      developer.log(
        '📦 Fetched ${tools.length} client-side tools from backend',
      );

      return tools;
    } catch (e) {
      developer.log('❌ Error fetching client tools: $e');
      _handleError(e.toString());
      rethrow;
    }
  }

  /// Bind a single tool handler
  ///
  /// This is an alias for [toolRegistry.bindToolHandler()] for convenience.
  ///
  /// [name] - The name of the tool to bind
  /// [handler] - The function to execute when the tool is called
  ///
  /// Example:
  /// ```dart
  /// engine.bindToolHandler('get_location', (args) async {
  ///   final position = await Geolocator.getCurrentPosition();
  ///   return {
  ///     'latitude': position.latitude,
  ///     'longitude': position.longitude,
  ///   };
  /// });
  /// ```
  void bindToolHandler(String name, ToolHandler handler) {
    _toolRegistry.bindToolHandler(name, handler);
    developer.log('🔗 Bound tool handler: $name');
  }

  /// Bind multiple tool handlers at once (RECOMMENDED)
  ///
  /// This method allows you to bind multiple tool handlers in a single call,
  /// making it easier to set up all client-side tools at once.
  ///
  /// [handlers] - A map of tool names to their handler functions
  ///
  /// Example:
  /// ```dart
  /// engine.bindToolHandlers({
  ///   'get_location': (args) async {
  ///     final position = await Geolocator.getCurrentPosition();
  ///     return {'latitude': position.latitude, 'longitude': position.longitude};
  ///   },
  ///   'get_device_info': (args) async {
  ///     return {
  ///       'platform': Platform.operatingSystem,
  ///       'version': Platform.operatingSystemVersion,
  ///     };
  ///   },
  /// });
  /// ```
  void bindToolHandlers(Map<String, ToolHandler> handlers) {
    _toolRegistry.bindToolHandlers(handlers);
    developer.log('🔗 Bound ${handlers.length} tool handlers');
  }

  /// Get list of unbound client tools
  ///
  /// Returns a list of tool names that have been fetched from the backend
  /// but haven't been bound to a handler yet.
  ///
  /// This is useful for detecting missing implementations:
  /// ```dart
  /// final unbound = engine.getUnboundClientTools();
  /// if (unbound.isNotEmpty) {
  ///   print('⚠️ Tools not implemented: $unbound');
  /// }
  /// ```
  List<String> getUnboundClientTools() {
    return _toolRegistry.getUnboundTools();
  }

  /// Initialize the engine with configuration
  ///
  /// [config] - Configuration for the chat engine
  /// Returns a Future that completes when initialization is done
  Future<void> initialize(VoiviConfig config) async {
    try {
      _config = config;

      // Set up listeners for WebSocket service
      _setupListeners();

      // Connect tool registry to WebSocket service for client-side tool execution
      _webSocketService.setToolRegistry(_toolRegistry);

      developer.log(
        '✅ VoiviChatEngine initialized with assistant: ${config.assistantId}',
      );
    } catch (e) {
      developer.log('❌ Error initializing VoiviChatEngine: $e');
      _handleError(e.toString());
      rethrow;
    }
  }

  /// Connect to the chat service
  ///
  /// Returns a Future that completes when connection is established
  Future<void> connect() async {
    if (_config == null) {
      throw Exception(
        'VoiviChatEngine not initialized. Call initialize() first.',
      );
    }

    try {
      await _webSocketService.connect(_config!);
      developer.log('🔗 Connected to Voivi chat service');

      // Sync state immediately after connection
      _syncWithWebSocketState();
    } catch (e) {
      developer.log('❌ Error connecting: $e');
      _handleError(e.toString());
      rethrow;
    }
  }

  /// Disconnect from the chat service
  ///
  /// Returns a Future that completes when disconnection is done
  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
      developer.log('👋 Disconnected from Voivi chat service');
    } catch (e) {
      developer.log('❌ Error disconnecting: $e');
      _handleError(e.toString());
    }
  }

  /// Initialize a conversation with optional history and context
  ///
  /// [chatHistory] - Optional previous conversation history
  /// [context] - Optional context data for the conversation
  /// Returns a Future that completes when conversation is initialized
  Future<void> initializeConversation({
    List<Map<String, dynamic>>? chatHistory,
    Map<String, dynamic>? context,
  }) async {
    if (!isConnected) {
      await connect();
    }

    try {
      await _webSocketService.initializeConversation(
        chatHistory: chatHistory,
        context: context,
      );
      developer.log('🚀 Conversation initialized');
    } catch (e) {
      developer.log('❌ Error initializing conversation: $e');
      _handleError(e.toString());
      rethrow;
    }
  }

  /// Send a text message to the AI assistant
  ///
  /// [text] - The message text to send
  /// Returns a Future that completes when message is sent
  Future<void> sendMessage(String text) async {
    if (!isConnected) {
      throw Exception('Not connected to chat service');
    }

    try {
      await _webSocketService.sendTextMessage(text);
      developer.log('📤 Sent text message: ${text.length} characters');
    } catch (e) {
      developer.log('❌ Error sending text message: $e');
      _handleError(e.toString());
      rethrow;
    }
  }

  /// Reconnect to the service
  ///
  /// This will disconnect and then reconnect with the current configuration
  Future<void> reconnect() async {
    if (_config == null) {
      throw Exception('Engine not initialized');
    }

    await disconnect();
    await connect();
  }

  /// Clear the current conversation
  ///
  /// This will reset the conversation state and clear messages
  void clearConversation() {
    _currentState = _currentState.copyWith(
      messages: [],
    );
    _stateController.add(_currentState);
  }

  /// Get conversation summary or metadata
  ///
  /// Returns metadata about the current conversation
  Map<String, dynamic> getConversationMetadata() {
    return {
      'messageCount': messages.length,
      'conversationId': conversationId,
      'isConnected': isConnected,
      'hasError': error != null,
      'sentimentData': sentimentData,
      'lastMessageTime': messages.isNotEmpty
          ? messages.last.timestamp.toIso8601String()
          : null,
    };
  }

  /// Dispose of the engine and clean up resources
  ///
  /// This should be called when the engine is no longer needed
  Future<void> dispose() async {
    try {
      await _messageSubscription?.cancel();
      await _stateSubscription?.cancel();

      await disconnect();

      await _messageController.close();
      await _stateController.close();
      await _errorController.close();

      _messageSubscription = null;
      _stateSubscription = null;

      developer.log('🗑️ VoiviChatEngine disposed');
    } catch (e) {
      developer.log('❌ Error disposing VoiviChatEngine: $e');
    }
  }

  void _setupListeners() {
    developer.log('🔧 Engine: Setting up listeners...');

    // Listen to WebSocket message stream
    _messageSubscription = _webSocketService.messageStream.listen(
      (message) {
        developer.log('📨 Received message: ${message.type}');
        _messageController.add(message);
      },
      onError: (Object error) {
        developer.log('❌ Message stream error: $error');
        _handleError(error.toString());
      },
    );
    developer.log('✅ Engine: Message stream subscription active');

    // Listen to WebSocket state changes
    _stateSubscription = _webSocketService.stateStream.listen(
      (state) {
        developer.log(
            '📥 Engine received state: Connected=${state.isConnected}, Messages=${state.messages.length}');
        _currentState = state;
        _stateController.add(state);
        developer
            .log('🚀 Engine broadcasted state: Connected=${state.isConnected}');
      },
      onError: (Object error) {
        developer.log('❌ State stream error: $error');
        _handleError(error.toString());
      },
    );
    developer.log('✅ Engine: State stream subscription active');

    // Sync with current WebSocket state immediately
    _syncWithWebSocketState();
  }

  void _syncWithWebSocketState() {
    final currentWebSocketState = _webSocketService.currentState;
    developer.log(
        '🔄 Engine: Syncing with WebSocket state - Connected=${currentWebSocketState.isConnected}');
    _currentState = currentWebSocketState;
    _stateController.add(_currentState);
    developer.log(
        '✅ Engine: State synchronized - Connected=${_currentState.isConnected}');
  }

  void _handleError(String error) {
    _currentState = _currentState.copyWith(error: error);
    _stateController.add(_currentState);
    _errorController.add(error);
  }

  /// Static helper method to convert generic messages to chat history format
  ///
  /// This utility method helps integrate with existing message formats
  static List<Map<String, dynamic>> convertMessagesToHistory(
    List<dynamic> messages,
  ) {
    return messages.map((message) {
      // Handle Map objects (from ChatDetailCubit._convertMessagesToVoiviFormat)
      if (message is Map<String, dynamic>) {
        return {
          'id': message['id']?.toString() ?? '',
          'content': message['content']?.toString() ??
              message['text']?.toString() ??
              '',
          'senderType': message['senderType']?.toString() ??
              message['role']?.toString() ??
              'user',
          'timestamp': message['timestamp']?.toString() ??
              DateTime.now().toIso8601String(),
          'type': message['type']?.toString() ?? 'text',
        };
      }

      // Handle object types (original logic for actual message objects)
      return {
        'id': message.id?.toString() ?? '',
        'content': message.text ?? message.content?.toString() ?? '',
        'senderType': message.senderType?.toString() ?? 'user',
        'timestamp': message.timestamp?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'type': message.type?.toString() ?? 'text',
      };
    }).toList();
  }
}
