import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monikode_event_store/monikode_event_store.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart'
    show MockPlatformInterfaceMixin;

class MockEventLogger with MockPlatformInterfaceMixin implements EventLogger {
  @override
  Future<LogResult> log(
    String eventName,
    EventLevel level,
    Map<String, dynamic> parameters,
  ) async {
    debugPrint("MockEventLogger: $eventName, $level, $parameters");
    return LogResult.success();
  }

  @override
  void logSync(
    String eventName,
    EventLevel level,
    Map<String, dynamic> parameters, {
    void Function(LogResult)? onComplete,
  }) {
    debugPrint("MockEventLogger.logSync: $eventName, $level, $parameters");
    if (onComplete != null) {
      onComplete(LogResult.success());
    }
  }

  @override
  Future<LogResult> flushBatch() async {
    debugPrint("MockEventLogger.flushBatch called");
    return LogResult.success();
  }
}

class MockLocalEventStore
    with MockPlatformInterfaceMixin
    implements LocalEventLogger {
  @override
  void log(String eventName, EventLevel level, Map<String, dynamic> parameters,
      {String? userId}) {
    debugPrint("MockLocalEventStore: $eventName, $level, $parameters");
  }
}

class MockEventStore with MockPlatformInterfaceMixin implements EventStore {
  @override
  EventLogger eventLogger = MockEventLogger();

  @override
  LocalEventLogger localEventStore = MockLocalEventStore();

  @override
  EventStoreConfig config = const EventStoreConfig();
}

