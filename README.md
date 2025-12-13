# Voivi Voice AI SDK

**Complete Conversation AI Kit for Flutter** 🤖

[![pub package](https://img.shields.io/pub/v/voivi_voice_ai.svg)](https://pub.dev/packages/voivi_voice_ai)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Build intelligent **conversation AI** experiences with voice, text, and multi-modal interactions. The most comprehensive **conversation AI SDK** for Flutter developers - enabling real-time voice conversations, text chat, AI-powered assistants, and seamless platform integration. **No UI dependencies** - works with any framework or platform.

## ✨ Features

### 🧠 Conversation AI Core
- 🤖 **Conversation AI Platform**: Build intelligent conversation AI applications with voice, text, and multi-modal interactions
- 🎙️ **Voice Conversation AI**: Real-time voice-powered conversations with AI assistants
- 💬 **Text Conversation AI**: Intelligent text-based chatbots and AI assistants
- 🔀 **Multi-Modal Conversation AI**: Seamless switching between voice and text conversations

### 🚀 Advanced Capabilities
- 🗣️ **Speech-to-Text (STT)**: Transcribe audio with speaker diarization & customer detection
- 🚀 **Pure Engine**: No Flutter or UI dependencies - works with any Dart environment
- 💬 **WebSocket Streaming**: Real-time bidirectional communication with AI assistants
- 🤖 **Assistant Management**: List, fetch, and manage AI assistants via REST API
- 🛠️ **Tool Execution**: Client-side tool execution (geolocation, device info, etc.)
- 📝 **AI Text Summarization**: Summarize any text with GPT-4o-mini
- 💰 **Cost Estimation**: Pre-flight cost calculation for AI operations

### 🔧 Developer Experience
- 🔧 **Framework Agnostic**: Use with Flutter, Angular Dart, console apps, or any Dart project
- 📱 **Cross-Platform**: Works on all Dart platforms (mobile, web, desktop, server)
- 🔄 **Auto-Reconnection**: Automatic connection retry with configurable settings
- 📊 **Reactive Streams**: Stream-based architecture for real-time updates
- 🛡️ **Production Ready**: Comprehensive error handling and logging
- 🔧 **Type Safe**: Full type safety with null safety support
- 📚 **Context-Aware**: Conversation history support
- 🎯 **Minimal Dependencies**: Lightweight with only essential dependencies

## 🔐 Getting Your Credentials

Before using the package, you'll need to get your credentials from the Voivi Dashboard:

1. **Access the Dashboard**
   - Visit your Voivi Dashboard (e.g., `http://localhost:3000` for development or your hosted instance)
   - Login with your account

2. **Get Organization ID & API Key**
   - Navigate to **Settings** > **API Keys**
   - Copy your **Organization ID**
   - Create a new **API Key** or use an existing one
   - Store these credentials securely

3. **Get Assistant ID**
   - Navigate to **Assistants** page
   - Select or create an assistant
   - Copy the **Assistant ID**

⚠️ **Security Note**: Never commit credentials to version control. Use environment variables or secure configuration files.

## 🚀 Quick Start

### 🎯 Simplified API Usage (v1.3.1+)

VoiviApiService now supports optional config-based initialization, eliminating the need to pass `baseUrl` and `apiKey` to every API call.

#### Before (Repetitive):
```dart
final apiService = VoiviApiService();

// Have to pass credentials every time 😞
await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: sttRequest,
  apiKey: 'your-api-key',
);

await apiService.listAssistants(
  baseUrl: 'http://localhost:5065',
  apiKey: 'your-api-key',
  organizationId: 'org-123',
);
```

#### After (Clean):
```dart
// Configure once with VoiviConfig
final config = VoiviConfig(
  baseUrl: 'http://localhost:5065',
  apiKey: 'your-api-key',
  organizationId: 'org-123',
  assistantId: 'ast-456',
);

final apiService = VoiviApiService(config: config);

// Use everywhere without repeating credentials 🎉
await apiService.transcribeAudio(request: sttRequest);
await apiService.listAssistants();
await apiService.generateSummaries(request: summaryRequest);
```

#### Override When Needed:
```dart
// Use config defaults
await apiService.transcribeAudio(request: request);

// Override with different baseUrl for specific call
await apiService.transcribeAudio(
  baseUrl: 'http://different-server:5065',
  request: request,
);
```

#### Benefits:
- ✅ **DRY Principle**: Set credentials once, use everywhere
- ✅ **Less Boilerplate**: Cleaner, more readable code
- ✅ **Fully Backward Compatible**: Old code continues to work
- ✅ **Flexible**: Override config parameters when needed
- ✅ **SOLID**: Single source of truth for configuration

All examples below have been updated to use this simplified pattern!

### Configuration Patterns

The package provides convenient factory methods for different environments:

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';

// Development (localhost backend)
final config = VoiviConfig.development(
  organizationId: 'your-org-id',
  apiKey: 'your-api-key',
  assistantId: 'your-assistant-id',
);

// Production (Azure backend)
final config = VoiviConfig.production(
  organizationId: 'your-org-id',
  apiKey: 'your-api-key',
  assistantId: 'your-assistant-id',
);

// Custom configuration
final config = VoiviConfig(
  organizationId: 'your-org-id',
  apiKey: 'your-api-key',
  assistantId: 'your-assistant-id',
  baseUrl: 'https://custom-backend.com',
  enableTTS: true,
  // ... other options
);
```

### Option A: With Assistant Selection (Recommended)

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';

// 1. Fetch available assistants
final apiService = VoiviApiService();
final assistants = await apiService.listAssistants(
  baseUrl: 'http://localhost:5065',
  apiKey: 'your-api-key',
  organizationId: 'your-org-id',
);

// 2. Let user select an assistant
final selectedAssistant = assistants[0];

// 3. Create chat engine with selected assistant
final engine = VoiviChatEngine();
await engine.initialize(VoiviConfig(
  apiKey: 'your-api-key',
  organizationId: 'your-org-id',
  assistantId: selectedAssistant.id,
  baseUrl: 'http://localhost:5065',
));

await engine.connect();

// 4. Listen and chat
engine.messageStream.listen((message) {
  // Handle messages in your app (update UI, store in DB, etc.)
  handleMessage(message);
});

await engine.sendMessage('Hello!');
```

### Option B: Direct Assistant Connection

If you already know the assistant ID:

### 1. Add to pubspec.yaml

```yaml
dependencies:
  voivi_voice_ai: ^1.2.0
```

### 2. Basic Usage

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';

// Create and initialize the engine
final engine = VoiviChatEngine();

await engine.initialize(VoiviConfig(
  apiKey: 'your-api-key',
  organizationId: 'your-organization-id',
  assistantId: 'your-assistant-id',
  baseUrl: 'wss://your-backend.com',
));

// Connect to the service
await engine.connect();

// Listen to messages
engine.messageStream.listen((message) {
  // Forward to your UI, logging system, or state management
  onMessageReceived(message);
});

// Send a message
await engine.sendMessage('Hello AI!');
```

That's it! You now have a fully functional AI chat engine.

## 📖 Complete Example

```dart
import 'dart:async';
import 'package:voivi_voice_ai/voivi_chat.dart';

class ChatManager {
  late VoiviChatEngine _engine;
  late StreamSubscription _messageSubscription;
  late StreamSubscription _stateSubscription;

  Future<void> initialize() async {
    _engine = VoiviChatEngine();

    // Initialize with configuration
    await _engine.initialize(VoiviConfig(
      apiKey: 'your-api-key',
      organizationId: 'your-org-id',
      assistantId: 'your-assistant-id',
      baseUrl: 'wss://api.yourdomain.com',
      userId: 'user-123', // Optional
      llmModel: 'gpt-4o', // Optional, defaults to gpt-4o
      enableSentimentAnalysis: true, // Optional
    ));

    // Set up listeners
    _messageSubscription = _engine.messageStream.listen(
      (message) => _handleNewMessage(message),
      onError: (error) => _handleStreamError('Message stream', error),
    );

    _stateSubscription = _engine.stateStream.listen(
      (state) => _handleStateChange(state),
      onError: (error) => _handleStreamError('State stream', error),
    );

    // Connect to the service
    await _engine.connect();
  }

  void _handleNewMessage(ChatMessage message) {
    // Log to your monitoring system
    logger.info('New message', {
      'type': message.type.toString(),
      'content': message.content,
      'timestamp': message.timestamp,
    });

    // Forward to your UI system, database, etc.
    _forwardToUI(message);
  }

  void _handleStateChange(ConversationState state) {
    // Update your app state
    notifyListeners(); // For ChangeNotifier
    // or emit(state); // For Bloc/Cubit
    // or update your state management solution

    if (state.error != null) {
      // Report error to monitoring service
      errorReporter.log(state.error);
    }
  }

  Future<void> sendUserMessage(String text) async {
    if (_engine.isConnected) {
      await _engine.sendMessage(text);
      logger.info('Message sent', {'text': text});
    } else {
      // Handle disconnected state
      onConnectionError('Not connected to service');
    }
  }

  void _forwardToUI(ChatMessage message) {
    // Your custom UI integration logic here
    // This could be updating a Flutter widget, web component,
    // console output, or any other display system
  }

  void _handleStreamError(String streamName, dynamic error) {
    // Log error to your monitoring service
    errorReporter.log('$streamName error: $error');
    // Optionally notify user or trigger recovery actions
  }

  Future<void> dispose() async {
    await _messageSubscription.cancel();
    await _stateSubscription.cancel();
    await _engine.dispose();
  }
}

// Usage
void main() async {
  final chatManager = ChatManager();
  await chatManager.initialize();

  // Send a test message
  await chatManager.sendUserMessage('Hello, how are you?');

  // Keep the program running to receive messages
  await Future.delayed(Duration(minutes: 5));

  await chatManager.dispose();
}
```

## 🎨 Advanced Configuration

### Full Configuration Options

```dart
VoiviConfig(
  // Required
  apiKey: 'your-api-key',
  organizationId: 'your-organization-id',
  assistantId: 'your-assistant-id',
  baseUrl: 'wss://your-backend.com',

  // Optional - User & Session
  userId: 'custom-user-id',
  defaultUserId: 'client-user', // Fallback if userId not provided

  // Optional - AI Configuration
  llmModel: 'gpt-4o', // AI model to use
  enableSentimentAnalysis: true,
  enableRealTimeAnalysis: true,
  enableConversationContext: false,

  // Optional - Connection Settings
  connectionTimeoutMs: 30000, // 30 seconds
  reconnectAttempts: 3,
  reconnectDelayMs: 1000, // 1 second

  // Optional - TTS/Voice Settings (for future voice features)
  enableTTS: false,
  ttsProvider: 'ai-services',
  ttsVoice: 'alloy',

  // Optional - Advanced Detection Settings
  enableCustomerDetection: true,
  minCustomerConfidence: 0.75,
  backgroundNoiseThreshold: 0.3,
)
```

## 🔄 Framework Integration Examples

### Flutter Integration

```dart
import 'package:flutter/material.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late VoiviChatEngine _engine;
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    _engine = VoiviChatEngine();

    await _engine.initialize(VoiviConfig(
      apiKey: 'your-api-key',
      organizationId: 'your-org-id',
      assistantId: 'your-assistant-id',
      baseUrl: 'wss://your-backend.com',
    ));

    // Listen to messages and update UI
    _engine.messageStream.listen((message) {
      setState(() {
        _messages.add(message);
      });
    });

    await _engine.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.type == ChatMessageType.userText;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.content ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final text = _textController.text;
                    if (text.isNotEmpty) {
                      _textController.clear();
                      await _engine.sendMessage(text);
                    }
                  },
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _engine.dispose();
    _textController.dispose();
    super.dispose();
  }
}
```

### Console Application

```dart
import 'dart:io';
import 'package:voivi_voice_ai/voivi_chat.dart';

