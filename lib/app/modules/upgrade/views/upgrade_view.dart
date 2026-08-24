import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/upgrade_controller.dart';
import 'widgets/upgrade_continue_button.dart';
import 'widgets/upgrade_current_plan_card.dart';
import 'widgets/upgrade_plan_selector.dart';
import 'widgets/upgrade_premium_showcase.dart';
import 'widgets/upgrade_selected_plan_details.dart';

class UpgradeView extends GetView<UpgradeController> {
  const UpgradeView({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomSafePadding = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom
        : mediaQuery.viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !controller.isPlanLocked,
        leading: controller.isPlanLocked
            ? null
            : IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(
          'upgrade_plan'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  bottomSafePadding + 24,
                ),
                children: [
                  UpgradePremiumShowcase(plans: controller.plans),
                  const SizedBox(height: 16),
                  UpgradeCurrentPlanCard(controller: controller),
                  const SizedBox(height: 18),
                  UpgradePlanSelector(controller: controller),
                  const SizedBox(height: 18),
                  UpgradeSelectedPlanDetails(controller: controller),
                  const SizedBox(height: 18),
                  UpgradeContinueButton(controller: controller),
                  // Manual QR payment section is hidden while Razorpay live payment is active.
                ],
              ),
      ),
    );
  }

  void _goBack() {
    if (controller.isPlanLocked) {
      return;
    }
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }
}
