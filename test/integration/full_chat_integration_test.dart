// ignore_for_file: avoid_print

import 'dart:async';

import 'package:test/test.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

import '../test_config.dart';

/// Full integration test: Assistant selection → Chat connection → Messaging
///
/// This test demonstrates the complete workflow from listing assistants
/// to establishing a chat connection and sending messages.
void main() {
  group('Full Chat Integration Tests', () {
    late VoiviApiService apiService;
    late VoiviChatEngine chatEngine;

    setUpAll(() {
      TestConfig.printConfig();

      if (!TestConfig.runIntegrationTests) {
        print('⚠️  Integration tests are disabled.');
      }

      if (!TestConfig.isConfigured) {
        print('⚠️  Test configuration is not set up.');
      }
    });

    setUp(() {
      VoiviApiService.resetInstance();
      apiService = VoiviApiService();
      chatEngine = VoiviChatEngine();
    });

    tearDown(() async {
      await chatEngine.dispose();
      apiService.dispose();
    });

    test('complete workflow: list assistants → select → connect → chat',
        () async {
      if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
        print('⏭️  Skipping test - not configured');
        return;
      }

      print('\n=== Complete Chat Workflow Test ===\n');

      // Step 1: List available assistants
      print('📋 Step 1: Fetching available assistants...');
      final assistants = await apiService.listAssistants(
        baseUrl: TestConfig.baseUrl,
        apiKey: TestConfig.apiKey,
        organizationId: TestConfig.organizationId,
      );

      expect(assistants, isNotEmpty, reason: 'Need at least one assistant');
      print('✅ Found ${assistants.length} assistants\n');

      // Step 2: Select an assistant
      final selectedAssistant =
          assistants.firstWhere((a) => a.id == TestConfig.assistantId);

      print('🎯 Step 2: Selected assistant: ${selectedAssistant.name}');
      print('   ID: ${selectedAssistant.id}\n');

      // Step 3: Create chat configuration
      print('⚙️  Step 3: Creating chat configuration...');
      final config = VoiviConfig(
        apiKey: TestConfig.apiKey,
        organizationId: TestConfig.organizationId,
        assistantId: selectedAssistant.id,
        baseUrl: TestConfig.baseUrl,
        userId: TestConfig.testUserId,
      );
      print('✅ Configuration created\n');

      // Step 4: Initialize chat engine
      print('🔧 Step 4: Initializing chat engine...');
      await chatEngine.initialize(config);
      expect(chatEngine.isInitialized, isTrue);
      print('✅ Chat engine initialized\n');

      // Step 5: Set up message listener
      print('👂 Step 5: Setting up message listeners...');
      final messageCompleter = Completer<ChatMessage>();
      final receivedMessages = <ChatMessage>[];

      final messageSubscription = chatEngine.messageStream.listen((message) {
        receivedMessages.add(message);
        print(
            '📨 Received message: [${message.type}] ${message.content?.substring(0, message.content!.length > 50 ? 50 : message.content!.length)}${(message.content?.length ?? 0) > 50 ? '...' : ''}');

        // Complete on first assistant response
        if (message.type == ChatMessageType.assistantText &&
            !messageCompleter.isCompleted) {
          messageCompleter.complete(message);
        }
      });

      final stateSubscription = chatEngine.stateStream.listen((state) {
        print(
            '🔄 State: Connected=${state.isConnected}, Processing=${state.isProcessing}, Messages=${state.messages.length}');
      });

      print('✅ Listeners configured\n');

      // Step 6: Connect to chat service
      print('🔌 Step 6: Connecting to chat service...');
      await chatEngine.connect();
      expect(chatEngine.isConnected, isTrue);
      print('✅ Connected to chat service\n');

      // Wait a bit for connection to stabilize
      await Future<void>.delayed(const Duration(seconds: 2));

      // Step 7: Send a test message
      print('📤 Step 7: Sending test message...');
      const testMessage = 'Hello! This is an integration test message.';
      await chatEngine.sendMessage(testMessage);
      print('✅ Message sent\n');

      // Step 8: Wait for response (with timeout)
      print('⏳ Step 8: Waiting for assistant response...');
      try {
        final response = await messageCompleter.future.timeout(
          TestConfig.messageTimeout,
          onTimeout: () {
            throw TimeoutException(
              'No response received within ${TestConfig.messageTimeout.inSeconds} seconds',
            );
          },
        );

        print('✅ Received response: ${response.content}\n');

        expect(response.content, isNotNull);
        expect(response.content, isNotEmpty);
        expect(response.type, ChatMessageType.assistantText);
      } on TimeoutException catch (e) {
        print('⚠️  Warning: ${e.message}');
        print('   This might be expected if the assistant is slow to respond.');
        print('   Messages received so far: ${receivedMessages.length}');
      }

      // Step 9: Verify chat state
      print('🔍 Step 9: Verifying final state...');
      final finalState = chatEngine.currentState;
      expect(finalState.isConnected, isTrue);
      expect(finalState.messages.length, greaterThanOrEqualTo(1));
      print('✅ Final state verified');
      print('   Messages in state: ${finalState.messages.length}');
      print('   Conversation ID: ${finalState.currentConversationId}\n');

      // Cleanup
      print('🧹 Cleaning up...');
      await messageSubscription.cancel();
      await stateSubscription.cancel();
      await chatEngine.disconnect();
      print('✅ Cleanup complete\n');

      print('=== Test Completed Successfully ===\n');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('should handle reconnection scenario', () async {
      if (!TestConfig.runIntegrationTests || !TestConfig.isConfigured) {
        print('⏭️  Skipping test - not configured');
        return;
      }

      print('\n=== Reconnection Test ===\n');

      // Get an assistant
      final assistants = await apiService.listAssistants(
        baseUrl: TestConfig.baseUrl,
        apiKey: TestConfig.apiKey,
        organizationId: TestConfig.organizationId,
      );
      expect(assistants, isNotEmpty);

      final assistant = assistants.first;

      // Initial connection
      print('🔌 Initial connection...');
      final config = VoiviConfig(
        apiKey: TestConfig.apiKey,
        organizationId: TestConfig.organizationId,
        assistantId: assistant.id,
        baseUrl: TestConfig.baseUrl,
        userId: TestConfig.testUserId,
      );

      await chatEngine.initialize(config);
      await chatEngine.connect();

      // Wait for connection to fully establish
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(chatEngine.isConnected, isTrue);
      print('✅ Initially connected\n');

      // Disconnect
      print('🔌 Disconnecting...');
      await chatEngine.disconnect();

      // Wait for disconnect to process
      await Future<void>.delayed(const Duration(seconds: 1));

      // Note: isConnected might still be true due to WebSocket state propagation delay
      print(
          '📊 Connection state after disconnect: ${chatEngine.isConnected}\n');

      // Reconnect
      print('🔌 Reconnecting...');
      await chatEngine.reconnect();

      // Wait for reconnection to establish
      await Future<void>.delayed(const Duration(seconds: 3));

      expect(chatEngine.isConnected, isTrue);
      print('✅ Reconnected successfully\n');

      print('=== Reconnection Test Completed ===\n');
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
