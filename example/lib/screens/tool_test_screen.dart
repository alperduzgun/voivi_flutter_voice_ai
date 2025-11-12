import 'package:flutter/material.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

class ToolTestScreen extends StatefulWidget {
  final VoiviChatEngine? engine;

  const ToolTestScreen({super.key, this.engine});

  @override
  State<ToolTestScreen> createState() => _ToolTestScreenState();
}

class _ToolTestScreenState extends State<ToolTestScreen> {
  final List<ToolTestResult> _testResults = [];
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildToolsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F3460),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF6C63FF),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text(
                'Tool Testing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Test client-side tool execution',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildToolCard(
          'get_random_number',
          'Generate random number in range',
          Icons.casino,
          () => _testRandomNumber(),
        ),
        _buildToolCard(
          'calculate_sum',
          'Calculate sum of numbers',
          Icons.calculate,
          () => _testCalculateSum(),
        ),
        _buildToolCard(
          'get_app_info',
          'Get application information',
          Icons.info,
          () => _testGetAppInfo(),
        ),
        if (_testResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildResultsSection(),
        ],
      ],
    );
  }

  Widget _buildToolCard(
    String name,
    String description,
    IconData icon,
    VoidCallback onTest,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF)),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: _isTesting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.play_arrow),
                color: const Color(0xFF6C63FF),
                onPressed: onTest,
              ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Test Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _testResults.clear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._testResults.reversed
                .take(5)
                .map((result) => _buildResultItem(result)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(ToolTestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.toolName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${result.executionTime}ms',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.result,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _testRandomNumber() async {
    if (widget.engine == null) {
      _showError('Engine not initialized');
      return;
    }

    setState(() => _isTesting = true);

    try {
      final startTime = DateTime.now();
      final result = await widget.engine!.toolRegistry.execute(
        'get_random_number',
        {'min': 1, 'max': 100},
      );
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds;

      setState(() {
        _testResults.add(ToolTestResult(
          toolName: 'get_random_number',
          success: result['success'] == true,
          result: result.toString(),
          executionTime: executionTime,
        ));
        _isTesting = false;
      });

      debugPrint('✅ Random number result: $result');
    } catch (e) {
      setState(() {
        _testResults.add(ToolTestResult(
          toolName: 'get_random_number',
          success: false,
          result: 'Error: $e',
          executionTime: 0,
        ));
        _isTesting = false;
      });
      debugPrint('❌ Random number error: $e');
    }
  }

  Future<void> _testCalculateSum() async {
    if (widget.engine == null) {
      _showError('Engine not initialized');
      return;
    }

    setState(() => _isTesting = true);

    try {
      final startTime = DateTime.now();
      final result = await widget.engine!.toolRegistry.execute(
        'calculate_sum',
        {
          'numbers': [10, 20, 30, 40, 50]
        },
      );
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds;

      setState(() {
        _testResults.add(ToolTestResult(
          toolName: 'calculate_sum',
          success: result['success'] == true,
          result: result.toString(),
          executionTime: executionTime,
        ));
        _isTesting = false;
      });

      debugPrint('✅ Calculate sum result: $result');
    } catch (e) {
      setState(() {
        _testResults.add(ToolTestResult(
          toolName: 'calculate_sum',
          success: false,
          result: 'Error: $e',
          executionTime: 0,
        ));
        _isTesting = false;
      });
      debugPrint('❌ Calculate sum error: $e');
    }
  }

  Future<void> _testGetAppInfo() async {
    if (widget.engine == null) {
      _showError('Engine not initialized');
      return;
    }

    setState(() => _isTesting = true);

    try {
      final startTime = DateTime.now();
      final result = await widget.engine!.toolRegistry.execute(
        'get_app_info',
        {},
      );
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds;

      setState(() {
        _testResults.add(ToolTestResult(
          toolName: 'get_app_info',
          success: result['success'] == true,
          result: result.toString(),
          executionTime: executionTime,
        ));
        _isTesting = false;
      });

      debugPrint('✅ Get app info result: $result');
    } catch (e) {
      setState(() {
        _testResults.add(ToolTestResult(
          toolName: 'get_app_info',
          success: false,
          result: 'Error: $e',
          executionTime: 0,
        ));
        _isTesting = false;
      });
      debugPrint('❌ Get app info error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class ToolTestResult {
  final String toolName;
  final bool success;
  final String result;
  final int executionTime;

  ToolTestResult({
    required this.toolName,
    required this.success,
    required this.result,
    required this.executionTime,
  });
}
