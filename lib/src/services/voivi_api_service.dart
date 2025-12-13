import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:voivi_voice_ai/src/core/voivi_config.dart';
import 'package:voivi_voice_ai/src/models/summary_models.dart';
import 'package:voivi_voice_ai/src/models/stt_models.dart';
import 'package:voivi_voice_ai/src/models/tool_definition_models.dart';

/// HTTP REST API service for Voivi AI Assistant management
///
/// This service provides methods to interact with the Voivi AI REST API
/// for managing assistants. It uses a singleton pattern for consistency
/// with other services in the package.
///
/// Example usage:
/// ```dart
/// final apiService = VoiviApiService();
/// final assistants = await apiService.listAssistants(
///   baseUrl: 'http://localhost:5065',
///   apiKey: 'your-api-key',
///   organizationId: 'org_xxx',
/// );
/// ```
class VoiviApiService {
  factory VoiviApiService({VoiviConfig? config}) {
    // CRITICAL FIX: Prevent config mutation in singleton
    if (_instance != null && config != null) {
      if (_instance!.config != config) {
        throw StateError(
          'VoiviApiService already initialized with different config. '
          'Call resetInstance() first to use new config.',
        );
      }
    }
    _instance ??= VoiviApiService._internal(config);
    return _instance!;
  }

  VoiviApiService._internal(this.config);

  // Optional config for smart defaults
  final VoiviConfig? config;

  // Singleton pattern (consistent with WebSocketService)
  static VoiviApiService? _instance;

  // HTTP client instance
  final http.Client _client = http.Client();

  // Timeout configuration for API requests
  static const Duration _apiTimeout = Duration(seconds: 30);

  // ==========================================================================
  // Input Sanitization & Validation
  // ==========================================================================

  /// Sanitize and validate baseUrl
  ///
  /// SECURITY: Prevents URL injection, validates scheme
  String _sanitizeBaseUrl(String url) {
    final trimmed = url.trim();

    // Empty/whitespace check
    if (trimmed.isEmpty) {
      throw ArgumentError('baseUrl cannot be empty or whitespace');
    }

    // Validate URL scheme (only http/https allowed)
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      throw ArgumentError(
        'baseUrl must start with http:// or https://, got: $trimmed',
      );
    }

