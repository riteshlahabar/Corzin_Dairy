import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  var mobile = ''.obs;
  RxBool isLoading = false.obs;

  Future<void> sendOtp() async {
    if (isLoading.value) return;

    final phone = mobile.value.trim();
    debugPrint("📱 Mobile: $phone");

    if (phone.isEmpty) {
      Get.snackbar('error'.tr, 'enter_mobile_number'.tr);
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      Get.snackbar('error'.tr, 'enter_valid_mobile_number'.tr);
      return;
    }

    isLoading.value = true;

    try {
      /// special test numbers -> skip firebase otp
      if (phone == "9999999999" || phone == "8888888888") {
        Get.offNamed(
          Routes.LOGIN_OTP,
          arguments: {
            "verificationId": "manual_skip",
            "mobile": phone,
            "isTestNumber": true,
            "autoVerified": false,
          },
        );
        return;
      }

      /// firebase otp flow
      final FirebaseAuth auth = FirebaseAuth.instance;

      await auth.verifyPhoneNumber(
        phoneNumber: "+91$phone",
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(credential);
            isLoading.value = false;

            Get.offNamed(
              Routes.LOGIN_OTP,
              arguments: {
                "verificationId": "auto_verified",
                "mobile": phone,
                "isTestNumber": false,
                "autoVerified": true,
              },
            );
          } catch (e) {
            debugPrint("❌ Auto verification sign-in error: $e");
            isLoading.value = false;
            Get.snackbar('error'.tr, 'auto_verification_failed'.tr);
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint("❌ verificationFailed: ${e.message}");
          isLoading.value = false;
          Get.snackbar('error'.tr, e.message ?? 'otp_failed'.tr);
        },

        codeSent: (String verificationId, int? resendToken) {
          debugPrint("✅ OTP sent. verificationId: $verificationId");
          isLoading.value = false;

          Get.offNamed(
            Routes.LOGIN_OTP,
            arguments: {
              "verificationId": verificationId,
              "resendToken": resendToken,
              "mobile": phone,
              "isTestNumber": false,
              "autoVerified": false,
            },
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("⏰ Auto retrieval timeout: $verificationId");
        },
      );
    } catch (e) {
      debugPrint("❌ sendOtp error: $e");
      isLoading.value = false;
      Get.snackbar('error'.tr, 'something_went_wrong_sending_otp'.tr);
    }
  }
}

