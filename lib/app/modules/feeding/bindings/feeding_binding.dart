import 'package:get/get.dart';

import '../controllers/feeding_controller.dart';

class FeedingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedingController>(() => FeedingController());
  }
}
