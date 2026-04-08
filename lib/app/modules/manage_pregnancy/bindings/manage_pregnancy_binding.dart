import 'package:get/get.dart';

import '../controllers/manage_pregnancy_controller.dart';

class ManagePregnancyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManagePregnancyController>(() => ManagePregnancyController());
  }
}
