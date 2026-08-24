import '../models/plan_model.dart';
import '../repositories/upgrade_repository.dart';
import 'upgrade_action_result.dart';
import 'upgrade_home_subscription_service.dart';

class UpgradeActivationService {
  const UpgradeActivationService({
    UpgradeRepository repository = const UpgradeRepository(),
    UpgradeHomeSubscriptionService homeSubscriptionService =
        const UpgradeHomeSubscriptionService(),
  }) : _repository = repository,
       _homeSubscriptionService = homeSubscriptionService;

  final UpgradeRepository _repository;
  final UpgradeHomeSubscriptionService _homeSubscriptionService;

  Future<UpgradeActionResult> activateFreePlan({
    required int farmerId,
    required PlanModel plan,
  }) async {
    if (farmerId <= 0) {
      return const UpgradeActionResult(
        success: false,
        titleKey: 'error',
        message: 'please_login_again',
      );
    }

    final result = await _repository.activateFreePlan(
      farmerId: farmerId,
      planId: plan.id,
    );

    if (result.success) {
      await _homeSubscriptionService.refreshHomeSubscription();
      return UpgradeActionResult(
        success: true,
        titleKey: 'success',
        message: result.message.isNotEmpty
            ? result.message
            : 'Your free plan activated successfully.',
        navigateHome: true,
      );
    }

    return UpgradeActionResult(
      success: false,
      titleKey: 'info',
      message: result.message.isNotEmpty
          ? result.message
          : 'Unable to activate free plan. Please choose paid plan.',
      reloadPlans: true,
    );
  }
}
