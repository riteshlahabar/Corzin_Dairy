part of 'health_controller.dart';

class HealthSubmitCoordinator {
  HealthSubmitCoordinator({
    required this.isSubmitting,
    required this.setLastSubmitMessage,
  });

  final RxBool isSubmitting;
  final void Function(String message) setLastSubmitMessage;

  Future<bool> submit({
    required Future<HealthApiResponse> Function() request,
    required String successMessage,
    required Future<void> Function() onSuccess,
    bool showSuccessSnackbar = true,
  }) async {
    try {
      isSubmitting.value = true;
      setLastSubmitMessage('');
      final response = await request();
      if (response.isSuccess) {
        await onSuccess();
        final message = response.message(fallback: successMessage);
        setLastSubmitMessage(message);
        if (showSuccessSnackbar) {
          Get.snackbar(
            'Success',
            message,
            duration: const Duration(seconds: 4),
          );
        }
        return true;
      }
      final message = response.message(fallback: 'failed_to_save_record'.tr);
      setLastSubmitMessage(message);
      Get.snackbar('error'.tr, message);
      return false;
    } catch (e) {
      final message = e.toString();
      setLastSubmitMessage(message);
      Get.snackbar('error'.tr, message);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
