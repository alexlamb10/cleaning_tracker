// Web implementation — only compiled on flutter web targets.
// Uses dart:js / dart:js_util which are unavailable on mobile.
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class NotificationService {
  static Future<String> requestPermission() async {
    try {
      final promise = js.context.callMethod('requestNotificationPermission');
      final status = await js_util.promiseToFuture<String>(promise);
      return status;
    } catch (e) {
      return 'unsupported';
    }
  }

  static String getPermission() {
    try {
      return js.context.callMethod('getNotificationPermission') as String;
    } catch (e) {
      return 'unsupported';
    }
  }

  static Future<String?> subscribeToPush(String vapidKey) async {
    try {
      final promise = js.context.callMethod('subscribeToPush', [vapidKey]);
      final result = await js_util.promiseToFuture<dynamic>(promise);
      return result?.toString();
    } catch (e) {
      return null;
    }
  }
}