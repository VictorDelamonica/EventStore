import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Configuration options for EventStore.
///
/// Allows customization of logging behavior, including remote and local logging,
/// error handling, and retry policies.
class EventStoreConfig {
  /// The name of the Firestore collection to use for logging.
  final String collectionName;

  /// Whether to enable remote logging to Firebase Firestore.
  /// Default: true
  final bool enableRemoteLogging;

  /// Whether to enable local console logging.
  /// Default: true
  final bool enableLocalLogging;

  /// Maximum number of retry attempts for failed remote logging operations.
  /// Set to 0 to disable retries.
  /// Default: 3
  final int maxRetries;

  /// Delay between retry attempts in milliseconds.
  /// Default: 1000 (1 second)
  final int retryDelayMs;

  /// Global error callback that gets called when logging operations fail.
  /// This is called in addition to returning a LogResult.
  final void Function(String eventName, String error)? onError;

  /// Whether to include user information (UID, email) in logs.
  /// Useful for privacy-sensitive applications.
  /// Default: true
  final bool includeUserInfo;

  /// Custom fields to add to every log entry.
  /// Example: {"app_version": "1.0.0", "environment": "production"}
  final Map<String, dynamic>? globalParameters;

  /// Minimum log level to record. Logs below this level will be ignored.
  /// Default: EventLevel.debug (logs everything)
  final EventLevel minimumLogLevel;

  /// Whether to enable batch logging mode.
  /// When enabled, logs are batched together and written in groups to reduce
  /// Firestore write operations and costs.
  /// Default: false
  final bool enableBatchMode;

  /// Maximum number of logs to batch before automatically flushing.
  /// Only applies when enableBatchMode is true.
  /// Default: 10
  final int batchSize;

  /// Maximum time in milliseconds to wait before flushing a batch.
  /// Even if batch is not full, it will be flushed after this time.
  /// Only applies when enableBatchMode is true.
  /// Default: 5000 (5 seconds)
  final int batchTimeoutMs;

  const EventStoreConfig({
    this.collectionName = "logs",
    this.enableRemoteLogging = true,
    this.enableLocalLogging = true,
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
    this.onError,
    this.includeUserInfo = true,
    this.globalParameters,
    this.minimumLogLevel = EventLevel.debug,
    this.enableBatchMode = false,
    this.batchSize = 10,
    this.batchTimeoutMs = 5000,
  });

  /// Creates a copy of this config with the given fields replaced.
  ///
  /// To explicitly remove the error callback, pass [clearOnError] = true.
  EventStoreConfig copyWith({
    String? collectionName,
    bool? enableRemoteLogging,
    bool? enableLocalLogging,
    int? maxRetries,
    int? retryDelayMs,
    void Function(String eventName, String error)? onError,
    bool clearOnError = false,
    bool? includeUserInfo,
    Map<String, dynamic>? globalParameters,
    bool clearGlobalParameters = false,
    EventLevel? minimumLogLevel,
    bool? enableBatchMode,
    int? batchSize,
    int? batchTimeoutMs,
  }) {
    return EventStoreConfig(
      collectionName: collectionName ?? this.collectionName,
      enableRemoteLogging: enableRemoteLogging ?? this.enableRemoteLogging,
      enableLocalLogging: enableLocalLogging ?? this.enableLocalLogging,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelayMs: retryDelayMs ?? this.retryDelayMs,
      onError: clearOnError ? null : (onError ?? this.onError),
      includeUserInfo: includeUserInfo ?? this.includeUserInfo,
      globalParameters: clearGlobalParameters
          ? null
          : (globalParameters ?? this.globalParameters),
      minimumLogLevel: minimumLogLevel ?? this.minimumLogLevel,
      enableBatchMode: enableBatchMode ?? this.enableBatchMode,
      batchSize: batchSize ?? this.batchSize,
      batchTimeoutMs: batchTimeoutMs ?? this.batchTimeoutMs,
    );
  }
}

/// A utility class for logging events.
///
/// Two classes are provided:
/// * **[EventLogger]**: A utility class for logging events to the Firebase Firestore database.
/// * **[LocalEventLogger]**: A utility class for logging events locally.
class EventStore {
  static const String defaultCollectionName = "logs";
  late final EventLogger eventLogger;
  late final LocalEventLogger localEventStore;
  late final EventStoreConfig config;

  static EventStore? _instance;

  EventStore._internal({EventStoreConfig? configuration}) {
    config = configuration ?? const EventStoreConfig();
    localEventStore = LocalEventLogger(config: config);
    eventLogger = EventLogger(
      config: config,
      localLogger: localEventStore,
    );
  }

