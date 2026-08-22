import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/login_otp_controller.dart';

class LoginOtpView extends GetView<LoginOtpController> {
  const LoginOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// 🔹 TITLE
              const Text(
                "Verify OTP",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                "Enter the 6 digit code sent to your mobile",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              Obx(
                () => Text(
                  controller.otpSecondsRemaining.value > 0
                      ? "OTP expires in ${controller.formatTimer(controller.otpSecondsRemaining.value)}"
                      : "OTP expired. Please resend OTP.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: controller.otpSecondsRemaining.value > 0
                        ? Colors.grey
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// 🔹 OTP BOXES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextField(
                      controller: controller.otpControllers[index],
                      focusNode: controller.focusNodes[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      /// 🔥 AUTO MOVE NEXT
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          controller.moveToNext(index);
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              /// 🔹 VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E9E2E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF8DBD6B),
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text("Verifying..."),
                            ],
                          )
                        : const Text("Verify"),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 RESEND
              Obx(
                () {
                  final canResend = controller.resendSecondsRemaining.value <= 0 &&
                      !controller.isResending.value &&
                      !controller.isLoading.value;

                  return TextButton(
                    onPressed: canResend ? controller.resendOtp : null,
                    child: controller.isResending.value
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text("Resending OTP..."),
                            ],
                          )
                        : Text(
                            controller.resendSecondsRemaining.value > 0
                                ? "Resend OTP in ${controller.resendSecondsRemaining.value}s"
                                : "Resend OTP",
                            style: TextStyle(
                              color: canResend ? Colors.green : Colors.grey,
                            ),
                          ),
                  );
                },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
