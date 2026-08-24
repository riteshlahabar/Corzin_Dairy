import 'package:get/get.dart';

import '../../../core/services/session_service.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';
import '../models/plan_model.dart';
import '../services/upgrade_action_result.dart';
import '../services/upgrade_activation_service.dart';
import '../services/upgrade_home_subscription_service.dart';
import '../services/upgrade_payment_service.dart';
import '../services/upgrade_plan_catalog_service.dart';
import '../services/upgrade_support_service.dart';

class UpgradeController extends GetxController {
  UpgradeController({
    UpgradePlanCatalogService catalogService =
        const UpgradePlanCatalogService(),
    UpgradeActivationService activationService =
        const UpgradeActivationService(),
    UpgradePaymentService paymentService = const UpgradePaymentService(),
    UpgradeSupportService supportService = const UpgradeSupportService(),
    UpgradeHomeSubscriptionService homeSubscriptionService =
        const UpgradeHomeSubscriptionService(),
  }) : _catalogService = catalogService,
       _activationService = activationService,
       _paymentService = paymentService,
       _supportService = supportService,
       _homeSubscriptionService = homeSubscriptionService;

  final UpgradePlanCatalogService _catalogService;
  final UpgradeActivationService _activationService;
  final UpgradePaymentService _paymentService;
  final UpgradeSupportService _supportService;
  final UpgradeHomeSubscriptionService _homeSubscriptionService;

  final RxBool isLoading = false.obs;
  final RxBool isPurchasingPlan = false.obs;
  final RxInt purchasingPlanId = 0.obs;
  final RxInt selectedPlanId = 0.obs;
  final RxString adminContactName = ''.obs;
  final RxString adminContactNumber = ''.obs;

  int farmerId = 0;
  String farmerName = '';
  String mobileNumber = '';

  late final RxList<PlanModel> plans = _catalogService.fallbackPlans.obs;

  @override
  void onInit() {
    super.onInit();
    _initialise();
  }

  Future<void> _initialise() async {
    await _loadSessionContext();
    await loadData();
  }

  Future<void> _loadSessionContext() async {
    farmerId = await SessionService.getFarmerId();
    farmerName = await SessionService.getFarmerName();
    mobileNumber = await SessionService.getMobile();
  }

  Future<void> loadData() async {
    await Future.wait([loadPlans(), loadAdminContact()]);
  }

  Future<void> loadPlans() async {
    try {
      isLoading.value = true;
      final fetchedPlans = await _catalogService.loadPlans(farmerId: farmerId);
      if (fetchedPlans != null && fetchedPlans.isNotEmpty) {
        plans.assignAll(fetchedPlans);
      }
    } catch (_) {
      // Keep fallback plans when API is not available.
    } finally {
      _ensureSelectedPlan();
      isLoading.value = false;
    }
  }

  void _ensureSelectedPlan() {
    selectedPlanId.value = _catalogService.ensureSelectedPlanId(
      plans,
      selectedPlanId.value,
    );
  }

  void selectPlan(PlanModel plan) {
    if (!plan.isSelectable) {
      _showResult(
        const UpgradeActionResult(
          success: false,
          titleKey: 'info',
          message:
              'Free plan already used for this mobile number. Please choose paid plan.',
        ),
      );
      _ensureSelectedPlan();
      return;
    }
    selectedPlanId.value = plan.id;
  }

  PlanModel get selectedPlan {
    return _catalogService.selectedPlan(plans, selectedPlanId.value);
  }

  Future<void> continueWithSelectedPlan() async {
    final plan = selectedPlan;
    if (!plan.isSelectable) {
      selectPlan(plan);
      return;
    }
    await _runPlanAction(
      plan,
      () => plan.amount > 0
          ? _paymentService.purchasePlan(
              farmerId: farmerId,
              farmerName: farmerName,
              mobileNumber: mobileNumber,
              plan: plan,
            )
          : _activationService.activateFreePlan(farmerId: farmerId, plan: plan),
    );
  }

  Future<void> _runPlanAction(
    PlanModel plan,
    Future<UpgradeActionResult> Function() action,
  ) async {
    if (isPurchasingPlan.value) return;

    try {
      isPurchasingPlan.value = true;
      purchasingPlanId.value = plan.id;
      final result = await action();
      await _handleActionResult(result);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isPurchasingPlan.value = false;
      purchasingPlanId.value = 0;
    }
  }

  Future<void> loadAdminContact() async {
    try {
      final contact = await _supportService.loadAdminContact();
      adminContactName.value = contact['name'] ?? '';
      adminContactNumber.value = contact['number'] ?? '';
    } catch (_) {}
  }

  Future<void> contactAdmin() async {
    final result = await _supportService.contactAdmin(
      adminContactNumber: adminContactNumber.value,
      refreshContact: loadAdminContact,
      latestContactNumber: () => adminContactNumber.value,
    );
    _showResult(result);
  }

  Future<void> _handleActionResult(UpgradeActionResult result) async {
    _showResult(result);
    if (result.reloadPlans) {
      await loadPlans();
    }
    if (result.navigateHome) {
      Get.offAllNamed(Routes.HOME);
    }
  }

  void _showResult(UpgradeActionResult result) {
    if (!result.showMessage || result.message.trim().isEmpty) return;
    final title = result.titleKey.trim().isEmpty ? 'info' : result.titleKey;
    Get.snackbar(title.tr, result.message.tr);
  }

  FarmerPlanModel get currentPlan => _homeSubscriptionService.currentPlan;

  bool get isPlanLocked => _homeSubscriptionService.isPlanLocked;

  String get planLockMessage => _homeSubscriptionService.planLockMessage;

  int get planDaysLeft => _homeSubscriptionService.planDaysLeft;
}