  /// Returns the singleton instance of EventStore.
  ///
  /// You can configure EventStore using either [config] or [collectionName] parameter.
  /// These parameters are only used on the first call to create the instance.
  /// Subsequent calls will ignore these parameters and return the existing instance.
  /// If you need to change the configuration, you must call [reset()] first.
  ///
  /// Example with full configuration:
  /// ```dart
  /// var store = EventStore.getInstance(
  ///   config: EventStoreConfig(
  ///     collectionName: 'my_logs',
  ///     enableRemoteLogging: true,
  ///     enableLocalLogging: true,
  ///     maxRetries: 3,
  ///     onError: (eventName, error) {
  ///       print('Failed to log $eventName: $error');
  ///     },
  ///     globalParameters: {
  ///       'app_version': '1.0.0',
  ///       'environment': 'production',
  ///     },
  ///   ),
  /// );
  /// ```
  ///
  /// Example with just collection name (backward compatible):
  /// ```dart
  /// var store = EventStore.getInstance(collectionName: 'my_logs');
  /// ```
  static EventStore getInstance(
      {EventStoreConfig? config, String? collectionName}) {
    if (_instance == null) {
      // If config is provided, use it directly
      if (config != null) {
        _instance = EventStore._internal(configuration: config);
      }
      // If only collectionName is provided, create config with it
      else if (collectionName != null) {
        _instance = EventStore._internal(
          configuration: EventStoreConfig(collectionName: collectionName),
        );
      }
      // Otherwise use default config
      else {
        _instance = EventStore._internal();
      }
    }
    return _instance!;
  }

  /// Resets the singleton instance.
  ///
  /// This is useful for testing or when you need to reinitialize
  /// the EventStore with different configuration.
  ///
  /// Warning: This will invalidate all existing references to the EventStore.
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}

/// A utility class for logging events to the Firebase Firestore database.
///
/// This class provides a method for logging events to the Firebase Firestore database.
///
/// Functions:
/// * **[log]**: Logs an event to the Firebase Firestore database.
/// * **[flushBatch]**: Manually flush the current batch of logs.
class EventLogger {
  late EventStoreConfig _config;
  late LocalEventLogger _localLogger;

  // Batch logging support
  final List<Map<String, dynamic>> _batchQueue = [];
  DateTime? _batchStartTime;
  bool _isFlushingBatch = false;

  EventLogger({
    required EventStoreConfig config,
    required LocalEventLogger localLogger,
  }) {
    _config = config;
    _localLogger = localLogger;

    // Start batch timer if batch mode is enabled
    if (_config.enableBatchMode) {
      _startBatchTimer();
    }
  }

