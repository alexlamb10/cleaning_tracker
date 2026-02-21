// Stub implementation for non-web platforms (mobile/desktop).
// The conditional import in data_service.dart picks notification_web.dart on web.

Future<String> _requestPermission() async => 'unsupported';
String _getPermission() => 'unsupported';
Future<String?> _subscribeToPush(String vapidKey) async => null;

class NotificationService {
  static Future<String> requestPermission() => _requestPermission();
  static String getPermission() => _getPermission();
  static Future<String?> subscribeToPush(String vapidKey) =>
      _subscribeToPush(vapidKey);
}
