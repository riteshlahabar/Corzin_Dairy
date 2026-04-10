import 'package:dairycorzin/app/core/theme/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/core/services/local_notification_service.dart';
import 'app/core/translations/translations.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
