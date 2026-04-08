import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  OnboardingView({super.key});

  final PageController pageController = PageController();

  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/screen1.jpeg",
      "title": "Farm Care",
      "desc":
          "Dedicated farmers nurture healthy cows with care, ensuring ethical practices and superior milk quality.",
    },
    {
      "image": "assets/images/screen2.jpeg",
      "title": "Fresh Milking",
      "desc":
          "Hygienic milking processes ensure pure, fresh milk collected safely with modern and traditional techniques.",
    },
    {
      "image": "assets/images/screen3.jpeg",
      "title": "Quality Dairy",
      "desc":
          "From farm to table, we deliver nutritious dairy products tested for purity and freshness.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            onPageChanged: controller.onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final item = pages[index];

              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(item["image"] ?? "", fit: BoxFit.cover),

                  Container(color: Colors.black.withValues(alpha: 0.3)),

                  Positioned(
                    bottom: 160,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Text(
                          item["title"] ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item["desc"] ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                await controller.onGetStarted();
              },
              child: const Text(
                "Skip",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Obx(
                  () => AnimatedSmoothIndicator(
                    activeIndex: controller.currentPage.value,
                    count: pages.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.currentPage.value == pages.length - 1) {
                        await controller.onGetStarted();
                      } else {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E9E2E),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Obx(
                      () => Text(
                        controller.currentPage.value == pages.length - 1
                            ? "Get started"
                            : "Next",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
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
