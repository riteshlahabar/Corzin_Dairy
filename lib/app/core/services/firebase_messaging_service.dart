import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
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
}
