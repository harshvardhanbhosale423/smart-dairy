import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('User notification permission status: ${settings.authorizationStatus}');
      }

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('FCM Foreground Message received: ${message.notification?.title}');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  static Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
      return null;
    }
  }
}

