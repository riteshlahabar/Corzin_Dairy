import 'package:get/get.dart';

import '../controllers/milk_controller.dart';

class MilkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MilkController>(() => MilkController());
  }
}
