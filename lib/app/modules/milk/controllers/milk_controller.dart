import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class MilkController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController milkDateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController fatController = TextEditingController();
  final TextEditingController snfController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<MilkAnimalModel> animals = <MilkAnimalModel>[].obs;
  final RxList<MilkDairyModel> dairies = <MilkDairyModel>[].obs;
  final Rxn<MilkAnimalModel> selectedAnimal = Rxn<MilkAnimalModel>();
  final Rxn<MilkDairyModel> selectedDairy = Rxn<MilkDairyModel>();
  final RxString selectedShift = 'Morning'.obs;

  final List<String> shifts = ['Morning', 'Afternoon', 'Evening'];

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    milkDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    initData();
  }

  Future<void> initData() async {
    await loadFarmerId();
    await Future.wait([fetchAnimals(), fetchDairies()]);
  }

  Future<void> loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) return;
    try {
      isPageLoading.value = true;
      final response = await http.get(Uri.parse('${Api.animalList}/$farmerId'), headers: {'Accept': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animals.assignAll(list.map((item) => MilkAnimalModel.fromJson(item)).toList());
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> fetchDairies() async {
    if (farmerId == 0) return;
    try {
      final response = await http.get(Uri.parse('${Api.dairyList}/$farmerId'), headers: {'Accept': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        dairies.assignAll(list.map((item) => MilkDairyModel.fromJson(item)).toList());
      } else {
        dairies.clear();
      }
    } catch (_) {
      dairies.clear();
    }
  }

  Future<void> pickMilkDate() async {
    DateTime initialDate = DateTime.now();
    if (milkDateController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(milkDateController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      milkDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> submitMilk() async {
    if (!formKey.currentState!.validate()) return;
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer ID not found. Please login again.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedAnimal.value == null) {
      Get.snackbar('Error', 'Please select an animal', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedDairy.value == null) {
      Get.snackbar('Error', 'Please select a dairy', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSubmitting.value = true;
      final payload = {
        'farmer_id': farmerId.toString(),
        'animal_id': selectedAnimal.value!.id.toString(),
        'dairy_id': selectedDairy.value!.id.toString(),
        'date': _formatDateForApi(milkDateController.text.trim()),
        'shift': selectedShift.value,
        'quantity': quantityController.text.trim(),
        'fat': fatController.text.trim(),
        'snf': snfController.text.trim(),
        'rate': rateController.text.trim(),
        'notes': notesController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(Api.addMilk),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        final successMessage = data['message']?.toString() ?? 'Milk record saved successfully';
        clearForm();
        Get.back(result: {'success': true, 'message': successMessage});
      } else if (response.statusCode == 422) {
        String errorMessage = 'Validation failed';
        if (data['message'] is Map) {
          final errors = data['message'] as Map;
          errorMessage = errors.values.map((e) => e is List ? e.join(', ') : e.toString()).join('\n');
        } else if (data['message'] != null) {
          errorMessage = data['message'].toString();
        }
        Get.snackbar('Validation Error', errorMessage, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
      } else {
        Get.snackbar('Error', data['message']?.toString() ?? 'Failed to save milk record', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, int>> submitBulkMilk(
    Map<int, String> quantityByAnimal,
  ) async {
    if (farmerId == 0) {
      Get.snackbar(
        'Error',
        'Farmer ID not found. Please login again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return {'success': 0, 'failed': 0};
    }
    if (selectedDairy.value == null) {
      Get.snackbar(
        'Error',
        'Please select a dairy first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return {'success': 0, 'failed': 0};
    }

    final entries = <MapEntry<int, String>>[];
    quantityByAnimal.forEach((animalId, quantity) {
      if (double.tryParse(quantity.trim()) != null &&
          (double.tryParse(quantity.trim()) ?? 0) > 0) {
        entries.add(MapEntry(animalId, quantity.trim()));
      }
    });

    if (entries.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter at least one valid quantity.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return {'success': 0, 'failed': 0};
    }

    int successCount = 0;
    int failedCount = 0;
    isSubmitting.value = true;

    for (final entry in entries) {
      try {
        final payload = {
          'farmer_id': farmerId.toString(),
          'animal_id': entry.key.toString(),
          'dairy_id': selectedDairy.value!.id.toString(),
          'date': _formatDateForApi(milkDateController.text.trim()),
          'shift': selectedShift.value,
          'quantity': entry.value,
          'fat': fatController.text.trim(),
          'snf': snfController.text.trim(),
          'rate': rateController.text.trim(),
          'notes': notesController.text.trim(),
        };

        final response = await http.post(
          Uri.parse(Api.addMilk),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          successCount++;
        } else {
          failedCount++;
        }
      } catch (_) {
        failedCount++;
      }
    }

    isSubmitting.value = false;
    return {'success': successCount, 'failed': failedCount};
  }

  String _formatDateForApi(String value) {
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(value);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return value;
    }
  }

  void clearForm() {
    selectedAnimal.value = null;
    selectedDairy.value = null;
    selectedShift.value = 'Morning';
    quantityController.clear();
    fatController.clear();
    snfController.clear();
    rateController.clear();
    notesController.clear();
    milkDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void onClose() {
    milkDateController.dispose();
    quantityController.dispose();
    fatController.dispose();
    snfController.dispose();
    rateController.dispose();
    notesController.dispose();
    super.onClose();
  }
}

class MilkAnimalModel {
  final int id;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;

  MilkAnimalModel({required this.id, required this.animalName, required this.tagNumber, required this.animalTypeName});

  String get displayName {
    final name = animalName.trim().isEmpty ? 'Unnamed Animal' : animalName;
    final tag = tagNumber.trim().isEmpty ? '' : ' - Tag $tagNumber';
    return '$name$tag';
  }

  factory MilkAnimalModel.fromJson(Map<String, dynamic> json) {
    return MilkAnimalModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
    );
  }
}

class MilkDairyModel {
  final int id;
  final String dairyName;
  final String city;

  MilkDairyModel({required this.id, required this.dairyName, required this.city});

  String get displayName {
    if (city.trim().isEmpty) return dairyName;
    return '$dairyName - $city';
  }

  factory MilkDairyModel.fromJson(Map<String, dynamic> json) {
    return MilkDairyModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      dairyName: json['dairy_name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
    );
  }
}