Future<void> main() async {
  final engine = VoiviChatEngine();

  // Initialize
  await engine.initialize(VoiviConfig(
    apiKey: 'your-api-key',
    organizationId: 'your-org-id',
    assistantId: 'your-assistant-id',
    baseUrl: 'wss://your-backend.com',
  ));

  // Listen to messages
  engine.messageStream.listen((message) {
    final sender = message.type == ChatMessageType.userText ? 'You' : 'AI';
    stdout.writeln('$sender: ${message.content}');
  });

  // Listen to connection status
  engine.stateStream.listen((state) {
    if (state.isConnected) {
      stdout.writeln('✅ Connected to chat service');
    } else {
      stderr.writeln('❌ Disconnected from chat service');
    }
  });

  // Connect
  await engine.connect();

  print('Chat started! Type messages and press Enter. Type "quit" to exit.');

  // Read user input
  while (true) {
    stdout.write('You: ');
    final input = stdin.readLineSync();

    if (input == null || input.toLowerCase() == 'quit') {
      break;
    }

    if (input.isNotEmpty) {
      await engine.sendMessage(input);
    }
  }

  await engine.dispose();
  print('Chat ended.');
}
```

### Server/Backend Integration

```dart
import 'dart:async';
import 'package:voivi_voice_ai/voivi_chat.dart';