  /// Starts the periodic batch flush timer
  void _startBatchTimer() {
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: _config.batchTimeoutMs));

      if (_batchQueue.isNotEmpty && !_isFlushingBatch) {
        final timeSinceStart = _batchStartTime != null
            ? DateTime.now().difference(_batchStartTime!).inMilliseconds
            : 0;

        if (timeSinceStart >= _config.batchTimeoutMs) {
          await flushBatch();
        }
      }

      // Continue timer if batch mode is still enabled
      return _config.enableBatchMode;
    });
  }

  /// Checks if a log level meets the minimum threshold.
  bool _shouldLog(EventLevel level) {
    return level.index >= _config.minimumLogLevel.index;
  }

  /// Logs an event to the Firebase Firestore database asynchronously.
  ///
  /// This method logs an event to the Firebase Firestore database asynchronously.
  /// The event is stored in the specified collection.
  ///
  /// When batch mode is enabled, events are queued and written in batches to reduce
  /// Firestore write operations. The batch is automatically flushed when it reaches
  /// batchSize or after batchTimeoutMs, whichever comes first.
  ///
  /// * **[eventName]** is the name of the event.
  /// * **[level]** is the level of the event. (info, warning, error, trace, debug)
  /// * **[parameters]** is a map containing the parameters of the event.
  ///
  /// Returns a [LogResult] indicating success or failure.
  ///
  /// Example:
  /// ```dart
  /// final result = await eventLogger.log("login", EventLevel.info, {
  ///   "custom_parameter": "custom_value",
  /// });
  ///
  /// if (!result.success) {
  ///   print('Logging failed: ${result.error}');
  /// }
  /// ```
  ///
  /// The event will be stored in the collection with the following fields:
  /// * **user_id**: The UID of the current user (if includeUserInfo is true).
  /// * **email**: The email of the current user (if includeUserInfo is true).
  /// * **level**: The level of the event.
  /// * **event**: The name of the event.
  /// * **timestamp**: Server timestamp from Firebase.
  /// * **custom_parameter**: Any custom parameters you provide.
  /// * Plus any global parameters configured in EventStoreConfig.
  ///
  /// Note: The original parameters map is not modified. A copy is created internally.
  ///
  /// See also: [logSync] for a synchronous alternative that can be used in non-async functions.
  Future<LogResult> log(String eventName, EventLevel level,
      Map<String, dynamic> parameters) async {
    // Check if this log level should be recorded
    if (!_shouldLog(level)) {
      return LogResult.success(); // Silently skip logs below minimum level
    }

    try {
      // Create a copy of parameters to avoid mutating the original map
      final eventData = <String, dynamic>{
        ...parameters,
      };

      // Add global parameters if configured
      if (_config.globalParameters != null) {
        eventData.addAll(_config.globalParameters!);
      }

      // Add user info if enabled
      if (_config.includeUserInfo) {
        eventData['user_id'] = currentUserUid();
        eventData['email'] = currentUserEmail();
      }

      eventData['level'] = level.toString().split('.').last;
      eventData['event'] = eventName;
      eventData['timestamp'] = FieldValue.serverTimestamp();

      // Log locally if enabled
      if (_config.enableLocalLogging) {
        _localLogger.log(eventName, level, parameters);
      }

      // Handle remote logging
      if (_config.enableRemoteLogging) {
        if (_config.enableBatchMode) {
          // Add to batch queue
          _addToBatch(eventData);

          // Check if we should flush the batch
          if (_batchQueue.length >= _config.batchSize) {
            await flushBatch();
          }
        } else {
          // Direct write (non-batch mode)
          await _logToFirestoreWithRetry(eventData, eventName);
        }
      }

      return LogResult.success();
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      final errorMessage = 'Firebase error: ${e.code} - ${e.message}';
      debugPrint('EventLogger: $errorMessage');

      // Call global error handler if configured
      if (_config.onError != null) {
        _config.onError!(eventName, errorMessage);
      }

      // Still log locally even if remote logging fails
      if (_config.enableLocalLogging) {
        _localLogger.log(eventName, level, parameters);
      }

      return LogResult.failure(errorMessage);
    } catch (e) {
      // Handle any other errors
      final errorMessage = 'Unexpected error while logging event: $e';
      debugPrint('EventLogger: $errorMessage');

      // Call global error handler if configured
      if (_config.onError != null) {
        _config.onError!(eventName, errorMessage);
      }

      // Still log locally even if remote logging fails
      if (_config.enableLocalLogging) {
        _localLogger.log(eventName, level, parameters);
      }

      return LogResult.failure(errorMessage);
    }
  }

  /// Adds an event to the batch queue
  void _addToBatch(Map<String, dynamic> eventData) {
    _batchQueue.add(eventData);

    // Set batch start time if this is the first item
    if (_batchQueue.length == 1) {
      _batchStartTime = DateTime.now();
    }
  }

  /// Manually flush the current batch of logs to Firestore.
  ///
  /// This forces all queued logs to be written immediately, regardless of
  /// batch size or timeout. Useful when you need to ensure logs are written
  /// before app termination or critical operations.
  ///
  /// Returns a [LogResult] indicating success or failure of the batch write.
  ///
  /// Example:
  /// ```dart
  /// // Log some events
  /// await eventLogger.log("event1", EventLevel.info, {});
  /// await eventLogger.log("event2", EventLevel.info, {});
  ///
  /// // Ensure they're written immediately
  /// final result = await eventLogger.flushBatch();
  /// if (result.success) {
  ///   print('Batch flushed successfully');
  /// }
  /// ```
  Future<LogResult> flushBatch() async {
    // Skip if batch mode is not enabled or queue is empty
    if (!_config.enableBatchMode || _batchQueue.isEmpty || _isFlushingBatch) {
      return LogResult.success();
    }

    _isFlushingBatch = true;

    try {
      // Check if Firebase is initialized
      try {
        FirebaseFirestore.instance;
      } catch (e) {
        throw Exception(
            'Firebase has not been initialized. Call Firebase.initializeApp() before logging events. Error: $e');
      }

      // Create a copy of the queue and clear it
      final batch = List<Map<String, dynamic>>.from(_batchQueue);
      _batchQueue.clear();
      _batchStartTime = null;

      // Use Firestore batch write
      final firebaseBatch = FirebaseFirestore.instance.batch();
      final collection =
          FirebaseFirestore.instance.collection(_config.collectionName);

      for (final eventData in batch) {
        final docRef = collection.doc(); // Auto-generate ID
        firebaseBatch.set(docRef, eventData);
      }

      // Commit the batch with retry logic
      await _commitBatchWithRetry(firebaseBatch, batch.length);

      debugPrint(
          'EventLogger: Successfully flushed batch of ${batch.length} logs');
      return LogResult.success();
    } on FirebaseException catch (e) {
      final errorMessage =
          'Firebase batch write error: ${e.code} - ${e.message}';
      debugPrint('EventLogger: $errorMessage');

      // Call global error handler if configured
      if (_config.onError != null) {
        _config.onError!('batch_flush', errorMessage);
      }

      return LogResult.failure(errorMessage);
    } catch (e) {
      final errorMessage = 'Unexpected error while flushing batch: $e';
      debugPrint('EventLogger: $errorMessage');

      // Call global error handler if configured
      if (_config.onError != null) {
        _config.onError!('batch_flush', errorMessage);
      }

      return LogResult.failure(errorMessage);
    } finally {
      _isFlushingBatch = false;
    }
  }

  /// Commits a Firestore batch with retry logic
  Future<void> _commitBatchWithRetry(WriteBatch batch, int eventCount) async {
    int attempts = 0;
    while (attempts <= _config.maxRetries) {
      try {
        await batch.commit();
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts > _config.maxRetries) {
          rethrow; // Exceeded max retries, propagate error
        }
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: _config.retryDelayMs));
        debugPrint(
            'EventLogger: Retry attempt $attempts/${_config.maxRetries} for batch of $eventCount events');
      }
    }
  }

  /// Internal method to log to Firestore with retry logic.
  Future<void> _logToFirestoreWithRetry(
      Map<String, dynamic> eventData, String eventName) async {
    // Check if Firebase is initialized before attempting to use it
    try {
      // This will throw if Firebase is not initialized
      FirebaseFirestore.instance;
    } catch (e) {
      throw Exception(
          'Firebase has not been initialized. Call Firebase.initializeApp() before logging events. Error: $e');
    }

    int attempts = 0;
    while (attempts <= _config.maxRetries) {
      try {
        await FirebaseFirestore.instance
            .collection(_config.collectionName)
            .add(eventData);
        return; // Success
      } catch (e) {
        attempts++;
        if (attempts > _config.maxRetries) {
          rethrow; // Exceeded max retries, propagate error
        }
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: _config.retryDelayMs));
        debugPrint(
            'EventLogger: Retry attempt $attempts/${_config.maxRetries} for event "$eventName"');
      }
    }
  }

  /// Logs an event synchronously (fire-and-forget).
  ///
  /// This is a convenience method for logging from non-async functions.
  /// It starts the logging operation but doesn't wait for it to complete.
  /// Use this when you can't use async/await, but be aware that you won't
  /// know if the logging succeeded or failed.
  ///
  /// * **[eventName]** is the name of the event.
  /// * **[level]** is the level of the event. (info, warning, error, trace, debug)
  /// * **[parameters]** is a map containing the parameters of the event.
  /// * **[onComplete]** optional callback that receives the [LogResult] when logging completes.
  ///
  /// Example:
  /// ```dart
  /// // Simple fire-and-forget
  /// eventLogger.logSync("button_click", EventLevel.info, {
  ///   "button_id": "submit",
  /// });
  ///
  /// // With callback to handle result
  /// eventLogger.logSync(
  ///   "purchase",
  ///   EventLevel.info,
  ///   {"item": "book"},
  ///   onComplete: (result) {
  ///     if (!result.success) {
  ///       print('Failed: ${result.error}');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// Note: If you're in an async context, prefer using [log] instead
  /// to properly handle errors.
  void logSync(
    String eventName,
    EventLevel level,
    Map<String, dynamic> parameters, {
    void Function(LogResult)? onComplete,
  }) {
    // Check if this log level should be recorded
    if (!_shouldLog(level)) {
      if (onComplete != null) {
        onComplete(LogResult.success());
      }
      return;
    }

    // Immediately log locally if enabled
    if (_config.enableLocalLogging) {
      _localLogger.log(eventName, level, parameters);
    }

    // Start the async operation but don't await it (only if remote logging is enabled)
    if (_config.enableRemoteLogging) {
      log(eventName, level, parameters).then((result) {
        if (onComplete != null) {
          onComplete(result);
        }
        // If there's an error and no callback, at least log it
        if (!result.success && onComplete == null) {
          debugPrint('EventLogger.logSync: ${result.error}');
        }
      });
    } else if (onComplete != null) {
      // If remote logging is disabled, just call onComplete with success
      onComplete(LogResult.success());
    }
  }
}

