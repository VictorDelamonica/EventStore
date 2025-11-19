## 2.2.1

### Dependency Updates
* **Updated `cloud_firestore`** from ^5.6.5 to ^6.1.0
* **Updated `firebase_auth`** from ^5.5.1 to ^6.1.2
* **Updated `firebase_core`** from 3.12.1 to 4.2.1 (transitive)
* **Updated `flutter_lints`** from ^3.0.0 to ^6.0.0
* **Updated `plugin_platform_interface`** from ^2.0.1 to ^2.1.8

### Testing
* All 23 tests passing ✅
* No breaking changes
* Fully compatible with latest Firebase SDK

## 2.2.0

### Major New Features 🎉
* **BATCH LOGGING SUPPORT** - Reduce Firestore costs by up to 90%!
  - New `enableBatchMode` configuration option
  - Configurable `batchSize` (default: 10 logs per batch)
  - Configurable `batchTimeoutMs` (default: 5000ms)
  - Automatic batch flushing when size or timeout is reached
  - New `flushBatch()` method for manual batch flushing
  - Perfect for high-volume logging scenarios

### New Configuration Options
* `enableBatchMode` (bool, default: false) - Enable batch logging
* `batchSize` (int, default: 10) - Maximum logs per batch before auto-flush
* `batchTimeoutMs` (int, default: 5000) - Maximum time before auto-flush

### New Methods
* `EventLogger.flushBatch()` - Manually flush the current batch of logs
  - Returns `Future<LogResult>`
  - Useful before app termination or critical operations

### Performance Improvements
* Batch writes use Firestore's native batch API for atomic operations
* Reduced network overhead for high-volume logging
* Configurable batch size and timeout for different use cases

### Documentation
* Added comprehensive batch logging section to README
* Added batch logging examples
* Updated configuration table with new options
* Added cost-saving calculations and best practices

### Testing
* Added 3 new tests for batch logging configuration
* All 23 tests passing ✅

### Migration Notes
Batch logging is **opt-in** and fully backward compatible:

```dart
// Before (still works, no changes needed)
var store = EventStore.getInstance();

// After (enable batch mode for cost savings)
var store = EventStore.getInstance(
  config: EventStoreConfig(
    enableBatchMode: true,
    batchSize: 10,
    batchTimeoutMs: 5000,
  ),
);

// Don't forget to flush before app closes!
await store.eventLogger.flushBatch();
```

**Recommended for:**
- High-volume logging (analytics, user tracking)
- Cost-sensitive applications
- Apps with frequent log events

**Not recommended for:**
- Critical error logging requiring immediate writes
- Low-volume apps (minimal cost savings)

## 2.1.1

### Critical Bug Fixes
* **CRITICAL:** Removed unused `firebase_database` dependency that was bloating the package
  - Reduces package size and dependency conflicts
  - Package only uses Firestore, not Realtime Database
* **CRITICAL:** Added Firebase initialization safety check
  - Prevents crashes if Firebase.initializeApp() hasn't been called
  - Provides clear error message to help developers debug
* **CRITICAL:** Fixed `EventStoreConfig.copyWith()` null callback bug
  - Can now properly remove `onError` callback by passing `clearOnError: true`
  - Can now properly remove `globalParameters` by passing `clearGlobalParameters: true`

### Improvements
* Added 2 new tests for `copyWith()` functionality
* All 20 tests passing ✅

### Migration Notes
If you need to clear callbacks or global parameters:
```dart
// Before (didn't work)
final newConfig = config.copyWith(onError: null); // Didn't clear

// After (works correctly)
final newConfig = config.copyWith(clearOnError: true);
final newConfig2 = config.copyWith(clearGlobalParameters: true);
```

## 2.1.0

