import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../../../routes/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    print("🔥 SplashController onInit called");

    Future.delayed(const Duration(seconds: 5), () async {
      print("⏳ Timer finished");

      if (Get.currentRoute != Routes.SPLASH) {
        print("❌ Already left splash → skip navigation");
        return;
      }

      await goToNext();
    });
  }

  Future<void> goToNext() async {
    final seenOnboarding = await SessionService.getSeenOnboarding();
    final isLoggedIn = await SessionService.getLoggedIn();
    final mobile = await SessionService.getMobile();

    print("📌 seenOnboarding: $seenOnboarding");
    print("📌 isLoggedIn: $isLoggedIn");
    print("📌 mobile: $mobile");

    /// first time app open OR after manual logout
    if (!seenOnboarding) {
      print("➡️ Go to Onboarding");
      Get.offAllNamed(Routes.ONBOARDING);
      return;
    }

    /// already logged in -> verify from backend
    if (isLoggedIn && mobile.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(Api.checkUser),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode({"mobile": mobile}),
        );

        print("✅ Splash check response code: ${response.statusCode}");
        print("✅ Splash check response body: ${response.body}");

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 &&
            data["status"] == true &&
            data["is_registered"] == true) {
          /// ✅ ADD THIS BLOCK HERE
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            'farmer_id',
            int.tryParse(data['data']['id'].toString()) ?? 0,
          );

          /// save latest farmer name from backend
          if (data["farmer_name"] != null &&
              data["farmer_name"].toString().isNotEmpty) {
            await SessionService.saveFarmerName(data["farmer_name"].toString());
          }

          print("➡️ Existing registered user -> Home");
          Get.offAllNamed(Routes.HOME);
          return;
        } else {
          /// user deleted from backend OR not registered anymore
          print("❌ User not found in backend -> clear session");
          await SessionService.clearAll();
          Get.offAllNamed(Routes.ONBOARDING);
          return;
        }
      } catch (e) {
        print("❌ Splash backend check error: $e");

        /// internet/api issue -> send to login
        Get.offAllNamed(Routes.LOGIN);
        return;
      }
    }

    /// onboarding done but not logged in
    print("➡️ Not logged in -> Login");
    Get.offAllNamed(Routes.LOGIN);
  }
}