/// A utility class for logging events locally.
/// This class provides a method for logging events locally.
class LocalEventLogger {
  late EventStoreConfig _config;

  LocalEventLogger({required EventStoreConfig config}) {
    _config = config;
  }

  /// Logs an event to the console.
  ///
  /// This method logs an event to the console in a structured JSON format.
  ///
  /// * **[eventName]** is the name of the event.
  /// * **[level]** is the level of the event. (info, warning, error, trace, debug)
  /// * **[parameters]** is a map containing the parameters of the event.
  /// * **[userId]** is the UID of the user. (default uses current Firebase user if includeUserInfo is true)
  ///
  /// Example:
  /// ```dart
  /// localEventLogger.log("login", EventLevel.info, {
  ///   "custom_parameter": "custom_value",
  /// });
  /// ```
  ///
  /// The event will be printed to console with the following fields:
  /// * **@t**: The UTC timestamp of the event.
  /// * **@u**: The UID of the current user (if includeUserInfo is true) or the one passed in parameter.
  /// * **@e**: The email of the current user (if includeUserInfo is true).
  /// * **@l**: The level of the event.
  /// * **@c**: The collection name.
  /// * **@n**: The event name.
  /// * **@p**: The event parameters.
  void log(String eventName, EventLevel level, Map<String, dynamic> parameters,
      {String? userId}) {
    if (!_config.enableLocalLogging) {
      return; // Skip if local logging is disabled
    }

    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final levelStr = level.toString().split('.').last;

      // Build the log entry
      final logData = <String, dynamic>{
        '@t': timestamp,
        '@l': levelStr,
        '@c': _config.collectionName,
        '@n': eventName,
        '@p': parameters,
      };

      // Add user info if enabled
      if (_config.includeUserInfo) {
        logData['@u'] = userId ?? currentUserUid();
        logData['@e'] = currentUserEmail();
      }

      // Add global parameters if configured
      if (_config.globalParameters != null) {
        logData['@g'] = _config.globalParameters;
      }

      debugPrint('$logData');
    } catch (e) {
      // If logging fails, at least try to print the error
      debugPrint(
          'LocalEventLogger error: Failed to log event "$eventName": $e');
    }
  }
}