    // Validate URL format
    try {
      final uri = Uri.parse(trimmed);
      if (uri.host.isEmpty) {
        throw ArgumentError('Invalid baseUrl: missing host');
      }

      // Prevent file:// javascript:// etc
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        throw ArgumentError('Invalid URL scheme: ${uri.scheme}');
      }
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw ArgumentError('Invalid baseUrl format: $e');
    }

    return trimmed;
  }

  /// Sanitize path parameter to prevent path traversal
  ///
  /// SECURITY: Prevents ../../../ attacks
  String _sanitizePathParam(String param, String paramName) {
    final trimmed = param.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('$paramName cannot be empty or whitespace');
    }

    // Prevent path traversal
    if (trimmed.contains('..') ||
        trimmed.contains('/') ||
        trimmed.contains('\\')) {
      throw ArgumentError(
        'Path traversal detected in $paramName: $trimmed',
      );
    }

    // URL encode the parameter
    return Uri.encodeComponent(trimmed);
  }

  /// Sanitize query parameter
  ///
  /// SECURITY: Prevents query injection
  String _sanitizeQueryParam(String param, String paramName) {
    final trimmed = param.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('$paramName cannot be empty or whitespace');
    }

    // URL encode to prevent injection
    return Uri.encodeComponent(trimmed);
  }

  // ==========================================================================
  // Smart Defaults Helper Methods
  // ==========================================================================

  /// Get baseUrl from provided parameter or config
  ///
  /// Throws ArgumentError if neither is available
  /// SECURITY: Sanitizes and validates URL
  String _getBaseUrl(String? providedUrl) {
    final url = providedUrl ?? config?.baseUrl;
    if (url == null) {
      throw ArgumentError(
        'baseUrl required: Provide in constructor config or method parameter',
      );
    }
    return _sanitizeBaseUrl(url);
  }

  /// Get apiKey from provided parameter or config
  ///
  /// Returns null if neither is available (authentication check happens later)
  String? _getApiKey(String? providedKey) {
    final key = providedKey ?? config?.apiKey;
    if (key != null && key.trim().isEmpty) {
      throw ArgumentError('apiKey cannot be empty or whitespace');
    }
    return key?.trim();
  }

  /// Get organizationId from provided parameter or config
  ///
  /// Returns null if neither is available (validation happens in API method)
  String? _getOrganizationId(String? providedId) {
    final orgId = providedId ?? config?.organizationId;
    if (orgId != null && orgId.trim().isEmpty) {
      throw ArgumentError('organizationId cannot be empty or whitespace');
    }
    return orgId?.trim();
  }

  // ==========================================================================
  // Assistant Management API Methods
  // ==========================================================================

  /// List all assistants for an organization
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [apiKey] - API key for authentication (optional if provided in config)
  /// [organizationId] - Organization ID (optional if provided in config)
  /// Returns a list of AssistantModel objects
  Future<List<AssistantModel>> listAssistants({
    String? baseUrl,
    String? apiKey,
    String? organizationId,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);
    final orgId = _getOrganizationId(organizationId);

    // FAIL-FAST: Validate required parameters
    if (key == null) {
      throw ArgumentError(
        'apiKey required: Provide in constructor config or method parameter',
      );
    }
    if (orgId == null) {
      throw ArgumentError(
        'organizationId required: Provide in constructor config or method parameter',
      );
    }

    // SECURITY: Sanitize query parameter
    final sanitizedOrgId = _sanitizeQueryParam(orgId, 'organizationId');

    try {
      final uri = Uri.parse(
        '$url/api/assistants?organizationId=$sanitizedOrgId',
      );

      developer.log('🔍 Fetching assistants from: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'X-Api-Key': key,
          'Content-Type': 'application/json',
        },
      ).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'List assistants timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log('📡 Response status: ${response.statusCode}');
      developer.log('📄 Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        developer.log('📦 Response type: ${decoded.runtimeType}');

        // Handle both List and Map responses
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
          developer.log('✅ Got List response with ${data.length} items');
        } else if (decoded is Map<String, dynamic>) {
          // Handle wrapped response like {"assistants": [...]}
          data = decoded['assistants'] as List? ??
                 decoded['data'] as List? ??
                 [];
          developer.log('✅ Got Map response, extracted ${data.length} items');
        } else {
          throw Exception('Unexpected response format: ${decoded.runtimeType}');
        }

        developer.log('🔄 Parsing ${data.length} assistants...');
        final assistants = <AssistantModel>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            developer.log('  [$i] Parsing: ${item.runtimeType}');
            final assistant = AssistantModel.fromJson(item as Map<String, dynamic>);
            assistants.add(assistant);
          } catch (e, stackTrace) {
            developer.log('  [$i] ❌ Error parsing assistant: $e');
            developer.log('  [$i] StackTrace: $stackTrace');
            // Continue with other assistants
          }
        }

        developer.log('✅ Successfully loaded ${assistants.length} assistants');
        return assistants;
      } else {
        final errorMessage =
            'Failed to load assistants: ${response.statusCode} - ${response.body}';
        developer.log('❌ $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('❌ Error listing assistants: $e');
      rethrow;
    }
  }

  /// Get a specific assistant by ID
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [apiKey] - API key for authentication (optional if provided in config)
  /// [organizationId] - Organization ID (optional if provided in config)
  /// [assistantId] - Assistant ID to fetch
  /// Returns an AssistantModel object
  Future<AssistantModel> getAssistant({
    String? baseUrl,
    String? apiKey,
    String? organizationId,
    required String assistantId,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);
    final orgId = _getOrganizationId(organizationId);

    // FAIL-FAST: Validate required parameters
    if (key == null) {
      throw ArgumentError(
        'apiKey required: Provide in constructor config or method parameter',
      );
    }
    if (orgId == null) {
      throw ArgumentError(
        'organizationId required: Provide in constructor config or method parameter',
      );
    }

    // SECURITY: Sanitize path and query parameters
    final sanitizedAssistantId = _sanitizePathParam(assistantId, 'assistantId');
    final sanitizedOrgId = _sanitizeQueryParam(orgId, 'organizationId');

    try {
      final uri = Uri.parse(
        '$url/api/assistants/$sanitizedAssistantId?organizationId=$sanitizedOrgId',
      );

      developer.log('🔍 Fetching assistant from: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'X-Api-Key': key,
          'Content-Type': 'application/json',
        },
      ).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Get assistant timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final assistant = AssistantModel.fromJson(data);

        developer.log('✅ Loaded assistant: ${assistant.name}');
        return assistant;
      } else if (response.statusCode == 404) {
        throw Exception('Assistant not found: $assistantId');
      } else {
        final errorMessage =
            'Failed to load assistant: ${response.statusCode} - ${response.body}';
        developer.log('❌ $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('❌ Error fetching assistant: $e');
      rethrow;
    }
  }

  /// Generate AI summaries for multiple calls in batch
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [request] - Request parameters for batch summary generation
  /// [apiKey] - Optional API key for authentication (x-api-key header)
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns a GenerateSummariesResponse with successful and failed summaries
  ///
  /// Either [apiKey] or [bearerToken] must be provided for authentication
  Future<GenerateSummariesResponse> generateSummaries({
    String? baseUrl,
    required GenerateSummariesRequest request,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate authentication
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    try {
      final uri = Uri.parse('$url/api/calls/generate-summaries');

      developer.log('🔍 Generating summaries: ${request.maxCalls} calls');
      developer.log('📋 Request: ${json.encode(request.toJson())}');

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }

      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.post(
        uri,
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Generate summaries timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final summariesResponse = GenerateSummariesResponse.fromJson(data);

        developer.log(
          '✅ Summaries generated: '
          '${summariesResponse.successCount}/${summariesResponse.totalProcessed} '
          '(\$${summariesResponse.totalCost.toStringAsFixed(6)})',
        );

        // Log failures if any
        if (summariesResponse.failureCount > 0) {
          developer.log(
            '⚠️ ${summariesResponse.failureCount} failed summaries',
          );
        }

        return summariesResponse;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final message = errorData['message'] as String? ?? 'Bad request';
        throw Exception('Bad request: $message');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or inactive credentials');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Forbidden: You are not authorized to access this organization',
        );
      } else {
        final errorMessage =
            'Failed to generate summaries: ${response.statusCode} - '
            '${response.body}';
        developer.log('❌ $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('❌ Error generating summaries: $e');
      rethrow;
    }
  }

  /// Fetch client-side tool definitions from backend
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [apiKey] - API key for authentication (optional if provided in config)
  /// [organizationId] - Organization ID to fetch tools for (optional if provided in config)
  /// [userId] - Optional user ID for user-specific tools
  ///
  /// Returns a list of ClientToolDefinition objects for client-side execution
  ///
  /// This method fetches InProcess tools with executionLocation='client'
  /// that should be implemented on the client side (Flutter app)
  Future<List<ClientToolDefinition>> fetchClientTools({
    String? baseUrl,
    String? apiKey,
    String? organizationId,
    String? userId,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);
    final orgId = _getOrganizationId(organizationId);

    // FAIL-FAST: Validate required parameters
    if (key == null) {
      throw ArgumentError(
        'apiKey required: Provide in constructor config or method parameter',
      );
    }
    if (orgId == null) {
      throw ArgumentError(
        'organizationId required: Provide in constructor config or method parameter',
      );
    }

    // SECURITY: Sanitize query parameters
    final sanitizedOrgId = _sanitizeQueryParam(orgId, 'organizationId');
    final sanitizedUserId = userId != null
        ? _sanitizeQueryParam(userId, 'userId')
        : null;

    try {
      // Build query parameters
      final queryParams = {
        'source': 'external',
        'organizationId': sanitizedOrgId,
        if (sanitizedUserId != null) 'userId': sanitizedUserId,
      };

      final uri =
          Uri.parse('$url/api/tools').replace(queryParameters: queryParams);

      developer.log('🔍 Fetching client tools from: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'X-Api-Key': key,
          'Content-Type': 'application/json',
        },
      ).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Fetch client tools timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        // Filter only InProcess tools with executionLocation='client'
        final clientTools = <ClientToolDefinition>[];

        for (final toolJson in data) {
          try {
            final toolData = toolJson as Map<String, dynamic>;

            // Check if it's an InProcess tool with client execution
            if (toolData['type'] == 'InProcess') {
              final customConfig =
                  toolData['customConfig'] as Map<String, dynamic>?;
              if (customConfig != null &&
                  customConfig['executionLocation'] == 'client') {
                clientTools.add(ClientToolDefinition.fromJson(toolData));
              }
            }
          } catch (e) {
            developer.log('⚠️ Skipping invalid tool definition: $e');
            // Continue processing other tools
          }
        }

        developer.log(
          '✅ Loaded ${clientTools.length} client-side tools '
          '(from ${data.length} total tools)',
        );

        return clientTools;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid API key');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Forbidden: You are not authorized to access this organization',
        );
      } else {
        final errorMessage =
            'Failed to fetch client tools: ${response.statusCode} - '
            '${response.body}';
        developer.log('❌ $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('❌ Error fetching client tools: $e');
      rethrow;
    }
  }

  /// Summarize any text using AI
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [request] - Request parameters for text summarization
  /// [apiKey] - Optional API key for authentication (x-api-key header)
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns a SummarizeTextResponse with the generated summary and metrics
  ///
  /// Either [apiKey] or [bearerToken] must be provided for authentication
  Future<SummarizeTextResponse> summarizeText({
    String? baseUrl,
    required SummarizeTextRequest request,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate authentication
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    try {
      final uri = Uri.parse('$url/api/AI/summarize-text');

      developer.log('🔍 Summarizing text: ${request.text.length} chars');
      developer.log('📋 Request: ${json.encode(request.toJson())}');

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }

      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client
          .post(
        uri,
        headers: headers,
        body: json.encode(request.toJson()),
      )
          .timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Summary generation timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final summaryResponse = SummarizeTextResponse.fromJson(data);

        developer.log(
          '✅ Summary generated: '
          '${summaryResponse.totalTokens} tokens, '
          '\$${summaryResponse.cost.toStringAsFixed(6)}, '
          '${summaryResponse.processingTimeMs}ms',
        );

        return summaryResponse;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final message = errorData['message'] as String? ?? 'Bad request';
        throw Exception('Bad request: $message');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or inactive credentials');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded: Too many requests');
      } else {
        final errorMessage =
            'Failed to summarize text: ${response.statusCode} - '
            '${response.body}';
        developer.log('❌ $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('❌ Error summarizing text: $e');
      rethrow;
    }
  }

  /// Estimate the cost of summarizing text before making the actual request
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [request] - Request parameters for text summarization
  /// [apiKey] - Optional API key for authentication (x-api-key header)
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns estimated cost information as a Map
  ///
  /// Either [apiKey] or [bearerToken] must be provided for authentication
  Future<Map<String, dynamic>> estimateSummarizationCost({
    String? baseUrl,
    required SummarizeTextRequest request,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate authentication
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    try {
      final uri = Uri.parse('$url/api/AI/summarize-text/estimate-cost');

      developer.log('💰 Estimating summarization cost');

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }

      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.post(
        uri,
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Estimate cost timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        developer.log(
          '✅ Estimated cost: \$${data['estimatedCost'] ?? 'unknown'}',
        );

        return data;
      } else {
        final errorMessage =
            'Failed to estimate cost: ${response.statusCode} - ${response.body}';
        developer.log('❌ $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('❌ Error estimating cost: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // STT (Speech-to-Text) API Methods
  // ==========================================================================

  /// Transcribe audio file to text with optional advanced features
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [request] - Transcription request configuration
  /// [apiKey] - Optional API key for authentication (x-api-key header)
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns a STTResponse with transcribed text and metadata
  ///
  /// SECURITY: Validates file before upload, enforces size limits
  /// FAIL-FAST: Throws ArgumentError for invalid inputs
  ///
  /// Either [apiKey] or [bearerToken] must be provided for authentication
  Future<STTResponse> transcribeAudio({
    String? baseUrl,
    required STTTranscribeRequest request,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate authentication
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    try {
      // FAIL-FAST: Validate request before network call
      await request.validate();

      final uri = Uri.parse('$url/api/ai-services/stt/transcribe');

      developer.log(
        '🎤 Transcribing audio',
        name: 'VoiviApiService.transcribeAudio',
        error: {
          'file': request.audioFile.path.split('/').last,
          'language': request.language,
          'diarization': request.enableDiarization,
          'customerDetection': request.enableCustomerDetection,
        },
      );

      // Create multipart request
      final multipartRequest = http.MultipartRequest('POST', uri);

      // Add authentication header
      if (key != null) {
        multipartRequest.headers['X-Api-Key'] = key;
      }
      if (bearerToken != null) {
        multipartRequest.headers['Authorization'] = 'Bearer $bearerToken';
      }

      // Add audio file
      multipartRequest.files.add(
        await http.MultipartFile.fromPath(
          'audioFile',
          request.audioFile.path,
        ),
      );

      // Add form fields
      multipartRequest.fields['language'] = request.language;
      multipartRequest.fields['modelId'] = request.modelId;
      multipartRequest.fields['enableDiarization'] =
          request.enableDiarization.toString();
      multipartRequest.fields['enableCustomerDetection'] =
          request.enableCustomerDetection.toString();
      multipartRequest.fields['includeWordTimings'] =
          request.includeWordTimings.toString();

      if (request.minSpeakers != null) {
        multipartRequest.fields['minSpeakers'] =
            request.minSpeakers.toString();
      }
      if (request.maxSpeakers != null) {
        multipartRequest.fields['maxSpeakers'] =
            request.maxSpeakers.toString();
      }

      // Send request with timeout
      final streamedResponse = await multipartRequest
          .send()
          .timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Transcription request timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);

      developer.log(
        '📡 Response status: ${response.statusCode}',
        name: 'VoiviApiService.transcribeAudio',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final sttResponse = STTResponse.fromJson(data);

        developer.log(
          '✅ Transcription completed',
          name: 'VoiviApiService.transcribeAudio',
          error: {
            'duration': '${sttResponse.duration.toStringAsFixed(2)}s',
            'cost': '\$${sttResponse.audioProcessingCost.toStringAsFixed(6)}',
            'speakers': sttResponse.speakerCount,
            'textLength': sttResponse.text.length,
          },
        );

        return sttResponse;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final message = errorData['message'] as String? ?? 'Bad request';
        throw ArgumentError('Bad request: $message');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or inactive credentials');
      } else if (response.statusCode == 413) {
        throw ArgumentError('File too large: Exceeds server limits');
      } else if (response.statusCode == 415) {
        throw ArgumentError('Unsupported media type: Invalid audio format');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded: Too many requests');
      } else if (response.statusCode == 502) {
        throw Exception('External service error: Speech service unavailable');
      } else {
        final errorMessage =
            'Failed to transcribe audio: ${response.statusCode} - '
            '${response.body}';
        developer.log(
          '❌ $errorMessage',
          name: 'VoiviApiService.transcribeAudio',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        '❌ Error transcribing audio',
        name: 'VoiviApiService.transcribeAudio',
        error: e,
      );
      rethrow;
    }
  }

  /// Get list of available STT models
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [apiKey] - Optional API key for authentication
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns a list of model IDs
  Future<List<String>> getAvailableSTTModels({
    String? baseUrl,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate authentication
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    try {
      final uri = Uri.parse('$url/api/ai-services/stt/models');

      developer.log(
        '🔍 Fetching STT models',
        name: 'VoiviApiService.getAvailableSTTModels',
      );

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }
      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.get(uri, headers: headers).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Get STT models timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log(
        '📡 Response status: ${response.statusCode}',
        name: 'VoiviApiService.getAvailableSTTModels',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final models = data.map((m) => m.toString()).toList();

        developer.log(
          '✅ Loaded ${models.length} STT models',
          name: 'VoiviApiService.getAvailableSTTModels',
        );

        return models;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid credentials');
      } else {
        final errorMessage =
            'Failed to fetch STT models: ${response.statusCode} - ${response.body}';
        developer.log(
          '❌ $errorMessage',
          name: 'VoiviApiService.getAvailableSTTModels',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching STT models',
        name: 'VoiviApiService.getAvailableSTTModels',
        error: e,
      );
      rethrow;
    }
  }

  /// Get information about a specific STT model
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [modelId] - Model ID to fetch information for
  /// [apiKey] - Optional API key for authentication
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns STTModelInfo with model details
  Future<STTModelInfo> getSTTModelInfo({
    String? baseUrl,
    required String modelId,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate inputs
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    if (modelId.isEmpty) {
      throw ArgumentError('Model ID cannot be empty');
    }

    // SECURITY: Sanitize path parameter
    final sanitizedModelId = _sanitizePathParam(modelId, 'modelId');

    try {
      final uri = Uri.parse('$url/api/ai-services/stt/models/$sanitizedModelId');

      developer.log(
        '🔍 Fetching STT model info: $modelId',
        name: 'VoiviApiService.getSTTModelInfo',
      );

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }
      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.get(uri, headers: headers).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Get STT model info timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log(
        '📡 Response status: ${response.statusCode}',
        name: 'VoiviApiService.getSTTModelInfo',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final modelInfo = STTModelInfo.fromJson(data);

        developer.log(
          '✅ Loaded model info: ${modelInfo.name}',
          name: 'VoiviApiService.getSTTModelInfo',
        );

        return modelInfo;
      } else if (response.statusCode == 404) {
        throw Exception('Model not found: $modelId');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid credentials');
      } else {
        final errorMessage =
            'Failed to fetch model info: ${response.statusCode} - ${response.body}';
        developer.log(
          '❌ $errorMessage',
          name: 'VoiviApiService.getSTTModelInfo',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching model info',
        name: 'VoiviApiService.getSTTModelInfo',
        error: e,
      );
      rethrow;
    }
  }

  /// Get supported languages for a specific STT model
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [modelId] - Model ID to fetch supported languages for
  /// [apiKey] - Optional API key for authentication
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns list of language codes (e.g., ["tr-TR", "en-US"])
  Future<List<String>> getSupportedLanguages({
    String? baseUrl,
    required String modelId,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate inputs
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    if (modelId.isEmpty) {
      throw ArgumentError('Model ID cannot be empty');
    }

    // SECURITY: Sanitize path parameter
    final sanitizedModelId = _sanitizePathParam(modelId, 'modelId');

    try {
      final uri =
          Uri.parse('$url/api/ai-services/stt/models/$sanitizedModelId/languages');

      developer.log(
        '🔍 Fetching supported languages for: $modelId',
        name: 'VoiviApiService.getSupportedLanguages',
      );

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }
      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.get(uri, headers: headers).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Get supported languages timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log(
        '📡 Response status: ${response.statusCode}',
        name: 'VoiviApiService.getSupportedLanguages',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final languages = data.map((l) => l.toString()).toList();

        developer.log(
          '✅ Loaded ${languages.length} supported languages',
          name: 'VoiviApiService.getSupportedLanguages',
        );

        return languages;
      } else if (response.statusCode == 404) {
        throw Exception('Model not found: $modelId');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid credentials');
      } else {
        final errorMessage =
            'Failed to fetch supported languages: ${response.statusCode} - ${response.body}';
        developer.log(
          '❌ $errorMessage',
          name: 'VoiviApiService.getSupportedLanguages',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching supported languages',
        name: 'VoiviApiService.getSupportedLanguages',
        error: e,
      );
      rethrow;
    }
  }

  /// Get supported audio formats for a specific STT model
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [modelId] - Model ID to fetch supported formats for
  /// [apiKey] - Optional API key for authentication
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns list of audio format extensions (e.g., ["wav", "mp3", "m4a"])
  Future<List<String>> getSupportedFormats({
    String? baseUrl,
    required String modelId,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate inputs
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    if (modelId.isEmpty) {
      throw ArgumentError('Model ID cannot be empty');
    }

    // SECURITY: Sanitize path parameter
    final sanitizedModelId = _sanitizePathParam(modelId, 'modelId');

    try {
      final uri =
          Uri.parse('$url/api/ai-services/stt/models/$sanitizedModelId/formats');

      developer.log(
        '🔍 Fetching supported formats for: $modelId',
        name: 'VoiviApiService.getSupportedFormats',
      );

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }
      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.get(uri, headers: headers).timeout(
        _apiTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Get supported formats timed out after ${_apiTimeout.inSeconds}s',
            _apiTimeout,
          );
        },
      );

      developer.log(
        '📡 Response status: ${response.statusCode}',
        name: 'VoiviApiService.getSupportedFormats',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final formats = data.map((f) => f.toString()).toList();

        developer.log(
          '✅ Loaded ${formats.length} supported formats',
          name: 'VoiviApiService.getSupportedFormats',
        );

        return formats;
      } else if (response.statusCode == 404) {
        throw Exception('Model not found: $modelId');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid credentials');
      } else {
        final errorMessage =
            'Failed to fetch supported formats: ${response.statusCode} - ${response.body}';
        developer.log(
          '❌ $errorMessage',
          name: 'VoiviApiService.getSupportedFormats',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        '❌ Error fetching supported formats',
        name: 'VoiviApiService.getSupportedFormats',
        error: e,
      );
      rethrow;
    }
  }

  /// Check STT service health
  ///
  /// [baseUrl] - Base URL of the Voivi AI API (optional if provided in config)
  /// [apiKey] - Optional API key for authentication
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns true if service is healthy, false otherwise
  Future<bool> sttHealthCheck({
    String? baseUrl,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Smart defaults
    final url = _getBaseUrl(baseUrl);
    final key = _getApiKey(apiKey);

    // FAIL-FAST: Validate authentication
    if (key == null && bearerToken == null) {
      throw ArgumentError(
        'Authentication required: Provide apiKey/bearerToken in config or parameters',
      );
    }

    try {
      final uri = Uri.parse('$url/api/ai-services/stt/health');

      developer.log(
        '🏥 Checking STT service health',
        name: 'VoiviApiService.sttHealthCheck',
      );

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (key != null) {
        headers['X-Api-Key'] = key;
      }
      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.get(uri, headers: headers).timeout(
        const Duration(seconds: 10), // Shorter timeout for health check
        onTimeout: () {
          developer.log(
            '⚠️ STT health check timed out',
            name: 'VoiviApiService.sttHealthCheck',
          );
          return http.Response('{"status": "timeout"}', 503);
        },
      );

      developer.log(
        '📡 Response status: ${response.statusCode}',
        name: 'VoiviApiService.sttHealthCheck',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        final isHealthy = status == 'healthy';

        developer.log(
          isHealthy ? '✅ STT service is healthy' : '⚠️ STT service is unhealthy',
          name: 'VoiviApiService.sttHealthCheck',
        );

        return isHealthy;
      } else {
        developer.log(
          '❌ STT service is unhealthy (status: ${response.statusCode})',
          name: 'VoiviApiService.sttHealthCheck',
        );
        return false;
      }
    } catch (e) {
      developer.log(
        '❌ Error checking STT health',
        name: 'VoiviApiService.sttHealthCheck',
        error: e,
      );
      return false; // FAIL-SAFE: Return false on error
    }
  }

  // ==========================================================================
  // Resource Management
  // ==========================================================================

  /// Dispose of the service and clean up resources
  ///
  /// This should be called when the service is no longer needed
  void dispose() {
    _client.close();
    developer.log('🗑️ VoiviApiService disposed');
  }

  /// Reset the singleton instance (useful for testing)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
    developer.log('🔄 VoiviApiService singleton reset');
  }
}
