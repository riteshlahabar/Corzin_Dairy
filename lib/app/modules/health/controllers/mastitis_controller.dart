part of 'health_controller.dart';

class HealthMastitisController {
  HealthMastitisController({
    required this.isLoading,
    required HealthSubmitCoordinator submitter,
    required List<HealthAnimalItem> Function() animalsProvider,
    required Future<void> Function() refreshReagentRecords,
  })  : _submitter = submitter,
        _animalsProvider = animalsProvider,
        _refreshReagentRecords = refreshReagentRecords;

  final RxBool isLoading;
  final HealthSubmitCoordinator _submitter;
  final List<HealthAnimalItem> Function() _animalsProvider;
  final Future<void> Function() _refreshReagentRecords;
  final MastitisRepository _mastitisRepository = MastitisRepository();

  final RxList<MastitisRecordItem> mastitisRecords =
      <MastitisRecordItem>[].obs;
  final RxString mastitisSearchQuery = ''.obs;
  final RxString mastitisResultFilter = 'positive'.obs;
  final Rxn<DateTime> mastitisFromDate = Rxn<DateTime>();
  final Rxn<DateTime> mastitisToDate = Rxn<DateTime>();

  int farmerId = 0;

  List<HealthAnimalItem> get animals => _animalsProvider();

  void setFarmerId(int value) {
    farmerId = value;
  }

  Future<void> fetchMastitisRecords({bool forceRefresh = false}) async {
    if (farmerId == 0) return;
    try {
      isLoading.value = mastitisRecords.isEmpty;
      void apply(List<MastitisRecordItem> records) {
        mastitisRecords.assignAll(records);
        isLoading.value = false;
      }

      final result = await _mastitisRepository.fetchMastitisRecords(
        farmerId: farmerId,
        onCached: apply,
        forceRefresh: forceRefresh,
      );
      if (result != null) {
        apply(result);
      } else if (mastitisRecords.isEmpty) {
        mastitisRecords.clear();
      }
    } catch (_) {
      if (mastitisRecords.isEmpty) {
        mastitisRecords.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveMastitis({
    required int animalId,
    required String testResult,
    String notes = '',
  }) async {
    return _submitter.submit(
      request: () => _mastitisRepository.saveMastitis(
        farmerId: farmerId,
        animalId: animalId,
        testResult: testResult,
        notes: notes,
      ),
      successMessage: 'Mastitis record saved successfully',
      onSuccess: () async {
        await Future.wait([
          fetchMastitisRecords(forceRefresh: true),
          _refreshReagentRecords(),
        ]);
      },
      showSuccessSnackbar: false,
    );
  }

  Future<bool> updateMastitis({
    required int recordId,
    required int animalId,
    required String testResult,
    required String treatment,
    required String recoveryStatus,
    required DateTime date,
    String notes = '',
  }) async {
    return _submitter.submit(
      request: () => _mastitisRepository.updateMastitis(
        farmerId: farmerId,
        recordId: recordId,
        animalId: animalId,
        testResult: testResult,
        treatment: treatment,
        recoveryStatus: recoveryStatus,
        date: date,
        notes: notes,
      ),
      successMessage: 'Mastitis record updated successfully',
      onSuccess: () => fetchMastitisRecords(forceRefresh: true),
      showSuccessSnackbar: false,
    );
  }

  Future<bool> addMastitisTreatment({
    int? mastitisRecordId,
    required int animalId,
    required String treatment,
    required DateTime date,
    String notes = '',
  }) async {
    return _submitter.submit(
      request: () => _mastitisRepository.addTreatment(
        farmerId: farmerId,
        mastitisRecordId: mastitisRecordId,
        animalId: animalId,
        treatment: treatment,
        date: date,
        notes: notes,
      ),
      successMessage: 'Treatment added successfully',
      onSuccess: () => fetchMastitisRecords(forceRefresh: true),
      showSuccessSnackbar: false,
    );
  }

  Future<bool> markMastitisRecovered({
    int? mastitisRecordId,
    required int animalId,
    required DateTime date,
  }) async {
    return _submitter.submit(
      request: () => _mastitisRepository.markRecovered(
        farmerId: farmerId,
        mastitisRecordId: mastitisRecordId,
        animalId: animalId,
        date: date,
      ),
      successMessage: 'Animal marked as recovered',
      onSuccess: () => fetchMastitisRecords(forceRefresh: true),
      showSuccessSnackbar: false,
    );
  }
}
