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

## [1.3.0] - 2025-12-13

### Added
- 🎤 **STT (Speech-to-Text) API Support**: Full transcription API with multipart file upload
- **Speaker Diarization**: Identify and segment different speakers in audio
- **Primary Customer Detection**: Detect main customer voice in conversations
- **Word-Level Timings**: Get precise timing information for each word
- **Audio Metadata Extraction**: File size, format, sample rate, channels, bit depth
- **Model Management**: List models, get model info, supported languages and formats
- **Health Check Endpoint**: Monitor STT service availability
- **Cost Tracking**: Real-time cost calculation for audio processing
- **Security Features**: File validation, size limits (100MB), format restrictions
- **STT Test Screen**: Comprehensive example app screen for testing all STT features
- New models: `STTResponse`, `STTSegment`, `STTWord`, `AudioFileMetadata`, `SpeakerSegmentDto`, `WordTimingDto`, `STTModelInfo`, `STTTranscribeRequest`

### Features
- `VoiviApiService.transcribeAudio()` - Main transcription method with advanced options
- `VoiviApiService.getAvailableSTTModels()` - List all available STT models
- `VoiviApiService.getSTTModelInfo()` - Get detailed model information
- `VoiviApiService.getSupportedLanguages()` - Get supported languages for a model
- `VoiviApiService.getSupportedFormats()` - Get supported audio formats
- `VoiviApiService.sttHealthCheck()` - Check STT service health status
- Dual authentication support (API Key or Bearer Token)
- Multipart form-data upload with timeout management (30s)
- Fail-fast validation with comprehensive error messages
- Structured logging for debugging and monitoring
- Idempotency support (backend cache-based)

### Technical Details
- **Supported Formats**: WAV, MP3, M4A, WEBM, OGG, FLAC
- **Max File Size**: 100MB
- **Processing Time**: Average 1-3s per audio file
- **Language Support**: Turkish, English, and 100+ languages via Azure Speech SDK
- **Security**: Early input sanitization, file validation, path traversal protection
- **Architecture**: SOLID principles, immutable models, null safety
- **Error Handling**: Fail-fast approach with clear error messages
- **Observability**: Comprehensive logging for all operations

### Enhanced
- Updated `VoiviApiService` with STT capabilities
- Added file_picker dependency to example app (v6.1.1)
- Enhanced example app with STT test screen
- Updated README with STT documentation and security notes

### Example Usage
```dart
import 'package:voivi_voice_ai/voivi_chat.dart';
import 'dart:io';

final apiService = VoiviApiService();
final audioFile = File('/path/to/audio.wav');

// Basic transcription
final request = STTTranscribeRequest(
  audioFile: audioFile,
  language: 'tr-TR',
);

final response = await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

print('Transcription: ${response.text}');
print('Cost: \$${response.audioProcessingCost}');
print('Duration: ${response.duration}s');

// With diarization and customer detection
final advancedRequest = STTTranscribeRequest(
  audioFile: audioFile,
  language: 'tr-TR',
  enableDiarization: true,
  enableCustomerDetection: true,
  includeWordTimings: true,
);

final result = await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: advancedRequest,
  apiKey: 'your-api-key',
);

// Process speaker segments
for (var segment in result.speakerSegments ?? []) {
  print('${segment.speakerId}: ${segment.text}');
  print('  Time: ${segment.startTimeSeconds}s - ${segment.endTimeSeconds}s');
}

if (result.primaryCustomerId != null) {
  print('Primary customer: ${result.primaryCustomerId}');
}
```

### Breaking Changes
- None - Fully backward compatible

### Migration Guide
- No migration needed - all new features are additive

## [1.3.2] - 2025-12-13

### 🔒 Security Fixes (CRITICAL)
- **Input Sanitization**: Added comprehensive input validation to prevent injection attacks
  - URL scheme validation (only http/https allowed)
  - Path traversal protection (prevents ../ attacks)
  - Query parameter sanitization (prevents injection)
  - Empty/whitespace string validation
- **Singleton Pattern Bug**: Fixed config mutation vulnerability
  - Prevents silent config replacement in singleton
  - Throws StateError if attempting to initialize with different config
  - Must call `resetInstance()` to use new config

### 🛡️ Resilience Improvements
- **Timeout Protection**: Added missing timeouts to 4 critical methods
  - `listAssistants()` - 30s timeout
  - `getAssistant()` - 30s timeout
  - `generateSummaries()` - 30s timeout
  - `estimateSummarizationCost()` - 30s timeout
- **Fail-Fast Validation**: Enhanced parameter validation
  - Trim whitespace from all string inputs
  - Validate non-empty strings for critical parameters
  - Clear error messages for debugging

### 🔧 Technical Details
- New sanitization helpers:
  - `_sanitizeBaseUrl()` - URL format and scheme validation
  - `_sanitizePathParam()` - Path traversal prevention
  - `_sanitizeQueryParam()` - Query injection prevention