/// Returns the UID of the current user.
/// If the current user is null, returns "null".
/// If Firebase Auth is not initialized, returns "uninitialized".
String currentUserUid() {
  try {
    return FirebaseAuth.instance.currentUser?.uid ?? "null";
  } catch (e) {
    debugPrint('EventStore: Firebase Auth not initialized or error: $e');
    return "uninitialized";
  }
}

/// Returns the email of the current user.
/// If the current user is null, returns "null".
/// If Firebase Auth is not initialized, returns "uninitialized".
String currentUserEmail() {
  try {
    return FirebaseAuth.instance.currentUser?.email ?? "null";
  } catch (e) {
    debugPrint('EventStore: Firebase Auth not initialized or error: $e');
    return "uninitialized";
  }
}

/// Returns the display name of the current user.
/// If the current user is null, returns "null".
/// If Firebase Auth is not initialized, returns "uninitialized".
String currentUserName() {
  try {
    return FirebaseAuth.instance.currentUser?.displayName ?? "null";
  } catch (e) {
    debugPrint('EventStore: Firebase Auth not initialized or error: $e');
    return "uninitialized";
  }
}

/// Enum representing the level of an event.
/// The levels are ordered by severity (debug being least severe, error being most severe):
/// * **debug**: Debug event (index 0).
/// * **trace**: Trace event (index 1).
/// * **info**: Informational event (index 2).
/// * **warning**: Warning event (index 3).
/// * **error**: Error event (index 4).
enum EventLevel {
  debug, // 0 - Lowest priority
  trace, // 1
  info, // 2
  warning, // 3
  error, // 4 - Highest priority
}

/// Represents the result of a logging operation.
///
/// Contains information about whether the operation succeeded and any error message if it failed.
class LogResult {
  /// Whether the logging operation was successful.
  final bool success;

  /// The error message if the operation failed. Null if successful.
  final String? error;

  LogResult._({required this.success, this.error});

  /// Creates a successful log result.
  factory LogResult.success() => LogResult._(success: true);

  /// Creates a failed log result with an error message.
  factory LogResult.failure(String errorMessage) =>
      LogResult._(success: false, error: errorMessage);

  @override
  String toString() => success
      ? 'LogResult(success: true)'
      : 'LogResult(success: false, error: $error)';
}
