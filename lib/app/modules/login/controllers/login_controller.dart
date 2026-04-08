import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  var mobile = ''.obs;
  RxBool isLoading = false.obs;

  Future<void> sendOtp() async {
    if (isLoading.value) return;

    final phone = mobile.value.trim();
    print("📱 Mobile: $phone");

    if (phone.isEmpty) {
      Get.snackbar("Error", "Enter mobile number");
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      Get.snackbar("Error", "Enter valid mobile number");
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

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(credential);

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
            print("❌ Auto verification sign-in error: $e");
            Get.snackbar("Error", "Auto verification failed");
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          print("❌ verificationFailed: ${e.message}");
          Get.snackbar("Error", e.message ?? "OTP failed");
        },

        codeSent: (String verificationId, int? resendToken) {
          print("✅ OTP sent. verificationId: $verificationId");

          Get.offNamed(
            Routes.LOGIN_OTP,
            arguments: {
              "verificationId": verificationId,
              "mobile": phone,
              "isTestNumber": false,
              "autoVerified": false,
            },
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          print("⏰ Auto retrieval timeout: $verificationId");
        },
      );
    } catch (e) {
      print("❌ sendOtp error: $e");
      Get.snackbar("Error", "Something went wrong while sending OTP");
    } finally {
      isLoading.value = false;
    }
  }
}
