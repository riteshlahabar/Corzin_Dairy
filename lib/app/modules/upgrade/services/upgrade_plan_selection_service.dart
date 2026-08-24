import '../models/plan_model.dart';

class UpgradePlanSelectionService {
  const UpgradePlanSelectionService();

  int ensureSelectedPlanId(List<PlanModel> plans, int currentId) {
    final selectablePlans = plans.where((plan) => plan.isSelectable).toList();
    if (selectablePlans.isEmpty) {
      return 0;
    }

    if (currentId != 0 && selectablePlans.any((plan) => plan.id == currentId)) {
      return currentId;
    }

    final highlighted = selectablePlans
        .where((plan) => plan.highlighted)
        .cast<PlanModel?>()
        .firstWhere((plan) => plan != null, orElse: () => null);
    return (highlighted ?? selectablePlans.first).id;
  }

  PlanModel selectedPlan(List<PlanModel> plans, int selectedPlanId) {
    if (plans.isEmpty) {
      return fallbackPaidPlan;
    }

    for (final plan in plans) {
      if (plan.id == selectedPlanId) {
        return plan;
      }
    }
    return plans.first;
  }

  static const PlanModel fallbackFreePlan = PlanModel(
    name: 'free_plan',
    price: 'Rs 0',
    amount: 0,
    features: ['limited_animals', 'limited_pans', 'basic_dashboard'],
    highlighted: false,
  );

  static const PlanModel fallbackPaidPlan = PlanModel(
    name: 'paid_plan',
    price: 'Rs 999 / year',
    amount: 999,
    features: ['unlimited_animals', 'unlimited_pans', 'advanced_reports'],
    highlighted: true,
  );
}
