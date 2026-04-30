import 'package:get/get.dart';

import '../controllers/feed_settings_controller.dart';

class FeedSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedSettingsController>(() => FeedSettingsController());
  }
}

