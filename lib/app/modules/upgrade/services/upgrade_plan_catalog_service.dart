import '../models/plan_model.dart';
import '../repositories/upgrade_repository.dart';
import 'upgrade_plan_selection_service.dart';

class UpgradePlanCatalogService {
  const UpgradePlanCatalogService({
    UpgradeRepository repository = const UpgradeRepository(),
    UpgradePlanSelectionService selectionService =
        const UpgradePlanSelectionService(),
  }) : _repository = repository,
       _selectionService = selectionService;

  final UpgradeRepository _repository;
  final UpgradePlanSelectionService _selectionService;

  List<PlanModel> get fallbackPlans => const [
    UpgradePlanSelectionService.fallbackFreePlan,
    UpgradePlanSelectionService.fallbackPaidPlan,
  ];

  Future<List<PlanModel>?> loadPlans({required int farmerId}) {
    return _repository.fetchPlans(farmerId: farmerId);
  }

  int ensureSelectedPlanId(List<PlanModel> plans, int currentId) {
    return _selectionService.ensureSelectedPlanId(plans, currentId);
  }

  PlanModel selectedPlan(List<PlanModel> plans, int selectedPlanId) {
    return _selectionService.selectedPlan(plans, selectedPlanId);
  }
}
