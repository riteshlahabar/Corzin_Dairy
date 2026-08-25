import 'package:get/get.dart';

import '../../home/controllers/home_controller.dart';

class UpgradeHomeSubscriptionService {
  const UpgradeHomeSubscriptionService();

  Future<void> refreshHomeSubscription() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadDashboard(silent: true);
    }
  }

  FarmerPlanModel get currentPlan {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>().currentPlan.value;
    }
    return const FarmerPlanModel(
      name: 'plan',
      amount: '-',
      expiryDate: '-',
      startDate: '-',
      renewDate: '-',
    );
  }

  bool get isPlanLocked {
    return Get.isRegistered<HomeController>() &&
        Get.find<HomeController>().isPlanLocked.value;
  }

  String get planLockMessage {
    if (!Get.isRegistered<HomeController>()) return '';
    return Get.find<HomeController>().planLockMessage.value;
  }

  int get planDaysLeft {
    if (!Get.isRegistered<HomeController>()) return 0;
    return Get.find<HomeController>().planDaysLeft.value;
  }
}
