import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class FeedingController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxList<FeedingAnimalModel> animals = <FeedingAnimalModel>[].obs;
  final RxList<FeedTypeModel> feedTypes = <FeedTypeModel>[].obs;
  final Rxn<FeedingAnimalModel> selectedAnimal = Rxn<FeedingAnimalModel>();
  final Rxn<FeedTypeModel> selectedFeedType = Rxn<FeedTypeModel>();
  final RxString selectedUnit = 'Kg'.obs;
  final RxString selectedFeedingTime = 'Morning'.obs;

  final List<String> units = const ['Kg', 'Gram'];
  final List<String> feedingTimes = const ['Morning', 'Afternoon', 'Evening'];

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    initData();
  }

  Future<void> initData() async {
    await loadFarmerId();
    await Future.wait([fetchAnimals(), fetchFeedTypes()]);
  }

  Future<void> loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) return;

    try {
      isPageLoading.value = true;

      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animals.assignAll(
          list.map((item) => FeedingAnimalModel.fromJson(item)).toList(),
        );
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> fetchFeedTypes() async {
    try {
      final response = await http.get(
        Uri.parse(Api.feedingTypes),
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        feedTypes.assignAll(
          list.map((item) => FeedTypeModel.fromJson(item)).toList(),
        );
        if (feedTypes.isNotEmpty) {
          selectedFeedType.value ??= feedTypes.first;
          selectedUnit.value = selectedFeedType.value?.defaultUnit ?? 'Kg';
        }
      } else {
        feedTypes.clear();
      }
    } catch (_) {
      feedTypes.clear();
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> submitFeeding() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedAnimal.value == null) {
      Get.snackbar('Error', 'Please select an animal');
      return;
    }
    if (selectedFeedType.value == null) {
      Get.snackbar('Error', 'Please select feed type');
      return;
    }

    try {
      isSubmitting.value = true;

      final payload = {
        'farmer_id': farmerId.toString(),
        'animal_id': selectedAnimal.value!.id.toString(),
        'feed_type_id': selectedFeedType.value!.id.toString(),
        'feed_type': selectedFeedType.value!.name,
        'quantity': quantityController.text.trim(),
        'unit': selectedUnit.value,
        'feeding_time': selectedFeedingTime.value,
        'date': _formatDate(dateController.text.trim()),
        'notes': notesController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(Api.addFeeding),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        clearForm();
        Get.back(
          result: {
            'success': true,
            'message':
                data['message']?.toString() ??
                'Feeding entry saved successfully',
          },
        );
      } else {
        Get.snackbar(
          'Error',
          data['message']?.toString() ?? 'Failed to save feeding entry',
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, int>> submitBulkFeeding(
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
    if (selectedFeedType.value == null) {
      Get.snackbar(
        'Error',
        'Please select feed type first.',
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
          'feed_type_id': selectedFeedType.value!.id.toString(),
          'feed_type': selectedFeedType.value!.name,
          'quantity': entry.value,
          'unit': selectedUnit.value,
          'feeding_time': selectedFeedingTime.value,
          'date': _formatDate(dateController.text.trim()),
          'notes': notesController.text.trim(),
        };

        final response = await http.post(
          Uri.parse(Api.addFeeding),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
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

  String _formatDate(String value) {
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(value);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return value;
    }
  }

  void onFeedTypeChanged(FeedTypeModel? value) {
    selectedFeedType.value = value;
    if (value != null) {
      selectedUnit.value = value.defaultUnit;
    }
  }

  void clearForm() {
    selectedAnimal.value = null;
    selectedFeedType.value = feedTypes.isNotEmpty ? feedTypes.first : null;
    selectedUnit.value = selectedFeedType.value?.defaultUnit ?? 'Kg';
    selectedFeedingTime.value = 'Morning';
    quantityController.clear();
    notesController.clear();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void onClose() {
    dateController.dispose();
    quantityController.dispose();
    notesController.dispose();
    super.onClose();
  }
}

class FeedingAnimalModel {
  final int id;
  final String animalName;
  final String tagNumber;

  FeedingAnimalModel({
    required this.id,
    required this.animalName,
    required this.tagNumber,
  });

  String get displayName {
    final name = animalName.trim().isEmpty ? 'Unnamed Animal' : animalName;
    final tag = tagNumber.trim().isEmpty ? '' : ' - Tag $tagNumber';
    return '$name$tag';
  }

  factory FeedingAnimalModel.fromJson(Map<String, dynamic> json) {
    return FeedingAnimalModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
    );
  }
}

class FeedTypeModel {
  final int id;
  final String name;
  final String defaultUnit;

  FeedTypeModel({
    required this.id,
    required this.name,
    required this.defaultUnit,
  });

  factory FeedTypeModel.fromJson(Map<String, dynamic> json) {
    return FeedTypeModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      defaultUnit: json['default_unit']?.toString() ?? 'Kg',
    );
  }
}
