import 'package:test/test.dart';
import 'package:voivi_voice_ai/voivi_chat.dart';

void main() {
  group('AssistantModel', () {
    test('fromJson should parse camelCase JSON correctly', () {
      final json = {
        'id': 'ast_123',
        'name': 'Test Assistant',
        'description': 'A test assistant',
        'firstMessage': 'Hello!',
        'endCallMessage': 'Goodbye!',
        'metadata': {'key': 'value'},
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-02T00:00:00.000Z',
      };

      final assistant = AssistantModel.fromJson(json);

      expect(assistant.id, 'ast_123');
      expect(assistant.name, 'Test Assistant');
      expect(assistant.description, 'A test assistant');
      expect(assistant.firstMessage, 'Hello!');
      expect(assistant.endCallMessage, 'Goodbye!');
      expect(assistant.metadata, {'key': 'value'});
      expect(assistant.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(assistant.updatedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
    });

    test('fromJson should parse PascalCase JSON correctly', () {
      final json = {
        'id': 'ast_456',
        'Name': 'Pascal Assistant',
        'Description': 'Pascal case test',
        'FirstMessage': 'Hi there!',
        'EndCallMessage': 'See you!',
        'Metadata': {'type': 'test'},
        'CreatedAt': '2024-01-01T00:00:00.000Z',
        'UpdatedAt': '2024-01-02T00:00:00.000Z',
      };

      final assistant = AssistantModel.fromJson(json);

      expect(assistant.id, 'ast_456');
      expect(assistant.name, 'Pascal Assistant');
      expect(assistant.description, 'Pascal case test');
      expect(assistant.firstMessage, 'Hi there!');
      expect(assistant.endCallMessage, 'See you!');
      expect(assistant.metadata, {'type': 'test'});
      expect(assistant.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(assistant.updatedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
    });

    test('fromJson should handle null optional fields', () {
      final json = {
        'id': 'ast_789',
        'name': 'Minimal Assistant',
      };

      final assistant = AssistantModel.fromJson(json);

      expect(assistant.id, 'ast_789');
      expect(assistant.name, 'Minimal Assistant');
      expect(assistant.description, isNull);
      expect(assistant.firstMessage, isNull);
      expect(assistant.endCallMessage, isNull);
      expect(assistant.metadata, isNull);
      expect(assistant.createdAt, isNull);
      expect(assistant.updatedAt, isNull);
    });

    test('toJson should include all non-null fields', () {
      final assistant = AssistantModel(
        id: 'ast_123',
        name: 'Test Assistant',
        description: 'A test',
        firstMessage: 'Hello',
        endCallMessage: 'Goodbye',
        metadata: {'key': 'value'},
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = assistant.toJson();

      expect(json['id'], 'ast_123');
      expect(json['name'], 'Test Assistant');
      expect(json['description'], 'A test');
      expect(json['firstMessage'], 'Hello');
      expect(json['endCallMessage'], 'Goodbye');
      expect(json['metadata'], {'key': 'value'});
      expect(json['createdAt'], '2024-01-01T00:00:00.000Z');
      expect(json['updatedAt'], '2024-01-02T00:00:00.000Z');
    });

    test('toJson should exclude null fields', () {
      const assistant = AssistantModel(
        id: 'ast_minimal',
        name: 'Minimal',
      );

      final json = assistant.toJson();

      expect(json['id'], 'ast_minimal');
      expect(json['name'], 'Minimal');
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('firstMessage'), isFalse);
      expect(json.containsKey('endCallMessage'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
    });

    test('copyWith should update specified fields', () {
      const original = AssistantModel(
        id: 'ast_original',
        name: 'Original Name',
        description: 'Original Description',
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        firstMessage: 'Hello!',
      );

      expect(updated.id, 'ast_original');
      expect(updated.name, 'Updated Name');
      expect(updated.description, 'Original Description');
      expect(updated.firstMessage, 'Hello!');
    });

    test('equality should work correctly', () {
      const assistant1 = AssistantModel(
        id: 'ast_1',
        name: 'Assistant 1',
        description: 'Test',
      );

      const assistant2 = AssistantModel(
        id: 'ast_1',
        name: 'Assistant 1',
        description: 'Test',
      );

      const assistant3 = AssistantModel(
        id: 'ast_2',
        name: 'Assistant 2',
        description: 'Different',
      );

      expect(assistant1, equals(assistant2));
      expect(assistant1 == assistant3, isFalse);
    });

    test('hashCode should be consistent', () {
      const assistant1 = AssistantModel(
        id: 'ast_1',
        name: 'Assistant 1',
        description: 'Test',
      );

      const assistant2 = AssistantModel(
        id: 'ast_1',
        name: 'Assistant 1',
        description: 'Test',
      );

      expect(assistant1.hashCode, equals(assistant2.hashCode));
    });

    test('toString should return formatted string', () {
      const assistant = AssistantModel(
        id: 'ast_123',
        name: 'Test Assistant',
      );

      final str = assistant.toString();

      expect(str, contains('ast_123'));
      expect(str, contains('Test Assistant'));
    });
  });
}
