import 'package:get/get.dart';

import '../controllers/dairy_controller.dart';

class DairyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DairyController>(() => DairyController());
  }
}
