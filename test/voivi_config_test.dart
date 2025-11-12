import 'package:test/test.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

void main() {
  group('VoiviConfig', () {
    test('should create config with required parameters', () {
      final config = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      expect(config.apiKey, 'test-api-key');
      expect(config.organizationId, 'test-org');
      expect(config.assistantId, 'test-assistant');
      expect(config.baseUrl, 'wss://test.com');
    });

    test('should use default values for optional parameters', () {
      final config = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      expect(config.llmModel, 'gpt-4o');
      expect(config.enableTTS, false);
      expect(config.enableSentimentAnalysis, true);
      expect(config.defaultUserId, 'client-user');
      expect(config.connectionTimeoutMs, 30000);
      expect(config.reconnectAttempts, 3);
    });

    test('should return effective user ID', () {
      final configWithUserId = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
        userId: 'custom-user',
      );

      final configWithoutUserId = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      expect(configWithUserId.effectiveUserId, 'custom-user');
      expect(configWithoutUserId.effectiveUserId, 'client-user');
    });

    test('should generate WebSocket parameters correctly', () {
      final config = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
        userId: 'test-user',
        llmModel: 'gpt-4',
        enableTTS: true,
        enableSentimentAnalysis: false,
      );

      final params = config.toWebSocketParams();

      expect(params['assistantId'], 'test-assistant');
      expect(params['organizationId'], 'test-org');
      expect(params['userId'], 'test-user');
      expect(params['llmModel'], 'gpt-4');
      expect(params['enableTTS'], 'true');
      expect(params['enableSentimentAnalysis'], 'false');
    });

    test('should create copy with updated parameters', () {
      final original = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      final updated = original.copyWith(
        userId: 'new-user',
        llmModel: 'gpt-3.5-turbo',
        enableSentimentAnalysis: false,
      );

      expect(updated.apiKey, 'test-api-key'); // unchanged
      expect(updated.userId, 'new-user'); // changed
      expect(updated.llmModel, 'gpt-3.5-turbo'); // changed
      expect(updated.enableSentimentAnalysis, false); // changed
      expect(updated.enableTTS, false); // unchanged default
    });

    test('should serialize to and from JSON correctly', () {
      final original = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
        userId: 'test-user',
        llmModel: 'gpt-4',
        enableSentimentAnalysis: false,
      );

      final json = original.toJson();
      final restored = VoiviConfig.fromJson(json);

      expect(restored.apiKey, original.apiKey);
      expect(restored.organizationId, original.organizationId);
      expect(restored.assistantId, original.assistantId);
      expect(restored.baseUrl, original.baseUrl);
      expect(restored.userId, original.userId);
      expect(restored.llmModel, original.llmModel);
      expect(restored.enableSentimentAnalysis, original.enableSentimentAnalysis);
    });

    test('should handle equality correctly', () {
      final config1 = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      final config2 = VoiviConfig(
        apiKey: 'test-api-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      final config3 = VoiviConfig(
        apiKey: 'different-key',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should mask API key in toString', () {
      final config = VoiviConfig(
        apiKey: 'very-long-api-key-that-should-be-masked',
        organizationId: 'test-org',
        assistantId: 'test-assistant',
        baseUrl: 'wss://test.com',
      );

      final stringRepresentation = config.toString();

      expect(stringRepresentation, contains('very-lon***'));
      expect(stringRepresentation, isNot(contains('very-long-api-key-that-should-be-masked')));
      expect(stringRepresentation, contains('test-org'));
      expect(stringRepresentation, contains('test-assistant'));
    });
  });
}
