import 'package:flutter/material.dart';
import 'package:monikode_event_store/monikode_event_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Initialize with comprehensive configuration including batch logging
  final _eventStorePlugin = EventStore.getInstance(
    config: EventStoreConfig(
      collectionName: 'example_logs',
      enableRemoteLogging: true,
      enableLocalLogging: true,
      maxRetries: 3,
      retryDelayMs: 1000,
      minimumLogLevel: EventLevel.debug, // Log everything in example
      includeUserInfo: true,
      // Enable batch logging for cost optimization
      enableBatchMode: true,
      batchSize: 5, // Flush after 5 logs (lower for demo purposes)
      batchTimeoutMs: 10000, // Or after 10 seconds
      globalParameters: {
        'app_name': 'EventStore Example',
        'version': '2.2.0',
        'platform': 'flutter',
      },
      onError: (eventName, error) {
        debugPrint('Global error handler: $eventName failed with: $error');
      },
    ),
  );

  String _lastResult = 'No logs yet';
  int _eventCount = 0;

  @override
  void initState() {
    super.initState();
    _logAppStart();
  }

  @override
  void dispose() {
    // Flush any pending batched logs before disposal
    _eventStorePlugin.eventLogger.flushBatch();
    super.dispose();
  }

  Future<void> _logAppStart() async {
    await _eventStorePlugin.eventLogger.log(
      "app_started",
      EventLevel.info,
      {
        "timestamp": DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _logEvent() async {
    _eventCount++;
    final result = await _eventStorePlugin.eventLogger.log(
      "test_event",
      EventLevel.info,
      {
        "custom_parameter": "custom_value",
        "timestamp": DateTime.now().toString(),
        "event_number": _eventCount,
      },
    );

    setState(() {
      if (result.success) {
        _lastResult = '✅ Event #$_eventCount logged successfully';
      } else {
        _lastResult = '❌ Failed to log event: ${result.error}';
      }
    });
  }

  void _logSyncEvent() {
    _eventCount++;
    // This can be called from non-async functions
    _eventStorePlugin.eventLogger.logSync(
      "sync_event",
      EventLevel.info,
      {
        "button": "sync_button",
        "timestamp": DateTime.now().toString(),
        "event_number": _eventCount,
      },
      onComplete: (result) {
        setState(() {
          if (result.success) {
            _lastResult = '✅ Sync event #$_eventCount logged successfully';
          } else {
            _lastResult = '❌ Sync event failed: ${result.error}';
          }
        });
      },
    );
  }

  void _logLocalEvent() {
    _eventCount++;
    _eventStorePlugin.localEventStore.log(
      "test_local_event",
      EventLevel.debug,
      {
        "custom_parameter": "custom_value",
        "timestamp": DateTime.now().toString(),
        "event_number": _eventCount,
      },
    );

    setState(() {
      _lastResult = '📝 Local event #$_eventCount logged (check console)';
    });
  }

  Future<void> _logWarning() async {
    _eventCount++;
    final result = await _eventStorePlugin.eventLogger.log(
      "test_warning",
      EventLevel.warning,
      {
        "message": "This is a test warning",
        "timestamp": DateTime.now().toString(),
        "event_number": _eventCount,
      },
    );

    setState(() {
      if (result.success) {
        _lastResult = '⚠️ Warning #$_eventCount logged';
      } else {
        _lastResult = '❌ Failed to log warning: ${result.error}';
      }
    });
  }

  Future<void> _logError() async {
    _eventCount++;
    final result = await _eventStorePlugin.eventLogger.log(
      "test_error",
      EventLevel.error,
      {
        "error_type": "test_error",
        "message": "This is a test error",
        "timestamp": DateTime.now().toString(),
        "event_number": _eventCount,
      },
    );

    setState(() {
      if (result.success) {
        _lastResult = '🚨 Error #$_eventCount logged';
      } else {
        _lastResult = '❌ Failed to log error: ${result.error}';
      }
    });
  }

  Future<void> _flushBatch() async {
    final result = await _eventStorePlugin.eventLogger.flushBatch();

    setState(() {
      if (result.success) {
        _lastResult = '✅ Batch flushed successfully!';
      } else {
        _lastResult = '❌ Failed to flush batch: ${result.error}';
      }
    });
    setState(() {
      if (result.success) {
        _lastResult = '🚨 Error #$_eventCount logged';
      } else {
        _lastResult = '❌ Failed to log error: ${result.error}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('EventStore Example'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'EventStore Configuration Demo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This example demonstrates the comprehensive configuration options',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _lastResult,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Async Logging',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _logEvent,
                    icon: const Icon(Icons.info),
                    label: const Text('Log Info Event'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _logWarning,
                    icon: const Icon(Icons.warning),
                    label: const Text('Log Warning Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _logError,
                    icon: const Icon(Icons.error),
                    label: const Text('Log Error Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Sync Logging (for non-async contexts)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _logSyncEvent,
                    icon: const Icon(Icons.sync),
                    label: const Text('Log Sync Event'),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Local Only Logging',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _logLocalEvent,
                    icon: const Icon(Icons.terminal),
                    label: const Text('Log Local Event (Console)'),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Batch Control (Batch Mode Enabled)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _flushBatch,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Flush Batch Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Forces immediate write of all queued logs',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configuration:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Collection: ${_eventStorePlugin.config.collectionName}'),
                        Text(
                            'Remote Logging: ${_eventStorePlugin.config.enableRemoteLogging}'),
                        Text(
                            'Local Logging: ${_eventStorePlugin.config.enableLocalLogging}'),
                        Text(
                            'Max Retries: ${_eventStorePlugin.config.maxRetries}'),
                        Text(
                            'Retry Delay: ${_eventStorePlugin.config.retryDelayMs}ms'),
                        Text(
                            'Min Level: ${_eventStorePlugin.config.minimumLogLevel}'),
                        Text(
                            'Batch Mode: ${_eventStorePlugin.config.enableBatchMode}'),
                        if (_eventStorePlugin.config.enableBatchMode) ...[
                          Text(
                              '  ├─ Batch Size: ${_eventStorePlugin.config.batchSize}'),
                          Text(
                              '  └─ Timeout: ${_eventStorePlugin.config.batchTimeoutMs}ms'),
                        ],
                        Text(
                            'Include User Info: ${_eventStorePlugin.config.includeUserInfo}'),
                        if (_eventStorePlugin.config.globalParameters != null)
                          Text(
                              'Global Params: ${_eventStorePlugin.config.globalParameters}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Total events logged: ',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '$_eventCount',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
