# Conversation AI Guide

## What is Conversation AI?

**Conversation AI** (Conversational AI) enables natural, human-like interactions between users and applications through voice, text, or multi-modal interfaces. Unlike traditional rule-based chatbots, **conversation AI** systems understand context, maintain memory across interactions, and adapt to user intent dynamically.

The **voivi_voice_ai** package provides everything you need to build production-ready **conversation AI** experiences in Flutter.

---

## Why Build Conversation AI Applications?

### Benefits of Conversation AI

- **Natural Interaction**: Users communicate naturally without learning complex interfaces
- **Context Awareness**: Conversation AI remembers past interactions and understands context
- **Multi-Modal**: Support voice, text, or both based on user preference
- **24/7 Availability**: AI-powered conversations never sleep
- **Scalability**: Handle thousands of concurrent conversations
- **Cost Efficiency**: Reduce support costs while improving user experience

### Use Cases

1. **Customer Support**: AI-powered help desks with conversation history
2. **Voice Assistants**: Hands-free interfaces for mobile apps
3. **Healthcare**: Patient intake and symptom checking
4. **E-Commerce**: Shopping assistants and product recommendations
5. **Education**: Interactive learning and tutoring
6. **Accessibility**: Voice interfaces for visually impaired users

---

## Types of Conversation AI

### 1. Voice Conversation AI

Real-time speech-to-text (STT) and text-to-speech (TTS) powered conversations.

**Best for:**
- Hands-free operations (driving, cooking, working)
- Accessibility needs
- Natural, human-like interactions
- Phone call automation

**Features:**
- Real-time speech recognition
- Natural voice synthesis
- Speaker diarization
- Voice activity detection

### 2. Text Conversation AI

Traditional text-based chatbot conversations with AI intelligence.

**Best for:**
- Customer support chats
- In-app messaging
- FAQ automation
- Data collection forms

**Features:**
- Instant messaging
- Rich message types (text, images, buttons)
- Conversation history
- Sentiment analysis

### 3. Multi-Modal Conversation AI

Seamlessly switch between voice and text in the same conversation.

**Best for:**
- Flexible user experiences
- Hybrid workflows (start with voice, finish with text)
- Accessibility compliance
- Complex multi-step processes

**Features:**
- Automatic mode switching
- Context preservation across modes
- Adaptive UI
- Best-of-both-worlds UX

---

## Building Your First Conversation AI

### Quick Start: Voice Conversation AI

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';

final engine = VoiviChatEngine();

// Configure for voice conversation AI
await engine.initialize(VoiviConfig(
  baseUrl: 'https://api.voivi.ai',
  apiKey: 'your-api-key',
  organizationId: 'org_xxx',
  assistantId: 'asst_xxx',
  enableTTS: true, // Enable voice output
));

// Listen to voice transcripts
engine.messageStream.listen((message) {
  if (message.type == ChatMessageType.userTranscript) {
    print('User said: ${message.content}');
  }
  if (message.type == ChatMessageType.assistantMessage) {
    print('AI responded: ${message.content}');
  }
});

await engine.connect();
```

### Quick Start: Text Conversation AI

```dart
import 'package:voivi_voice_ai/voivi_chat.dart';

final engine = VoiviChatEngine();

// Configure for text conversation AI
await engine.initialize(VoiviConfig(
  baseUrl: 'https://api.voivi.ai',
  apiKey: 'your-api-key',
  organizationId: 'org_xxx',
  assistantId: 'asst_xxx',
  enableTTS: false, // Text only
));

// Listen to messages
engine.messageStream.listen((message) {
  print('${message.type}: ${message.content}');
});

await engine.connect();

// Send text message
await engine.sendMessage('Hello AI!');
```

### Quick Start: Multi-Modal Conversation AI

```dart
final engine = VoiviChatEngine();

await engine.initialize(VoiviConfig(
  baseUrl: 'https://api.voivi.ai',
  apiKey: 'your-api-key',
  organizationId: 'org_xxx',
  assistantId: 'asst_xxx',
  enableTTS: true, // Support both modes
));

// User can speak or type
engine.messageStream.listen((message) {
  // Handle both voice and text messages
  handleMessage(message);
});

await engine.connect();

// Send text message
await engine.sendMessage('Can you help me?');

// Or use voice input (handled automatically by backend)
```

---

## Advanced Conversation AI Features

### Context & Memory Management

```dart
// Initialize with conversation history
await engine.initializeConversation(
  chatHistory: [
    {
      'content': 'Previous user message',
      'senderType': 'user',
      'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
    },
  ],
  context: {
    'user_preferences': 'technical_support',
    'language': 'en',
  },
);
```

### Tool Calling & Function Execution

Enable AI to execute platform-specific functions:

```dart
// Bind client-side tools
engine.bindToolHandlers({
  'get_location': (args) async {
    final position = await Geolocator.getCurrentPosition();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  },
  'search_products': (args) async {
    final query = args['query'] as String;
    final products = await searchDatabase(query);
    return {'products': products};
  },
});

// AI can now call these tools during conversation
// User: "What's my current location?"
// → AI calls get_location tool
// → AI responds: "You are at latitude X, longitude Y"
```

### Sentiment Analysis

```dart
final config = VoiviConfig(
  // ... other config
  enableSentimentAnalysis: true,
);

