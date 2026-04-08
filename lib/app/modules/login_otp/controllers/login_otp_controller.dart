import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../../../routes/app_pages.dart';

class LoginOtpController extends GetxController {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  late String verificationId;
  late String mobile;
  bool isTestNumber = false;
  bool autoVerified = false;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    verificationId = Get.arguments?["verificationId"] ?? "";
    mobile = Get.arguments?["mobile"] ?? "";
    isTestNumber = Get.arguments?["isTestNumber"] ?? false;
    autoVerified = Get.arguments?["autoVerified"] ?? false;

    print("📱 OTP Screen Mobile: $mobile");
    print("🔐 VerificationId: $verificationId");
    print("🧪 isTestNumber: $isTestNumber");
    print("⚡ autoVerified: $autoVerified");

    /// If firebase auto verification completed
    if (autoVerified) {
      Future.microtask(() async {
        await handlePostOtpSuccess();
      });
    }
  }

  void moveToNext(int index) {
    if (index < 5) {
      focusNodes[index + 1].requestFocus();
    } else {
      focusNodes[index].unfocus();
    }
  }

  String getOtp() {
    return otpControllers.map((e) => e.text.trim()).join();
  }

  Future<void> verifyOtp() async {
    if (isLoading.value) return;

    final otp = getOtp();
    print("🔐 Entered OTP: $otp");

    if (!autoVerified && otp.length < 6) {
      Get.snackbar("Error", "Enter complete OTP");
      return;
    }

    isLoading.value = true;

    try {
      /// Case 1: special test numbers skip firebase verification
      if (isTestNumber) {
        if (otp != "123456") {
          Get.snackbar("Error", "Invalid OTP");
          isLoading.value = false;
          return;
        }
      }

      /// Case 2: normal firebase OTP verification
      if (!isTestNumber && !autoVerified) {
        final PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      await handlePostOtpSuccess();
    } catch (e) {
      print("❌ verifyOtp error: $e");
      Get.snackbar("Error", "Invalid OTP");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handlePostOtpSuccess() async {
    /// Save basic session immediately after OTP success
    await SessionService.setLoggedIn(true);
    await SessionService.saveMobile(mobile);
    await SessionService.setSeenOnboarding(true);

    /// Check backend registration status
    await checkUserAndNavigate();
  }

  Future<void> checkUserAndNavigate() async {
    try {
      final response = await http.post(
        Uri.parse(Api.checkUser),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"mobile": mobile}),
      );

      print("✅ checkUser statusCode: ${response.statusCode}");
      print("✅ checkUser response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == true) {
        final bool isRegistered = data["is_registered"] == true;

        if (isRegistered) {
          await SessionService.setRegistered(true);

          if (data["farmer_name"] != null &&
              data["farmer_name"].toString().isNotEmpty) {
            await SessionService.saveFarmerName(data["farmer_name"].toString());
          }

          /// Existing user -> Home
          Get.offAllNamed(Routes.HOME);
          return;
        } else {
          await SessionService.setRegistered(false);

          /// New user -> Farmer Details
          Get.offAllNamed(
            Routes.FARMER_DETAILS,
            arguments: {"mobile": mobile, "lang": "en"},
          );
          return;
        }
      }

      /// Unexpected response
      await SessionService.setLoggedIn(false);
      Get.snackbar("Error", "Unable to verify user");
    } catch (e) {
      print("❌ checkUserAndNavigate error: $e");
      await SessionService.setLoggedIn(false);
      Get.snackbar("Error", "Failed to verify user");
    }
  }

  Future<void> resendOtp() async {
    Get.snackbar("Info", "OTP Resent to $mobile");
  }

  @override
  void onClose() {
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.onClose();
  }
}