class BackendChatService {
  late VoiviChatEngine _engine;
  final Map<String, List<ChatMessage>> _userChats = {};

  Future<void> initialize() async {
    _engine = VoiviChatEngine();

    await _engine.initialize(VoiviConfig(
      apiKey: 'your-api-key',
      organizationId: 'your-org-id',
      assistantId: 'your-assistant-id',
      baseUrl: 'wss://your-backend.com',
    ));

    // Store all messages for later retrieval
    _engine.messageStream.listen((message) {
      _storeMessage(message);
      _broadcastToWebsocketClients(message);
    });

    await _engine.connect();
  }

  Future<void> handleUserMessage(String userId, String message) async {
    // Forward user message to AI
    await _engine.sendMessage(message);
  }

  void _storeMessage(ChatMessage message) {
    // Store in database, cache, etc.
    final userId = _engine.config?.userId ?? 'unknown';
    _userChats.putIfAbsent(userId, () => []).add(message);
  }

  void _broadcastToWebsocketClients(ChatMessage message) {
    // Send to connected web clients, mobile apps, etc.
    // Implement your WebSocket broadcast logic here
    websocketBroadcaster.send(message);
  }

  List<ChatMessage> getUserChatHistory(String userId) {
    return _userChats[userId] ?? [];
  }
}
```

## 🔧 Client-Side Tool Execution (v1.2.0+)

Execute platform-specific tools (geolocation, device info, camera, etc.) directly from your client application, with backend-driven tool definitions.

### Backend-Driven Tool Binding

Fetch tool definitions from backend and bind platform-specific handlers:

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

final engine = VoiviChatEngine();
await engine.initialize(config);

// 1. Fetch available client-side tools from backend
final clientTools = await engine.fetchClientTools();
// Log available tools (use your logging system)
logger.info('Available tools', {'tools': clientTools.map((t) => t.name).toList()});

// 2. Bind tool handlers (Map-based - RECOMMENDED)
engine.bindToolHandlers({
  'get_location': (args) async {
    final position = await Geolocator.getCurrentPosition();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
  },
  'get_device_info': (args) async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
  },
  'capture_photo': (args) async {
    // Use image_picker or camera package
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    return {
      'path': image?.path,
      'size': await image?.length(),
    };
  },
});

// 3. Check for unimplemented tools (optional)
final unbound = engine.getUnboundClientTools();
if (unbound.isNotEmpty) {
  logger.warning('Tools not implemented', {'tools': unbound});
  // Implement missing tools, ignore them, or notify user
  onUnimplementedTools(unbound);
}

// 4. Connect - backend can now delegate tool execution to client
await engine.connect();

// User: "What's my current location?"
// → Backend sends tool_execution_request for 'get_location'
// → Flutter executes handler and returns GPS coordinates
// → Backend receives result and AI responds with location info
```

### How It Works

