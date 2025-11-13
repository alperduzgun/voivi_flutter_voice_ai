import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:voivi_voice_ai/src/core/voivi_config.dart';
import 'package:voivi_voice_ai/src/models/summary_models.dart';
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
  factory VoiviApiService() {
    _instance ??= VoiviApiService._internal();
    return _instance!;
  }

  VoiviApiService._internal();
  // Singleton pattern (consistent with WebSocketService)
  static VoiviApiService? _instance;

  // HTTP client instance
  final http.Client _client = http.Client();

  // Timeout configuration for API requests
  static const Duration _apiTimeout = Duration(seconds: 30);

  /// List all assistants for an organization
  ///
  /// [baseUrl] - Base URL of the Voivi AI API
  /// [apiKey] - API key for authentication
  /// [organizationId] - Organization ID
  /// Returns a list of AssistantModel objects
  Future<List<AssistantModel>> listAssistants({
    required String baseUrl,
    required String apiKey,
    required String organizationId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/assistants?organizationId=$organizationId',
      );

      developer.log('🔍 Fetching assistants from: $url');

      final response = await _client.get(
        url,
        headers: {
          'X-Api-Key': apiKey,
          'Content-Type': 'application/json',
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
  /// [baseUrl] - Base URL of the Voivi AI API
  /// [apiKey] - API key for authentication
  /// [organizationId] - Organization ID
  /// [assistantId] - Assistant ID to fetch
  /// Returns an AssistantModel object
  Future<AssistantModel> getAssistant({
    required String baseUrl,
    required String apiKey,
    required String organizationId,
    required String assistantId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/assistants/$assistantId?organizationId=$organizationId',
      );

      developer.log('🔍 Fetching assistant from: $url');

      final response = await _client.get(
        url,
        headers: {
          'X-Api-Key': apiKey,
          'Content-Type': 'application/json',
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
  /// [baseUrl] - Base URL of the Voivi AI API
  /// [request] - Request parameters for batch summary generation
  /// [apiKey] - Optional API key for authentication (x-api-key header)
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns a GenerateSummariesResponse with successful and failed summaries
  ///
  /// Either [apiKey] or [bearerToken] must be provided for authentication
  Future<GenerateSummariesResponse> generateSummaries({
    required String baseUrl,
    required GenerateSummariesRequest request,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Validate authentication
    if (apiKey == null && bearerToken == null) {
      throw ArgumentError(
        'Either apiKey or bearerToken must be provided for authentication',
      );
    }

    try {
      final url = Uri.parse('$baseUrl/api/calls/generate-summaries');

      developer.log('🔍 Generating summaries: ${request.maxCalls} calls');
      developer.log('📋 Request: ${json.encode(request.toJson())}');

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (apiKey != null) {
        headers['X-Api-Key'] = apiKey;
      }

      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(request.toJson()),
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
  /// [baseUrl] - Base URL of the Voivi AI API
  /// [apiKey] - API key for authentication
  /// [organizationId] - Organization ID to fetch tools for
  /// [userId] - Optional user ID for user-specific tools
  ///
  /// Returns a list of ClientToolDefinition objects for client-side execution
  ///
  /// This method fetches InProcess tools with executionLocation='client'
  /// that should be implemented on the client side (Flutter app)
  Future<List<ClientToolDefinition>> fetchClientTools({
    required String baseUrl,
    required String apiKey,
    required String organizationId,
    String? userId,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'source': 'external',
        'organizationId': organizationId,
        if (userId != null) 'userId': userId,
      };

      final uri =
          Uri.parse('$baseUrl/api/tools').replace(queryParameters: queryParams);

      developer.log('🔍 Fetching client tools from: $uri');

      final response = await _client.get(
        uri,
        headers: {
          'X-Api-Key': apiKey,
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
  /// [baseUrl] - Base URL of the Voivi AI API
  /// [request] - Request parameters for text summarization
  /// [apiKey] - Optional API key for authentication (x-api-key header)
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns a SummarizeTextResponse with the generated summary and metrics
  ///
  /// Either [apiKey] or [bearerToken] must be provided for authentication
  Future<SummarizeTextResponse> summarizeText({
    required String baseUrl,
    required SummarizeTextRequest request,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Validate authentication
    if (apiKey == null && bearerToken == null) {
      throw ArgumentError(
        'Either apiKey or bearerToken must be provided for authentication',
      );
    }

    try {
      final url = Uri.parse('$baseUrl/api/AI/summarize-text');

      developer.log('🔍 Summarizing text: ${request.text.length} chars');
      developer.log('📋 Request: ${json.encode(request.toJson())}');

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (apiKey != null) {
        headers['X-Api-Key'] = apiKey;
      }

      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client
          .post(
        url,
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
  /// [baseUrl] - Base URL of the Voivi AI API
  /// [request] - Request parameters for text summarization
  /// [apiKey] - Optional API key for authentication (x-api-key header)
  /// [bearerToken] - Optional JWT Bearer token for authentication
  ///
  /// Returns estimated cost information as a Map
  ///
  /// Either [apiKey] or [bearerToken] must be provided for authentication
  Future<Map<String, dynamic>> estimateSummarizationCost({
    required String baseUrl,
    required SummarizeTextRequest request,
    String? apiKey,
    String? bearerToken,
  }) async {
    // Validate authentication
    if (apiKey == null && bearerToken == null) {
      throw ArgumentError(
        'Either apiKey or bearerToken must be provided for authentication',
      );
    }

    try {
      final url = Uri.parse('$baseUrl/api/AI/summarize-text/estimate-cost');

      developer.log('💰 Estimating summarization cost');

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (apiKey != null) {
        headers['X-Api-Key'] = apiKey;
      }

      if (bearerToken != null) {
        headers['Authorization'] = 'Bearer $bearerToken';
      }

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(request.toJson()),
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
