import 'package:flutter/material.dart';
import 'package:monikode_event_store/event_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _eventStorePlugin = EventStore();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              OutlinedButton(
                onPressed: () {
                  _eventStorePlugin.eventLogger.log(
                    "test_event",
                    EventLevel.info,
                    {
                      "custom_parameter": "custom_value",
                    },
                  );
                },
                child: const Text('Log Event'),
              ),
              OutlinedButton(
                onPressed: () {
                  _eventStorePlugin.localEventStore.log(
                    "test_event",
                    EventLevel.info,
                    {
                      "custom_parameter": "custom_value",
                    },
                  );
                },
                child: const Text('Log Local Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
