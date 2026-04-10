import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialised = false;

  Future<void> initialise() async {
    if (_isInitialised) return;

    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'doctor_updates',
        'Doctor Updates',
        description: 'Notifications for doctor appointments and approvals.',
        importance: Importance.max,
      ),
    );

    _isInitialised = true;
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    await initialise();

    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _plugin.show(
      message.hashCode,
      title?.isNotEmpty == true ? title : 'Notification',
      body?.isNotEmpty == true ? body : 'You have a new update.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'doctor_updates',
          'Doctor Updates',
          channelDescription:
              'Notifications for doctor appointments and approvals.',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_launcher',
        ),
      ),
    );
  }
}
