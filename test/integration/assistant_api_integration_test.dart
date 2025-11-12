import 'package:test/test.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

import '../test_config.dart';

/// Integration tests for VoiviApiService
///
/// These tests require a running Voivi API instance with valid credentials
/// Update test/test_config.dart with your credentials before running
void main() {
  group('VoiviApiService Integration Tests', () {
    late VoiviApiService apiService;

    setUpAll(() {
      // Print configuration for debugging
      TestConfig.printConfig();

      // Skip if not configured
      if (!TestConfig.runIntegrationTests) {}

      if (!TestConfig.isConfigured) {}
    });

    setUp(() {
      VoiviApiService.resetInstance();
      apiService = VoiviApiService();
    });

    tearDown(() {
      apiService.dispose();
    });

    test('should list assistants successfully', () async {
      // Skip if configuration is not set or integration tests disabled
      if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
        return;
      }

      final assistants = await apiService.listAssistants(
        baseUrl: TestConfig.baseUrl,
        apiKey: TestConfig.apiKey,
        organizationId: TestConfig.organizationId,
      );

      // Assertions
      expect(assistants, isNotEmpty,
          reason: 'Should have at least one assistant');
      expect(assistants, isA<List<AssistantModel>>());

      // Check first assistant structure
      final firstAssistant = assistants.first;
      expect(firstAssistant.id, isNotEmpty);
      expect(firstAssistant.name, isNotEmpty);

      // Print all assistants
      for (var i = 0; i < assistants.length; i++) {
        final assistant = assistants[i];
        if (assistant.description != null) {}
      }
    }, timeout: const Timeout(TestConfig.connectionTimeout));

    test('should get specific assistant successfully', () async {
      // Skip if configuration is not set or integration tests disabled
      if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
        return;
      }

      // First, get list of assistants
      final assistants = await apiService.listAssistants(
        baseUrl: TestConfig.baseUrl,
        apiKey: TestConfig.apiKey,
        organizationId: TestConfig.organizationId,
      );

      expect(assistants, isNotEmpty,
          reason: 'Need at least one assistant for this test');

      final assistantId = TestConfig.assistantId;

      // Get specific assistant
      final assistant = await apiService.getAssistant(
        baseUrl: TestConfig.baseUrl,
        apiKey: TestConfig.apiKey,
        organizationId: TestConfig.organizationId,
        assistantId: assistantId,
      );

      // Assertions
      expect(assistant, isA<AssistantModel>());
      expect(assistant.id, equals(assistantId));
      expect(assistant.name, isNotEmpty);

      if (assistant.description != null) {}
      if (assistant.firstMessage != null) {}
      if (assistant.metadata != null) {}
    }, timeout: const Timeout(TestConfig.connectionTimeout));

    test('should fail gracefully with invalid assistant ID', () async {
      // Skip if configuration is not set or integration tests disabled
      if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
        return;
      }

      // Try to get non-existent assistant
      expect(
        () => apiService.getAssistant(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
          assistantId: 'non_existent_assistant_id_12345',
        ),
        throwsException,
      );
    }, timeout: const Timeout(TestConfig.connectionTimeout));

    test('should fail gracefully with invalid credentials', () async {
      // Skip if integration tests disabled (but don't require configuration)
      if (!TestConfig.runIntegrationTests) {
        return;
      }

      // Try with invalid API key
      expect(
        () => apiService.listAssistants(
          baseUrl: TestConfig.baseUrl,
          apiKey: 'invalid_api_key',
          organizationId: TestConfig.organizationId,
        ),
        throwsException,
      );
    }, timeout: const Timeout(TestConfig.connectionTimeout));
  });
}
