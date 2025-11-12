import 'dart:async';
import 'dart:developer' as developer;

import 'package:voivi_voice_ai/src/models/tool_definition_models.dart';

/// Signature for tool handler functions
/// Takes arguments as a Map and returns a Future with the result
typedef ToolHandler = Future<dynamic> Function(Map<String, dynamic> args);

/// Tool Registry for Client-Side Tool Execution
///
/// This service provides a registry for platform-specific tools that can be
/// executed by the AI assistant via WebSocket delegation from the backend.
///
/// Usage:
/// ```dart
/// // Fetch available tools from backend
/// final tools = await engine.fetchClientTools();
///
/// // Bind handlers for tools
/// engine.bindToolHandlers({
///   'get_device_info': (args) async {
///     return {
///       'platform': Platform.operatingSystem,
///       'version': Platform.operatingSystemVersion,
///     };
///   },
///   'get_location': _getLocationHandler,
/// });
///
/// // Backend automatically delegates execution to client when needed
/// ```
class ToolRegistry {
  final Map<String, ToolHandler> _tools = {};
  final List<ClientToolDefinition> _availableTools = [];

  // Timeout for tool execution (chaos engineering safeguard)
  static const Duration _toolExecutionTimeout = Duration(seconds: 30);

  /// Register a tool handler
  ///
  /// [name] - Tool name (must match backend handler name in tool definition)
  /// [handler] - Async function that executes the tool
  void register(String name, ToolHandler handler) {
    if (_tools.containsKey(name)) {
      developer.log(
        '⚠️ [TOOL REGISTRY] Tool already registered, overwriting: $name',
      );
    }

    _tools[name] = handler;
    developer.log('✅ [TOOL REGISTRY] Registered tool: $name');
  }

  /// Unregister a tool handler
  ///
  /// [name] - Tool name to remove
  /// Returns true if tool was found and removed
  bool unregister(String name) {
    final removed = _tools.remove(name) != null;
    if (removed) {
      developer.log('🗑️ [TOOL REGISTRY] Unregistered tool: $name');
    }
    return removed;
  }

  /// Execute a registered tool with chaos engineering safeguards
  ///
  /// [name] - Tool name
  /// [args] - Tool arguments as a Map
  /// Returns the tool execution result
  /// Throws if tool is not found or execution fails
  ///
  /// Chaos Engineering Safeguards:
  /// - 30-second timeout to prevent hanging
  /// - Detailed error classification
  /// - Result type validation
  /// - Execution time monitoring
  Future<dynamic> execute(String name, Map<String, dynamic> args) async {
    developer.log('🚀 [TOOL REGISTRY] Executing tool: $name with args: $args');

    // Safeguard 1: Check if tool exists
    final handler = _tools[name];
    if (handler == null) {
      final availableTools = _tools.keys.join(', ');
      final errorMessage =
          'Tool not found: $name. Available tools: ${availableTools.isEmpty ? 'none' : availableTools}';
      developer.log('❌ [TOOL REGISTRY] $errorMessage');
      throw Exception(errorMessage);
    }

    // Safeguard 2: args is guaranteed non-null by type system
    try {
      final startTime = DateTime.now();

      // Safeguard 3: Execute with timeout to prevent hanging
      final result = await handler(args).timeout(
        _toolExecutionTimeout,
        onTimeout: () {
          developer.log(
            '⏱️ [TOOL REGISTRY] Tool execution timeout: $name after ${_toolExecutionTimeout.inSeconds}s',
          );
          throw TimeoutException(
            'Tool execution timed out after ${_toolExecutionTimeout.inSeconds} seconds',
            _toolExecutionTimeout,
          );
        },
      );

      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // Safeguard 4: Warn if execution took too long (>10s)
      if (duration > 10000) {
        developer.log(
          '⚠️ [TOOL REGISTRY] Tool took longer than expected: $name (${duration}ms)',
        );
      }

      // Safeguard 5: Validate result is not null (tools should return something)
      if (result == null) {
        developer.log(
          '⚠️ [TOOL REGISTRY] Tool returned null: $name. Consider returning empty map instead.',
        );
      }

      developer.log(
        '✅ [TOOL REGISTRY] Tool executed successfully: $name (${duration}ms)',
      );
      developer.log('📦 [TOOL REGISTRY] Result type: ${result.runtimeType}');

      return result;
    } on TimeoutException catch (e) {
      developer.log('⏱️ [TOOL REGISTRY] Tool execution timeout: $name');
      developer.log('❌ [TOOL REGISTRY] Timeout error: $e');
      rethrow;
    } on FormatException catch (e) {
      // Handle JSON parsing errors or format issues
      developer.log('📝 [TOOL REGISTRY] Tool format error: $name');
      developer.log('❌ [TOOL REGISTRY] Format error: $e');
      throw Exception('Tool result format error: ${e.message}');
    } catch (error, stackTrace) {
      developer.log('❌ [TOOL REGISTRY] Tool execution failed: $name');
      developer.log('❌ [TOOL REGISTRY] Error: $error');
      developer.log('📚 [TOOL REGISTRY] Stack trace: $stackTrace');

      // Enhanced error message for debugging
      throw Exception('Tool execution failed: $name - $error');
    }
  }

