import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../farmer_details/controllers/farmer_details_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      Get.put<HomeController>(
        HomeController(),
        permanent: true,
      );
    }

    if (!Get.isRegistered<FarmerDetailsController>()) {
      Get.lazyPut<FarmerDetailsController>(
        () => FarmerDetailsController(),
        fenix: true,
      );
    }
  }
}