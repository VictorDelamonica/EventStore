# Event Store

## Description

This is a simple event store that can be used to store events and retrieve them.

## Installation

To install the event store, you can use the following command:

```bash
flutter pub add monikode_event_store
```

## Usage

To use the event store, you need to import the class in your file:

```dart

import 'package:monikode_event_store/monikode_event_store.dart';

```

Then, you need to create an instance of the class:

```dart

EventStore store = EventStore();

```

You can also use the following methods:

```dart

store.eventLogger.logEvent("login", EventLevel.info, {
    "custom_parameter": "custom_value",
});
    
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.