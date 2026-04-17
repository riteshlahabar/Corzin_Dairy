import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseMessagingService {
  static const String globalNotificationStoreKey = 'farmer_notifications_global';
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> initialise() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return _messaging.getToken();
  }

  Stream<String> tokenRefreshStream() {
    return _messaging.onTokenRefresh;
  }

  Stream<RemoteMessage> foregroundMessageStream() {
    return FirebaseMessaging.onMessage;
  }

  Stream<RemoteMessage> messageOpenedAppStream() {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  Future<RemoteMessage?> getInitialMessage() {
    return FirebaseMessaging.instance.getInitialMessage();
  }

  static Future<void> persistGlobalNotification({
    required String title,
    required String body,
    String type = '',
  }) async {
    final cleanTitle = title.trim().isEmpty ? 'Notification' : title.trim();
    final cleanBody = body.trim().isEmpty ? 'You have a new update.' : body.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(globalNotificationStoreKey);
      final existing = <Map<String, dynamic>>[];
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              existing.add(item.map((k, v) => MapEntry(k.toString(), v)));
            }
          }
        }
      }

      existing.insert(0, {
        'title': cleanTitle,
        'body': cleanBody,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (existing.length > 100) {
        existing.removeRange(100, existing.length);
      }

      await prefs.setString(globalNotificationStoreKey, jsonEncode(existing));
    } catch (_) {}
  }
}
