# Event Store

## Description

This is a singleton service to log events into a Firebase Firestore database. Can also log events
locally into the console with different log levels (debug, info, warning, error, trace).

**Features:**
- 🔥 Firebase Firestore integration for remote logging
- 📝 Local console logging with structured JSON format
- ⚙️ Comprehensive configuration options
- 🔄 Automatic retry logic for failed network requests
- 🎯 Minimum log level filtering
- 🌍 Global parameters for all log entries
- 🚨 Global error handling callbacks
- 🔐 Configurable user information inclusion
- 🎭 Async and sync logging methods

## Installation

To install the event store, you can use the following command:

```bash
flutter pub add monikode_event_store
```

## Configuration

EventStore can be configured using the `EventStoreConfig` class, which provides comprehensive control over logging behavior.

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `collectionName` | String | "logs" | Firestore collection name for storing logs |
| `enableRemoteLogging` | bool | true | Enable/disable Firebase Firestore logging |
| `enableLocalLogging` | bool | true | Enable/disable console logging |
| `maxRetries` | int | 3 | Maximum retry attempts for failed remote logging |
| `retryDelayMs` | int | 1000 | Delay between retries in milliseconds |
| `onError` | Function? | null | Global error callback for logging failures |
| `includeUserInfo` | bool | true | Include user ID and email in logs |
| `globalParameters` | Map? | null | Parameters added to every log entry |
| `minimumLogLevel` | EventLevel | debug | Minimum log level to record |
| `enableBatchMode` | bool | false | Enable batch logging to reduce write operations |
| `batchSize` | int | 10 | Max logs per batch before auto-flush |
| `batchTimeoutMs` | int | 5000 | Max time before auto-flush (milliseconds) |

### Basic Configuration

```dart
import 'package:monikode_event_store/monikode_event_store.dart';

// Simple configuration with just a custom collection name
var instance = EventStore.getInstance(collectionName: 'my_logs');
```

### Advanced Configuration

```dart
var instance = EventStore.getInstance(
  config: EventStoreConfig(
    collectionName: 'production_logs',
    enableRemoteLogging: true,
    enableLocalLogging: true,
    maxRetries: 5,
    retryDelayMs: 2000,
    minimumLogLevel: EventLevel.info, // Only log info, warning, and error
    includeUserInfo: true,
    globalParameters: {
      'app_version': '1.0.0',
      'environment': 'production',
      'platform': 'mobile',
    },
    onError: (eventName, error) {
      // Handle logging errors globally
      print('Failed to log $eventName: $error');
      // You could send this to an error tracking service
    },
  ),
);
```

### Privacy-Focused Configuration

```dart
// For privacy-sensitive applications, disable user info collection
var instance = EventStore.getInstance(
  config: EventStoreConfig(
    includeUserInfo: false,
    globalParameters: {
      'session_id': generateSessionId(), // Use anonymous session ID instead
    },
  ),
);
```

### Development vs Production

```dart
// Development: Enable all logging
var devConfig = EventStoreConfig(
  enableRemoteLogging: true,
  enableLocalLogging: true,
  minimumLogLevel: EventLevel.debug,
);

// Production: Reduce noise, disable debug logs
var prodConfig = EventStoreConfig(
  enableRemoteLogging: true,
  enableLocalLogging: false, // Disable console logs in production
  minimumLogLevel: EventLevel.info, // Skip debug and trace logs
  maxRetries: 5, // More retries for production
);

var instance = EventStore.getInstance(
  config: isProduction ? prodConfig : devConfig,
);
```

### Local-Only Logging

```dart
// Useful for testing or offline mode
var instance = EventStore.getInstance(
  config: EventStoreConfig(
    enableRemoteLogging: false,
    enableLocalLogging: true,
  ),
);
```

## Usage

To use the event store, you need to import the package in your file:

```dart
import 'package:monikode_event_store/monikode_event_store.dart';
```

### Log Levels

EventStore supports five log levels, ordered by severity:

1. **debug** - Detailed debugging information
2. **trace** - Trace execution flow
3. **info** - General informational messages
4. **warning** - Warning messages
5. **error** - Error messages

### Basic Usage with Error Handling

Get the singleton instance and log events asynchronously:

```dart
var instance = EventStore.getInstance();

// Log an event and handle the result
final result = await instance.eventLogger.log(
  "user_login",
  EventLevel.info,
  {
    "login_method": "email",
    "timestamp": DateTime.now().toString(),
  },
);

// Check if logging was successful
if (result.success) {
  print('Event logged successfully!');
} else {
  print('Failed to log event: ${result.error}');
}
```

### Simple Usage (Fire and Forget)

If you don't need to check the result:

```dart
var instance = EventStore.getInstance();
await instance.eventLogger.log("login", EventLevel.info, {
  "custom_parameter": "custom_value",
});
```

### Synchronous Logging (Non-Async Functions)

If you're in a non-async function and can't use `await`, use `logSync()`:

