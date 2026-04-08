import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../farmer_details/controllers/farmer_details_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());

    /// 🔥 FIX: Register FarmerDetailsController
    Get.lazyPut<FarmerDetailsController>(() => FarmerDetailsController());
  }
}
