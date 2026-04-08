import 'package:flutter/material.dart';
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
                child: ElevatedButton(
                  onPressed: controller.verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E9E2E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Verify"),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 RESEND
              TextButton(
                onPressed: controller.resendOtp,
                child: const Text(
                  "Resend OTP",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
