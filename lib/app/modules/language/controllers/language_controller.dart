import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';

class LanguageController extends GetxController {
  final RxString selectedLang = 'en'.obs;

  String mobile = '';
  bool fromDrawer = false;

  @override
  void onInit() {
    super.onInit();
    mobile = Get.arguments?['mobile'] ?? '';
    fromDrawer = Get.arguments?['fromDrawer'] == true;
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    selectedLang.value = prefs.getString('app_language') ?? 'en';
  }

  Future<void> selectLanguage(String code) async {
  selectedLang.value = code;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_language', code);

  if (fromDrawer && !Get.isRegistered<HomeController>()) {
    Get.put<HomeController>(
      HomeController(),
      permanent: true,
    );
  }

  Get.updateLocale(Locale(code));
  Get.snackbar('success'.tr, 'language_success'.tr);

  await Future.delayed(const Duration(milliseconds: 700));

  if (fromDrawer) {
    Get.offAllNamed(Routes.HOME);
    return;
  }

  Get.toNamed(
    Routes.FARMER_DETAILS,
    arguments: {'lang': code, 'mobile': mobile},
  );
}
}
