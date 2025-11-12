import 'package:flutter/material.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';
import 'package:intl/intl.dart';
import '../services/config_service.dart';

class ChatScreen extends StatefulWidget {
  final VoiviChatEngine? engine;
  final String? selectedAssistantId;

  const ChatScreen({super.key, this.engine, this.selectedAssistantId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _assistantIdController = TextEditingController();
  final List<ExampleChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    if (widget.engine != null) {
      widget.engine!.messageStream.listen(_onMessageReceived);
    }
    // Auto-fill assistant ID if provided
    if (widget.selectedAssistantId != null) {
      _assistantIdController.text = widget.selectedAssistantId!;
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-connect when assistant is selected
    if (widget.selectedAssistantId != null &&
        widget.selectedAssistantId != oldWidget.selectedAssistantId &&
        !_isConnected &&
        !_isConnecting) {
      _assistantIdController.text = widget.selectedAssistantId!;
      // Auto-connect after a short delay to allow UI to settle
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isConnected && !_isConnecting) {
          _connect();
        }
      });
    }
  }

  void _onMessageReceived(ChatMessage message) {
    setState(() {
      _messages.add(ExampleChatMessage(
        content: message.content ?? '',
        isUser: message.type == ChatMessageType.userText,
        timestamp: DateTime.now(),
        type: message.type.toString(),
      ));
      _isConnected = true;
      _connectionStatus = 'Connected';
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _connect() async {
    if (widget.engine == null) {
      _showError('Engine not initialized');
      return;
    }

    final assistantId = _assistantIdController.text.trim();
    if (assistantId.isEmpty) {
      _showError('Please enter an assistant ID');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    try {
      await widget.engine!.initialize(VoiviConfig(
        apiKey: ConfigService.apiKey,
        organizationId: ConfigService.organizationId,
        assistantId: assistantId,
        baseUrl: ConfigService.webSocketUrl,
      ));

      await widget.engine!.connect();

      setState(() {
        _isConnecting = false;
      });

      debugPrint('✅ Connected to assistant: $assistantId');
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Connection failed';
      });
      _showError('Connection failed: $e');
      debugPrint('❌ Connection error: $e');
    }
  }

  Future<void> _disconnect() async {
    if (widget.engine != null) {
      await widget.engine!.disconnect();
      setState(() {
        _messages.clear();
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    if (!_isConnected || widget.engine == null) {
      _showError('Not connected to assistant');
      return;
    }

    try {
      await widget.engine!.sendMessage(message);
      debugPrint('✅ Message sent: $message');
    } catch (e) {
      _showError('Failed to send message: $e');
      debugPrint('❌ Send error: $e');
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

  @override
  void dispose() {
    _messageController.dispose();
    _assistantIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildConnectionPanel(),
        Expanded(child: _buildMessageList()),
        if (_isConnected) _buildMessageInput(),
      ],
    );
  }

  Widget _buildConnectionPanel() {
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
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _connectionStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (!_isConnected) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _assistantIdController,
              decoration: const InputDecoration(
                hintText: 'Enter Assistant ID',
                prefixIcon: Icon(Icons.smart_toy),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connect,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.logout),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _isConnected
                  ? 'No messages yet'
                  : 'Connect to start chatting',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ExampleChatMessage message) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF6C63FF)
              : const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
                if (!message.isUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      message.type.split('.').last.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F3460),
        border: Border(
          top: BorderSide(
            color: Color(0xFF6C63FF),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: const Color(0xFF6C63FF),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class ExampleChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String type;

  ExampleChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.type,
  });
}
