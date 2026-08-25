part of 'health_controller.dart';

class HealthDmiController {
  HealthDmiController({
    required this.isLoading,
    required HealthSubmitCoordinator submitter,
    required List<HealthAnimalItem> Function() animalsProvider,
  })  : _submitter = submitter,
        _animalsProvider = animalsProvider;

  final RxBool isLoading;
  final HealthSubmitCoordinator _submitter;
  final List<HealthAnimalItem> Function() _animalsProvider;
  final DmiRepository _dmiRepository = DmiRepository();

  final RxList<DmiRecordItem> dmiRecords = <DmiRecordItem>[].obs;
  final RxString dmiSearchQuery = ''.obs;
  final RxString dmiAnimalTypeFilter = 'all'.obs;
  final Rx<DateTime> dmiFromDate = DateTime.now().obs;
  final Rx<DateTime> dmiToDate = DateTime.now().obs;

  int farmerId = 0;

  List<HealthAnimalItem> get animals => _animalsProvider();

  void setFarmerId(int value) {
    farmerId = value;
  }

  Future<void> fetchDmiRecords({bool forceRefresh = false}) async {
    if (farmerId == 0) {
      dmiRecords.clear();
      return;
    }
    try {
      isLoading.value = dmiRecords.isEmpty;
      void apply(List<DmiRecordItem> records) {
        dmiRecords.assignAll(records);
        isLoading.value = false;
      }

      final result = await _dmiRepository.fetchDmiRecords(
        farmerId: farmerId,
        fromDate: dmiFromDate.value,
        toDate: dmiToDate.value,
        onCached: apply,
        forceRefresh: forceRefresh,
      );
      if (result != null) {
        apply(result);
      } else if (dmiRecords.isEmpty) {
        dmiRecords.clear();
      }
    } catch (_) {
      if (dmiRecords.isEmpty) {
        dmiRecords.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveDmi({
    required int animalId,
    required double bodyWeight,
    required double totalMilk,
    required double actualDmi,
    required DateTime date,
    String notes = '',
  }) async {
    return _submitter.submit(
      request: () => _dmiRepository.saveDmi(
        farmerId: farmerId,
        animalId: animalId,
        bodyWeight: bodyWeight,
        totalMilk: totalMilk,
        actualDmi: actualDmi,
        date: date,
        notes: notes,
      ),
      successMessage: 'DMI record saved successfully',
      onSuccess: () => fetchDmiRecords(forceRefresh: true),
    );
  }

  double calculateRequiredDmi(double bodyWeight, double totalMilk) {
    return _dmiRepository.calculateRequiredDmi(bodyWeight, totalMilk);
  }

  bool isMilkingByMilk(double totalMilk) => totalMilk > 0;
}