```dart
var instance = EventStore.getInstance();

// Simple fire-and-forget
instance.eventLogger.logSync("button_click", EventLevel.info, {
  "button_id": "submit",
});

// With callback to handle the result
instance.eventLogger.logSync(
  "user_action",
  EventLevel.info,
  {"action": "tap"},
  onComplete: (result) {
    if (!result.success) {
      print('Failed to log: ${result.error}');
    }
  },
);
```

**Note:** `logSync()` is useful for:
- Widget builders and constructors
- Non-async event handlers
- Places where you can't use async/await
- Fire-and-forget logging scenarios

### Using Different Log Levels

```dart
var logger = EventStore.getInstance().eventLogger;

// Debug information
await logger.log("debug_info", EventLevel.debug, {"detail": "value"});

// Trace execution
await logger.log("method_called", EventLevel.trace, {"method": "fetchData"});

// Informational
await logger.log("user_action", EventLevel.info, {"action": "click"});

// Warnings
await logger.log("api_slow", EventLevel.warning, {"duration": "5s"});

// Errors
await logger.log("api_failed", EventLevel.error, {
  "error": "timeout",
  "endpoint": "/api/data"
});
```

### Global Error Handling

Configure a global error handler to catch all logging failures:

```dart
var instance = EventStore.getInstance(
  config: EventStoreConfig(
    onError: (eventName, error) {
      // Send to error tracking service
      ErrorTracker.logError('EventStore failed for $eventName: $error');
      // Or show user notification
      showSnackbar('Failed to log event');
    },
  ),
);
```

### Batch Logging (Reduce Firestore Costs by 90%!)

Enable batch mode to group multiple log entries into a single Firestore write operation. This dramatically reduces costs and improves performance for high-volume logging.

**How it works:**
- Logs are queued in memory instead of written immediately
- Batch is automatically flushed when it reaches `batchSize` OR after `batchTimeoutMs`
- You can also manually flush with `flushBatch()`

```dart
var instance = EventStore.getInstance(
  config: EventStoreConfig(
    enableBatchMode: true,
    batchSize: 10,           // Flush after 10 logs
    batchTimeoutMs: 5000,    // Or after 5 seconds, whichever comes first
  ),
);

// Log events normally - they'll be batched automatically
await instance.eventLogger.log("event1", EventLevel.info, {"data": "1"});
await instance.eventLogger.log("event2", EventLevel.info, {"data": "2"});
await instance.eventLogger.log("event3", EventLevel.info, {"data": "3"});

// Manually flush the batch if needed (e.g., before app closes)
await instance.eventLogger.flushBatch();
```

**Benefits:**
- 💰 **Save up to 90% on Firestore costs** - 10 logs = 1 write operation
- ⚡ **Better performance** - Less network overhead
- 📊 **Perfect for high-volume apps** - Analytics, tracking, etc.

**When to use:**
- ✅ Apps with frequent logging (analytics, user tracking)
- ✅ Non-critical logs that can be delayed slightly
- ✅ Cost-sensitive applications

