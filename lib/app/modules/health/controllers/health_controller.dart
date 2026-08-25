import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cached_api_service.dart';
import '../../../core/utils/api.dart';

part '../services/health_api_service.dart';
part '../repositories/medical_repository.dart';
part '../repositories/mastitis_repository.dart';
part '../repositories/vaccination_repository.dart';
part '../repositories/dmi_repository.dart';
part '../repositories/reagent_repository.dart';
part '../models/health_models.dart';
part '../helpers/health_filter_helper.dart';
part 'reagent_controller.dart';
part 'dmi_controller.dart';
part 'vaccination_controller.dart';
part 'mastitis_controller.dart';
part 'medical_controller.dart';
part 'health_submit_coordinator.dart';
part 'health_controller_facade.dart';

enum HealthSection { reagent, dmi, mastitis, vaccination }

class HealthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final Rx<HealthSection> selectedSection = HealthSection.dmi.obs;
  String lastSubmitMessage = '';

  late final HealthSubmitCoordinator _submitter;
  late final HealthMedicalController medicalController;
  late final HealthMastitisController mastitisController;
  late final HealthVaccinationController vaccinationController;
  late final HealthDmiController dmiController;
  late final HealthReagentController reagentController;

  int farmerId = 0;
  Future<void>? _initFuture;

  HealthController() {
    _submitter = HealthSubmitCoordinator(
      isSubmitting: isSubmitting,
      setLastSubmitMessage: (message) => lastSubmitMessage = message,
    );
    medicalController = HealthMedicalController(
      isLoading: isLoading,
      submitter: _submitter,
    );
    reagentController = HealthReagentController(
      isLoading: isLoading,
      submitter: _submitter,
    );
    mastitisController = HealthMastitisController(
      isLoading: isLoading,
      submitter: _submitter,
      animalsProvider: () => medicalController.animals,
      refreshReagentRecords: reagentController.fetchReagentRecords,
    );
    vaccinationController = HealthVaccinationController(
      isLoading: isLoading,
      submitter: _submitter,
    );
    dmiController = HealthDmiController(
      isLoading: isLoading,
      submitter: _submitter,
      animalsProvider: () => medicalController.animals,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _initFuture = initData();
  }

  Future<void> initData() {
    return _initFuture ??= _initializeFarmer();
  }

  Future<void> _initializeFarmer() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    _setFarmerIdForSections();
  }

  void _setFarmerIdForSections() {
    medicalController.setFarmerId(farmerId);
    mastitisController.setFarmerId(farmerId);
    vaccinationController.setFarmerId(farmerId);
    dmiController.setFarmerId(farmerId);
    reagentController.setFarmerId(farmerId);
  }

  void setSection(HealthSection section) {
    if (selectedSection.value == section) return;
    selectedSection.value = section;
  }

  Future<void> loadSection(HealthSection section) async {
    selectedSection.value = section;
    await initData();

    switch (section) {
      case HealthSection.reagent:
        await reagentController.fetchReagentRecords();
        break;
      case HealthSection.mastitis:
        await Future.wait([
          medicalController.fetchAnimals(),
          mastitisController.fetchMastitisRecords(),
          reagentController.fetchReagentRecords(
            showLoader: false,
            summaryOnly: true,
          ),
        ]);
        break;
      case HealthSection.vaccination:
        await Future.wait([
          medicalController.fetchAnimals(),
          vaccinationController.fetchVaccines(),
          vaccinationController.fetchVaccinationRecords(),
        ]);
        break;
      case HealthSection.dmi:
        await Future.wait([
          medicalController.fetchAnimals(),
          dmiController.fetchDmiRecords(),
        ]);
        break;
    }
  }

  Future<void> refreshSelectedSection() async {
    await loadSection(selectedSection.value);
  }
}
