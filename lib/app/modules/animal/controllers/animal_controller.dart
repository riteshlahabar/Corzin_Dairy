import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class AnimalController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController animalNameController = TextEditingController();
  final TextEditingController tagNumberController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString selectedGender = ''.obs;
  final List<String> genderList = ['Male', 'Female'];
  final Rxn<AnimalTypeModel> selectedAnimalType = Rxn<AnimalTypeModel>();
  final RxList<AnimalTypeModel> animalTypes = <AnimalTypeModel>[].obs;
  final Rxn<XFile> selectedImage = Rxn<XFile>();

  final ImagePicker _picker = ImagePicker();

  int farmerId = 0;
  bool isNewBornMode = false;
  String lockedAnimalTypeName = '';
  String pageTitle = 'Add Animal';

  @override
  void onInit() {
    super.onInit();
    _readArguments();
    initData();
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args is Map) {
      isNewBornMode = args['prefillAnimalTypeName']?.toString().isNotEmpty == true;
      lockedAnimalTypeName = args['prefillAnimalTypeName']?.toString() ?? '';
      pageTitle = args['title']?.toString() ?? (isNewBornMode ? 'Add New Born Cow' : 'Add Animal');
    }
  }

  Future<void> initData() async {
    await loadFarmerId();
    await fetchAnimalTypes();
  }

  Future<void> loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> fetchAnimalTypes() async {
    try {
      isPageLoading.value = true;
      final response = await http.get(Uri.parse(Api.animalTypes), headers: {'Accept': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animalTypes.assignAll(list.map((e) => AnimalTypeModel.fromJson(e)).toList());
        if (isNewBornMode && lockedAnimalTypeName.isNotEmpty) {
          final match = animalTypes.firstWhereOrNull((type) => type.name.toLowerCase() == lockedAnimalTypeName.toLowerCase());
          if (match != null) {
            selectedAnimalType.value = match;
          }
        }
      } else {
        Get.snackbar('Error', data['message']?.toString() ?? 'Failed to fetch animal types', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> pickBirthDate() async {
    DateTime initialDate = DateTime.now();
    if (birthDateController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(birthDateController.text);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(context: Get.context!, initialDate: initialDate, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (picked != null) {
      birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      selectedImage.value = image;
    }
  }

  Future<void> submitAnimal() async {
    if (!formKey.currentState!.validate()) return;
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer ID not found. Please login again.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedAnimalType.value == null) {
      Get.snackbar('Error', 'Please select animal type', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSubmitting.value = true;
      final request = http.MultipartRequest('POST', Uri.parse(Api.addAnimal));
      request.headers.addAll({'Accept': 'application/json'});
      request.fields['farmer_id'] = farmerId.toString();
      request.fields['animal_name'] = animalNameController.text.trim();
      request.fields['tag_number'] = tagNumberController.text.trim();
      request.fields['animal_type_id'] = selectedAnimalType.value!.id.toString();
      request.fields['birth_date'] = birthDateController.text.trim();
      request.fields['gender'] = selectedGender.value;
      if (weightController.text.trim().isNotEmpty) {
        request.fields['weight'] = weightController.text.trim();
      }
      if (selectedImage.value != null) {
        final imagePath = selectedImage.value!.path;
        final fileName = imagePath.split(Platform.pathSeparator).last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            filename: fileName,
          ),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final successMessage = data['message']?.toString() ?? 'Animal created successfully';
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
        Get.snackbar('Error', data['message']?.toString() ?? 'Failed to save animal', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearForm() {
    animalNameController.clear();
    tagNumberController.clear();
    birthDateController.clear();
    weightController.clear();
    selectedGender.value = '';
    selectedImage.value = null;
    if (!isNewBornMode) {
      selectedAnimalType.value = null;
    }
  }

  @override
  void onClose() {
    animalNameController.dispose();
    tagNumberController.dispose();
    birthDateController.dispose();
    weightController.dispose();
    super.onClose();
  }
}

class AnimalTypeModel {
  final int id;
  final String name;

  AnimalTypeModel({required this.id, required this.name});

  factory AnimalTypeModel.fromJson(Map<String, dynamic> json) {
    return AnimalTypeModel(id: int.tryParse(json['id'].toString()) ?? 0, name: json['name']?.toString() ?? '');
  }
}
