/// Configuration service for Voivi Chat Example
///
/// ⚠️ IMPORTANT: Replace these values with your own credentials from the Voivi Dashboard
///
/// Get your credentials:
/// 1. Go to https://your-voivi-dashboard.com (or your hosted instance)
/// 2. Navigate to Settings > API Keys
/// 3. Create a new API key or use an existing one
/// 4. Copy your Organization ID and API Key
/// 5. Replace the values below
///
/// For the Assistant ID:
/// 1. Go to Assistants page in the dashboard
/// 2. Select or create an assistant
/// 3. Copy the Assistant ID
class ConfigService {
  // ⚠️ REPLACE THESE WITH YOUR ACTUAL CREDENTIALS
  static const String organizationId = 'YOUR_ORGANIZATION_ID_HERE';
  static const String apiKey = 'YOUR_API_KEY_HERE';

  // Environment URLs
  static const String developmentBaseUrl = 'http://localhost:5065';
  static const String productionBaseUrl = 'https://voivi-engineering.azurewebsites.net';

  static const String developmentWebSocketUrl = 'ws://localhost:5065';
  static const String productionWebSocketUrl = 'wss://voivi-engineering.azurewebsites.net';

  // Current environment (change this to switch environments)
  static bool isProduction = false;

  static String get baseUrl => isProduction ? productionBaseUrl : developmentBaseUrl;

  static String get webSocketUrl => isProduction ? productionWebSocketUrl : developmentWebSocketUrl;

  /// Toggle between development and production
  static void toggleEnvironment() {
    isProduction = !isProduction;
  }

  /// Check if configuration is valid (credentials are not placeholders)
  static bool get isConfigured {
    return !organizationId.contains('YOUR_') &&
           !apiKey.contains('YOUR_') &&
           organizationId.isNotEmpty &&
           apiKey.isNotEmpty;
  }

  /// Get configuration summary for debugging
  static String get configSummary => '''
Configuration Status: ${isConfigured ? '✅ Configured' : '❌ Not Configured'}
Environment: ${isProduction ? 'Production' : 'Development'}
Base URL: $baseUrl
Organization ID: ${organizationId.contains('YOUR_') ? '❌ Not Set' : '✅ ${organizationId.substring(0, 8)}...'}
API Key: ${apiKey.contains('YOUR_') ? '❌ Not Set' : '✅ ${apiKey.substring(0, 8)}...'}

${!isConfigured ? '\n⚠️ Please update ConfigService with your actual credentials!' : ''}
''';
}
