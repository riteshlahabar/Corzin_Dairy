import 'package:dairycorzin/app/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/routes/app_pages.dart';
import 'app/core/translations/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      translations: MyTranslations(), // ✅ ADD
      locale: Locale(localeCode),
      fallbackLocale: const Locale('en'),
      debugShowCheckedModeBanner: false,

      /// 🔹 App Name
      title: 'DairyCorzin',

      /// 🔹 Initial Route (Splash)
      initialRoute: AppPages.INITIAL,
      //home: const MainBottomNavView(),

      /// 🔹 All Routes
      getPages: AppPages.routes,

      /// 🔹 Theme (keep simple for now, we’ll match design later)
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
