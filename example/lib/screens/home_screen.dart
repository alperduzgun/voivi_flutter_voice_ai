import 'package:flutter/material.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';
import '../services/config_service.dart';
import 'assistant_list_screen.dart';
import 'chat_screen.dart';
import 'tool_test_screen.dart';
import 'logs_screen.dart';
import 'stt_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  VoiviChatEngine? _engine;
  final VoiviApiService _apiService = VoiviApiService();
  String? _selectedAssistantId;

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    try {
      _engine = VoiviChatEngine();

      // Register example tools
      _engine!.bindToolHandlers({
        'get_random_number': _getRandomNumber,
        'calculate_sum': _calculateSum,
        'get_app_info': _getAppInfo,
      });

      debugPrint('✅ Example tools registered');
    } catch (e) {
      debugPrint('❌ Engine initialization failed: $e');
    }
  }

  // Example tool implementations
  Future<Map<String, dynamic>> _getRandomNumber(
      Map<String, dynamic> args) async {
    final min = (args['min'] as num?)?.toInt() ?? 1;
    final max = (args['max'] as num?)?.toInt() ?? 100;

    if (min > max) {
      return {
        'error': 'Invalid range: min must be <= max',
        'success': false,
      };
    }

    final randomNumber =
        min + DateTime.now().microsecond % (max - min + 1);

    return {
      'success': true,
      'randomNumber': randomNumber,
      'min': min,
      'max': max,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _calculateSum(
      Map<String, dynamic> args) async {
    final numbers = (args['numbers'] as List?)?.cast<num>() ?? [];

    if (numbers.isEmpty) {
      return {
        'error': 'No numbers provided to sum',
        'success': false,
      };
    }

    final sum = numbers.fold<num>(0, (prev, curr) => prev + curr);

    return {
      'success': true,
      'sum': sum,
      'count': numbers.length,
      'numbers': numbers,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _getAppInfo(
      Map<String, dynamic> args) async {
    return {
      'success': true,
      'appName': 'Voivi Chat Example',
      'version': '1.0.0',
      'platform': 'Flutter',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voivi Chat Example'),
        actions: [
          IconButton(
            icon: Icon(
              ConfigService.isProduction
                  ? Icons.cloud_queue
                  : Icons.computer,
            ),
            tooltip: ConfigService.isProduction
                ? 'Using Production'
                : 'Using Localhost',
            onPressed: () {
              setState(() {
                ConfigService.toggleEnvironment();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ConfigService.isProduction
                        ? 'Switched to Production'
                        : 'Switched to Localhost',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          AssistantListScreen(
            apiService: _apiService,
            onAssistantSelected: (assistantId) {
              setState(() {
                _selectedAssistantId = assistantId;
                _selectedIndex = 2; // Switch to Chat tab
              });
            },
          ),
          ChatScreen(
            engine: _engine,
            selectedAssistantId: _selectedAssistantId,
          ),
          ToolTestScreen(engine: _engine),
          const LogsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy),
            label: 'Assistants',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.article),
            label: 'Logs',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigCard(),
          const SizedBox(height: 16),
          _buildFeaturesCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFF6C63FF)),
                const SizedBox(width: 8),
                const Text(
                  'Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ConfigService.isProduction
                        ? Colors.orange
                        : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ConfigService.isProduction ? 'Production' : 'Localhost',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConfigItem('Base URL', ConfigService.baseUrl),
            _buildConfigItem('WebSocket URL', ConfigService.webSocketUrl),
            _buildConfigItem('Organization ID',
                ConfigService.organizationId),
            _buildConfigItem(
              'API Key',
              '${ConfigService.apiKey.substring(0, 8)}...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Color(0xFF00D9FF)),
                SizedBox(width: 8),
                Text(
                  'Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.smart_toy,
              'Assistant Management',
              'List and select AI assistants',
            ),
            _buildFeatureItem(
              Icons.chat_bubble,
              'Real-time Chat',
              'WebSocket-based messaging',
            ),
            _buildFeatureItem(
              Icons.mic,
              'Speech-to-Text',
              'Transcribe audio with AI',
            ),
            _buildFeatureItem(
              Icons.build_circle,
              'Client-Side Tools',
              'Test in-process tool execution',
            ),
            _buildFeatureItem(
              Icons.article,
              'Debug Logging',
              'View real-time system logs',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Color(0xFFFFD700)),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  Icons.list,
                  'View Assistants',
                  () => setState(() => _selectedIndex = 1),
                ),
                _buildActionChip(
                  Icons.chat,
                  'Start Chat',
                  () => setState(() => _selectedIndex = 2),
                ),
                _buildActionChip(
                  Icons.mic,
                  'Test STT',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const STTTestScreen(),
                      ),
                    );
                  },
                ),
                _buildActionChip(
                  Icons.build,
                  'Test Tools',
                  () => setState(() => _selectedIndex = 3),
                ),
                _buildActionChip(
                  Icons.article,
                  'View Logs',
                  () => setState(() => _selectedIndex = 4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: const Color(0xFF0F3460),
    );
  }
}
