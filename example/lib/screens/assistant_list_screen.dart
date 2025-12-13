import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';
import '../services/config_service.dart';

class AssistantListScreen extends StatefulWidget {
  final VoiviApiService apiService;
  final void Function(String assistantId)? onAssistantSelected;

  const AssistantListScreen({
    super.key,
    required this.apiService,
    this.onAssistantSelected,
  });

  @override
  State<AssistantListScreen> createState() => _AssistantListScreenState();
}

class _AssistantListScreenState extends State<AssistantListScreen> {
  List<AssistantModel> _assistants = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssistants();
  }

  Future<void> _loadAssistants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assistants = await widget.apiService.listAssistants(
        baseUrl: ConfigService.baseUrl,
        apiKey: ConfigService.apiKey,
        organizationId: ConfigService.organizationId,
      );

      setState(() {
        _assistants = assistants;
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${assistants.length} assistants');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('❌ Error loading assistants: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAssistants,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading assistants...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading assistants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAssistants,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_assistants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No assistants found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an assistant in the backend first',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAssistants,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssistants,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assistants.length,
        itemBuilder: (context, index) {
          final assistant = _assistants[index];
          return _buildAssistantCard(assistant);
        },
      ),
    );
  }

  Widget _buildAssistantCard(AssistantModel assistant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAssistantDetails(assistant),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF757575).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assistant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${assistant.id.substring(0, 12)}...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              if (assistant.firstMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    assistant.firstMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (assistant.toolIds != null && assistant.toolIds!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.build_circle,
                      size: 16,
                      color: Color(0xFF757575),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${assistant.toolIds!.length} Tools',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAssistantDetails(AssistantModel assistant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy, color: Color(0xFF757575)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assistant.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailItem('ID', assistant.id),
              if (assistant.firstMessage != null)
                _buildDetailItem('First Message', assistant.firstMessage!),
              if (assistant.endCallMessage != null)
                _buildDetailItem('End Call Message', assistant.endCallMessage!),
              if (assistant.toolIds != null && assistant.toolIds!.isNotEmpty)
                _buildToolIdsSection(assistant.toolIds!),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Notify parent to switch to chat
                    widget.onAssistantSelected?.call(assistant.id);
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Start Chat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIdsSection(List<String> toolIds) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tools',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF757575).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${toolIds.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF757575).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: toolIds.asMap().entries.map((entry) {
                final index = entry.key;
                final toolId = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < toolIds.length - 1 ? 8 : 0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF757575).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          toolId,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Color(0xFF757575),
                        ),
                        onPressed: () {
                          // Copy to clipboard
                          Clipboard.setData(ClipboardData(text: toolId));
                          // Show snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied: ${toolId.substring(0, 8)}...'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
