// Web implementation — only compiled on flutter web targets.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<String> requestPermission() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        return 'granted';
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return 'denied';
      }
      return 'default';
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return 'unsupported';
    }
  }

  static String getPermission() {
    return 'unknown';
  }

  static Future<String?> getToken(String vapidKey) async {
    try {
      return await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<String?> subscribeToPush(String vapidKey) => getToken(vapidKey);
}