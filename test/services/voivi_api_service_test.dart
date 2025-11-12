import 'package:test/test.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

import '../test_config.dart';

/// Real integration tests for VoiviApiService
///
/// These tests make real API calls using test_config.dart credentials
/// Update test/test_config.dart with your actual credentials before running
void main() {
  group('VoiviApiService Integration Tests', () {
    late VoiviApiService service;

    setUpAll(() {
      TestConfig.printConfig();

      if (!TestConfig.runIntegrationTests) {
        print(
          '⚠️  Integration tests disabled. Set TestConfig.runIntegrationTests = true',
        );
      }

      if (!TestConfig.isConfigured) {
        print('⚠️  Update test/test_config.dart with your credentials');
      }
    });

    setUp(() {
      VoiviApiService.resetInstance();
      service = VoiviApiService();
    });

    tearDown(() {
      service.dispose();
    });

    group('listAssistants', () {
      test('should return list of assistants with real API', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('📋 Fetching real assistants from API...');

        final assistants = await service.listAssistants(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        print('✅ Received ${assistants.length} assistants');

        // Assertions
        expect(assistants, isA<List<AssistantModel>>());
        expect(
          assistants,
          isNotEmpty,
          reason: 'Should have at least one assistant',
        );

        // Verify structure of first assistant
        final first = assistants.first;
        expect(first.id, isNotEmpty);
        expect(first.name, isNotEmpty);

        print('📝 Sample assistant: ${first.name} (${first.id})');

        // Verify all assistants have required fields
        for (final assistant in assistants) {
          expect(assistant.id, isNotEmpty);
          expect(assistant.name, isNotEmpty);
        }
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should handle invalid credentials gracefully', () async {
        if (!TestConfig.runIntegrationTests) {
          print('⏭️  Skipping - integration tests disabled');
          return;
        }

        print('🔍 Testing with invalid API key...');

        expect(
          () => service.listAssistants(
            baseUrl: TestConfig.baseUrl,
            apiKey: 'invalid_key_12345',
            organizationId: TestConfig.organizationId,
          ),
          throwsException,
        );

        print('✅ Correctly threw exception for invalid credentials');
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should handle invalid base URL', () async {
        if (!TestConfig.runIntegrationTests) {
          print('⏭️  Skipping - integration tests disabled');
          return;
        }

        print('🔍 Testing with invalid base URL...');

        expect(
          () => service.listAssistants(
            baseUrl: 'http://nonexistent.invalid.url.test',
            apiKey: TestConfig.apiKey,
            organizationId: TestConfig.organizationId,
          ),
          throwsException,
        );

        print('✅ Correctly threw exception for invalid URL');
      }, timeout: const Timeout(TestConfig.connectionTimeout));
    });

    group('getAssistant', () {
      test('should get specific assistant with real API', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('📋 First fetching assistant list...');

        // Get list first
        final assistants = await service.listAssistants(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        expect(assistants, isNotEmpty);

        final assistantId = TestConfig.assistantId;
        print('🔍 Fetching assistant: $assistantId');

        // Get specific assistant
        final assistant = await service.getAssistant(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
          assistantId: assistantId,
        );

        print('✅ Retrieved: ${assistant.name}');

        // Assertions
        expect(assistant, isA<AssistantModel>());
        expect(assistant.id, equals(assistantId));
        expect(assistant.name, isNotEmpty);

        // Log details
        print('📝 Details:');
        print('   ID: ${assistant.id}');
        print('   Name: ${assistant.name}');
        if (assistant.description != null) {
          print('   Description: ${assistant.description}');
        }
        if (assistant.firstMessage != null) {
          print('   First Message: ${assistant.firstMessage}');
        }
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should handle non-existent assistant ID', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Attempting to fetch non-existent assistant...');

        expect(
          () => service.getAssistant(
            baseUrl: TestConfig.baseUrl,
            apiKey: TestConfig.apiKey,
            organizationId: TestConfig.organizationId,
            assistantId: 'nonexistent-assistant-id-99999',
          ),
          throwsException,
        );

        print('✅ Correctly threw exception for invalid ID');
      }, timeout: const Timeout(TestConfig.connectionTimeout));
    });

    group('data integrity', () {
      test('should properly parse all assistant fields', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Testing data integrity...');

        final assistants = await service.listAssistants(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        expect(assistants, isNotEmpty);

        for (final assistant in assistants) {
          // Required fields
          expect(assistant.id, isNotEmpty);
          expect(assistant.name, isNotEmpty);

          // Optional fields should be nullable or have values
          if (assistant.createdAt != null) {
            expect(assistant.createdAt, isA<DateTime>());
          }
          if (assistant.updatedAt != null) {
            expect(assistant.updatedAt, isA<DateTime>());
          }
          if (assistant.metadata != null) {
            expect(assistant.metadata, isA<Map<String, dynamic>>());
          }

          // Test toJson/fromJson roundtrip
          final json = assistant.toJson();
          final parsed = AssistantModel.fromJson(json);
          expect(parsed.id, equals(assistant.id));
          expect(parsed.name, equals(assistant.name));
        }

        print('✅ Data integrity verified for ${assistants.length} assistants');
      }, timeout: const Timeout(TestConfig.connectionTimeout));
    });

    group('singleton pattern', () {
      test('should return same instance', () {
        final instance1 = VoiviApiService();
        final instance2 = VoiviApiService();

        expect(identical(instance1, instance2), isTrue);
        print('✅ Singleton pattern working correctly');
      });

      test('should reset instance', () {
        final instance1 = VoiviApiService();
        VoiviApiService.resetInstance();
        final instance2 = VoiviApiService();

        expect(identical(instance1, instance2), isFalse);
        print('✅ Instance reset working correctly');
      });
    });

    group('fetchClientTools', () {
      test('should fetch client-side tools from backend', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Fetching client-side tools from API...');

        final tools = await service.fetchClientTools(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        print('✅ Received ${tools.length} client-side tools');

        // Assertions
        expect(tools, isA<List<ClientToolDefinition>>());

        // Log tool details
        for (final tool in tools) {
          expect(tool.id, isNotEmpty);
          expect(tool.name, isNotEmpty);
          expect(tool.executionLocation, equals('client'));

          print('📝 Tool: ${tool.name} (${tool.category})');
          print('   ID: ${tool.id}');
          print('   Description: ${tool.description}');
          print('   Parameters: ${tool.parameters.length}');
          if (tool.requiredPermissions != null) {
            print('   Permissions: ${tool.requiredPermissions}');
          }
        }
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should filter only client-side InProcess tools', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Verifying tool filtering...');

        final tools = await service.fetchClientTools(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        // All returned tools should be client-side
        for (final tool in tools) {
          expect(
            tool.executionLocation,
            equals('client'),
            reason: 'Tool ${tool.name} should have executionLocation=client',
          );
        }

        print('✅ All ${tools.length} tools are client-side');
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should include tool parameters if defined', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Checking tool parameters...');

        final tools = await service.fetchClientTools(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        // Find tools with parameters
        final toolsWithParams = tools.where((t) => t.parameters.isNotEmpty);

        if (toolsWithParams.isNotEmpty) {
          print('✅ Found ${toolsWithParams.length} tools with parameters');

          for (final tool in toolsWithParams) {
            print('📝 ${tool.name}: ${tool.parameters.length} parameters');

            for (final param in tool.parameters) {
              expect(param.name, isNotEmpty);
              expect(param.type, isNotEmpty);
              expect(param.description, isNotEmpty);

              print(
                '   - ${param.name} (${param.type})'
                '${param.required ? ' [required]' : ''}',
              );
            }
          }
        } else {
          print('⚠️  No tools with parameters found');
        }
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should handle invalid credentials gracefully', () async {
        if (!TestConfig.runIntegrationTests) {
          print('⏭️  Skipping - integration tests disabled');
          return;
        }

        print('🔍 Testing with invalid API key...');

        expect(
          () => service.fetchClientTools(
            baseUrl: TestConfig.baseUrl,
            apiKey: 'invalid_key_12345',
            organizationId: TestConfig.organizationId,
          ),
          throwsException,
        );

        print('✅ Correctly threw exception for invalid credentials');
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should handle optional userId parameter', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Fetching tools with userId...');

        final tools = await service.fetchClientTools(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
          userId: 'test-user-123',
        );

        expect(tools, isA<List<ClientToolDefinition>>());

        print('✅ Successfully fetched ${tools.length} tools with userId');
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should parse tool definitions correctly', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Testing tool definition parsing...');

        final tools = await service.fetchClientTools(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        for (final tool in tools) {
          // Required fields
          expect(tool.id, isNotEmpty);
          expect(tool.name, isNotEmpty);
          expect(tool.description, isNotNull);
          expect(tool.category, isNotEmpty);
          expect(tool.executionLocation, equals('client'));

          // Timeout should be positive
          expect(tool.timeoutSeconds, greaterThan(0));

          // Parameters should be valid
          for (final param in tool.parameters) {
            expect(param.name, isNotEmpty);
            expect(param.type, isNotEmpty);
            expect(param.description, isNotEmpty);
            expect(param.required, isA<bool>());
          }
        }

        print('✅ All tool definitions parsed correctly');
      }, timeout: const Timeout(TestConfig.connectionTimeout));

      test('should handle empty tool list', () async {
        if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
          print('⏭️  Skipping - not configured');
          return;
        }

        print('🔍 Testing empty tool list handling...');

        // Even if there are no client-side tools, it should return empty list
        final tools = await service.fetchClientTools(
          baseUrl: TestConfig.baseUrl,
          apiKey: TestConfig.apiKey,
          organizationId: TestConfig.organizationId,
        );

        expect(tools, isA<List<ClientToolDefinition>>());
        expect(tools, isNotNull);

        print('✅ Tool list handling works (${tools.length} tools)');
      }, timeout: const Timeout(TestConfig.connectionTimeout));
    });
  });
}
