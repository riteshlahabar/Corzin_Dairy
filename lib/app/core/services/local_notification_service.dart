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

    final title = _resolveTitle(message);
    final body = _resolveBody(message);

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

  Future<void> showMessage({
    required String title,
    required String body,
    required int id,
  }) async {
    await initialise();
    await _plugin.show(
      id,
      title,
      body,
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

  String? _resolveTitle(RemoteMessage message) {
    final notificationTitle = message.notification?.title?.trim();
    if (notificationTitle != null && notificationTitle.isNotEmpty) return notificationTitle;

    final dataTitle = message.data['title']?.toString().trim();
    if (dataTitle != null && dataTitle.isNotEmpty) return dataTitle;

    return null;
  }

  String? _resolveBody(RemoteMessage message) {
    var body = message.notification?.body?.trim();
    if (body == null || body.isEmpty) {
      final dataBody = message.data['body']?.toString().trim();
      if (dataBody != null && dataBody.isNotEmpty) {
        body = dataBody;
      }
    }

    final otp = message.data['visit_otp']?.toString().trim().isNotEmpty == true
        ? message.data['visit_otp']!.toString().trim()
        : (message.data['otp']?.toString().trim().isNotEmpty == true
            ? message.data['otp']!.toString().trim()
            : '');

    if (otp.isNotEmpty) {
      final otpLine = 'Visit OTP: $otp';
      if (body == null || body.isEmpty) {
        body = otpLine;
      } else if (!body.contains(otp)) {
        body = '$body\n$otpLine';
      }
    }

    return body;
  }
}
