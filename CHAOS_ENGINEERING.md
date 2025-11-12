# Chaos Engineering - Backend-Driven Tool Binding

This document outlines chaos engineering safeguards implemented in the backend-driven tool binding system to handle failure scenarios gracefully.

## Overview

The voivi_chat package implements multiple layers of protection against common failure modes in distributed systems, ensuring robust operation even under adverse conditions.

## Implemented Safeguards

### 1. Network & API Failures

#### VoiviApiService.fetchClientTools()
**Location:** `lib/src/services/voivi_api_service.dart:173-257`

**Safeguards:**
- ✅ **30-second timeout** - Prevents indefinite hanging on slow networks
- ✅ **HTTP error code handling** - 401 Unauthorized, 403 Forbidden, 4xx/5xx errors
- ✅ **Malformed JSON protection** - try-catch around JSON parsing
- ✅ **Empty response handling** - Gracefully returns empty list if no tools
- ✅ **Individual tool parsing errors** - Skips invalid tools, continues with valid ones

**Test Scenarios:**
```dart
// Scenario 1: Network timeout
// Expected: TimeoutException after 30s, error logged
await apiService.fetchClientTools(...); // on slow network

// Scenario 2: Backend returns 401 Unauthorized
// Expected: Exception('Unauthorized: Invalid API key')
await apiService.fetchClientTools(apiKey: 'invalid');

// Scenario 3: Backend returns malformed JSON
// Expected: FormatException caught, error logged, rethrow
// Backend responds with: {"invalid": json}

// Scenario 4: Backend returns empty tools list
// Expected: Returns empty List<ClientToolDefinition>
// Backend responds with: []

// Scenario 5: Some tools have invalid schema
// Expected: Invalid tools skipped, valid tools returned
// Backend returns mix of valid and invalid tool definitions
```

### 2. Tool Execution Failures

#### ToolRegistry.execute()
**Location:** `lib/src/services/tool_registry_service.dart:67-151`

**Safeguards:**
- ✅ **30-second execution timeout** - Prevents hanging on long-running tools
- ✅ **Null arguments protection** - Defaults to empty map if args is null
- ✅ **Tool not found validation** - Clear error message with available tools list
- ✅ **Result type validation** - Warns if tool returns null
- ✅ **Execution time monitoring** - Warns if tool takes >10 seconds
- ✅ **Error classification** - TimeoutException, FormatException, generic Exception
- ✅ **Stack trace logging** - Full error context for debugging

**Test Scenarios:**
```dart
// Scenario 1: Tool execution timeout
// Expected: TimeoutException after 30s
registry.register('slow_tool', (args) async {
  await Future.delayed(Duration(seconds: 35)); // Exceeds timeout
  return {};
});

// Scenario 2: Tool throws exception
// Expected: Exception caught, logged with stack trace, rethrown with context
registry.register('error_tool', (args) async {
  throw Exception('Something went wrong');
});

// Scenario 3: Tool returns null
// Expected: Warning logged, null returned
registry.register('null_tool', (args) async => null);

// Scenario 4: Tool takes long but within timeout
// Expected: Warning logged for >10s execution
registry.register('slow_but_ok', (args) async {
  await Future.delayed(Duration(seconds: 15));
  return {};
});

// Scenario 5: Tool not registered
// Expected: Exception with available tools list
await registry.execute('nonexistent_tool', {});

// Scenario 6: Null arguments passed
// Expected: Defaults to empty map, executes normally
await registry.execute('some_tool', null);
```

### 3. WebSocket Communication Failures

#### WebSocketService._handleToolExecutionRequest()
**Location:** `lib/src/services/websocket_service.dart:303-374`

**Safeguards:**
- ✅ **Required field validation** - toolCallId and toolName checked
- ✅ **Empty string validation** - Rejects empty toolCallId/toolName
- ✅ **Tool registry availability check** - Validates registry is set
- ✅ **Tool bound check** - Validates tool has handler before execution
- ✅ **Error response for fallback** - Backend can fallback to HTTP tool if client fails
- ✅ **Execution error handling** - Sends error result to backend

