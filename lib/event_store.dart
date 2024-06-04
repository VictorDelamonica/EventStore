import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A utility class for logging events.
///
/// Tow classes are provided:
/// * **[EventLogger]**: A utility class for logging events to the Firebase Firestore database.
/// * **[LocalEventLogger]**: A utility class for logging events locally.
class EventStore {
  String defaultCollectionName = "logs";
  late EventLogger eventLogger;
  late LocalEventLogger localEventStore;

  EventStore({String? collectionName}) {
    localEventStore = LocalEventLogger(
        collectionName: collectionName ?? defaultCollectionName);
    eventLogger = EventLogger(
      collectionName: collectionName ?? defaultCollectionName,
      localLogger: localEventStore,
    );
  }
}

/// A utility class for logging events to the Firebase Firestore database.
///
/// This class provides a method for logging events to the Firebase Firestore database.
///
/// Functions:
/// * **[logEvent]**: Logs an event to the Firebase Firestore database.
class EventLogger {
  late String _collectionName;
  late LocalEventLogger _localLogger;

  EventLogger(
      {required String collectionName, required LocalEventLogger localLogger}) {
    _collectionName = collectionName;
    _localLogger = localLogger;
  }

  /// Logs an event to the Firebase Firestore database.
  ///
  /// This method logs an event to the Firebase Firestore database.
  /// The event is stored in the 'logs' collection.
  ///
  /// * **[eventName]** is the name of the event.
  /// * **[level]** is the level of the event. (info, warning, error, trace, debug)
  /// * **[parameters]** is a map containing the parameters of the event.
  ///
  /// Example:
  /// ```dart
  /// EventLogger.logEvent("login", EventLevel.info, {
  /// "custom_parameter": "custom_value",
  /// });
  /// ```
  ///
  /// The event will be stored in the 'logs' collection with the following fields:
  /// * **user_id**: The UID of the current user.
  /// * **email**: The email of the current user.
  /// * **level**: The level of the event.
  /// * **event**: The name of the event.
  /// * **timestamp**: The timestamp of the event.
  /// * **custom_parameter**: The custom value of the event.
  void log(
      String eventName, EventLevel level, Map<String, dynamic> parameters) {
    FirebaseFirestore.instance.collection(_collectionName).add(
          parameters
            ..addAll({
              'user_id': currentUserUid(),
              'email': currentUserEmail(),
              'level': level.toString().split('.').last,
              'event': eventName,
              'timestamp': DateTime.now(),
            }),
        );
    _localLogger.log(eventName, level, parameters);
  }
}

/// A utility class for logging events locally.
/// This class provides a method for logging events locally.
class LocalEventLogger {
  late String _collectionName;

  LocalEventLogger({required String collectionName}) {
    _collectionName = collectionName;
  }

  /// Logs an event to the console.
  ///
  /// This method logs an event to the console.
  ///
  /// * **[eventName]** is the name of the event.
  /// * **[level]** is the level of the event. (info, warning, error, trace, debug)
  /// * **[parameters]** is a map containing the parameters of the event.
  ///
  /// Example:
  /// ```dart
  /// LocalEventStore.logEvent("login", EventLevel.info, {
  /// "custom_parameter": "custom_value",
  /// });
  /// ```
  ///
  /// The event will be stored in the 'logs' collection with the following fields:
  /// * **user_id**: The UID of the current user.
  /// * **email**: The email of the current user.
  /// * **level**: The level of the event.
  /// * **event**: The name of the event.
  /// * **timestamp**: The timestamp of the event.
  /// * **custom_parameter**: The custom value of the event.
  void log(
      String eventName, EventLevel level, Map<String, dynamic> parameters) {
    debugPrint(
        "{\"@t\": ${DateTime.now()}, \"@u\": \"user_id\", \"@e\": \"user_email\", \"@l\": \"${level.toString().split('.').last}\", \"@c\": \"$_collectionName\", \"@n\": \"$eventName\", \"@p\": \"$parameters\"}");
  }
}

/// Returns the UID of the current user.
/// If the current user is null, returns "null".
String currentUserUid() => FirebaseAuth.instance.currentUser?.uid ?? "null";

/// Returns the email of the current user.
/// If the current user is null, returns "null".
String currentUserEmail() => FirebaseAuth.instance.currentUser?.email ?? "null";

/// Returns the display name of the current user.
/// If the current user is null, returns "null".
String currentUserName() =>
    FirebaseAuth.instance.currentUser?.displayName ?? "null";

/// Enum representing the level of an event.
/// The levels are:
/// * **info**: Informational event.
/// * **warning**: Warning event.
/// * **error**: Error event.
/// * **trace**: Trace event.
/// * **debug**: Debug event.
enum EventLevel { info, warning, error, trace, debug }
