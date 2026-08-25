part of 'health_controller.dart';

extension HealthControllerFacade on HealthController {
  RxList<HealthAnimalItem> get animals => medicalController.animals;
  RxList<HealthVaccineItem> get vaccines => vaccinationController.vaccines;
  RxList<MedicalRecordItem> get medicalRecords => medicalController.medicalRecords;
  RxList<MastitisRecordItem> get mastitisRecords => mastitisController.mastitisRecords;
  RxList<VaccinationRecordItem> get vaccinationRecords => vaccinationController.vaccinationRecords;
  RxList<DmiRecordItem> get dmiRecords => dmiController.dmiRecords;
  RxList<ReagentUsageItem> get reagentUsages => reagentController.reagentUsages;
  RxDouble get reagentBalanceMl => reagentController.reagentBalanceMl;
  RxString get reagentSearchQuery => reagentController.reagentSearchQuery;
  RxString get dmiSearchQuery => dmiController.dmiSearchQuery;
  RxString get dmiAnimalTypeFilter => dmiController.dmiAnimalTypeFilter;
  Rx<DateTime> get dmiFromDate => dmiController.dmiFromDate;
  Rx<DateTime> get dmiToDate => dmiController.dmiToDate;
  RxString get mastitisSearchQuery => mastitisController.mastitisSearchQuery;
  RxString get mastitisResultFilter => mastitisController.mastitisResultFilter;
  Rxn<DateTime> get mastitisFromDate => mastitisController.mastitisFromDate;
  Rxn<DateTime> get mastitisToDate => mastitisController.mastitisToDate;
  RxString get vaccinationSearchQuery => vaccinationController.vaccinationSearchQuery;
  Rx<DateTime> get vaccinationFromDate => vaccinationController.vaccinationFromDate;
  Rx<DateTime> get vaccinationToDate => vaccinationController.vaccinationToDate;

  List<MastitisRecordItem> get filteredMastitisRecords =>
      mastitisController.filteredMastitisRecords;
  List<MastitisGroupItem> get allMastitisGroups => mastitisController.allMastitisGroups;
  List<MastitisGroupItem> get filteredMastitisGroups =>
      mastitisController.filteredMastitisGroups;
  List<HealthAnimalItem> get milkingAnimals => mastitisController.milkingAnimals;
  Set<int> get activeMastitisAnimalIds => mastitisController.activeMastitisAnimalIds;
  List<HealthAnimalItem> get availableMastitisAnimals =>
      mastitisController.availableMastitisAnimals;
  List<VaccinationRecordItem> get filteredVaccinationRecords =>
      vaccinationController.filteredVaccinationRecords;
  List<VaccinationGroupItem> get filteredVaccinationGroups =>
      vaccinationController.filteredVaccinationGroups;
  List<ReagentUsageItem> get filteredReagentUsages => reagentController.filteredReagentUsages;
  List<DmiRecordItem> get filteredDmiRecords => dmiController.filteredDmiRecords;
  List<DmiRecordItem> get groupedDmiRecords => dmiController.groupedDmiRecords;
  List<String> get dmiAnimalTypes => dmiController.dmiAnimalTypes;

  Future<void> fetchAnimals() => medicalController.fetchAnimals();
  Future<void> fetchMedicalRecords() => medicalController.fetchMedicalRecords();
  Future<void> fetchVaccines() => vaccinationController.fetchVaccines();
  Future<void> fetchMastitisRecords() => mastitisController.fetchMastitisRecords();
  Future<void> fetchVaccinationRecords() => vaccinationController.fetchVaccinationRecords();
  Future<void> fetchDmiRecords({bool forceRefresh = false}) =>
      dmiController.fetchDmiRecords(forceRefresh: forceRefresh);
  Future<void> fetchReagentRecords() => reagentController.fetchReagentRecords();

  Future<bool> saveMedical({
    required int animalId,
    required String medicineName,
    required String dose,
    required DateTime date,
    required String disease,
    String notes = '',
  }) {
    return medicalController.saveMedical(
      animalId: animalId,
      medicineName: medicineName,
      dose: dose,
      date: date,
      disease: disease,
      notes: notes,
    );
  }

  Future<bool> saveMastitis({
    required int animalId,
    required String testResult,
    String notes = '',
  }) {
    return mastitisController.saveMastitis(
      animalId: animalId,
      testResult: testResult,
      notes: notes,
    );
  }

  Future<bool> addReagent({required double quantityMl}) {
    return reagentController.addReagent(quantityMl: quantityMl);
  }

  Future<bool> saveVaccination({
    required int animalId,
    required int vaccineId,
    required String doses,
    required DateTime vaccinationDate,
    String notes = '',
  }) {
    return vaccinationController.saveVaccination(
      animalId: animalId,
      vaccineId: vaccineId,
      doses: doses,
      vaccinationDate: vaccinationDate,
      notes: notes,
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
  }) {
    return mastitisController.updateMastitis(
      recordId: recordId,
      animalId: animalId,
      testResult: testResult,
      treatment: treatment,
      recoveryStatus: recoveryStatus,
      date: date,
      notes: notes,
    );
  }

  Future<bool> addMastitisTreatment({
    int? mastitisRecordId,
    required int animalId,
    required String treatment,
    required DateTime date,
    String notes = '',
  }) {
    return mastitisController.addMastitisTreatment(
      mastitisRecordId: mastitisRecordId,
      animalId: animalId,
      treatment: treatment,
      date: date,
      notes: notes,
    );
  }

  Future<bool> markMastitisRecovered({
    int? mastitisRecordId,
    required int animalId,
    required DateTime date,
  }) {
    return mastitisController.markMastitisRecovered(
      mastitisRecordId: mastitisRecordId,
      animalId: animalId,
      date: date,
    );
  }

  void setMastitisDateRange({DateTime? from, DateTime? to}) {
    mastitisController.setMastitisDateRange(from: from, to: to);
  }

  Future<void> setDmiDateRange({DateTime? from, DateTime? to}) {
    return dmiController.setDmiDateRange(from: from, to: to);
  }

  Future<void> setVaccinationDateRange({DateTime? from, DateTime? to}) {
    return vaccinationController.setVaccinationDateRange(from: from, to: to);
  }

  Future<bool> saveDmi({
    required int animalId,
    required double bodyWeight,
    required double totalMilk,
    required double actualDmi,
    required DateTime date,
    String notes = '',
  }) {
    return dmiController.saveDmi(
      animalId: animalId,
      bodyWeight: bodyWeight,
      totalMilk: totalMilk,
      actualDmi: actualDmi,
      date: date,
      notes: notes,
    );
  }

  double calculateRequiredDmi(double bodyWeight, double totalMilk) {
    return dmiController.calculateRequiredDmi(bodyWeight, totalMilk);
  }

  bool isMilkingByMilk(double totalMilk) {
    return dmiController.isMilkingByMilk(totalMilk);
  }
}
