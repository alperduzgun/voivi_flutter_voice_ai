import 'package:test/test.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

void main() {
  group('ToolParameter', () {
    test('should create valid parameter', () {
      final param = ToolParameter(
        name: 'location',
        type: 'object',
        description: 'Device location',
        required: true,
      );

      expect(param.name, equals('location'));
      expect(param.type, equals('object'));
      expect(param.description, equals('Device location'));
      expect(param.required, isTrue);
    });

    test('should default required to false', () {
      final param = ToolParameter(
        name: 'optional',
        type: 'string',
        description: 'Optional param',
      );

      expect(param.required, isFalse);
    });

    test('should serialize to JSON correctly', () {
      final param = ToolParameter(
        name: 'test',
        type: 'number',
        description: 'Test param',
        required: true,
      );

      final json = param.toJson();

      expect(json['name'], equals('test'));
      expect(json['type'], equals('number'));
      expect(json['description'], equals('Test param'));
      expect(json['required'], isTrue);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'name': 'test',
        'type': 'string',
        'description': 'Test parameter',
        'required': true,
      };

      final param = ToolParameter.fromJson(json);

      expect(param.name, equals('test'));
      expect(param.type, equals('string'));
      expect(param.description, equals('Test parameter'));
      expect(param.required, isTrue);
    });

    test('should handle JSON without required field', () {
      final json = {
        'name': 'test',
        'type': 'boolean',
        'description': 'Test',
      };

      final param = ToolParameter.fromJson(json);

      expect(param.required, isFalse);
    });

    test('should implement equality correctly', () {
      final param1 = ToolParameter(
        name: 'test',
        type: 'string',
        description: 'Test',
        required: true,
      );

      final param2 = ToolParameter(
        name: 'test',
        type: 'string',
        description: 'Different description',
        required: true,
      );

      final param3 = ToolParameter(
        name: 'different',
        type: 'string',
        description: 'Test',
        required: true,
      );

      expect(param1, equals(param2)); // Description not in equality
      expect(param1, isNot(equals(param3))); // Different name
    });

    test('should have consistent hashCode', () {
      final param1 = ToolParameter(
        name: 'test',
        type: 'string',
        description: 'Test',
        required: true,
      );

      final param2 = ToolParameter(
        name: 'test',
        type: 'string',
        description: 'Different',
        required: true,
      );

      expect(param1.hashCode, equals(param2.hashCode));
    });
  });

  group('ClientToolDefinition', () {
    test('should create valid tool definition', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'get_location',
        description: 'Get device location',
        category: 'device',
        parameters: [
          ToolParameter(
            name: 'accuracy',
            type: 'string',
            description: 'GPS accuracy',
          ),
        ],
        requiredPermissions: 'location',
        executionLocation: 'client',
        timeoutSeconds: 15,
      );

      expect(tool.id, equals('tool-123'));
      expect(tool.name, equals('get_location'));
      expect(tool.description, equals('Get device location'));
      expect(tool.category, equals('device'));
      expect(tool.parameters.length, equals(1));
      expect(tool.requiredPermissions, equals('location'));
      expect(tool.executionLocation, equals('client'));
      expect(tool.timeoutSeconds, equals(15));
    });

    test('should have default values', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Test',
        category: 'general',
      );

      expect(tool.parameters, isEmpty);
      expect(tool.requiredPermissions, isNull);
      expect(tool.executionLocation, equals('client'));
      expect(tool.timeoutSeconds, equals(10));
    });

    test('should serialize to JSON correctly', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'get_location',
        description: 'Get location',
        category: 'device',
        parameters: [
          ToolParameter(
            name: 'accuracy',
            type: 'string',
            description: 'Accuracy level',
          ),
        ],
        requiredPermissions: 'location',
      );

      final json = tool.toJson();

      expect(json['id'], equals('tool-123'));
      expect(json['name'], equals('get_location'));
      expect(json['description'], equals('Get location'));
      expect(json['category'], equals('device'));
      expect(json['parameters'], isList);
      expect((json['parameters'] as List).length, equals(1));
      expect(json['requiredPermissions'], equals('location'));
      expect(json['executionLocation'], equals('client'));
      expect(json['timeoutSeconds'], equals(10));
    });

    test('should deserialize from backend JSON (InProcess)', () {
      final json = {
        'id': 'tool-123',
        'name': 'get_location',
        'description': 'Get device location',
        'category': 'device',
        'type': 'InProcess',
        'customConfig': {
          'executionLocation': 'client',
          'timeoutSeconds': 20,
        },
        'parameters': [
          {
            'name': 'accuracy',
            'type': 'string',
            'description': 'GPS accuracy',
            'required': true,
          }
        ],
        'requiredPermissions': 'location',
      };

      final tool = ClientToolDefinition.fromJson(json);

      expect(tool.id, equals('tool-123'));
      expect(tool.name, equals('get_location'));
      expect(tool.description, equals('Get device location'));
      expect(tool.category, equals('device'));
      expect(tool.executionLocation, equals('client'));
      expect(tool.timeoutSeconds, equals(20));
      expect(tool.parameters.length, equals(1));
      expect(tool.parameters.first.name, equals('accuracy'));
      expect(tool.parameters.first.required, isTrue);
      expect(tool.requiredPermissions, equals('location'));
    });

    test('should deserialize from backend JSON (minimal)', () {
      final json = {
        'id': 'tool-123',
        'name': 'simple_tool',
      };

      final tool = ClientToolDefinition.fromJson(json);

      expect(tool.id, equals('tool-123'));
      expect(tool.name, equals('simple_tool'));
      expect(tool.description, isEmpty);
      expect(tool.category, equals('general'));
      expect(tool.parameters, isEmpty);
      expect(tool.executionLocation, equals('client'));
      expect(tool.timeoutSeconds, equals(10));
    });

    test('should check permission requirements', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'get_location',
        description: 'Test',
        category: 'device',
        requiredPermissions: 'location,camera',
      );

      expect(tool.requiresPermission('location'), isTrue);
      expect(tool.requiresPermission('camera'), isTrue);
      expect(tool.requiresPermission('storage'), isFalse);
    });

    test('should handle no permissions', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Test',
        category: 'general',
      );

      expect(tool.requiresPermission('location'), isFalse);
      expect(tool.requiresPermission('anything'), isFalse);
    });

    test('should get parameter by name', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Test',
        category: 'general',
        parameters: [
          ToolParameter(
            name: 'param1',
            type: 'string',
            description: 'First',
          ),
          ToolParameter(
            name: 'param2',
            type: 'number',
            description: 'Second',
          ),
        ],
      );

      final param1 = tool.getParameter('param1');
      final param2 = tool.getParameter('param2');
      final param3 = tool.getParameter('nonexistent');

      expect(param1, isNotNull);
      expect(param1!.name, equals('param1'));
      expect(param2, isNotNull);
      expect(param2!.name, equals('param2'));
      expect(param3, isNull);
    });

    test('should validate required parameters', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Test',
        category: 'general',
        parameters: [
          ToolParameter(
            name: 'required_param',
            type: 'string',
            description: 'Required',
            required: true,
          ),
          ToolParameter(
            name: 'optional_param',
            type: 'string',
            description: 'Optional',
            required: false,
          ),
        ],
      );

      // Valid args
      expect(
        tool.validateParameters({'required_param': 'value'}),
        isTrue,
      );

      expect(
        tool.validateParameters({
          'required_param': 'value',
          'optional_param': 'value',
        }),
        isTrue,
      );

      // Missing required parameter
      expect(
        tool.validateParameters({'optional_param': 'value'}),
        isFalse,
      );

      expect(
        tool.validateParameters({}),
        isFalse,
      );
    });

    test('should validate with no parameters', () {
      final tool = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Test',
        category: 'general',
      );

      expect(tool.validateParameters({}), isTrue);
      expect(tool.validateParameters({'any': 'args'}), isTrue);
    });

    test('should implement equality correctly', () {
      final tool1 = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Test',
        category: 'general',
      );

      final tool2 = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Different description',
        category: 'general',
      );

      final tool3 = ClientToolDefinition(
        id: 'tool-456',
        name: 'test',
        description: 'Test',
        category: 'general',
      );

      expect(tool1, equals(tool2)); // Same id, name, category
      expect(tool1, isNot(equals(tool3))); // Different id
    });

    test('should have consistent hashCode', () {
      final tool1 = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Test',
        category: 'general',
      );

      final tool2 = ClientToolDefinition(
        id: 'tool-123',
        name: 'test',
        description: 'Different',
        category: 'general',
      );

      expect(tool1.hashCode, equals(tool2.hashCode));
    });

    test('should handle complex JSON parsing', () {
      final json = {
        'id': 'tool-complex',
        'name': 'complex_tool',
        'description': 'Complex tool',
        'category': 'advanced',
        'type': 'InProcess',
        'customConfig': {
          'executionLocation': 'client',
          'timeoutSeconds': 30,
        },
        'parameters': [
          {
            'name': 'param1',
            'type': 'object',
            'description': 'Object param',
            'required': true,
          },
          {
            'name': 'param2',
            'type': 'array',
            'description': 'Array param',
            'required': false,
          },
        ],
        'requiredPermissions': 'camera,microphone,storage',
      };

      final tool = ClientToolDefinition.fromJson(json);

      expect(tool.id, equals('tool-complex'));
      expect(tool.name, equals('complex_tool'));
      expect(tool.category, equals('advanced'));
      expect(tool.executionLocation, equals('client'));
      expect(tool.timeoutSeconds, equals(30));
      expect(tool.parameters.length, equals(2));
      expect(tool.requiresPermission('camera'), isTrue);
      expect(tool.requiresPermission('microphone'), isTrue);
      expect(tool.requiresPermission('storage'), isTrue);
    });
  });

  group('JSON roundtrip', () {
    test('ToolParameter should survive JSON roundtrip', () {
      final original = ToolParameter(
        name: 'test',
        type: 'string',
        description: 'Test param',
        required: true,
      );

      final json = original.toJson();
      final restored = ToolParameter.fromJson(json);

      expect(restored, equals(original));
      expect(restored.name, equals(original.name));
      expect(restored.type, equals(original.type));
      expect(restored.description, equals(original.description));
      expect(restored.required, equals(original.required));
    });

    test('ClientToolDefinition should survive JSON roundtrip', () {
      final original = ClientToolDefinition(
        id: 'tool-123',
        name: 'test_tool',
        description: 'Test tool',
        category: 'testing',
        parameters: [
          ToolParameter(
            name: 'param1',
            type: 'string',
            description: 'Param 1',
            required: true,
          ),
        ],
        requiredPermissions: 'location',
        executionLocation: 'client',
        timeoutSeconds: 25,
      );

      final json = original.toJson();

      // Add backend-style wrapper for proper parsing
      final backendJson = {
        ...json,
        'type': 'InProcess',
        'customConfig': {
          'executionLocation': json['executionLocation'],
          'timeoutSeconds': json['timeoutSeconds'],
        },
      };

      final restored = ClientToolDefinition.fromJson(backendJson);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.category, equals(original.category));
      expect(restored.parameters.length, equals(original.parameters.length));
      expect(restored.executionLocation, equals(original.executionLocation));
      expect(restored.timeoutSeconds, equals(original.timeoutSeconds));
    });
  });
}
