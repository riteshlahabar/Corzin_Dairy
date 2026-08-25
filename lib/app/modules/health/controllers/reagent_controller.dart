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

  Future<void> fetchReagentRecords({
    bool forceRefresh = false,
    bool showLoader = true,
    bool summaryOnly = false,
  }) async {
    if (farmerId == 0) {
      reagentUsages.clear();
      reagentBalanceMl.value = 0;
      return;
    }

    try {
      if (showLoader) {
        isLoading.value = reagentUsages.isEmpty;
      }

      void apply(ReagentRecordsResult records) {
        reagentBalanceMl.value = records.balanceMl;
        reagentUsages.assignAll(records.usages);
        if (showLoader) {
          isLoading.value = false;
        }
      }

      final result = await _reagentRepository.fetchReagentRecords(
        farmerId,
        onCached: apply,
        forceRefresh: forceRefresh,
        summaryOnly: summaryOnly,
      );
      if (result != null) {
        apply(result);
      } else if (reagentUsages.isEmpty) {
        reagentUsages.clear();
        reagentBalanceMl.value = 0;
      }
    } catch (_) {
      if (reagentUsages.isEmpty) {
        reagentUsages.clear();
        reagentBalanceMl.value = 0;
      }
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
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
      onSuccess: () => fetchReagentRecords(forceRefresh: true),
      showSuccessSnackbar: false,
    );
  }
}
