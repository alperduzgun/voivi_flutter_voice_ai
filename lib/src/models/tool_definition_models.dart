import 'dart:developer' as developer;

import 'package:meta/meta.dart';

/// Tool parameter definition
@immutable
class ToolParameter {
  const ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
  });

  factory ToolParameter.fromJson(Map<String, dynamic> json) {
    return ToolParameter(
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      required: json['required'] as bool? ?? false,
    );
  }

  /// Parameter name
  final String name;

  /// Parameter type (string, number, boolean, object, array)
  final String type;

  /// Parameter description
  final String description;

  /// Whether this parameter is required
  final bool required;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'description': description,
        'required': required,
      };

  @override
  String toString() {
    return 'ToolParameter(name: $name, type: $type, required: $required)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolParameter &&
        other.name == name &&
        other.type == type &&
        other.required == required;
  }

  @override
  int get hashCode => Object.hash(name, type, required);
}

/// Client-side tool definition from backend
@immutable
class ClientToolDefinition {
  const ClientToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.parameters = const [],
    this.requiredPermissions,
    this.executionLocation = 'client',
    this.timeoutSeconds = 10,
  });

  factory ClientToolDefinition.fromJson(Map<String, dynamic> json) {
    try {
      // Parse parameters if present
      final paramsList = json['parameters'] as List? ?? [];
      final parameters = paramsList
          .map((p) => ToolParameter.fromJson(p as Map<String, dynamic>))
          .toList();

      // Get execution location from customConfig if InProcess tool
      String executionLocation = 'client';
      int timeoutSeconds = 10;

      if (json['type'] == 'InProcess' && json['customConfig'] != null) {
        final customConfig = json['customConfig'] as Map<String, dynamic>;
        executionLocation = customConfig['executionLocation'] as String? ?? 'client';
        timeoutSeconds = customConfig['timeoutSeconds'] as int? ?? 10;
      }

      return ClientToolDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        parameters: parameters,
        requiredPermissions: json['requiredPermissions'] as String?,
        executionLocation: executionLocation,
        timeoutSeconds: timeoutSeconds,
      );
    } catch (e) {
      developer.log('❌ Error parsing ClientToolDefinition: $e');
      rethrow;
    }
  }

  /// Tool ID from backend
  final String id;

  /// Tool name (handler name)
  final String name;

  /// Tool description
  final String description;

  /// Tool category (e.g., 'user', 'device', 'media')
  final String category;

  /// Tool parameters
  final List<ToolParameter> parameters;

  /// Required permissions (e.g., 'camera', 'location', 'storage')
  final String? requiredPermissions;

  /// Execution location (should be 'client' for client-side tools)
  final String executionLocation;

  /// Timeout in seconds
  final int timeoutSeconds;

  /// Check if tool requires specific permission
  bool requiresPermission(String permission) {
    return requiredPermissions?.contains(permission) ?? false;
  }

  /// Get parameter by name
  ToolParameter? getParameter(String name) {
    try {
      return parameters.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Check if all required parameters are present in args
  bool validateParameters(Map<String, dynamic> args) {
    for (final param in parameters) {
      if (param.required && !args.containsKey(param.name)) {
        developer.log(
          '⚠️ Missing required parameter: ${param.name} for tool: $name',
        );
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        if (requiredPermissions != null)
          'requiredPermissions': requiredPermissions,
        'executionLocation': executionLocation,
        'timeoutSeconds': timeoutSeconds,
      };

  @override
  String toString() {
    return 'ClientToolDefinition(name: $name, category: $category, params: ${parameters.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientToolDefinition &&
        other.id == id &&
        other.name == name &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(id, name, category);
}
