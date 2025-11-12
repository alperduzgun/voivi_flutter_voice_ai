# Voivi Chat Example App

A comprehensive Flutter application demonstrating all features of the `voivi_chat` package.

## Features

### 🎯 Dashboard
- Environment switcher (localhost ⇄ production)
- Configuration overview
- Quick actions

### 🤖 Assistant Management
- List all assistants from backend
- View assistant details
- Select assistant for chat

### 💬 Real-time Chat
- WebSocket-based messaging
- Connect to any assistant
- Send and receive messages
- Message history with timestamps
- Connection status indicator

### 🔧 Tool Testing
- Test client-side tool execution
- View execution results
- Monitor performance (execution time)
- Three example tools:
  - `get_random_number`: Generate random numbers
  - `calculate_sum`: Calculate sum of array
  - `get_app_info`: Get app metadata

### 📋 Debug Logs
- Real-time log viewer
- Color-coded log levels
- Timestamp tracking

## Quick Start

### 1. Prerequisites

Ensure the Voivi backend is running:
```bash
# Backend should be running on localhost:5065
# Check if it's accessible:
curl http://localhost:5065/api/assistants
```

### 2. Run the Example App

```bash
cd packages/voivi_chat/example
flutter pub get
flutter run
```

### 3. Test the Features

#### Test Assistant List:
1. Navigate to **Assistants** tab
2. Tap refresh button
3. View available assistants
4. Tap on an assistant to see details

#### Test Chat:
1. Navigate to **Chat** tab
2. Enter an assistant ID
3. Tap **Connect**
4. Send messages and receive responses

#### Test Tools:
1. Navigate to **Tools** tab
2. Tap play button on any tool
3. View execution results

## Configuration

The app automatically connects to:

### Localhost (Development)
- **Base URL**: `http://localhost:5065`
- **WebSocket URL**: `ws://localhost:5065`
- **Organization ID**: `68331233c2295b8ea205994f`
- **API Key**: `421e0d1da2b2460a9b008568d2ebd929`

### Production
- **Base URL**: `https://voivi-engineering.azurewebsites.net`
- **WebSocket URL**: `wss://voivi-engineering.azurewebsites.net`

Toggle between environments using the cloud/computer icon in the app bar.

## Testing Client-Side Tools

The example app includes 3 pre-registered tools:

### 1. get_random_number
```dart
// Test in Tools tab or use in chat:
"Generate a random number between 1 and 50"
```

**Expected response**:
```json
{
  "success": true,
  "randomNumber": 42,
  "min": 1,
  "max": 50,
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### 2. calculate_sum
```dart
// Test in Tools tab or use in chat:
"Calculate the sum of 10, 20, 30, 40, 50"
```

**Expected response**:
```json
{
  "success": true,
  "sum": 150,
  "count": 5,
  "numbers": [10, 20, 30, 40, 50],
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### 3. get_app_info
```dart
// Test in Tools tab or use in chat:
"What's the app information?"
```

**Expected response**:
```json
{
  "success": true,
  "appName": "Voivi Chat Example",
  "version": "1.0.0",
  "platform": "Flutter",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## Backend Tool Registration

For tools to work in chat, register them in the Voivi backend as **InProcess** type:

```json
{
  "name": "get_random_number",
  "description": "Generates a random number within a specified range",
  "category": "utility",
  "type": "InProcess",
  "customConfig": {
    "executionLocation": "client",
    "handlerName": "get_random_number",
    "timeoutSeconds": 5
  },
  "parameters": [
    {
      "name": "min",
      "type": "number",
      "description": "Minimum value (default: 1)",
      "required": false
    },
    {
      "name": "max",
      "type": "number",
      "description": "Maximum value (default: 100)",
      "required": false
    }
  ]
}
```

## Architecture

```
example/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── services/
│   │   └── config_service.dart      # Configuration management
│   └── screens/
│       ├── home_screen.dart         # Dashboard & navigation
│       ├── assistant_list_screen.dart  # Assistant management
│       ├── chat_screen.dart         # Real-time chat
│       ├── tool_test_screen.dart    # Tool testing
│       └── logs_screen.dart         # Debug logs
└── pubspec.yaml
```

## Troubleshooting

### Connection Failed
- ✅ Ensure backend is running on `localhost:5065`
- ✅ Check firewall settings
- ✅ Verify API key and organization ID

### No Assistants Found
- ✅ Create assistants in the backend first
- ✅ Check API key permissions
- ✅ Try refreshing the list

### Tool Execution Fails
- ✅ Check if tool is registered in engine
- ✅ Verify tool parameters
- ✅ Check debug logs for errors

## Debug Logging

The app uses Flutter's `debugPrint` for logging. View logs in your IDE console:

```
✅ [TOOL REGISTRY] Registered tool: get_random_number
🚀 [TOOL REGISTRY] Executing tool: get_random_number with args: {min: 1, max: 100}
✅ [TOOL REGISTRY] Tool executed successfully: get_random_number (5ms)
```

## Related Documentation

- [Voivi Chat Package README](../README.md)
- [Chaos Engineering Guide](../CHAOS_ENGINEERING.md)
- [Changelog](../CHANGELOG.md)

## Support

For issues or questions:
- Check the main package documentation
- Review debug logs
- Verify backend connectivity
- Test with curl/Postman first
