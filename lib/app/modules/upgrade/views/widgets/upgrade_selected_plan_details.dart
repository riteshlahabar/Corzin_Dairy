import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/colors.dart';
import '../../controllers/upgrade_controller.dart';
import '../../services/upgrade_plan_display_service.dart';

class UpgradeSelectedPlanDetails extends StatelessWidget {
  const UpgradeSelectedPlanDetails({
    super.key,
    required this.controller,
    this.displayService = const UpgradePlanDisplayService(),
  });

  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _softGreen = Color(0xFFEAF7E6);

  final UpgradeController controller;
  final UpgradePlanDisplayService displayService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = controller.selectedPlan;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFD8EAD3)),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayService.planSubtext(plan),
                        style: TextStyle(
                          color: AppColors.grey.shade700,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  plan.price,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...plan.features
                  .take(6)
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: _softGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature.tr,
                              style: const TextStyle(
                                color: AppColors.black,
                                fontSize: 12.8,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      );
    });
  }
}