### New Features
* **MAJOR:** Added comprehensive `EventStoreConfig` class with extensive configuration options:
  - `enableRemoteLogging` - Toggle Firebase Firestore logging on/off
  - `enableLocalLogging` - Toggle console logging on/off
  - `maxRetries` - Configure automatic retry attempts for failed remote operations (default: 3)
  - `retryDelayMs` - Set delay between retry attempts (default: 1000ms)
  - `onError` - Global error callback for handling all logging failures
  - `includeUserInfo` - Control whether user ID and email are included (privacy feature)
  - `globalParameters` - Add custom fields to every log entry (e.g., app version, environment)
  - `minimumLogLevel` - Filter logs by severity level
* Added automatic retry logic with configurable attempts and delays for network failures
* Added `copyWith()` method to EventStoreConfig for easy configuration updates
* `EventStore.getInstance()` now accepts full `EventStoreConfig` object
* Backward compatible - still supports legacy `collectionName` parameter

### Breaking Changes
* **EventLevel enum order changed** - Now properly ordered by severity (debug → trace → info → warning → error)
  - This affects the `minimumLogLevel` comparison
  - Migration: Review any code that depends on EventLevel enum order

### Improvements
* Logs below `minimumLogLevel` are now silently skipped (performance optimization)
* Global parameters are automatically merged into all log entries
* Remote logging failures no longer block local logging
* Better privacy controls with `includeUserInfo` flag
* LocalEventLogger now includes global parameters in output (new `@g` field)
* Both `log()` and `logSync()` now respect all configuration settings
* Enhanced error messages with context about which event failed

### Documentation
* Completely rewritten README with comprehensive examples
* Added configuration reference table
* Added 5 real-world usage examples (E-commerce, Analytics, Development, Privacy, Offline)
* Added API Reference section
* Added Best Practices section
* Documented all configuration options with use cases
* Added development vs production configuration examples

### Bug Fixes
* Fixed issue where configuration options were not available
* Local logger now properly respects `enableLocalLogging` setting

## 2.0.0

### Breaking Changes
* **BREAKING:** `EventLogger.log()` is now async and returns `Future<LogResult>` instead of `void`
  - Migration: Add `await` to all `log()` calls and make calling functions `async`

### New Features
* Added `LogResult` class to communicate success/failure of logging operations
* Added comprehensive error handling with try-catch blocks for Firebase operations
* Added Firebase initialization safety checks to prevent crashes
* Added `EventStore.reset()` method for testing (marked with `@visibleForTesting`)
* **NEW:** Added `EventLogger.logSync()` method for synchronous logging from non-async functions
  - Supports fire-and-forget logging
  - Optional callback to receive `LogResult` when operation completes
  - Useful for widget builders, constructors, and non-async event handlers

### Bug Fixes
* **CRITICAL:** Fixed broken singleton pattern - `collectionName` parameter now works correctly on first initialization
* **CRITICAL:** Fixed map mutation bug - no longer modifies user's parameter map
* Fixed hardcoded "user_email" string in LocalEventLogger output
* Fixed JSON formatting in LocalEventLogger output
* Fixed typo: "Tow classes" → "Two classes"

### Improvements
* Changed to server-side timestamps using `FieldValue.serverTimestamp()` for consistency
* Made EventStore fields immutable (`late final`)
* Changed `defaultCollectionName` to `static const`
* Graceful degradation - local logging still works when remote logging fails
* All Firebase Auth helper functions now handle uninitialized Firebase
* Changed LocalEventLogger `userId` parameter to nullable (`String?`)
* Improved error messages with detailed FirebaseException handling
* Removed unused `firebase_database` dependency (package only uses Firestore)
* Improved package description grammar

### Documentation
* Updated README with async/await examples
* Added error handling examples
* Improved API documentation
* Updated example app to demonstrate error handling

### Testing
* Added 3 new tests for LogResult class
* Added 2 new tests for logSync() method
* Updated all tests to handle async methods
* All 11 tests passing ✅

## 1.0.3

* Update local `log`.

## 1.0.2

* Update dependencies versions.

## 1.0.1

* Refactor the EventStore class to pass on a Singleton pattern.

## 1.0.0

* Add the basic for the EventStore class.
