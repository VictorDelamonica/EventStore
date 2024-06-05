import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monikode_event_store/monikode_event_store.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart'
    show MockPlatformInterfaceMixin;

class MockEventLogger with MockPlatformInterfaceMixin implements EventLogger {
  @override
  void log(
    String eventName,
    EventLevel level,
    Map<String, dynamic> parameters,
  ) {
    debugPrint("MockEventLogger: $eventName, $level, $parameters");
  }
}

class MockLocalEventStore
    with MockPlatformInterfaceMixin
    implements LocalEventLogger {
  @override
  void log(
    String eventName,
    EventLevel level,
    Map<String, dynamic> parameters,
  ) {
    debugPrint("MockLocalEventStore: $eventName, $level, $parameters");
  }
}

class MockEventStore with MockPlatformInterfaceMixin implements EventStore {
  @override
  String defaultCollectionName = "test";

  @override
  EventLogger eventLogger = MockEventLogger();

  @override
  LocalEventLogger localEventStore = MockLocalEventStore();
}

void main() {
  test('EventStore', () {
    final eventStore = MockEventStore();
    eventStore.eventLogger.log("test_event", EventLevel.info, {
      "custom_parameter": "custom_value",
    });
    eventStore.localEventStore.log("test_event", EventLevel.info, {
      "custom_parameter": "custom_value",
    });
  });
}
