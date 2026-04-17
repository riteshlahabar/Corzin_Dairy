import 'package:dairycorzin/app/core/theme/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/core/services/firebase_messaging_service.dart';
import 'app/core/services/local_notification_service.dart';
import 'app/core/translations/translations.dart';
import 'app/routes/app_pages.dart';

@pragma('vm:entry-point')
Future<void> _farmerFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final title = message.notification?.title?.trim().isNotEmpty == true
      ? message.notification!.title!.trim()
      : (message.data['title']?.toString().trim().isNotEmpty == true
          ? message.data['title']!.toString().trim()
          : (message.data['event']?.toString().trim().isNotEmpty == true
              ? message.data['event']!.toString().trim()
              : 'Notification'));
  final body = message.notification?.body?.trim().isNotEmpty == true
      ? message.notification!.body!.trim()
      : (message.data['body']?.toString().trim().isNotEmpty == true
          ? message.data['body']!.toString().trim()
          : (message.data['message']?.toString().trim().isNotEmpty == true
              ? message.data['message']!.toString().trim()
              : 'You have a new update.'));

  await FirebaseMessagingService.persistGlobalNotification(
    title: title,
    body: body,
    type: message.data['type']?.toString() ?? '',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_farmerFirebaseBackgroundHandler);
  await LocalNotificationService.instance.initialise();

  final prefs = await SharedPreferences.getInstance();
  final localeCode = prefs.getString('app_language') ?? 'en';

  runApp(MyApp(localeCode: localeCode));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.localeCode = 'en'});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: MyTranslations(),
      locale: Locale(localeCode),
      fallbackLocale: const Locale('en'),
      debugShowCheckedModeBanner: false,
      title: 'DairyCorzin',
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        fontFamily: 'SFPro',
        scaffoldBackgroundColor: AppColors.white,
        primaryColor: AppColors.primary,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
