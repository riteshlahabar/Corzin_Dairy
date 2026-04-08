import 'package:get/get.dart';
import '../../../core/services/session_service.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  var currentPage = 0.obs;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> onGetStarted() async {
    await SessionService.setSeenOnboarding(true);

    final isLoggedIn = await SessionService.getLoggedIn();

    if (isLoggedIn) {
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
