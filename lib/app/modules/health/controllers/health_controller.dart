import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

enum HealthSection { dmi, mastitis }

class HealthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final Rx<HealthSection> selectedSection = HealthSection.dmi.obs;
  final RxList<HealthAnimalItem> animals = <HealthAnimalItem>[].obs;
  final RxList<MedicalRecordItem> medicalRecords = <MedicalRecordItem>[].obs;
  final RxList<MastitisRecordItem> mastitisRecords = <MastitisRecordItem>[].obs;
  final RxList<DmiRecordItem> dmiRecords = <DmiRecordItem>[].obs;
  final RxString mastitisSearchQuery = ''.obs;
  final RxString mastitisResultFilter = 'all'.obs;
  String lastSubmitMessage = '';

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await Future.wait([
      fetchAnimals(),
      fetchMedicalRecords(),
      fetchMastitisRecords(),
      fetchDmiRecords(),
    ]);
  }

  void setSection(HealthSection section) {
    if (selectedSection.value == section) return;
    selectedSection.value = section;
  }

  Future<void> refreshSelectedSection() async {
    switch (selectedSection.value) {
      case HealthSection.mastitis:
        await fetchMastitisRecords();
        break;
      case HealthSection.dmi:
        await fetchDmiRecords();
        break;
    }
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) {
      animals.clear();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animals.assignAll(list.map((item) => HealthAnimalItem.fromJson(item)).toList());
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
      final response = await http.get(Uri.parse('${Api.healthMedical}/$farmerId'), headers: {'Accept': 'application/json'});
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        medicalRecords.assignAll(list.map((item) => MedicalRecordItem.fromJson(item)).toList());
      } else {
        medicalRecords.clear();
      }
    } catch (_) {
      medicalRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMastitisRecords() async {
    if (farmerId == 0) return;
    try {
      isLoading.value = true;
      final response = await http.get(Uri.parse('${Api.healthMastitis}/$farmerId'), headers: {'Accept': 'application/json'});
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        mastitisRecords.assignAll(list.map((item) => MastitisRecordItem.fromJson(item)).toList());
      } else {
        mastitisRecords.clear();
      }
    } catch (_) {
      mastitisRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDmiRecords() async {
    if (farmerId == 0) return;
    try {
      isLoading.value = true;
      final response = await http.get(Uri.parse('${Api.healthDmi}/$farmerId'), headers: {'Accept': 'application/json'});
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        dmiRecords.assignAll(list.map((item) => DmiRecordItem.fromJson(item)).toList());
      } else {
        dmiRecords.clear();
      }
    } catch (_) {
      dmiRecords.clear();
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
    return _submit(
      endpoint: Api.healthMedical,
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'medicine_name': medicineName,
        'dose': dose,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'disease': disease,
        'notes': notes,
      },
      successMessage: 'Medical record saved successfully',
      onSuccess: fetchMedicalRecords,
    );
  }

  Future<bool> saveMastitis({
    required int animalId,
    required String testResult,
    required String treatment,
    required String recoveryStatus,
    required DateTime date,
    String notes = '',
  }) async {
    return _submit(
      endpoint: Api.healthMastitis,
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'test_result': testResult,
        'treatment': treatment,
        'recovery_status': recoveryStatus,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'notes': notes,
      },
      successMessage: 'Mastitis record saved successfully',
      onSuccess: fetchMastitisRecords,
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
    return _submit(
      endpoint: '${Api.healthMastitisUpdate}/$recordId',
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'test_result': testResult,
        'treatment': treatment,
        'recovery_status': recoveryStatus,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'notes': notes,
      },
      successMessage: 'Mastitis record updated successfully',
      onSuccess: fetchMastitisRecords,
      showSuccessSnackbar: false,
    );
  }

  List<MastitisRecordItem> get filteredMastitisRecords {
    final query = mastitisSearchQuery.value.trim().toLowerCase();
    final filter = mastitisResultFilter.value.trim().toLowerCase();

    return mastitisRecords.where((item) {
      final result = item.testResult.trim().toLowerCase();
      if (filter != 'all' && result != filter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        item.animalName,
        item.tagNumber,
        item.testResult,
        item.treatment,
        item.recoveryStatus,
        item.date,
        item.notes,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  Future<bool> saveDmi({
    required int animalId,
    required double bodyWeight,
    required double totalMilk,
    required double actualDmi,
    required DateTime date,
    String notes = '',
  }) async {
    return _submit(
      endpoint: Api.healthDmi,
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'body_weight': bodyWeight.toString(),
        'total_milk': totalMilk.toString(),
        'actual_dmi': actualDmi.toString(),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'notes': notes,
      },
      successMessage: 'DMI record saved successfully',
      onSuccess: fetchDmiRecords,
    );
  }

  Future<bool> _submit({
    required String endpoint,
    required Map<String, String> payload,
    required String successMessage,
    required Future<void> Function() onSuccess,
    bool showSuccessSnackbar = true,
  }) async {
    try {
      isSubmitting.value = true;
      lastSubmitMessage = '';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (_isSuccessResponse(response, data)) {
        await onSuccess();
        lastSubmitMessage = _extractMessage(data, fallback: successMessage);
        if (showSuccessSnackbar) {
          Get.snackbar(
            'Success',
            lastSubmitMessage,
            duration: const Duration(seconds: 4),
          );
        }
        return true;
      }
      lastSubmitMessage = _extractMessage(data, fallback: 'Failed to save record');
      Get.snackbar(
        'Error',
        lastSubmitMessage,
      );
      return false;
    } catch (e) {
      lastSubmitMessage = e.toString();
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _isSuccessResponse(http.Response response, dynamic data) {
    final codeOk = response.statusCode >= 200 && response.statusCode < 300;
    if (!codeOk) return false;
    if (data is! Map) return true;
    final status = data['status'];
    final success = data['success'];
    final statusOk = status == true ||
        status == 1 ||
        status?.toString().toLowerCase() == 'true';
    final successOk = success == true ||
        success == 1 ||
        success?.toString().toLowerCase() == 'true';
    return statusOk || successOk || data.isEmpty;
  }

  String _extractMessage(dynamic data, {required String fallback}) {
    if (data is! Map) return fallback;
    final message = data['message'];
    if (message == null) return fallback;
    if (message is String && message.trim().isNotEmpty) return message.trim();
    if (message is Map) {
      final first = message.values.firstWhere(
        (value) => value != null && value.toString().trim().isNotEmpty,
        orElse: () => '',
      );
      final text = first.toString().trim();
      return text.isEmpty ? fallback : text;
    }
    final text = message.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double calculateRequiredDmi(double bodyWeight, double totalMilk) {
    if (totalMilk <= 0) {
      return bodyWeight * 0.025;
    }
    return (bodyWeight * 0.02) + (totalMilk * 0.33);
  }

  bool isMilkingByMilk(double totalMilk) => totalMilk > 0;
}

class HealthAnimalItem {
  final int id;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;

  HealthAnimalItem({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
  });

  String get displayName => '${animalName.trim().isEmpty ? 'Animal' : animalName} - Tag ${tagNumber.trim().isEmpty ? '-' : tagNumber}';

  factory HealthAnimalItem.fromJson(Map<String, dynamic> json) {
    return HealthAnimalItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
    );
  }
}

class MedicalRecordItem {
  final String animalName;
  final String tagNumber;
  final String medicineName;
  final String dose;
  final String date;
  final String disease;
  final String notes;

  MedicalRecordItem({required this.animalName, required this.tagNumber, required this.medicineName, required this.dose, required this.date, required this.disease, required this.notes});

  factory MedicalRecordItem.fromJson(Map<String, dynamic> json) {
    return MedicalRecordItem(
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      medicineName: json['medicine_name']?.toString() ?? '',
      dose: json['dose']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      disease: json['disease']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class MastitisRecordItem {
  final int id;
  final int animalId;
  final String animalName;
  final String tagNumber;
  final String testResult;
  final String treatment;
  final String recoveryStatus;
  final String date;
  final String notes;

  MastitisRecordItem({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.testResult,
    required this.treatment,
    required this.recoveryStatus,
    required this.date,
    required this.notes,
  });

  factory MastitisRecordItem.fromJson(Map<String, dynamic> json) {
    return MastitisRecordItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      animalId: int.tryParse(json['animal_id']?.toString() ?? '0') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      testResult: json['test_result']?.toString() ?? '',
      treatment: json['treatment']?.toString() ?? '',
      recoveryStatus: json['recovery_status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class DmiRecordItem {
  final int animalId;
  final String animalName;
  final String tagNumber;
  final String dmiType;
  final String bodyWeight;
  final String totalMilk;
  final String requiredDmi;
  final String actualDmi;
  final String alertStatus;
  final String date;
  final String notes;

  DmiRecordItem({
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.dmiType,
    required this.bodyWeight,
    required this.totalMilk,
    required this.requiredDmi,
    required this.actualDmi,
    required this.alertStatus,
    required this.date,
    required this.notes,
  });

  factory DmiRecordItem.fromJson(Map<String, dynamic> json) {
    return DmiRecordItem(
      animalId: int.tryParse(json['animal_id']?.toString() ?? '0') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      dmiType: json['dmi_type']?.toString() ?? '',
      bodyWeight: json['body_weight']?.toString() ?? '',
      totalMilk: json['total_milk']?.toString() ?? '',
      requiredDmi: json['required_dmi']?.toString() ?? '',
      actualDmi: json['actual_dmi']?.toString() ?? '',
      alertStatus: json['alert_status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

