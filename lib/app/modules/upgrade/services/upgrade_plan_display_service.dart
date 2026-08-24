import 'package:get/get.dart';

import '../models/plan_model.dart';

class UpgradePlanDisplayService {
  const UpgradePlanDisplayService();

  PlanModel spotlightPlan(List<PlanModel> plans) {
    for (final plan in plans) {
      if (plan.highlighted) return plan;
    }
    if (plans.isNotEmpty) {
      return plans.first;
    }
    return const PlanModel(
      name: 'paid_plan',
      price: 'Rs 0',
      amount: 0,
      features: <String>[],
      highlighted: false,
    );
  }

  bool isTwelveMonthPlan(PlanModel plan) {
    final name = plan.name.toLowerCase();
    return name.contains('12 month') ||
        name.contains('12month') ||
        name.contains('year');
  }

  String planTitle(PlanModel plan) {
    final name = plan.name.toLowerCase();

    if (name.contains('12 month') ||
        name.contains('12month') ||
        name.contains('year')) {
      return 'yearly'.tr;
    }
    if (name.contains('6 month') || name.contains('6month')) {
      return 'half_yearly'.tr;
    }
    if (name.contains('month')) {
      return 'monthly'.tr;
    }
    if (plan.amount <= 0) {
      return 'free_trial'.tr;
    }
    return plan.name.tr;
  }

  String planSubtext(PlanModel plan) {
    final name = plan.name.toLowerCase();

    if (name.contains('12 month') ||
        name.contains('12month') ||
        name.contains('year')) {
      return 'billed_annually'.tr;
    }
    if (name.contains('6 month') || name.contains('6month')) {
      return 'billed_every_6_months'.tr;
    }
    if (name.contains('month')) {
      return 'billed_monthly'.tr;
    }
    if (plan.amount <= 0) {
      return 'play_after_trial'.tr;
    }
    return plan.highlighted ? 'best_value_plan'.tr : 'flexible_farm_plan'.tr;
  }
}
