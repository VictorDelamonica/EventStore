# Event Store

## Description

This is a singleton service to log event into a Firebase Firestore database. Can also log events
locally into the console with different log levels(debug, info, warning, error, trace).

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

You can also use the following methods:

```dart

var instance = EventStore.getInstance();
instance.eventLogger.logEvent
("login
"
, EventLevel.info, {
    "custom_parameter": "custom_value",
});
    
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.