**When NOT to use:**
- ❌ Critical error logging that must be immediate
- ❌ Low-volume apps (won't see significant savings)

**Important:** Always call `flushBatch()` before app termination to ensure queued logs are written:

```dart
@override
void dispose() {
  // Flush any pending logs before closing
  EventStore.getInstance().eventLogger.flushBatch();
  super.dispose();
}
```

### Custom Collection Name

You can specify a custom collection name when getting the instance for the first time:

```dart
// First call - creates instance with custom collection name
var instance = EventStore.getInstance(collectionName: 'my_custom_logs');

// All subsequent calls return the same instance
var sameInstance = EventStore.getInstance(); // Still uses 'my_custom_logs'
```

**Note:** The collection name parameter is only respected on the first call. Subsequent calls will return the existing singleton instance.

### Local Logging Only

For debugging purposes, you can use just the local event logger:

```dart
var instance = EventStore.getInstance();
instance.localEventStore.log("debug_event", EventLevel.debug, {
  "debug_info": "some value",
});
```

### Resetting the Singleton (Testing)

For testing purposes, you can reset the singleton:

```dart
EventStore.reset(); // Clears the singleton instance

// Now you can create a new instance with different configuration
var newInstance = EventStore.getInstance(
  config: EventStoreConfig(
    collectionName: 'test_logs',
  ),
);
```

## Complete Examples

### Example 1: E-commerce App

```dart
// Initialize with app metadata
final store = EventStore.getInstance(
  config: EventStoreConfig(
    collectionName: 'ecommerce_events',
    globalParameters: {
      'app_version': '2.1.0',
      'store_id': 'store_123',
    },
    minimumLogLevel: EventLevel.info,
  ),
);

// Track purchase
await store.eventLogger.log("purchase", EventLevel.info, {
  "product_id": "prod_456",
  "amount": 99.99,
  "currency": "USD",
  "payment_method": "credit_card",
});

// Track errors
await store.eventLogger.log("payment_failed", EventLevel.error, {
  "reason": "insufficient_funds",
  "amount": 99.99,
});
```

### Example 2: Analytics Dashboard

```dart
// Production configuration
final store = EventStore.getInstance(
  config: EventStoreConfig(
    collectionName: 'analytics',
    enableLocalLogging: false, // No console spam in production
    minimumLogLevel: EventLevel.info,
    maxRetries: 5,
    retryDelayMs: 2000,
    globalParameters: {
      'app_name': 'MyApp',
      'version': '1.0.0',
      'build': '42',
    },
    onError: (eventName, error) {
      // Report to error tracking service
      Sentry.captureMessage('Analytics event failed: $eventName');
    },
  ),
);

// Track page views
store.eventLogger.logSync("page_view", EventLevel.info, {
  "page": "/dashboard",
  "referrer": "/login",
});

// Track feature usage
await store.eventLogger.log("feature_used", EventLevel.info, {
  "feature": "export_csv",
  "items_count": 1500,
});
```

### Example 3: Debugging & Development

```dart
// Development configuration with maximum visibility
final store = EventStore.getInstance(
  config: EventStoreConfig(
    collectionName: 'dev_logs',
    enableRemoteLogging: false, // Don't pollute production database
    enableLocalLogging: true,   // See everything in console
    minimumLogLevel: EventLevel.debug, // Log everything
  ),
);

// Debug logging
await store.eventLogger.log("api_request", EventLevel.debug, {
  "endpoint": "/api/users",
  "method": "GET",
  "headers": {"Authorization": "Bearer ***"},
});

await store.eventLogger.log("api_response", EventLevel.debug, {
  "status": 200,
  "duration_ms": 245,
  "data_size": 1024,
});
```

### Example 4: Privacy-Compliant Logging

```dart
// GDPR-compliant configuration
final store = EventStore.getInstance(
  config: EventStoreConfig(
    collectionName: 'anonymous_events',
    includeUserInfo: false, // Don't log user ID or email
    globalParameters: {
      'session_id': generateAnonymousSessionId(),
      'region': 'EU',
    },
  ),
);

// All logs will be anonymous
await store.eventLogger.log("feature_accessed", EventLevel.info, {
  "feature": "settings",
  "timestamp": DateTime.now().toIso8601String(),
});
```

### Example 5: Offline-First App

```dart
// Configure with retries for spotty connectivity
final store = EventStore.getInstance(
  config: EventStoreConfig(
    maxRetries: 10,
    retryDelayMs: 3000,
    onError: (eventName, error) {
      // Queue for later retry or show offline indicator
      offlineQueue.add(eventName);
    },
  ),
);

// Will retry up to 10 times if network is unavailable
await store.eventLogger.log("user_action", EventLevel.info, {
  "action": "create_note",
  "note_length": 150,
});
```

## API Reference

### EventStoreConfig

Constructor parameters for configuring EventStore behavior.

### EventStore

Singleton class that provides access to logging functionality.

**Methods:**
- `static EventStore getInstance({EventStoreConfig? config, String? collectionName})` - Get singleton instance
- `static void reset()` - Reset singleton (for testing)

**Properties:**
- `eventLogger` - Remote and local event logger
- `localEventStore` - Local-only event logger
- `config` - Current configuration

### EventLogger

Handles logging to Firebase Firestore and local console.

**Methods:**
- `Future<LogResult> log(String eventName, EventLevel level, Map<String, dynamic> parameters)` - Async logging
- `void logSync(String eventName, EventLevel level, Map<String, dynamic> parameters, {Function(LogResult)? onComplete})` - Sync logging

### LocalEventLogger

Handles local console logging only.

**Methods:**
- `void log(String eventName, EventLevel level, Map<String, dynamic> parameters, {String? userId})` - Log to console

### LogResult

Result object returned from logging operations.

**Properties:**
- `bool success` - Whether the operation succeeded
- `String? error` - Error message if failed

**Methods:**
- `factory LogResult.success()` - Create success result
- `factory LogResult.failure(String errorMessage)` - Create failure result

### EventLevel

Enum for log severity levels.

**Values:**
- `EventLevel.debug` - Debug information (lowest priority)
- `EventLevel.trace` - Trace execution flow
- `EventLevel.info` - Informational messages
- `EventLevel.warning` - Warning messages
- `EventLevel.error` - Error messages (highest priority)

## Best Practices

1. **Use appropriate log levels**: Reserve `error` for actual errors, `info` for business events, `debug` for development
2. **Configure minimum log level in production**: Set to `EventLevel.info` or higher to reduce noise
3. **Add global parameters**: Include app version, environment, and other context in every log
4. **Handle errors gracefully**: Use `onError` callback for global error handling
5. **Test with retries**: Configure appropriate retry settings based on your network conditions
6. **Respect user privacy**: Disable `includeUserInfo` for sensitive applications
7. **Use logSync for non-async contexts**: But prefer async `log()` when possible for better error handling
8. **Reset in tests**: Always call `EventStore.reset()` before each test

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.