engine.messageStream.listen((message) {
  if (message.sentiment != null) {
    print('User sentiment: ${message.sentiment}');
    // Adjust AI response based on sentiment
  }
});
```

---

## Best Practices

### 1. Error Handling

Always handle conversation AI errors gracefully:

```dart
engine.errorStream.listen((error) {
  print('Conversation AI error: $error');
  // Show user-friendly error message
  // Log error to monitoring service
  // Attempt reconnection if needed
});
```

### 2. State Management

Monitor conversation state for robust UX:

```dart
engine.stateStream.listen((state) {
  if (!state.isConnected) {
    // Show "Connecting..." UI
  }
  if (state.isTyping) {
    // Show typing indicator
  }
});
```

### 3. Resource Management

Always dispose of conversation AI resources:

```dart
try {
  // Use conversation AI
} finally {
  await engine.dispose();
}
```

### 4. Privacy & Security

- Store API keys securely (environment variables, secure storage)
- Validate user input before sending to conversation AI
- Implement rate limiting for conversation AI requests
- Use HTTPS for all conversation AI communications
- Comply with data privacy regulations (GDPR, CCPA)

---

## Performance Optimization

### Reduce Latency

```dart
// Use production-optimized configuration
final config = VoiviConfig(
  baseUrl: 'https://api.voivi.ai', // Use CDN/edge endpoints
  connectionTimeoutMs: 15000, // Shorter timeout
  reconnectAttempts: 1, // Faster failure detection
  llmModel: 'gpt-4o-mini', // Faster model
);
```

### Minimize Token Usage

```dart
// Limit conversation history
await engine.initializeConversation(
  chatHistory: recentMessages.takeLast(10), // Only last 10 messages
);

// Use concise system prompts
```

### Handle High Traffic

```dart
// Implement conversation pooling for scalability
class ConversationPool {
  final Map<String, VoiviChatEngine> _engines = {};

  Future<VoiviChatEngine> getEngine(String userId) async {
    if (!_engines.containsKey(userId)) {
      final engine = VoiviChatEngine();
      await engine.initialize(config);
      await engine.connect();
      _engines[userId] = engine;
    }
    return _engines[userId]!;
  }

  Future<void> dispose() async {
    for (final engine in _engines.values) {
      await engine.dispose();
    }
    _engines.clear();
  }
}
```

---

## Conversation AI vs Traditional Chatbots

| Feature | Traditional Chatbots | Conversation AI |
|---------|---------------------|-----------------|
| **Context Understanding** | ❌ Limited | ✅ Advanced |
| **Natural Language** | ⚠️ Keyword-based | ✅ GPT-powered |
| **Voice Support** | ❌ Text only | ✅ Voice + Text |
| **Memory** | ⚠️ Basic | ✅ Persistent |
| **Intent Recognition** | ⚠️ Rule-based | ✅ AI-powered |
| **Multi-Turn Dialogue** | ❌ Difficult | ✅ Natural |
| **Adaptability** | ❌ Static | ✅ Learning |
| **Tool Calling** | ❌ Hardcoded | ✅ Dynamic |

---

## Migration from Other Solutions

### From Dialogflow to Conversation AI

```dart
// Before (Dialogflow)
final dialogflow = DialogflowV2(...);
await dialogflow.detectIntent(text);

// After (voivi_voice_ai)
final engine = VoiviChatEngine();
await engine.initialize(config);
await engine.sendMessage(text);
```

### From Traditional Chat to Conversation AI

```dart
// Before (Traditional Chat)
class ChatService {
  void sendMessage(String text) {
    // Simple message sending
    http.post('/chat', body: {'message': text});
  }
}

// After (Conversation AI)
final engine = VoiviChatEngine();
await engine.initialize(config);
await engine.connect();
await engine.sendMessage(text); // With context, memory, tools
```

---

## Resources

### Documentation
- [Main README](../README.md) - Complete package documentation
- [API Reference](https://pub.dev/documentation/voivi_voice_ai) - Full API documentation
- [Example App](../example/) - Working examples

### Community
- [GitHub Issues](https://github.com/voivihq/voivi_voice_ai/issues) - Bug reports and feature requests
- [Discussions](https://github.com/voivihq/voivi_voice_ai/discussions) - Community Q&A

### Learning Resources
- [What is Conversational AI?](https://en.wikipedia.org/wiki/Conversational_AI) - Wikipedia overview
- [LangChain Docs](https://docs.langchain.com/) - LLM orchestration concepts
- [OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling) - Tool execution patterns

---

## Glossary

- **Conversation AI**: AI systems that enable natural dialogue with users
- **STT (Speech-to-Text)**: Converting spoken audio to text
- **TTS (Text-to-Speech)**: Converting text to spoken audio
- **LLM (Large Language Model)**: AI model for text generation (GPT-4, Claude, etc.)
- **Diarization**: Identifying different speakers in audio
- **Tool Calling**: AI executing platform-specific functions
- **Multi-Modal**: Supporting multiple input/output modes (voice, text, etc.)
- **Context**: Information from past conversation turns
- **Sentiment Analysis**: Detecting emotional tone in messages

---

**Need Help?** Open an issue on [GitHub](https://github.com/voivihq/voivi_voice_ai/issues) or check the [Discussions](https://github.com/voivihq/voivi_voice_ai/discussions) forum.

**Building Conversation AI?** We'd love to hear about your project! Share your story in our community.
