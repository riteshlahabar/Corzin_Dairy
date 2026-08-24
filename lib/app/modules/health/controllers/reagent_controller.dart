part of 'health_controller.dart';

class HealthReagentController {
  HealthReagentController({
    required this.isLoading,
    required HealthSubmitCoordinator submitter,
  }) : _submitter = submitter;

  final RxBool isLoading;
  final HealthSubmitCoordinator _submitter;
  final ReagentRepository _reagentRepository = ReagentRepository();

  final RxList<ReagentUsageItem> reagentUsages = <ReagentUsageItem>[].obs;
  final RxDouble reagentBalanceMl = 0.0.obs;
  final RxString reagentSearchQuery = ''.obs;

  int farmerId = 0;

  void setFarmerId(int value) {
    farmerId = value;
  }

  Future<void> fetchReagentRecords() async {
    if (farmerId == 0) {
      reagentUsages.clear();
      reagentBalanceMl.value = 0;
      return;
    }

    try {
      isLoading.value = true;
      final result = await _reagentRepository.fetchReagentRecords(farmerId);
      if (result != null) {
        reagentBalanceMl.value = result.balanceMl;
        reagentUsages.assignAll(result.usages);
      } else {
        reagentUsages.clear();
        reagentBalanceMl.value = 0;
      }
    } catch (_) {
      reagentUsages.clear();
      reagentBalanceMl.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addReagent({
    required double quantityMl,
  }) async {
    return _submitter.submit(
      request: () => _reagentRepository.addReagent(
        farmerId: farmerId,
        quantityMl: quantityMl,
      ),
      successMessage: 'reagent_added_successfully'.tr,
      onSuccess: fetchReagentRecords,
      showSuccessSnackbar: false,
    );
  }
}
