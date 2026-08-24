part of 'health_controller.dart';

class HealthVaccinationController {
  HealthVaccinationController({
    required this.isLoading,
    required HealthSubmitCoordinator submitter,
  }) : _submitter = submitter;

  final RxBool isLoading;
  final HealthSubmitCoordinator _submitter;
  final VaccinationRepository _vaccinationRepository = VaccinationRepository();

  final RxList<HealthVaccineItem> vaccines = <HealthVaccineItem>[].obs;
  final RxList<VaccinationRecordItem> vaccinationRecords =
      <VaccinationRecordItem>[].obs;
  final RxString vaccinationSearchQuery = ''.obs;
  final Rx<DateTime> vaccinationFromDate = DateTime.now().obs;
  final Rx<DateTime> vaccinationToDate = DateTime.now().obs;

  int farmerId = 0;

  void setFarmerId(int value) {
    farmerId = value;
  }

  Future<void> fetchVaccines() async {
    try {
      final result = await _vaccinationRepository.fetchVaccines();
      if (result != null) {
        vaccines.assignAll(result);
      } else {
        vaccines.clear();
      }
    } catch (_) {
      vaccines.clear();
    }
  }

  Future<void> fetchVaccinationRecords() async {
    if (farmerId == 0) {
      vaccinationRecords.clear();
      return;
    }

    try {
      isLoading.value = true;
      final result =
          await _vaccinationRepository.fetchVaccinationRecords(farmerId);
      if (result != null) {
        vaccinationRecords.assignAll(result);
      } else {
        vaccinationRecords.clear();
      }
    } catch (_) {
      vaccinationRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveVaccination({
    required int animalId,
    required int vaccineId,
    required String doses,
    required DateTime vaccinationDate,
    String notes = '',
  }) async {
    return _submitter.submit(
      request: () => _vaccinationRepository.saveVaccination(
        farmerId: farmerId,
        animalId: animalId,
        vaccineId: vaccineId,
        doses: doses,
        vaccinationDate: vaccinationDate,
        notes: notes,
      ),
      successMessage: 'Vaccination record saved successfully',
      onSuccess: fetchVaccinationRecords,
      showSuccessSnackbar: false,
    );
  }
}
