# Changelog

All notable changes to the Voivi Chat package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0+1] - 2024-12-18

### Added
- Initial universal package release
- Production-ready AI-powered text chat integration
- WebSocket-based real-time communication
- BLoC state management for reactive UI updates
- Customizable chat message bubbles
- Connection status indicators and error handling
- Support for chat history and conversation context
- Automatic message retry and connection management
- Comprehensive error handling and logging
- Easy integration with existing Flutter applications

### Features
- **Text Chat**: Full-featured text messaging with AI assistants
- **Real-time Communication**: WebSocket-based instant messaging
- **State Management**: BLoC pattern for predictable state updates
- **Customizable UI**: Flexible widgets for chat integration
- **Error Recovery**: Automatic reconnection and error handling
- **Chat History**: Support for conversation context and history
- **Production Ready**: Built for scale with comprehensive error handling

### Dependencies
- `flutter: >=3.10.0`
- `web_socket_channel: ^3.0.1`
- `flutter_bloc: ^8.1.3`
- `meta: ^1.9.1`

### Supported Platforms
- Android ✅
- iOS ✅
- Web ✅
- macOS ✅
- Windows ✅
- Linux ✅

## [1.1.0] - 2025-11-01

### Added
- **AI Text Summarization**: New `summarizeText()` method to summarize any text using GPT-4o-mini
- **Cost Estimation**: Pre-flight cost calculation with `estimateSummarizationCost()`
- New models: `SummarizeTextRequest` and `SummarizeTextResponse`
- Comprehensive text summarization documentation with use cases
- Support for custom instructions, temperature control, and token limits
- Multi-language support for text summarization

### Enhanced
- `VoiviApiService` now includes text summarization capabilities
- Added detailed examples for content summarization, meeting notes, and document analysis
- Updated README with text summarization features and pricing

### Technical Details
- Maximum input: 100K tokens
- Temperature range: 0.0 - 2.0
- Max summary tokens: 50 - 2000
- Average processing time: 1-2 seconds
- Cost range: $0.0008 - $0.0050 per summary

## [1.2.0] - 2025-11-11

### Added
- **Client-Side Tool Execution**: New ToolRegistry system for platform-specific tool delegation
- **Backend-Driven Tool Binding**: Fetch tool definitions from backend and bind handlers dynamically
- **Tool Definition Models**: New `ClientToolDefinition` and `ToolParameter` models for tool metadata
- **Tool Registry**: Register custom functions that can be invoked by AI assistants
- **WebSocket Tool Delegation**: Backend automatically delegates tool execution to client via WebSocket
- **Platform-Specific Tools**: Execute mobile/browser-specific functions (geolocation, device info, etc.)
- **Tool Availability Tracking**: Check which tools are available but not yet implemented

### Features
- `ToolRegistry` class for registering client-side tools
- `VoiviChatEngine.fetchClientTools()` - Fetch available tools from backend
- `VoiviChatEngine.bindToolHandler()` - Bind single tool handler
- `VoiviChatEngine.bindToolHandlers()` - Bind multiple tool handlers at once (RECOMMENDED)
- `VoiviChatEngine.getUnboundClientTools()` - Get list of tools not yet implemented
- `VoiviChatEngine.toolRegistry` getter for direct registry access
- Automatic WebSocket message handling for `tool_execution_request`
- Tool bound check with warning when tool is not available on client
- Tool result propagation back to backend via `tool_execution_result`
- Support for async tool execution with error handling
- Comprehensive logging for tool execution debugging

### Technical Details
- Tool handlers are async functions: `Future<dynamic> Function(Map<String, dynamic>)`
- Tools can access platform-specific APIs (geolocation, camera, sensors, etc.)
- Backend sends tool execution requests with: toolCallId, toolName, arguments
- Client responds with: toolCallId, success, result/error
- Client-side tools filtered by: source=external, executionLocation=client
- Timeout handling and error propagation
- Backend can fallback to server-side execution if tool not bound on client

### Example Usage
```dart
final engine = VoiviChatEngine();
await engine.initialize(config);

// 1. Fetch available tools from backend
final clientTools = await engine.fetchClientTools();
print('Available tools: ${clientTools.map((t) => t.name).toList()}');

// 2. Bind tool handlers (Map-based - RECOMMENDED)
engine.bindToolHandlers({
  'get_location': (args) async {
    final position = await Geolocator.getCurrentPosition();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  },
  'get_device_info': (args) async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
  },
});

// 3. Check unbound tools (optional)
final unbound = engine.getUnboundClientTools();
if (unbound.isNotEmpty) {
  print('⚠️ Tools not implemented: $unbound');
}

await engine.connect();
// Backend can now delegate tool execution to client
```

## [Unreleased]

### Planned Features
- Voice message support
- Message encryption
- Offline message queuing
- Push notification integration
- Custom theme support
- Message reactions
- File attachment support