import 'package:get/get.dart';

import '../controllers/animal_history_controller.dart';

class AnimalHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnimalHistoryController>(() => AnimalHistoryController());
  }
}
