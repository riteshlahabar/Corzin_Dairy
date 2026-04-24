import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../core/theme/colors.dart';

class ShopOrderSuccessView extends StatelessWidget {
  const ShopOrderSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 92,
                  width: 92,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('shop_order_placed_title'.tr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'shop_order_placed_desc'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offAll(() => const MainBottomNavView(initialIndex: 3));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('shop_continue_shopping'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
