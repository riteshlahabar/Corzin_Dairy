import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/language_controller.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.black,
        automaticallyImplyLeading: controller.fromDrawer,
        title: Text('select_language'.tr),
      ),
      body: Center(
        child: Obx(
          () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'select_language'.tr,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),
              _langButton('english_label'.tr, 'en'),
              _langButton('hindi_label'.tr, 'hi'),
              _langButton('marathi_label'.tr, 'mr'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langButton(String title, String code) {
    return GestureDetector(
      onTap: () => controller.selectLanguage(code),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
        decoration: BoxDecoration(
          color: controller.selectedLang.value == code ? const Color(0xFF5E9E2E) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF5E9E2E)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: controller.selectedLang.value == code ? Colors.white : const Color(0xFF5E9E2E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