1. **Backend defines tools** with `executionLocation: "client"` flag
2. **Client fetches** available tool definitions via `fetchClientTools()`
3. **Client binds** platform-specific handlers using `bindToolHandlers()`
4. **Backend delegates** tool execution via WebSocket when needed
5. **Client executes** the tool and returns result to backend
6. **AI assistant** receives tool result and continues conversation

### Individual Tool Binding

Bind tools one at a time (useful for conditional loading):

```dart
// Check if location permission is granted
final hasLocationPermission = await _checkLocationPermission();

if (hasLocationPermission) {
  engine.bindToolHandler('get_location', (args) async {
    final position = await Geolocator.getCurrentPosition();
    return {'latitude': position.latitude, 'longitude': position.longitude};
  });
}

// Conditionally bind based on platform
if (Platform.isAndroid || Platform.isIOS) {
  engine.bindToolHandler('get_contacts', (args) async {
    final contacts = await ContactsService.getContacts();
    return {'count': contacts.length};
  });
}
```

### Tool Availability Tracking

Monitor which tools are available but not yet implemented:

```dart
// After fetching tools
final availableTools = await engine.fetchClientTools();
logger.info('Tools available', {'count': availableTools.length});

// After binding handlers
final boundCount = engine.toolRegistry.toolCount;
final unboundTools = engine.getUnboundClientTools();

logger.info('Tool binding status', {
  'bound': boundCount,
  'unbound': unboundTools.length,
});

if (unboundTools.isNotEmpty) {
  logger.warning('Missing tool implementations', {
    'tools': unboundTools.join(", "),
  });
  // Option 1: Implement missing tools
  // Option 2: Ignore if tools are optional
  // Option 3: Show warning to user via onMissingTools(unboundTools)
}
```

### Tool Definition Metadata

Access tool metadata from backend:

```dart
final tools = await engine.fetchClientTools();

for (final tool in tools) {
  logger.info('Tool metadata', {
    'name': tool.name,
    'description': tool.description,
    'parameterCount': tool.parameters.length,
  });

  for (final param in tool.parameters) {
    logger.debug('Tool parameter', {
      'tool': tool.name,
      'param': param.name,
      'type': param.type,
      'required': param.required,
      'description': param.description,
    });
  }
}
```

### WebSocket Message Flow

```
User Message → Backend LLM → Tool Call Decision
                              ↓
                    tool_execution_request (WebSocket)
                              ↓
                        Client executes tool
                              ↓
                    tool_execution_result (WebSocket)
                              ↓
                    Backend LLM receives result
                              ↓
                    Final AI response → User
```

### Error Handling

```dart
engine.bindToolHandlers({
  'get_location': (args) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      // Return error - backend will handle gracefully
      return {
        'error': 'Location permission denied',
        'code': 'PERMISSION_DENIED',
      };
    }
  },
});
```

### Benefits

- **Backend defines once**: Tool definitions stored in backend database
- **Client fetches dynamically**: No hardcoded tool lists
- **Version control**: Backend can add/remove tools without client updates
- **Platform-specific**: Execute native APIs not available on server
- **Secure**: Client validates tool permissions before execution
- **Fallback**: Backend can fallback to server-side execution if client fails

## 🔄 Advanced Usage

### With Chat History

```dart
// Initialize with existing conversation history
await engine.initializeConversation(
  chatHistory: [
    {
      'id': '1',
      'content': 'Hello!',
      'senderType': 'user',
      'timestamp': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
    },
    {
      'id': '2',
      'content': 'Hi there! How can I help you?',
      'senderType': 'assistant',
      'timestamp': DateTime.now().subtract(Duration(minutes: 4)).toIso8601String(),
    },
  ],
  context: {
    'user_preferences': 'casual_tone',
    'session_type': 'support',
  },
);
```

### Error Handling and Reconnection

```dart
final engine = VoiviChatEngine();

// Listen to errors
engine.errorStream.listen((error) {
  print('Chat error: $error');

  // Handle different error types
  if (error.contains('WebSocket')) {
    // Connection error - automatic reconnection will handle this
    print('Connection error detected, automatic reconnection in progress...');
  } else if (error.contains('timeout')) {
    // Timeout error
    print('Connection timeout, retrying...');
  }
});

// Monitor connection status
engine.stateStream.listen((state) {
  if (!state.isConnected && state.error != null) {
    print('Connection lost, will retry automatically');
  }
});

// Manual reconnection if needed
Future<void> forceReconnect() async {
  try {
    await engine.reconnect();
    print('Reconnection successful');
  } catch (e) {
    print('Reconnection failed: $e');
  }
}
```

### State Monitoring

```dart
// Get current state information
final state = engine.currentState;
print('Connected: ${state.isConnected}');
print('Message count: ${state.messages.length}');
print('Conversation ID: ${state.currentConversationId}');
print('Is typing: ${state.isTyping}');

// Get metadata
final metadata = engine.getConversationMetadata();
print('Metadata: $metadata');

// Access current messages
final messages = engine.messages;
print('Current messages: ${messages.length}');

// Get sentiment data (if enabled)
final sentiment = engine.sentimentData;
print('Sentiment: $sentiment');
```

## 🛠️ Backend Integration

### WebSocket Message Format

Your WebSocket backend should handle these message types:

**Outgoing (Client → Server):**
```json
{
  "type": "text",
  "content": "User's message text"
}

{
  "type": "initialize_conversation",
  "chatHistory": [...],
  "context": {...}
}
```

**Incoming (Server → Client):**
```json
{
  "type": "assistant_message",
  "content": "AI response text"
}

{
  "type": "conversation_started",
  "conversationId": "unique-id"
}

{
  "type": "connection_confirmed"
}
```

