import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';
import '../../../core/theme/colors.dart';
import '../../../routes/app_pages.dart';

class AnimalController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController animalNameController = TextEditingController();
  final TextEditingController tagNumberController = TextEditingController();
  final TextEditingController lactationNumberController = TextEditingController();
  final TextEditingController aiDateController = TextEditingController();
  final TextEditingController breedNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController defaultMilkPerSessionController = TextEditingController();
  final FocusNode animalNameFocus = FocusNode();
  final FocusNode tagNumberFocus = FocusNode();
  final FocusNode weightFocus = FocusNode();
  final FocusNode defaultMilkPerSessionFocus = FocusNode();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString selectedGender = ''.obs;
  final List<String> genderList = ['Male', 'Female'];
  final Rxn<AnimalTypeModel> selectedAnimalType = Rxn<AnimalTypeModel>();
  final RxList<AnimalTypeModel> animalTypes = <AnimalTypeModel>[].obs;
  final Rxn<MotherAnimalModel> selectedMotherAnimal = Rxn<MotherAnimalModel>();
  final RxList<MotherAnimalModel> motherAnimals = <MotherAnimalModel>[].obs;
  final Rxn<XFile> selectedImage = Rxn<XFile>();

  final ImagePicker _picker = ImagePicker();
  Worker? _animalTypeWorker;

  int farmerId = 0;
  bool isNewBornMode = false;
  String lockedAnimalTypeName = '';
  String pageTitle = 'Add Animal';

  @override
  void onInit() {
    super.onInit();
    _readArguments();
    _bindAnimalTypeWatcher();
    initData();
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args is Map) {
      isNewBornMode = args['prefillAnimalTypeName']?.toString().isNotEmpty == true;
      lockedAnimalTypeName = args['prefillAnimalTypeName']?.toString() ?? '';
      pageTitle = args['title']?.toString() ?? 'Add Animal';
    }
  }

  void _bindAnimalTypeWatcher() {
    _animalTypeWorker = ever<AnimalTypeModel?>(selectedAnimalType, (_) {
      if (!showMotherAnimalDropdown) {
        selectedMotherAnimal.value = null;
      }
    });
  }

  bool get showMotherAnimalDropdown {
    final name = selectedAnimalType.value?.name.trim().toLowerCase() ?? '';
    if (name.isEmpty) return false;
    return name.contains('calf') ||
        name.contains('calves') ||
        name.contains('new born') ||
        name.contains('बछ') ||
        name.contains('वासर');
  }

  Future<void> initData() async {
    await loadFarmerId();
    await Future.wait([fetchAnimalTypes(), fetchMotherAnimals()]);
  }

  Future<void> loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> fetchMotherAnimals() async {
    if (farmerId == 0) {
      motherAnimals.clear();
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        motherAnimals.assignAll(
          list.map((e) => MotherAnimalModel.fromJson(e)).where((e) => e.id > 0).toList(),
        );
      } else {
        motherAnimals.clear();
      }
    } catch (_) {
      motherAnimals.clear();
    }
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

  Future<DateTime?> _showGreenDatePicker({
    required DateTime initialDate,
  }) async {
    return showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        const softGreen = Color(0xFFF4FAF4);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF95BE95),
              onPrimary: AppColors.black,
              surface: softGreen,
              onSurface: AppColors.black,
            ),
            dialogTheme: theme.dialogTheme.copyWith(backgroundColor: softGreen),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: softGreen,
              headerBackgroundColor: const Color(0xFFDDEEDC),
              headerForegroundColor: AppColors.black,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  _AgeInfo? _calculateAgeInfoFromBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    if (birthDate.isAfter(now)) return null;

    var years = now.year - birthDate.year;
    var months = now.month - birthDate.month;
    var days = now.day - birthDate.day;

    if (days < 0) {
      final previousMonthLastDay = DateTime(now.year, now.month, 0).day;
      days += previousMonthLastDay;
      months -= 1;
    }

    if (months < 0) {
      months += 12;
      years -= 1;
    }

    if (years < 0) {
      years = 0;
      months = 0;
      days = 0;
    }

    final display = '$years years $months month $days days';
    return _AgeInfo(years: years, months: months, days: days, display: display);
  }

  _AgeInfo? _calculateAgeInfoFromText(String birthDateText) {
    final text = birthDateText.trim();
    if (text.isEmpty) return null;
    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(text);
      return _calculateAgeInfoFromBirthDate(parsed);
    } catch (_) {
      return null;
    }
  }

  void _syncAgeFromBirthDateText() {
    final ageInfo = _calculateAgeInfoFromText(birthDateController.text);
    ageController.text = ageInfo?.display ?? '';
  }

  Future<void> pickBirthDate() async {
    DateTime initialDate = DateTime.now();
    if (birthDateController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parseStrict(birthDateController.text);
      } catch (_) {}
    }
    final DateTime? picked = await _showGreenDatePicker(initialDate: initialDate);
    if (picked != null) {
      birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      _syncAgeFromBirthDateText();
    }
  }

  Future<void> pickPurchaseDate() async {
    DateTime initialDate = DateTime.now();
    if (purchaseDateController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parseStrict(purchaseDateController.text);
      } catch (_) {}
    }
    final DateTime? picked = await _showGreenDatePicker(initialDate: initialDate);
    if (picked != null) {
      purchaseDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> pickAiDate() async {
    DateTime initialDate = DateTime.now();
    if (aiDateController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(aiDateController.text);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        const softGreen = Color(0xFFF4FAF4);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF95BE95),
              onPrimary: AppColors.black,
              surface: softGreen,
              onSurface: AppColors.black,
            ),
            dialogTheme: theme.dialogTheme.copyWith(backgroundColor: softGreen),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: softGreen,
              headerBackgroundColor: const Color(0xFFDDEEDC),
              headerForegroundColor: AppColors.black,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      aiDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void clearAiDate() {
    aiDateController.clear();
  }

  void clearBirthDate() {
    birthDateController.clear();
    ageController.clear();
  }

  void clearPurchaseDate() {
    purchaseDateController.clear();
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
    final duplicateMessage = _duplicateAnimalValidationMessage(
      animalName: animalNameController.text,
      tagNumber: tagNumberController.text,
    );
    if (duplicateMessage != null) {
      Get.snackbar('Validation Error', duplicateMessage, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedAnimalType.value == null) {
      Get.snackbar('Error', 'Please select animal type', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (showMotherAnimalDropdown && selectedMotherAnimal.value == null) {
      Get.snackbar('Error', 'Please select mother animal', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final birthDateText = birthDateController.text.trim();
    final ageInfo = _calculateAgeInfoFromText(birthDateText);
    if (ageInfo == null) {
      Get.snackbar('Error', 'Please select valid birth date', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final weightText = weightController.text.trim();
    final weightValue = double.tryParse(weightText);
    if (weightText.isEmpty || weightValue == null || weightValue <= 0) {
      Get.snackbar('Error', 'Please enter valid weight', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final defaultMilkText = defaultMilkPerSessionController.text.trim();
    final defaultMilkValue = double.tryParse(defaultMilkText);
    if (defaultMilkText.isEmpty || defaultMilkValue == null || defaultMilkValue < 0) {
      Get.snackbar('Error', 'Please enter valid default milk per milking', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedImage.value == null) {
      Get.snackbar('Error', 'Please upload animal image', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isSubmitting.value = true;
      final request = http.MultipartRequest('POST', Uri.parse(Api.addAnimal));
      request.headers.addAll({'Accept': 'application/json'});
      request.fields['farmer_id'] = farmerId.toString();
      request.fields['animal_name'] = animalNameController.text.trim();
      request.fields['tag_number'] = tagNumberController.text.trim();
      if (lactationNumberController.text.trim().isNotEmpty) {
        request.fields['lactation_number'] = lactationNumberController.text.trim();
      }
      if (aiDateController.text.trim().isNotEmpty) {
        request.fields['ai_date'] = aiDateController.text.trim();
      }
      if (breedNameController.text.trim().isNotEmpty) {
        request.fields['breed_name'] = breedNameController.text.trim();
      }
      request.fields['animal_type_id'] = selectedAnimalType.value!.id.toString();
      if (showMotherAnimalDropdown && selectedMotherAnimal.value != null) {
        request.fields['mother_animal_id'] = selectedMotherAnimal.value!.id.toString();
      }
      request.fields['birth_date'] = birthDateText;
      if (purchaseDateController.text.trim().isNotEmpty) {
        request.fields['purchase_date'] = purchaseDateController.text.trim();
      }
      request.fields['age'] = ageInfo.years.toString();
      request.fields['gender'] = selectedGender.value;
      request.fields['weight'] = weightController.text.trim();
      request.fields['default_milk_per_session'] = defaultMilkText;
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
        final String successMessage = (data['message']?.toString().trim().isNotEmpty ?? false)
            ? data['message'].toString().trim()
            : 'Animal added successfully';
        clearForm();
        Get.offAllNamed(Routes.HOME);
        Future.delayed(const Duration(milliseconds: 150), () {
          Get.snackbar(
            'Success',
            successMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
        });
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

  String? _duplicateAnimalValidationMessage({
    required String animalName,
    required String tagNumber,
  }) {
    final normalizedName = animalName.trim().toLowerCase();
    final normalizedTag = tagNumber.trim().toLowerCase();
    if (normalizedName.isEmpty || normalizedTag.isEmpty) {
      return null;
    }

    final nameExists = motherAnimals.any(
      (item) => item.animalName.trim().toLowerCase() == normalizedName,
    );
    final tagExists = motherAnimals.any(
      (item) => item.tagNumber.trim().toLowerCase() == normalizedTag,
    );

    if (nameExists && tagExists) {
      return 'Animal name and tag number already exist for this farmer.';
    }
    if (nameExists) {
      return 'Animal name already exists for this farmer.';
    }
    if (tagExists) {
      return 'Tag number already exists for this farmer.';
    }
    return null;
  }

  void clearForm() {
    animalNameController.clear();
    tagNumberController.clear();
    lactationNumberController.clear();
    aiDateController.clear();
    breedNameController.clear();
    birthDateController.clear();
    purchaseDateController.clear();
    ageController.clear();
    weightController.clear();
    defaultMilkPerSessionController.clear();
    selectedGender.value = '';
    selectedImage.value = null;
    selectedMotherAnimal.value = null;
    if (!isNewBornMode) {
      selectedAnimalType.value = null;
    }
  }

  @override
  void onClose() {
    _animalTypeWorker?.dispose();
    animalNameController.dispose();
    tagNumberController.dispose();
    lactationNumberController.dispose();
    aiDateController.dispose();
    breedNameController.dispose();
    birthDateController.dispose();
    purchaseDateController.dispose();
    ageController.dispose();
    weightController.dispose();
    defaultMilkPerSessionController.dispose();
    animalNameFocus.dispose();
    tagNumberFocus.dispose();
    weightFocus.dispose();
    defaultMilkPerSessionFocus.dispose();
    super.onClose();
  }
}

class _AgeInfo {
  final int years;
  final int months;
  final int days;
  final String display;

  const _AgeInfo({
    required this.years,
    required this.months,
    required this.days,
    required this.display,
  });
}

class AnimalTypeModel {
  final int id;
  final String name;

  AnimalTypeModel({required this.id, required this.name});

  factory AnimalTypeModel.fromJson(Map<String, dynamic> json) {
    return AnimalTypeModel(id: int.tryParse(json['id'].toString()) ?? 0, name: json['name']?.toString() ?? '');
  }
}

class MotherAnimalModel {
  final int id;
  final String animalName;
  final String tagNumber;

  MotherAnimalModel({
    required this.id,
    required this.animalName,
    required this.tagNumber,
  });

  String get label {
    final name = animalName.trim().isEmpty ? 'Animal #$id' : animalName.trim();
    final tag = tagNumber.trim().isEmpty ? '-' : tagNumber.trim();
    return '$name (Tag: $tag)';
  }

  factory MotherAnimalModel.fromJson(Map<String, dynamic> json) {
    return MotherAnimalModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
    );
  }
}

