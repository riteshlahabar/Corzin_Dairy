import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final splashController = controller;
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: GestureDetector(
          onTap: () {
            splashController.goToNext();
          },

          /// ✅ FIXED: added child
          child: Image.asset(
            "assets/images/img_frame.jpeg",
            height: 130,
            width: 139,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
