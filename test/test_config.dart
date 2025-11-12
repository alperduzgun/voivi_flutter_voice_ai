/// Test configuration for integration tests
///
/// IMPORTANT: Update these values with your actual credentials before running tests
/// These values are used for integration testing with a real Voivi API instance
class TestConfig {
  // API Configuration
  static const String baseUrl = 'http://localhost:5065';
  static const String apiKey = 'aac01db82611481cb27e6059b1c8f8aa';
  static const String organizationId = '68331233c2295b8ea205994f';

  // Optional: Specific assistant ID for direct testing
  // Leave null to fetch assistants dynamically
  static const String assistantId = '55170caa-a61f-4c85-81e8-9e03f7fc907f';

  // Test user configuration
  static const String testUserId = 'test-user-123';

  // Test timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration messageTimeout = Duration(seconds: 10);

  /// Whether to run integration tests
  /// Set to false to skip tests that require a real API connection
  static const bool runIntegrationTests = true;

  /// Whether to print detailed logs during tests
  static const bool verboseLogs = true;

  // Validation
  static bool get isConfigured {
    return baseUrl.isNotEmpty &&
        apiKey != 'your-api-key' &&
        organizationId != 'org_xxx';
  }

  static void validateConfig() {
    if (!isConfigured) {
      throw Exception(
        'Test configuration is not set up. '
        'Please update test/test_config.dart with your actual API credentials.',
      );
    }
  }

  static void printConfig() {
    if (!verboseLogs) return;

    print('=== Test Configuration ===');
    print('Base URL: $baseUrl');
    print(
        'API Key: ${apiKey.length > 8 ? '${apiKey.substring(0, 8)}***' : '***'}');
    print('Organization ID: $organizationId');
    print('Assistant ID: $assistantId');
    print('Run Integration Tests: $runIntegrationTests');
    print('========================\n');
  }
}
