import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: Stack(
        children: [
          /// 🔥 BACKGROUND IMAGE
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            width: double.infinity,
            child: Image.asset("assets/images/screen4.jpeg", fit: BoxFit.cover),
          ),

          /// 🔥 SCROLLABLE CONTENT
          SingleChildScrollView(
            child: Column(
              children: [
                /// SPACE FOR IMAGE
                SizedBox(height: MediaQuery.of(context).size.height * 0.58),

                /// 🔥 LOGIN CARD
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    25,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 15),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Enter your mobile number to continue",
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 25),

                      TextField(
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          controller.mobile.value = value;
                        },
                        decoration: InputDecoration(
                          hintText: "Enter mobile number",
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.sendOtp();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E9E2E),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text("Send OTP"),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Center(
                        child: Text(
                          "By continuing, you agree to our Terms & Conditions",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
