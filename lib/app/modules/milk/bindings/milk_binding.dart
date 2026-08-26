import 'package:get/get.dart';

import '../controllers/milk_controller.dart';

class MilkBinding extends Bindings {
  @override
  void dependencies() {
    // MilkView is rendered inside MainBottomNavView instead of being pushed as
    // a GetPage route. Keep its controller alive for the Home session so an
    // overlay (for example Quick Add) cannot dispose it while MilkView is
    // still mounted.
    if (!Get.isRegistered<MilkController>()) {
      Get.put<MilkController>(MilkController(), permanent: true);
    }
  }
}
