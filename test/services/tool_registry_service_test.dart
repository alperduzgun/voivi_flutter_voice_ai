import 'dart:async';

import 'package:test/test.dart';
import 'package:voivi_voice_ai/src/models/tool_definition_models.dart';
import 'package:voivi_voice_ai/src/services/tool_registry_service.dart';

void main() {
  group('ToolRegistry', () {
    late ToolRegistry registry;

    setUp(() {
      registry = ToolRegistry();
    });

    group('register/unregister', () {
      test('should register a tool handler', () {
        registry.register('test_tool', (args) async => {'result': 'success'});

        expect(registry.has('test_tool'), isTrue);
        expect(registry.toolCount, equals(1));
        expect(registry.getRegisteredTools(), contains('test_tool'));
      });

      test('should overwrite existing tool when registering twice', () {
        registry.register('test_tool', (args) async => {'version': 1});
        registry.register('test_tool', (args) async => {'version': 2});

        expect(registry.toolCount, equals(1));
      });

      test('should unregister a tool', () {
        registry.register('test_tool', (args) async => {});

        expect(registry.has('test_tool'), isTrue);

        final removed = registry.unregister('test_tool');

        expect(removed, isTrue);
        expect(registry.has('test_tool'), isFalse);
        expect(registry.toolCount, equals(0));
      });

      test('should return false when unregistering non-existent tool', () {
        final removed = registry.unregister('nonexistent');

        expect(removed, isFalse);
      });

      test('should clear all registered tools', () {
        registry.register('tool1', (args) async => {});
        registry.register('tool2', (args) async => {});
        registry.register('tool3', (args) async => {});

        expect(registry.toolCount, equals(3));

        registry.clear();

        expect(registry.toolCount, equals(0));
        expect(registry.getRegisteredTools(), isEmpty);
      });
    });

    group('bindToolHandlers', () {
      test('should bind multiple tools at once', () {
        registry.bindToolHandlers({
          'tool1': (args) async => {},
          'tool2': (args) async => {},
          'tool3': (args) async => {},
        });

        expect(registry.toolCount, equals(3));
        expect(registry.has('tool1'), isTrue);
        expect(registry.has('tool2'), isTrue);
        expect(registry.has('tool3'), isTrue);
      });

      test('bindToolHandler should work as alias for register', () {
        registry.bindToolHandler('test', (args) async => {});

        expect(registry.has('test'), isTrue);
        expect(registry.toolCount, equals(1));
      });
    });

    group('execute', () {
      test('should execute registered tool successfully', () async {
        registry.register('get_info', (args) async {
          return {
            'name': args['name'],
            'value': 42,
          };
        });

        final result = await registry.execute('get_info', {'name': 'test'});

        expect(result, isA<Map>());
        expect(result['name'], equals('test'));
        expect(result['value'], equals(42));
      });

      test('should throw when executing non-existent tool', () async {
        expect(
          () => registry.execute('nonexistent', {}),
          throwsException,
        );
      });

      test('should handle empty args', () async {
        registry.register('test', (args) async {
          // Should receive empty map
          expect(args, isNotNull);
          expect(args, isEmpty);
          return {'received': 'empty'};
        });

        final result = await registry.execute('test', {});

        expect(result, isNotNull);
        expect(result['received'], equals('empty'));
      });

      test('should handle tool that returns null', () async {
        registry.register('null_tool', (args) async => null);

        final result = await registry.execute('null_tool', {});

        expect(result, isNull);
      });

      test('should handle tool that throws error', () async {
        registry.register('error_tool', (args) async {
          throw Exception('Tool error');
        });

        expect(
          () => registry.execute('error_tool', {}),
          throwsException,
        );
      });

      test('should timeout after 30 seconds', () async {
        registry.register('slow_tool', (args) async {
          // Simulate a tool that never completes
          await Future.delayed(Duration(seconds: 35));
          return {};
        });

        expect(
          () => registry.execute('slow_tool', {}),
          throwsA(isA<TimeoutException>()),
        );
      }, timeout: Timeout(Duration(seconds: 35)));

      test('should handle FormatException', () async {
        registry.register('format_error_tool', (args) async {
          throw FormatException('Invalid format');
        });

        expect(
          () => registry.execute('format_error_tool', {}),
          throwsException,
        );
      });

      test('should execute tool with complex arguments', () async {
        registry.register('complex_tool', (args) async {
          return {
            'nested': args['nested'],
            'array': args['array'],
            'number': args['number'],
          };
        });

        final result = await registry.execute('complex_tool', {
          'nested': {'key': 'value'},
          'array': [1, 2, 3],
          'number': 42.5,
        });

        expect(result['nested'], equals({'key': 'value'}));
        expect(result['array'], equals([1, 2, 3]));
        expect(result['number'], equals(42.5));
      });

      test('should execute tool with no arguments', () async {
        registry.register('no_args_tool', (args) async {
          return {'timestamp': DateTime.now().toIso8601String()};
        });

        final result = await registry.execute('no_args_tool', {});

        expect(result, isA<Map>());
        expect(result['timestamp'], isNotNull);
      });
    });

    group('available tools', () {
      test('should set available tools from backend', () {
        final tools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'get_location',
            description: 'Get device location',
            category: 'device',
          ),
          ClientToolDefinition(
            id: 'tool-2',
            name: 'get_device_info',
            description: 'Get device info',
            category: 'device',
          ),
        ];

        registry.setAvailableTools(tools);

        expect(registry.availableToolCount, equals(2));
        expect(registry.getAvailableTools().length, equals(2));
      });

      test('should return immutable list of available tools', () {
        final tools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'test',
            description: 'Test',
            category: 'general',
          ),
        ];

        registry.setAvailableTools(tools);

        final availableTools = registry.getAvailableTools();

        // Should not be able to modify the returned list
        expect(() => availableTools.add(tools[0]), throwsUnsupportedError);
      });

      test('should clear available tools when setting new ones', () {
        final tools1 = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'old_tool',
            description: 'Old',
            category: 'general',
          ),
        ];

        final tools2 = [
          ClientToolDefinition(
            id: 'tool-2',
            name: 'new_tool',
            description: 'New',
            category: 'general',
          ),
        ];

        registry.setAvailableTools(tools1);
        expect(registry.availableToolCount, equals(1));

        registry.setAvailableTools(tools2);
        expect(registry.availableToolCount, equals(1));
        expect(registry.getAvailableTools().first.name, equals('new_tool'));
      });

      test('should get tool definition by name', () {
        final tools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'get_location',
            description: 'Get location',
            category: 'device',
          ),
          ClientToolDefinition(
            id: 'tool-2',
            name: 'get_info',
            description: 'Get info',
            category: 'device',
          ),
        ];

        registry.setAvailableTools(tools);

        final definition = registry.getToolDefinition('get_location');

        expect(definition, isNotNull);
        expect(definition!.id, equals('tool-1'));
        expect(definition.name, equals('get_location'));
      });

      test('should return null for non-existent tool definition', () {
        final definition = registry.getToolDefinition('nonexistent');

        expect(definition, isNull);
      });
    });

    group('unbound tools', () {
      test('should identify unbound tools', () {
        final tools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'tool_a',
            description: 'Tool A',
            category: 'general',
          ),
          ClientToolDefinition(
            id: 'tool-2',
            name: 'tool_b',
            description: 'Tool B',
            category: 'general',
          ),
          ClientToolDefinition(
            id: 'tool-3',
            name: 'tool_c',
            description: 'Tool C',
            category: 'general',
          ),
        ];

        registry.setAvailableTools(tools);

        // Bind only tool_a and tool_b
        registry.bindToolHandlers({
          'tool_a': (args) async => {},
          'tool_b': (args) async => {},
        });

        final unbound = registry.getUnboundTools();

        expect(unbound.length, equals(1));
        expect(unbound, contains('tool_c'));
        expect(registry.unboundToolCount, equals(1));
      });

      test('should return empty list when all tools are bound', () {
        final tools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'tool_a',
            description: 'Tool A',
            category: 'general',
          ),
        ];

        registry.setAvailableTools(tools);
        registry.register('tool_a', (args) async => {});

        final unbound = registry.getUnboundTools();

        expect(unbound, isEmpty);
        expect(registry.unboundToolCount, equals(0));
      });

      test('should return all tools as unbound when none are bound', () {
        final tools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'tool_a',
            description: 'Tool A',
            category: 'general',
          ),
          ClientToolDefinition(
            id: 'tool-2',
            name: 'tool_b',
            description: 'Tool B',
            category: 'general',
          ),
        ];

        registry.setAvailableTools(tools);

        final unbound = registry.getUnboundTools();

        expect(unbound.length, equals(2));
        expect(unbound, containsAll(['tool_a', 'tool_b']));
      });

      test('isToolBound should check if tool has handler', () {
        registry.register('bound_tool', (args) async => {});

        expect(registry.isToolBound('bound_tool'), isTrue);
        expect(registry.isToolBound('unbound_tool'), isFalse);
      });
    });

    group('getters', () {
      test('toolCount should return number of registered tools', () {
        expect(registry.toolCount, equals(0));

        registry.register('tool1', (args) async => {});
        expect(registry.toolCount, equals(1));

        registry.register('tool2', (args) async => {});
        expect(registry.toolCount, equals(2));

        registry.unregister('tool1');
        expect(registry.toolCount, equals(1));
      });

      test('availableToolCount should return number of available tools', () {
        expect(registry.availableToolCount, equals(0));

        registry.setAvailableTools([
          ClientToolDefinition(
            id: 'tool-1',
            name: 'test',
            description: 'Test',
            category: 'general',
          ),
        ]);

        expect(registry.availableToolCount, equals(1));
      });

      test('getRegisteredTools should return list of tool names', () {
        registry.bindToolHandlers({
          'tool_a': (args) async => {},
          'tool_b': (args) async => {},
          'tool_c': (args) async => {},
        });

        final registered = registry.getRegisteredTools();

        expect(registered.length, equals(3));
        expect(registered, containsAll(['tool_a', 'tool_b', 'tool_c']));
      });
    });

    group('real-world scenarios', () {
      test('should handle typical client-side tool workflow', () async {
        // 1. Backend provides available tools
        final availableTools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'get_location',
            description: 'Get device location',
            category: 'device',
            parameters: [
              ToolParameter(
                name: 'accuracy',
                type: 'string',
                description: 'GPS accuracy',
                required: false,
              ),
            ],
          ),
          ClientToolDefinition(
            id: 'tool-2',
            name: 'get_device_info',
            description: 'Get device information',
            category: 'device',
          ),
        ];

        registry.setAvailableTools(availableTools);

        // 2. Client binds handlers for available tools
        registry.bindToolHandlers({
          'get_location': (args) async {
            return {
              'latitude': 37.7749,
              'longitude': -122.4194,
              'accuracy': args['accuracy'] ?? 'high',
            };
          },
          'get_device_info': (args) async {
            return {
              'platform': 'ios',
              'version': '17.0',
            };
          },
        });

        // 3. Verify all tools are bound
        expect(registry.unboundToolCount, equals(0));
        expect(registry.toolCount, equals(2));

        // 4. Execute tools
        final location = await registry.execute('get_location', {
          'accuracy': 'medium',
        });

        expect(location['latitude'], equals(37.7749));
        expect(location['accuracy'], equals('medium'));

        final deviceInfo = await registry.execute('get_device_info', {});

        expect(deviceInfo['platform'], equals('ios'));
      });

      test('should handle partial tool implementation', () {
        final availableTools = [
          ClientToolDefinition(
            id: 'tool-1',
            name: 'implemented_tool',
            description: 'Implemented',
            category: 'general',
          ),
          ClientToolDefinition(
            id: 'tool-2',
            name: 'not_implemented_tool',
            description: 'Not implemented',
            category: 'general',
          ),
        ];

        registry.setAvailableTools(availableTools);
        registry.register('implemented_tool', (args) async => {});

        // Check implementation status
        expect(registry.isToolBound('implemented_tool'), isTrue);
        expect(registry.isToolBound('not_implemented_tool'), isFalse);

        final unbound = registry.getUnboundTools();
        expect(unbound, equals(['not_implemented_tool']));
      });

      test('should handle tool re-binding after clear', () async {
        registry.register('test_tool', (args) async => {'version': 1});

        final result1 = await registry.execute('test_tool', {});
        expect(result1['version'], equals(1));

        registry.clear();

        expect(registry.has('test_tool'), isFalse);

        registry.register('test_tool', (args) async => {'version': 2});

        final result2 = await registry.execute('test_tool', {});
        expect(result2['version'], equals(2));
      });
    });
  });
}
