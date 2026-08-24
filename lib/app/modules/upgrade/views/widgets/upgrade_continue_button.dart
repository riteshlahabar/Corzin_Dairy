import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/upgrade_controller.dart';

class UpgradeContinueButton extends StatelessWidget {
  const UpgradeContinueButton({super.key, required this.controller});

  static const Color _primaryGreen = Color(0xFF2E7D32);

  final UpgradeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = controller.selectedPlan;
      final canContinue = plan.isSelectable && plan.id > 0;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF145423)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: controller.isPurchasingPlan.value || !canContinue
              ? null
              : controller.continueWithSelectedPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: controller.isPurchasingPlan.value
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_open_rounded, size: 19),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'continue_with_plan'.trParams({'price': plan.price}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}
