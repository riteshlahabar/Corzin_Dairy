import 'package:get/get.dart';

import '../controllers/manage_animal_controller.dart';

class ManageAnimalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ManageAnimalController>(() => ManageAnimalController());
  }
}