### WebSocket URL Structure

The engine automatically constructs WebSocket URLs like:

```
wss://your-backend.com/ws/conversation?assistantId=123&organizationId=456&userId=789&llmModel=gpt-4o&enableTTS=false&enableSentimentAnalysis=true&...
```

All configuration parameters are automatically included as query parameters.

## 🧪 Testing

### Mock Usage for Testing

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  group('VoiviChatEngine', () {
    late VoiviChatEngine engine;

    setUp(() {
      engine = VoiviChatEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('initializes with valid config', () async {
      final config = VoiviConfig(
        apiKey: 'test-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      await engine.initialize(config);
      expect(engine.isInitialized, isTrue);
      expect(engine.config, equals(config));
    });

    test('emits messages to stream', () async {
      // Setup test message
      final testMessage = ChatMessage(
        id: 'test-id',
        content: 'Test message',
        type: ChatMessageType.assistantMessage,
        timestamp: DateTime.now(),
        conversationId: 'test-conv',
      );

      // Listen to message stream
      expectLater(
        engine.messageStream,
        emits(testMessage),
      );

      // Simulate receiving a message (this would be done by WebSocketService)
      // engine._messageController.add(testMessage);
    });
  });
}
```

## 🐛 Error Handling

The engine provides comprehensive error handling:

```dart
// Listen to all errors
engine.errorStream.listen((error) {
  print('Error: $error');
});

// Check for specific error states
if (engine.error != null) {
  print('Current error: ${engine.error}');
}

// Customize connection behavior
final config = VoiviConfig(
  // ... other config
  reconnectAttempts: 5,      // Try 5 times
  reconnectDelayMs: 2000,    // Wait 2 seconds between attempts
  connectionTimeoutMs: 45000, // 45 second timeout
);
```

## 🤖 AI Text Summarization

The package provides AI-powered text summarization for any content using GPT-4o-mini.

### Summarize Any Text

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';

final apiService = VoiviApiService();

// Create summarization request
final request = SummarizeTextRequest(
  text: 'Your long text to summarize here...',
  customInstructions: 'Summarize in bullet points',
  maxSummaryTokens: 300,
  temperature: 0.3,
);

// Generate summary
final response = await apiService.summarizeText(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

print('Summary: ${response.summary}');
print('Tokens used: ${response.totalTokens}');
print('Cost: \$${response.cost.toStringAsFixed(6)}');
print('Processing time: ${response.processingTimeMs}ms');
```

### Estimate Cost Before Summarizing

```dart
// Estimate cost without actually generating the summary
final costEstimate = await apiService.estimateSummarizationCost(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

print('Estimated cost: \$${costEstimate['estimatedCost']}');
print('Estimated tokens: ${costEstimate['estimatedTokens']}');

// Proceed with summarization if cost is acceptable
if (costEstimate['estimatedCost'] < 0.01) {
  final response = await apiService.summarizeText(
    baseUrl: 'http://localhost:5065',
    request: request,
    apiKey: 'your-api-key',
  );
}
```

### Custom Summarization Options

```dart
// Concise summary
final concise = SummarizeTextRequest(
  text: longText,
  maxSummaryTokens: 100,
  temperature: 0.2, // More consistent
);

// Creative summary
final creative = SummarizeTextRequest(
  text: longText,
  customInstructions: 'Write an engaging summary with a storytelling approach',
  maxSummaryTokens: 500,
  temperature: 0.7, // More creative
);

// Technical summary
final technical = SummarizeTextRequest(
  text: technicalDocument,
  customInstructions: 'Focus on technical details and key metrics',
  maxSummaryTokens: 400,
  temperature: 0.3,
  modelId: 'gpt-4o-mini', // Specify model
);
```

### Text Summarization Features

- ✅ **Any Text**: Summarize articles, documents, conversations, etc.
- 🎯 **Custom Instructions**: Control summarization style and focus
- 🤖 **GPT-4o-mini**: Fast and cost-effective AI model
- 💰 **Cost Estimation**: Check cost before summarizing
- 🔐 **Dual Auth**: API Key or JWT Bearer Token support
- ⚡ **Fast**: Average processing time ~1-2 seconds
- 🎨 **Flexible**: Control length, temperature, and output style
- 🌍 **Multi-language**: Supports multiple languages including Turkish

### Text Summarization Pricing

| Type | Cost |
|------|------|
| Input tokens | $0.15 / 1M tokens |
| Output tokens | $0.60 / 1M tokens |
| Average summary | $0.0008 - $0.0050 |
| 100K token limit | Maximum input size |

### Use Cases

**Content Summarization**
```dart
// Summarize news articles
final newsRequest = SummarizeTextRequest(
  text: newsArticle,
  customInstructions: 'Provide key facts and main points',
  maxSummaryTokens: 200,
);
```

**Meeting Notes**
```dart
// Summarize meeting transcripts
final meetingRequest = SummarizeTextRequest(
  text: meetingTranscript,
  customInstructions: 'Extract action items and decisions',
  maxSummaryTokens: 300,
);
```

**Document Analysis**
```dart
// Summarize long documents
final docRequest = SummarizeTextRequest(
  text: longDocument,
  customInstructions: 'Highlight main arguments and conclusions',
  maxSummaryTokens: 500,
);
```

## 🎤 Speech-to-Text (STT) API

The package provides comprehensive speech-to-text transcription capabilities with advanced features like speaker diarization, customer detection, and word-level timings.

### Basic Audio Transcription

```dart
import 'dart:io';
import 'package:voivi_voice_ai/voivi_chat.dart';

final apiService = VoiviApiService();

// Create transcription request
final request = STTTranscribeRequest(
  audioFile: File('/path/to/audio.wav'),
  language: 'tr-TR',
);

// Transcribe audio
final response = await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

print('Transcription: ${response.text}');
print('Duration: ${response.duration.toStringAsFixed(2)}s');
print('Confidence: ${(response.confidence * 100).toStringAsFixed(1)}%');
print('Cost: \$${response.audioProcessingCost.toStringAsFixed(6)}');
```

### Speaker Diarization

Identify and separate different speakers in audio:

```dart
// Enable speaker diarization
final request = STTTranscribeRequest(
  audioFile: audioFile,
  language: 'tr-TR',
  enableDiarization: true,
  minSpeakers: 2,
  maxSpeakers: 8,
);

final response = await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

// Process speaker segments
print('Detected ${response.speakerCount} speakers');

for (final segment in response.speakerSegments ?? []) {
  print('${segment.speakerId} (${segment.startTimeSeconds.toStringAsFixed(1)}s - ${segment.endTimeSeconds.toStringAsFixed(1)}s):');
  print('  ${segment.text}');
  print('  Confidence: ${(segment.confidence * 100).toStringAsFixed(1)}%');
}
```

### Customer Detection

Automatically identify the primary customer in conversations:

```dart
// Enable customer detection
final request = STTTranscribeRequest(
  audioFile: audioFile,
  language: 'tr-TR',
  enableCustomerDetection: true,
);

final response = await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

if (response.primaryCustomerId != null) {
  print('Primary customer: ${response.primaryCustomerId}');

  // Filter customer segments
  final customerSegments = response.speakerSegments
      ?.where((s) => s.speakerId == response.primaryCustomerId)
      .toList();

  print('Customer said:');
  for (final segment in customerSegments ?? []) {
    print('  ${segment.text}');
  }
}
```

### Word-Level Timings

Get precise timing information for each word:

```dart
// Enable word-level timings
final request = STTTranscribeRequest(
  audioFile: audioFile,
  language: 'tr-TR',
  enableDiarization: true,
  includeWordTimings: true,
);

final response = await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

// Access word timings
for (final segment in response.speakerSegments ?? []) {
  if (segment.wordTimings != null) {
    for (final word in segment.wordTimings!) {
      print('${word.word}: ${word.startTimeSeconds}s - ${word.endTimeSeconds}s');
    }
  }
}
```

### Advanced STT Features

```dart
// Full-featured transcription
final request = STTTranscribeRequest(
  audioFile: audioFile,
  language: 'tr-TR',
  modelId: 'azure-speech-1',
  enableDiarization: true,
  enableCustomerDetection: true,
  includeWordTimings: true,
  minSpeakers: 2,
  maxSpeakers: 5,
);

final response = await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

// Access comprehensive results
print('Full transcript: ${response.text}');
print('Language: ${response.language}');
print('Duration: ${response.duration}s');
print('Confidence: ${response.confidence}');
print('Provider: ${response.provider}');
print('Speakers: ${response.speakerCount}');
print('Cost: \$${response.audioProcessingCost}');

// Audio metadata
if (response.audioInfo != null) {
  final info = response.audioInfo!;
  print('\nAudio Info:');
  print('  Format: ${info.format}');
  print('  Size: ${info.fileSizeMB} MB');
  print('  Sample Rate: ${info.sampleRate} Hz');
  print('  Channels: ${info.channels}');
  print('  Bit Depth: ${info.bitDepth}-bit');
}
```

### STT Model Management

```dart
// List available models
final models = await apiService.getAvailableSTTModels(
  baseUrl: 'http://localhost:5065',
  apiKey: 'your-api-key',
);
print('Available models: $models');

// Get model information
final modelInfo = await apiService.getSTTModelInfo(
  baseUrl: 'http://localhost:5065',
  modelId: 'azure-speech-1',
  apiKey: 'your-api-key',
);
print('Model: ${modelInfo.name}');
print('Provider: ${modelInfo.provider}');

// Get supported languages
final languages = await apiService.getSupportedLanguages(
  baseUrl: 'http://localhost:5065',
  modelId: 'azure-speech-1',
  apiKey: 'your-api-key',
);
print('Supported languages: $languages');

// Get supported formats
final formats = await apiService.getSupportedFormats(
  baseUrl: 'http://localhost:5065',
  modelId: 'azure-speech-1',
  apiKey: 'your-api-key',
);
print('Supported formats: $formats');

// Health check
final isHealthy = await apiService.sttHealthCheck(
  baseUrl: 'http://localhost:5065',
  apiKey: 'your-api-key',
);
print('STT service healthy: $isHealthy');
```

### STT Security & Validation

The SDK includes comprehensive security features:

```dart
// File validation before upload
final request = STTTranscribeRequest(
  audioFile: audioFile,
  language: 'tr-TR',
);

try {
  // Automatic validation checks:
  // ✅ File exists
  // ✅ File size (max 100MB)
  // ✅ File format (WAV, MP3, M4A, WEBM, OGG, FLAC)
  // ✅ File is not empty
  await request.validate();

  final response = await apiService.transcribeAudio(
    baseUrl: 'http://localhost:5065',
    request: request,
    apiKey: 'your-api-key',
  );
} on ArgumentError catch (e) {
  // Handle validation errors
  print('Validation error: ${e.message}');
} catch (e) {
  // Handle other errors
  print('Transcription error: $e');
}
```

### STT Features

- ✅ **Multi-Format Support**: WAV, MP3, M4A, WEBM, OGG, FLAC
- 🗣️ **Speaker Diarization**: Identify and separate different speakers
- 👤 **Customer Detection**: Automatically detect primary customer voice
- ⏱️ **Word-Level Timings**: Precise timestamp for each word
- 🌍 **Multi-Language**: Turkish, English, and 100+ languages
- 💰 **Cost Tracking**: Real-time cost calculation
- 🔐 **Dual Authentication**: API Key or Bearer Token
- 📊 **Audio Metadata**: Format, sample rate, channels, bit depth
- 🛡️ **Security**: File validation, size limits, format restrictions
- 🎯 **High Accuracy**: Azure Speech SDK powered
- ⚡ **Fast Processing**: Average 1-3s per audio file
- 🔄 **Idempotency**: Cache-based duplicate request prevention

### STT Technical Details

| Feature | Specification |
|---------|--------------|
| **Supported Formats** | WAV, MP3, M4A, WEBM, OGG, FLAC |
| **Max File Size** | 100 MB |
| **Language Support** | Turkish, English, 100+ languages |
| **Processing Time** | 1-3 seconds average |
| **Provider** | Azure Speech SDK |
| **Diarization** | 2-8 speakers optimal |
| **Security** | Input sanitization, path traversal protection |
| **Architecture** | SOLID principles, immutable models |

### STT Pricing

| Type | Cost |
|------|------|
| Standard transcription | $0.016 / minute |
| With diarization | $0.016 / minute |
| Average 1-minute audio | ~$0.016 |
| Average 5-minute audio | ~$0.080 |

### STT Error Handling

```dart
try {
  final response = await apiService.transcribeAudio(
    baseUrl: 'http://localhost:5065',
    request: request,
    apiKey: 'your-api-key',
  );
} on ArgumentError catch (e) {
  // Invalid input (file size, format, etc.)
  print('Invalid input: ${e.message}');
} on TimeoutException catch (e) {
  // Request timed out (30s default)
  print('Request timed out: $e');
} catch (e) {
  // Other errors (network, authentication, etc.)
  if (e.toString().contains('Unauthorized')) {
    print('Authentication failed: Check API key');
  } else if (e.toString().contains('413')) {
    print('File too large: Exceeds 100MB limit');
  } else if (e.toString().contains('415')) {
    print('Unsupported format: Use WAV, MP3, M4A, etc.');
  } else {
    print('Transcription error: $e');
  }
}
```

### STT Use Cases

**Call Center Transcription**
```dart
// Transcribe customer support calls
final request = STTTranscribeRequest(
  audioFile: callRecording,
  language: 'tr-TR',
  enableDiarization: true,
  enableCustomerDetection: true,
);
```

**Meeting Transcription**
```dart
// Transcribe meetings with multiple participants
final request = STTTranscribeRequest(
  audioFile: meetingAudio,
  language: 'en-US',
  enableDiarization: true,
  minSpeakers: 3,
  maxSpeakers: 10,
  includeWordTimings: true,
);
```

**Voice Note Transcription**
```dart
// Transcribe simple voice notes
final request = STTTranscribeRequest(
  audioFile: voiceNote,
  language: 'tr-TR',
);
```

## 🤖 AI-Powered Call Summary Generation

The package includes batch AI summary generation for call transcripts using GPT-4o-mini.

### Generate Summaries in Batch

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';

final apiService = VoiviApiService();

// Generate summaries for calls without summaries
final request = GenerateSummariesRequest(
  maxCalls: 10,
  onlyMissingSummaries: true,
);

final response = await apiService.generateSummaries(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

print('Success: ${response.successCount}/${response.totalProcessed}');
print('Total cost: \$${response.totalCost.toStringAsFixed(6)}');
print('Total tokens: ${response.totalTokensUsed}');

// Process successful summaries
for (final summary in response.successfulSummaries) {
  print('Call ${summary.callId}: ${summary.summary}');
  print('  Tokens: ${summary.tokensUsed}, Cost: \$${summary.cost}');
}

// Handle failures
for (final failed in response.failedSummaries) {
  print('Failed ${failed.callId}: ${failed.error}');
}
```

### Advanced Filtering

```dart
// Generate summaries for specific date range
final request = GenerateSummariesRequest(
  maxCalls: 50,
  startDate: DateTime(2025, 10, 1),
  endDate: DateTime(2025, 10, 31),
  onlyMissingSummaries: false, // Re-generate all
);

// Generate summaries for specific call IDs
final request = GenerateSummariesRequest(
  maxCalls: 10,
  callIds: [
    'c2183a4a-5301-4aad-9e23-77fb23ebaa43',
    '2224d014-0d64-4af6-8451-37c9c8450e06',
  ],
);

// Use JWT Bearer Token instead of API Key
final response = await apiService.generateSummaries(
  baseUrl: 'http://localhost:5065',
  request: request,
  bearerToken: 'your-jwt-token',
);
```

### Response Metrics

```dart
final response = await apiService.generateSummaries(...);

// Overall statistics
print('Success rate: ${(response.successRate * 100).toStringAsFixed(1)}%');
print('Average cost per call: \$${response.averageCostPerCall.toStringAsFixed(6)}');
print('Average tokens per call: ${response.averageTokensPerCall.toStringAsFixed(0)}');
print('Processing duration: ${response.processingDuration.inSeconds}s');

// Individual summaries
for (final summary in response.successfulSummaries) {
  print('📄 ${summary.callId}');
  print('   Summary: ${summary.summary}');
  print('   Tokens: ${summary.tokensUsed}');
  print('   Cost: \$${summary.cost.toStringAsFixed(6)}');
  print('   Processing time: ${summary.processingTimeMs}ms');
}
```

### Summary Generation Features

- ✅ **Batch Processing**: Generate up to 500 summaries per request
- 🤖 **GPT-4o-mini**: Powered by Azure OpenAI
- 💰 **Cost Tracking**: Real-time token and cost calculations
- 🎯 **Smart Filtering**: Date ranges, specific calls, or missing summaries only
- 🔐 **Dual Auth**: API Key or JWT Bearer Token support
- ⚡ **Performance**: Average ~1.5s per summary
- 🌍 **Turkish Language**: Optimized for Turkish conversations

### API Pricing

| Type | Cost |
|------|------|
| Input (Prompt) | $0.15 / 1M tokens |
| Output (Completion) | $0.60 / 1M tokens |
| Average per call | $0.0001 - $0.0008 |

## 📚 API Reference

### VoiviChatEngine

| Method | Returns | Description |
|--------|---------|-------------|
| `initialize(config)` | `Future<void>` | Initialize engine with configuration |
| `connect()` | `Future<void>` | Connect to WebSocket service |
| `disconnect()` | `Future<void>` | Disconnect from service |
| `sendMessage(text)` | `Future<void>` | Send text message |
| `reconnect()` | `Future<void>` | Reconnect to service |
| `dispose()` | `Future<void>` | Clean up resources |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `messageStream` | `Stream<ChatMessage>` | Stream of incoming messages |
| `stateStream` | `Stream<ConversationState>` | Stream of state changes |
| `errorStream` | `Stream<String>` | Stream of error messages |
| `isInitialized` | `bool` | Whether engine is initialized |
| `isConnected` | `bool` | Whether connected to service |
| `messages` | `List<ChatMessage>` | Current conversation messages |
| `currentState` | `ConversationState` | Current conversation state |

### VoiviConfig

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `apiKey` | `String` | ✅ | - | Your API authentication key |
| `organizationId` | `String` | ✅ | - | Organization identifier |
| `assistantId` | `String` | ✅ | - | AI assistant identifier |
| `baseUrl` | `String` | ✅ | - | WebSocket server URL |
| `userId` | `String?` | - | `null` | Custom user identifier |
| `llmModel` | `String` | - | `'gpt-4o'` | AI language model |
| `enableSentimentAnalysis` | `bool` | - | `true` | Enable sentiment analysis |
| `connectionTimeoutMs` | `int` | - | `30000` | Connection timeout (ms) |
| `reconnectAttempts` | `int` | - | `3` | Max reconnection attempts |

## 💡 Tips & Best Practices

1. **Environment Variables**: Store your API keys securely:
   ```dart
   VoiviConfig(
     apiKey: const String.fromEnvironment('VOIVI_API_KEY'),
     // ...
   )
   ```

2. **Resource Management**: Always dispose of the engine:
   ```dart
   try {
     // Use engine
   } finally {
     await engine.dispose();
   }
   ```

3. **Error Handling**: Always listen to error streams:
   ```dart
   engine.errorStream.listen((error) {
     // Handle errors appropriately
   });
   ```

4. **State Monitoring**: Monitor connection state for robust apps:
   ```dart
   engine.stateStream.listen((state) {
     if (!state.isConnected) {
       // Show connection lost UI
     }
   });
   ```

## 🚀 Migration from UI Package

If migrating from a Flutter-specific chat package:

**Before:**
```dart
VoiviChatWidget(config: config) // UI component
```

**After:**
```dart
final engine = VoiviChatEngine();
await engine.initialize(config);
await engine.connect();
// Build your own UI with engine.messageStream
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 [Documentation](https://github.com/voivihq/voivi_chat#readme)
- 🐛 [Issue Tracker](https://github.com/voivihq/voivi_chat/issues)
- 💬 [Discussions](https://github.com/voivihq/voivi_chat/discussions)

---

## 🔍 Keywords & Search Terms

**Conversation AI Development**: Build production-ready conversation AI applications with this comprehensive Flutter SDK. Perfect for developers looking to implement voice conversation AI, text conversation AI, or multi-modal conversation AI experiences.

**Core Technologies**: conversation ai, conversational ai, flutter conversation ai, conversation ai kit, conversation ai sdk, conversation ai framework, flutter ai conversation, ai conversation platform, multimodal conversation ai, voice conversation ai, text conversation ai

**Features**: speech to text flutter, text to speech flutter, flutter chatbot, flutter ai assistant, flutter voice assistant, ai chat sdk, conversation platform, gpt-4 flutter, azure speech flutter, openai whisper flutter, flutter websocket streaming, real-time ai chat

**Use Cases**: customer support ai, voice assistant flutter, ai chatbot development, conversation ai platform, intelligent conversation, multi-turn dialogue, context-aware chat, ai voice chat, flutter voice chat, conversation history, sentiment analysis

---

**Made with ❤️ by the Voivi Team** | Building the future of **conversation AI** in Flutter