import 'package:get/get.dart';

import '../controllers/animal_controller.dart';

class AnimalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnimalController>(() => AnimalController());
  }
}