**Test Scenarios:**
```dart
// Scenario 1: Missing toolCallId
// Expected: Error logged, no response sent
_handleToolExecutionRequest({'toolName': 'test'});

// Scenario 2: Empty toolCallId
// Expected: Error logged, no response sent
_handleToolExecutionRequest({'toolCallId': '', 'toolName': 'test'});

// Scenario 3: Missing toolName
// Expected: Error response sent to backend
_handleToolExecutionRequest({'toolCallId': '123'});

// Scenario 4: Tool registry not set
// Expected: Error response sent, logged
_handleToolExecutionRequest({'toolCallId': '123', 'toolName': 'test'});
// (with _toolRegistry = null)

// Scenario 5: Tool not bound
// Expected: Warning logged, error response sent for backend fallback
_handleToolExecutionRequest({'toolCallId': '123', 'toolName': 'unbound_tool'});

// Scenario 6: Tool execution fails
// Expected: Error caught, error result sent to backend
// Tool throws exception during execution
```

## Failure Mode Matrix

| Failure Mode | Component | Detection | Recovery | Impact |
|--------------|-----------|-----------|----------|--------|
| Network timeout | VoiviApiService | 30s timeout | Exception thrown, retry possible | Tool list not fetched |
| Invalid API key | VoiviApiService | 401 status | Exception thrown | Cannot fetch tools |
| Malformed JSON | VoiviApiService | JSON parse error | Skip invalid, continue | Some tools not available |
| Tool timeout | ToolRegistry | 30s timeout | TimeoutException | Tool call fails, backend fallback |
| Tool exception | ToolRegistry | try-catch | Exception logged/rethrown | Tool call fails, backend fallback |
| Missing toolCallId | WebSocketService | Null check | Early return | No action taken |
| Tool not bound | WebSocketService | Registry check | Error to backend | Backend uses HTTP tool |
| WebSocket disconnect | WebSocketService | Stream close | Reconnection logic | Message queue, retry |

## Testing Recommendations

### Unit Tests

```dart
// test/services/tool_registry_test.dart
test('Tool execution timeout', () async {
  final registry = ToolRegistry();
  registry.register('slow', (args) => Future.delayed(Duration(seconds: 35)));

  expect(
    () => registry.execute('slow', {}),
    throwsA(isA<TimeoutException>()),
  );
});

test('Null arguments default to empty map', () async {
  final registry = ToolRegistry();
  registry.register('test', (args) async {
    expect(args, isNotNull);
    expect(args, isA<Map<String, dynamic>>());
    return {'ok': true};
  });

  await registry.execute('test', null);
});
```

### Integration Tests

```dart
// integration_test/chaos_engineering_test.dart
testWidgets('Network failure during tool fetch', (tester) async {
  // Simulate network failure
  final mockClient = MockHttpClient();
  when(mockClient.get(any)).thenThrow(SocketException('Network error'));

  final apiService = VoiviApiService(client: mockClient);

  expect(
    () => apiService.fetchClientTools(...),
    throwsA(isA<SocketException>()),
  );
});

testWidgets('Backend returns partial tool list', (tester) async {
  // Backend returns mix of valid/invalid tools
  final response = '''[
    {"id": "1", "name": "valid_tool", "type": "InProcess", ...},
    {"id": "2", "invalid": "missing required fields"},
    {"id": "3", "name": "another_valid", "type": "InProcess", ...}
  ]''';

  final tools = await apiService.fetchClientTools(...);

  // Should get 2 valid tools, skip 1 invalid
  expect(tools.length, 2);
});
```

### Manual Chaos Testing

1. **Network Chaos:**
   ```bash
   # Simulate slow network (macOS)
   sudo pfctl -e
   sudo dnctl pipe 1 config delay 5000 # 5s delay
   sudo pfctl -f /etc/pf.conf

   # Test fetchClientTools() with 5s delay
   # Expected: Still works, but slower

   # Increase delay to 35s
   # Expected: Timeout after 30s
   ```

