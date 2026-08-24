part of 'health_controller.dart';

class HealthMedicalController {
  HealthMedicalController({
    required this.isLoading,
    required HealthSubmitCoordinator submitter,
  }) : _submitter = submitter;

  final RxBool isLoading;
  final HealthSubmitCoordinator _submitter;
  final MedicalRepository _medicalRepository = MedicalRepository();

  final RxList<HealthAnimalItem> animals = <HealthAnimalItem>[].obs;
  final RxList<MedicalRecordItem> medicalRecords = <MedicalRecordItem>[].obs;

  int farmerId = 0;

  void setFarmerId(int value) {
    farmerId = value;
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) {
      animals.clear();
      return;
    }

    try {
      final result = await _medicalRepository.fetchAnimals(farmerId);
      if (result != null) {
        animals.assignAll(result);
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    }
  }

  Future<void> fetchMedicalRecords() async {
    if (farmerId == 0) return;
    try {
      isLoading.value = true;
      final result = await _medicalRepository.fetchMedicalRecords(farmerId);
      if (result != null) {
        medicalRecords.assignAll(result);
      } else {
        medicalRecords.clear();
      }
    } catch (_) {
      medicalRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveMedical({
    required int animalId,
    required String medicineName,
    required String dose,
    required DateTime date,
    required String disease,
    String notes = '',
  }) async {
    return _submitter.submit(
      request: () => _medicalRepository.saveMedical(
        farmerId: farmerId,
        animalId: animalId,
        medicineName: medicineName,
        dose: dose,
        date: date,
        disease: disease,
        notes: notes,
      ),
      successMessage: 'Medical record saved successfully',
      onSuccess: fetchMedicalRecords,
    );
  }
}
