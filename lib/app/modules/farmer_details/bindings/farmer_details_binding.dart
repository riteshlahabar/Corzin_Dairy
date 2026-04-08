import 'package:get/get.dart';

import '../controllers/farmer_details_controller.dart';

class FarmerDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FarmerDetailsController>(() => FarmerDetailsController());
  }
}