2. **Backend Chaos:**
   ```bash
   # Return 500 Internal Server Error
   # Expected: Exception with error message

   # Return invalid JSON
   # Expected: FormatException, logged and rethrown

   # Close connection mid-response
   # Expected: SocketException or HttpException
   ```

3. **Tool Handler Chaos:**
   ```dart
   // Register intentionally failing tool
   engine.bindToolHandler('chaos_tool', (args) async {
     if (Random().nextBool()) {
       throw Exception('Random failure');
     }
     await Future.delayed(Duration(seconds: Random().nextInt(35)));
     return {'result': 'success'};
   });

   // Execute multiple times
   // Expected: Sometimes succeeds, sometimes fails, sometimes times out
   ```

## Monitoring & Alerting

### Key Metrics to Monitor

1. **Tool Execution Time**
   - p50: < 1s
   - p95: < 5s
   - p99: < 10s
   - Max: 30s (timeout)

2. **Tool Success Rate**
   - Target: > 95%
   - Alert: < 90%

3. **API Request Time (fetchClientTools)**
   - p50: < 500ms
   - p95: < 2s
   - p99: < 10s
   - Max: 30s (timeout)

4. **Error Rates**
   - Timeout errors: < 5%
   - Execution errors: < 10%
   - Network errors: < 5%

### Log Patterns for Debugging

```dart
// Tool timeout pattern
'⏱️ [TOOL REGISTRY] Tool execution timeout: <toolName> after 30s'

// Tool not bound pattern
'⚠️ [TOOL WARNING] Tool not bound on client: <toolName>. Backend may fallback'

// Network timeout pattern
'Fetch client tools timed out after 30s'

// Invalid tool definition pattern
'⚠️ Skipping invalid tool definition: <error>'
```

## Best Practices for Tool Implementations

### ✅ DO:

```dart
// 1. Set realistic timeouts
engine.bindToolHandler('api_call', (args) async {
  return await http.get(url).timeout(Duration(seconds: 10));
});

// 2. Handle errors gracefully
engine.bindToolHandler('location', (args) async {
  try {
    final pos = await Geolocator.getCurrentPosition();
    return {'lat': pos.latitude, 'lng': pos.longitude};
  } catch (e) {
    return {'error': 'Location permission denied', 'code': 'PERMISSION_DENIED'};
  }
});

// 3. Return meaningful results
engine.bindToolHandler('device_info', (args) async {
  return {
    'platform': Platform.operatingSystem,
    'version': Platform.operatingSystemVersion,
    'success': true,
  };
});

// 4. Validate input parameters
engine.bindToolHandler('calculate', (args) async {
  final a = args['a'] as int?;
  final b = args['b'] as int?;

  if (a == null || b == null) {
    return {'error': 'Parameters a and b are required'};
  }

  return {'result': a + b};
});
```

### ❌ DON'T:

```dart
// 1. Don't create infinite loops
engine.bindToolHandler('bad', (args) async {
  while (true) { // Will timeout after 30s
    await Future.delayed(Duration(seconds: 1));
  }
});

// 2. Don't ignore errors
engine.bindToolHandler('bad', (args) async {
  await riskyOperation(); // No try-catch, will crash
});

// 3. Don't return null without reason
engine.bindToolHandler('bad', (args) async {
  return null; // Warning will be logged
});

// 4. Don't perform blocking operations
engine.bindToolHandler('bad', (args) async {
  sleep(Duration(seconds: 10)); // Blocks thread
  return {};
});
```

## Conclusion

The backend-driven tool binding system is designed with multiple layers of protection:

1. **Network Layer:** Timeouts, retry logic, error classification
2. **Execution Layer:** Timeouts, error handling, validation
3. **Communication Layer:** Field validation, fallback mechanisms

These safeguards ensure the system remains operational even when:
- Network is slow or unavailable
- Backend returns errors or malformed data
- Tools fail or timeout
- WebSocket connection is unstable

By following the best practices and monitoring key metrics, you can maintain a robust and reliable tool execution system.

---

**Last Updated:** 2025-11-12
**Version:** 1.2.0
**Related:** Backend-Driven Tool Binding (Phase 3)