  /// Check if a tool is registered
  ///
  /// [name] - Tool name
  /// Returns true if the tool is registered
  bool has(String name) {
    return _tools.containsKey(name);
  }

  /// Get list of registered tool names
  ///
  /// Returns a list of all registered tool names
  List<String> getRegisteredTools() {
    return _tools.keys.toList();
  }

  /// Clear all registered tools
  void clear() {
    final count = _tools.length;
    _tools.clear();
    developer.log('🗑️ [TOOL REGISTRY] Cleared $count tools');
  }

  /// Set available tools from backend
  ///
  /// [tools] - List of tool definitions fetched from backend
  void setAvailableTools(List<ClientToolDefinition> tools) {
    _availableTools.clear();
    _availableTools.addAll(tools);
    developer.log(
      '📋 [TOOL REGISTRY] Set ${tools.length} available tools from backend',
    );
  }

  /// Bind a tool handler (alias for register for consistency)
  ///
  /// [name] - Tool name
  /// [handler] - Tool handler function
  void bindToolHandler(String name, ToolHandler handler) {
    register(name, handler);
  }

  /// Bind multiple tool handlers at once
  ///
  /// [handlers] - Map of tool name to handler function
  /// This is the recommended way to bind tools for better code organization
  ///
  /// Example:
  /// ```dart
  /// registry.bindToolHandlers({
  ///   'get_location': _getLocation,
  ///   'get_device_info': _getDeviceInfo,
  /// });
  /// ```
  void bindToolHandlers(Map<String, ToolHandler> handlers) {
    for (final entry in handlers.entries) {
      register(entry.key, entry.value);
    }
    developer.log(
      '✅ [TOOL REGISTRY] Bound ${handlers.length} tool handlers',
    );
  }

  /// Get available tools from backend
  ///
  /// Returns list of tool definitions fetched from backend
  List<ClientToolDefinition> getAvailableTools() {
    return List.unmodifiable(_availableTools);
  }

  /// Get list of unbound tools (tools available in backend but not implemented)
  ///
  /// Returns list of tool names that are available but don't have handlers
  List<String> getUnboundTools() {
    return _availableTools
        .where((tool) => !_tools.containsKey(tool.name))
        .map((tool) => tool.name)
        .toList();
  }

  /// Check if a tool is bound (has a handler registered)
  ///
  /// [name] - Tool name
  /// Returns true if tool has a handler
  bool isToolBound(String name) {
    return _tools.containsKey(name);
  }

  /// Get tool definition by name
  ///
  /// [name] - Tool name
  /// Returns tool definition or null if not found
  ClientToolDefinition? getToolDefinition(String name) {
    try {
      return _availableTools.firstWhere((tool) => tool.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Get count of registered tools
  int get toolCount => _tools.length;

  /// Get count of available tools from backend
  int get availableToolCount => _availableTools.length;

  /// Get count of unbound tools
  int get unboundToolCount => getUnboundTools().length;
}