- Applied to all 12 API methods
- Zero performance impact (validation is O(1))

### Security Impact
- **Prevented Attacks**:
  - Path traversal: `assistantId = "../../../admin"`
  - URL injection: `baseUrl = "file:///etc/passwd"`
  - Query injection: `orgId = "foo&admin=true"`
  - XSS: `assistantId = "<script>alert(1)</script>"`

### Breaking Changes
- **Singleton Behavior**: May throw `StateError` if reinitializing with different config
  - **Migration**: Call `VoiviApiService.resetInstance()` before creating new instance with different config
  - Example:
    ```dart
    // Old (may fail now)
    final service1 = VoiviApiService(config: config1);
    final service2 = VoiviApiService(config: config2); // ❌ StateError

    // New (correct)
    final service1 = VoiviApiService(config: config1);
    VoiviApiService.resetInstance();
    final service2 = VoiviApiService(config: config2); // ✅ Works
    ```

### Testing
- ✅ All 110 unit tests passing
- ✅ dart analyze: No issues
- ✅ Backward compatible (except singleton edge case)

## [1.3.1] - 2025-12-13

### Enhanced
- 🎯 **Simplified API Usage**: VoiviApiService now accepts optional `VoiviConfig` in constructor
  - Set configuration once, use everywhere without repeating credentials
  - All API methods now support smart defaults from config
  - Parameters can still override config values when needed
  - Fully backward compatible - existing code works unchanged

### Changed
- `VoiviApiService` constructor now accepts optional `VoiviConfig` parameter
- All 12 API methods updated with optional `baseUrl`, `apiKey`, and/or `organizationId` parameters
  - **Assistant Management** (2 methods): `listAssistants`, `getAssistant`
  - **Summarization** (3 methods): `generateSummaries`, `summarizeText`, `estimateSummarizationCost`
  - **Tool Management** (1 method): `fetchClientTools`
  - **STT API** (6 methods): `transcribeAudio`, `getAvailableSTTModels`, `getSTTModelInfo`, `getSupportedLanguages`, `getSupportedFormats`, `sttHealthCheck`

### Added
- Smart defaults helper methods: `_getBaseUrl()`, `_getApiKey()`, `_getOrganizationId()`
- Fail-fast validation with clear error messages when required parameters missing
- Updated README with simplified API usage examples and benefits

### Example Usage
```dart
// Before: Repetitive
final apiService = VoiviApiService();
await apiService.transcribeAudio(
  baseUrl: 'http://localhost:5065',
  request: request,
  apiKey: 'your-api-key',
);

// After: Clean and DRY
final config = VoiviConfig(
  baseUrl: 'http://localhost:5065',
  apiKey: 'your-api-key',
  organizationId: 'org-123',
  assistantId: 'ast-456',
);
final apiService = VoiviApiService(config: config);

await apiService.transcribeAudio(request: request);
await apiService.listAssistants();
await apiService.generateSummaries(request: summaryRequest);
```

### Benefits
- ✅ **DRY Principle**: Configure once, use everywhere
- ✅ **Less Boilerplate**: Cleaner, more readable code
- ✅ **Fully Backward Compatible**: No breaking changes
- ✅ **Flexible**: Override config with method parameters when needed
- ✅ **SOLID**: Single source of truth for configuration

### Breaking Changes
- None - All changes are fully backward compatible

## [1.3.3] - 2025-01-XX

### Documentation
- 📚 **Enhanced SEO & Discoverability**: Comprehensive optimization for conversation AI discoverability
  - Added "conversation AI" keyword strategy throughout documentation
  - Positioned as complete conversation AI kit for Flutter developers
  - Enhanced feature categorization (Conversation AI Core, Advanced Capabilities, Developer Experience)
  - Added comprehensive keyword section for search engine optimization
  - Updated pubspec.yaml description with conversation AI focus
  - Added 14 conversation AI-focused topics for better pub.dev visibility

### Improved
- **Package Description**: Updated to emphasize conversation AI capabilities (voice + text + multi-modal)
- **README Structure**: Reorganized features into logical categories for better readability
- **SEO Keywords**: Added extensive keyword coverage for voice conversation AI, text conversation AI, and multimodal conversation AI use cases
- **Topics**: Updated pub.dev topics with conversation-ai, multimodal-ai, chatbot, gpt-4, and other high-value keywords

### Meta
- No code changes - purely documentation and metadata improvements
- Zero breaking changes - fully backward compatible
- Improved discoverability for developers searching for conversation AI solutions

## [Unreleased]

### Planned Features
- Real-time STT streaming
- Voice message support
- Message encryption
- Offline message queuing
- Push notification integration
- Custom theme support
- Message reactions
- File attachment support