void main() {
  setUp(() {
    // Reset singleton before each test
    EventStore.reset();
  });

  test('EventStore mock implementation', () async {
    final eventStore = MockEventStore();
    await eventStore.eventLogger.log("test_event", EventLevel.info, {
      "custom_parameter": "custom_value",
    });
    eventStore.localEventStore.log("test_event", EventLevel.info, {
      "custom_parameter": "custom_value",
    });
  });

  test('EventStore singleton returns same instance', () {
    final instance1 = EventStore.getInstance();
    final instance2 = EventStore.getInstance();

    expect(instance1, same(instance2));
  });

  test('EventStore singleton uses custom collection name on first call', () {
    final instance = EventStore.getInstance(collectionName: 'custom_logs');

    // Verify the instance was created (not null)
    expect(instance, isNotNull);
    expect(instance.eventLogger, isNotNull);
    expect(instance.localEventStore, isNotNull);
  });

  test('EventStore singleton ignores collection name on subsequent calls', () {
    final instance1 =
        EventStore.getInstance(collectionName: 'first_collection');
    final instance2 =
        EventStore.getInstance(collectionName: 'second_collection');

    // Should return the same instance
    expect(instance1, same(instance2));
  });

  test('EventStore reset allows new instance creation', () {
    final instance1 = EventStore.getInstance(collectionName: 'collection1');

    EventStore.reset();

    final instance2 = EventStore.getInstance(collectionName: 'collection2');

    // Should be different instances
    expect(instance1, isNot(same(instance2)));
  });

  test('EventStore uses default collection name when none provided', () {
    final instance = EventStore.getInstance();

    expect(instance, isNotNull);
    expect(EventStore.defaultCollectionName, equals('logs'));
  });

  test('LogResult success creates successful result', () {
    final result = LogResult.success();

    expect(result.success, isTrue);
    expect(result.error, isNull);
  });

  test('LogResult failure creates failed result with error message', () {
    const errorMessage = 'Test error message';
    final result = LogResult.failure(errorMessage);

    expect(result.success, isFalse);
    expect(result.error, equals(errorMessage));
  });

  test('LogResult toString provides useful information', () {
    final successResult = LogResult.success();
    final failureResult = LogResult.failure('Error occurred');

    expect(successResult.toString(), contains('success: true'));
    expect(failureResult.toString(), contains('success: false'));
    expect(failureResult.toString(), contains('Error occurred'));
  });

  test('EventLogger.logSync works in non-async context', () {
    final eventStore = MockEventStore();

    // This should not require await
    eventStore.eventLogger.logSync("sync_event", EventLevel.info, {
      "test": "value",
    });

    // Test passes if no error is thrown
    expect(true, isTrue);
  });

  test('EventLogger.logSync with callback receives result', () async {
    final eventStore = MockEventStore();
    LogResult? capturedResult;

    eventStore.eventLogger.logSync(
      "callback_event",
      EventLevel.info,
      {"test": "value"},
      onComplete: (result) {
        capturedResult = result;
      },
    );

    // Give callback time to execute
    await Future.delayed(const Duration(milliseconds: 100));

    expect(capturedResult, isNotNull);
    expect(capturedResult?.success, isTrue);
  });

  test('EventStoreConfig has correct default values', () {
    const config = EventStoreConfig();

    expect(config.collectionName, equals('logs'));
    expect(config.enableRemoteLogging, isTrue);
    expect(config.enableLocalLogging, isTrue);
    expect(config.maxRetries, equals(3));
    expect(config.retryDelayMs, equals(1000));
    expect(config.onError, isNull);
    expect(config.includeUserInfo, isTrue);
    expect(config.globalParameters, isNull);
    expect(config.minimumLogLevel, equals(EventLevel.debug));
  });

  test('EventStoreConfig can be customized', () {
    const config = EventStoreConfig(
      collectionName: 'custom_logs',
      enableRemoteLogging: false,
      enableLocalLogging: false,
      maxRetries: 5,
      retryDelayMs: 2000,
      includeUserInfo: false,
      globalParameters: {'app': 'test'},
      minimumLogLevel: EventLevel.warning,
    );

    expect(config.collectionName, equals('custom_logs'));
    expect(config.enableRemoteLogging, isFalse);
    expect(config.enableLocalLogging, isFalse);
    expect(config.maxRetries, equals(5));
    expect(config.retryDelayMs, equals(2000));
    expect(config.includeUserInfo, isFalse);
    expect(config.globalParameters, equals({'app': 'test'}));
    expect(config.minimumLogLevel, equals(EventLevel.warning));
  });

  test('EventStoreConfig copyWith creates new instance with updated values',
      () {
    const original = EventStoreConfig(
      collectionName: 'original',
      maxRetries: 3,
    );

    final updated = original.copyWith(
      collectionName: 'updated',
      maxRetries: 5,
    );

    expect(original.collectionName, equals('original'));
    expect(original.maxRetries, equals(3));
    expect(updated.collectionName, equals('updated'));
    expect(updated.maxRetries, equals(5));
  });

  test('EventStore getInstance accepts EventStoreConfig', () {
    final instance = EventStore.getInstance(
      config: const EventStoreConfig(
        collectionName: 'config_test',
        maxRetries: 10,
      ),
    );

    expect(instance, isNotNull);
    expect(instance.config.collectionName, equals('config_test'));
    expect(instance.config.maxRetries, equals(10));
  });

  test('EventStore getInstance backward compatible with collectionName', () {
    EventStore.reset();
    final instance = EventStore.getInstance(collectionName: 'legacy_logs');

    expect(instance, isNotNull);
    expect(instance.config.collectionName, equals('legacy_logs'));
    // Should use other defaults
    expect(instance.config.maxRetries, equals(3));
    expect(instance.config.enableRemoteLogging, isTrue);
  });

  test('EventLevel enum has correct order', () {
    // Verify the order is from least to most severe
    expect(EventLevel.debug.index, lessThan(EventLevel.trace.index));
    expect(EventLevel.trace.index, lessThan(EventLevel.info.index));
    expect(EventLevel.info.index, lessThan(EventLevel.warning.index));
    expect(EventLevel.warning.index, lessThan(EventLevel.error.index));
  });

  test('EventStoreConfig with global error handler', () {
    String? capturedEventName;
    String? capturedError;

    final config = EventStoreConfig(
      onError: (eventName, error) {
        capturedEventName = eventName;
        capturedError = error;
      },
    );

    expect(config.onError, isNotNull);

    // Test the callback
    config.onError!('test_event', 'test_error');
    expect(capturedEventName, equals('test_event'));
    expect(capturedError, equals('test_error'));
  });

  test('EventStoreConfig copyWith can clear onError callback', () {
    final configWithCallback = EventStoreConfig(
      onError: (eventName, error) {
        // Some callback
      },
    );

    expect(configWithCallback.onError, isNotNull);

    // Test clearing the callback
    final configWithoutCallback = configWithCallback.copyWith(
      clearOnError: true,
    );

    expect(configWithoutCallback.onError, isNull);
  });

  test('EventStoreConfig copyWith can clear globalParameters', () {
    const configWithParams = EventStoreConfig(
      globalParameters: {'app': 'test'},
    );

    expect(configWithParams.globalParameters, isNotNull);

    // Test clearing the parameters
    final configWithoutParams = configWithParams.copyWith(
      clearGlobalParameters: true,
    );

    expect(configWithoutParams.globalParameters, isNull);
  });

  test('EventStoreConfig batch mode has correct defaults', () {
    const config = EventStoreConfig();

    expect(config.enableBatchMode, isFalse);
    expect(config.batchSize, equals(10));
    expect(config.batchTimeoutMs, equals(5000));
  });

  test('EventStoreConfig batch mode can be configured', () {
    const config = EventStoreConfig(
      enableBatchMode: true,
      batchSize: 20,
      batchTimeoutMs: 3000,
    );

    expect(config.enableBatchMode, isTrue);
    expect(config.batchSize, equals(20));
    expect(config.batchTimeoutMs, equals(3000));
  });

  test('EventStore with batch mode configuration', () {
    EventStore.reset();

    final instance = EventStore.getInstance(
      config: const EventStoreConfig(
        enableBatchMode: true,
        batchSize: 15,
        batchTimeoutMs: 2000,
      ),
    );

    expect(instance.config.enableBatchMode, isTrue);
    expect(instance.config.batchSize, equals(15));
    expect(instance.config.batchTimeoutMs, equals(2000));
  });
}
