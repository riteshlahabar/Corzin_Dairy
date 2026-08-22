import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/firebase_messaging_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../../../routes/app_pages.dart';

class LoginOtpController extends GetxController {
  static const int otpValidityDurationSeconds = 15 * 60;
  static const int resendCooldownSeconds = 30;

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  late String verificationId;
  late String mobile;
  int? resendToken;
  bool isTestNumber = false;
  bool autoVerified = false;
  RxBool isLoading = false.obs;
  RxBool isResending = false.obs;
  RxInt otpSecondsRemaining = otpValidityDurationSeconds.obs;
  RxInt resendSecondsRemaining = resendCooldownSeconds.obs;
  Timer? _otpTimer;
  Timer? _resendTimer;
  final FirebaseMessagingService _firebaseMessagingService = FirebaseMessagingService();

  @override
  void onInit() {
    super.onInit();

    verificationId = Get.arguments?["verificationId"] ?? "";
    resendToken = Get.arguments?["resendToken"];
    mobile = Get.arguments?["mobile"] ?? "";
    isTestNumber = Get.arguments?["isTestNumber"] ?? false;
    autoVerified = Get.arguments?["autoVerified"] ?? false;

    debugPrint("📱 OTP Screen Mobile: $mobile");
    debugPrint("🔐 VerificationId: $verificationId");
    debugPrint("🔁 Resend token: $resendToken");
    debugPrint("🧪 isTestNumber: $isTestNumber");
    debugPrint("⚡ autoVerified: $autoVerified");

    startOtpTimer();
    startResendTimer();

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

  bool get isOtpExpired {
    return !autoVerified && otpSecondsRemaining.value <= 0;
  }

  String formatTimer(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startOtpTimer() {
    _otpTimer?.cancel();
    otpSecondsRemaining.value = otpValidityDurationSeconds;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpSecondsRemaining.value <= 1) {
        otpSecondsRemaining.value = 0;
        timer.cancel();
        return;
      }
      otpSecondsRemaining.value--;
    });
  }

  void startResendTimer() {
    _resendTimer?.cancel();
    resendSecondsRemaining.value = resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsRemaining.value <= 1) {
        resendSecondsRemaining.value = 0;
        timer.cancel();
        return;
      }
      resendSecondsRemaining.value--;
    });
  }

  void clearOtp() {
    for (final controller in otpControllers) {
      controller.clear();
    }
    if (focusNodes.isNotEmpty) {
      focusNodes.first.requestFocus();
    }
  }

  Future<void> verifyOtp() async {
    if (isLoading.value) return;

    final otp = getOtp();
    debugPrint("🔐 Entered OTP: $otp");

    if (!autoVerified && otp.length < 6) {
      Get.snackbar('error'.tr, 'enter_complete_otp'.tr);
      return;
    }

    if (isOtpExpired) {
      Get.snackbar('error'.tr, 'OTP expired. Please resend OTP.');
      return;
    }

    isLoading.value = true;

    try {
      /// Case 1: special test numbers skip firebase verification
      if (isTestNumber) {
        if (otp != "123456") {
          Get.snackbar('error'.tr, 'invalid_otp'.tr);
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
      debugPrint("❌ verifyOtp error: $e");
      Get.snackbar('error'.tr, 'invalid_otp'.tr);
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
      final deviceId = await SessionService.getOrCreateDeviceId();
      final fcmToken = await _loadFcmToken();
      final response = await http.post(
        Uri.parse(Api.checkUser),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "mobile": mobile,
          "device_id": deviceId,
          "fcm_token": fcmToken,
          "start_session": true,
        }),
      );

      debugPrint("✅ checkUser statusCode: ${response.statusCode}");
      debugPrint("✅ checkUser response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 403 && data["account_inactive"] == true) {
        await SessionService.setLoggedIn(false);
        final dynamic adminContact = data["admin_contact"];
        String adminNumber = "";
        if (adminContact is Map) {
          adminNumber = (adminContact["number"] ?? "").toString().trim();
        }
        _showInactiveAccountMessage(adminNumber);
        Get.offAllNamed(Routes.LOGIN);
        return;
      }

      if (response.statusCode == 401 && data["force_logout"] == true) {
        await SessionService.forceLogoutFromAnotherDevice();
        Get.offAllNamed(Routes.LOGIN);
        return;
      }

      if (response.statusCode == 200 && data["status"] == true) {
        final bool isRegistered = data["is_registered"] == true;
        final Map<String, dynamic> farmerData = data["data"] is Map
            ? Map<String, dynamic>.from(data["data"] as Map)
            : <String, dynamic>{};

        if (isRegistered) {
          await SessionService.setRegistered(true);
          await SessionService.saveActiveSessionToken(data["session_token"]?.toString() ?? "");

          final dynamic farmerIdValue = farmerData["id"];
          final int farmerId = farmerIdValue is int
              ? farmerIdValue
              : int.tryParse(farmerIdValue?.toString() ?? "0") ?? 0;
          if (farmerId > 0) {
            await SessionService.saveFarmerId(farmerId);
          }

          if (data["farmer_name"] != null &&
              data["farmer_name"].toString().isNotEmpty) {
            await SessionService.saveFarmerName(data["farmer_name"].toString());
          }

          await SessionService.saveFarmerProfile(
            firstName: farmerData["first_name"]?.toString() ?? "",
            middleName: farmerData["middle_name"]?.toString() ?? "",
            lastName: farmerData["last_name"]?.toString() ?? "",
            village: farmerData["village"]?.toString() ?? "",
            city: farmerData["city"]?.toString() ?? "",
            taluka: farmerData["taluka"]?.toString() ?? "",
            district: farmerData["district"]?.toString() ?? "",
            state: farmerData["state"]?.toString() ?? "",
            pincode: farmerData["pincode"]?.toString() ?? "",
            farmerPhoto: farmerData["farmer_photo"]?.toString() ?? "",
          );
          await SessionService.saveFarmerLocation(
            latitude: farmerData["latitude"]?.toString() ?? "",
            longitude: farmerData["longitude"]?.toString() ?? "",
            currentLocationAddress: farmerData["current_location_address"]?.toString() ?? "",
          );

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
      Get.snackbar('error'.tr, 'unable_verify_user'.tr);
    } catch (e) {
      debugPrint("❌ checkUserAndNavigate error: $e");
      await SessionService.setLoggedIn(false);
      Get.snackbar('error'.tr, 'failed_verify_user'.tr);
    }
  }

  Future<void> resendOtp() async {
    if (isResending.value || isLoading.value) return;

    if (resendSecondsRemaining.value > 0) {
      Get.snackbar(
        'info'.tr,
        'Please wait ${resendSecondsRemaining.value} seconds before resending OTP.',
      );
      return;
    }

    if (mobile.trim().isEmpty) {
      Get.snackbar('error'.tr, 'enter_valid_mobile_number'.tr);
      return;
    }

    if (isTestNumber) {
      clearOtp();
      startOtpTimer();
      startResendTimer();
      Get.snackbar('info'.tr, 'otp_resent_to'.trParams({'mobile': mobile}));
      return;
    }

    isResending.value = true;

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$mobile",
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            autoVerified = true;
            isResending.value = false;
            await handlePostOtpSuccess();
          } catch (e) {
            debugPrint("❌ Resend auto verification sign-in error: $e");
            isResending.value = false;
            Get.snackbar('error'.tr, 'auto_verification_failed'.tr);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("❌ resend verificationFailed: ${e.message}");
          isResending.value = false;
          Get.snackbar('error'.tr, e.message ?? 'otp_failed'.tr);
        },
        codeSent: (String newVerificationId, int? newResendToken) {
          debugPrint("✅ OTP resent. verificationId: $newVerificationId");
          verificationId = newVerificationId;
          resendToken = newResendToken ?? resendToken;
          isResending.value = false;
          clearOtp();
          startOtpTimer();
          startResendTimer();
          Get.snackbar('info'.tr, 'otp_resent_to'.trParams({'mobile': mobile}));
        },
        codeAutoRetrievalTimeout: (String newVerificationId) {
          verificationId = newVerificationId;
          debugPrint("⏰ Resend auto retrieval timeout: $newVerificationId");
        },
      );
    } catch (e) {
      debugPrint("❌ resendOtp error: $e");
      isResending.value = false;
      Get.snackbar('error'.tr, 'something_went_wrong_sending_otp'.tr);
    }
  }

  void _showInactiveAccountMessage(String adminNumber) {
    final message = adminNumber.isEmpty
        ? 'account_inactive_message'.tr
        : 'account_inactive_message_with_admin'.trParams({'number': adminNumber});

    Get.closeAllSnackbars();
    Get.snackbar(
      'account_inactive'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 10),
      margin: const EdgeInsets.all(12),
    );
  }

  Future<String> _loadFcmToken() async {
    try {
      return (await _firebaseMessagingService.initialise())?.trim() ?? "";
    } catch (_) {
      return "";
    }
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    _resendTimer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.onClose();
  }
}

