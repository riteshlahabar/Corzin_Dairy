import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class AnimalHistoryController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<AnimalHistoryItem> history = <AnimalHistoryItem>[].obs;
  final RxList<AnimalTypeOption> animalTypes = <AnimalTypeOption>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxInt selectedAnimalTypeId = 0.obs;
  final ImagePicker _picker = ImagePicker();

  int farmerId = 0;

  List<AnimalHistoryItem> get filteredHistory {
    final query = searchQuery.value.trim().toLowerCase();
    final animalTypeId = selectedAnimalTypeId.value;
    return history.where((item) {
      final matchesSearch = query.isEmpty || item.searchText.contains(query);
      final matchesType = animalTypeId == 0 || item.animalTypeId == animalTypeId;
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() => searchQuery.value = searchController.text);
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await Future.wait([fetchAnimalTypes(), fetchHistory()]);
  }

  Future<void> fetchAnimalTypes() async {
    try {
      final response = await http.get(
        Uri.parse(Api.animalTypes),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animalTypes.assignAll(
          list.map((item) => AnimalTypeOption.fromJson(item)).toList(),
        );
      } else {
        animalTypes.clear();
      }
    } catch (_) {
      animalTypes.clear();
    }
  }

  Future<void> fetchHistory() async {
    if (farmerId == 0) {
      history.clear();
      return;
    }

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId?include_inactive=1'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        history.assignAll(list.map((item) => AnimalHistoryItem.fromJson(item)).toList());
      } else {
        history.clear();
      }
    } catch (_) {
      history.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<XFile?> pickAnimalPhoto() async {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  }

  Future<bool> updateAnimal({
    required AnimalHistoryItem item,
    required String animalName,
    required String tagNumber,
    required int animalTypeId,
    String lactationNumber = '',
    String aiDate = '',
    String breedName = '',
    int? motherAnimalId,
    required String birthDate,
    String purchaseDate = '',
    String age = '',
    required String gender,
    required String weight,
    String defaultMilkPerSession = '',
    XFile? imageFile,
  }) async {
    final duplicateMessage = _duplicateAnimalValidationMessage(
      currentAnimalId: item.id,
      animalName: animalName,
      tagNumber: tagNumber,
    );
    if (duplicateMessage != null) {
      Get.snackbar('Validation Error', duplicateMessage);
      return false;
    }

    try {
      isSubmitting.value = true;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.animalUpdate}/${item.id}'),
      );
      request.headers['Accept'] = 'application/json';
      request.fields.addAll({
        'farmer_id': farmerId.toString(),
        'animal_name': animalName.trim(),
        'tag_number': tagNumber.trim(),
        'animal_type_id': animalTypeId.toString(),
        'lactation_number': lactationNumber.trim(),
        'ai_date': aiDate.trim(),
        'breed_name': breedName.trim(),
        'birth_date': birthDate.trim(),
        'purchase_date': purchaseDate.trim(),
        'age': age.trim(),
        'gender': gender.trim(),
        'weight': weight.trim(),
        'default_milk_per_session': defaultMilkPerSession.trim(),
      });
      request.fields['mother_animal_id'] =
          motherAnimalId != null && motherAnimalId > 0 ? motherAnimalId.toString() : '';

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 && data['status'] == true) {
        Get.snackbar('Success', data['message']?.toString() ?? 'Animal updated successfully');
        await fetchHistory();
        return true;
      }

      Get.snackbar('Error', data['message']?.toString() ?? 'Failed to update animal');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  String? _duplicateAnimalValidationMessage({
    required int currentAnimalId,
    required String animalName,
    required String tagNumber,
  }) {
    final normalizedName = animalName.trim().toLowerCase();
    final normalizedTag = tagNumber.trim().toLowerCase();
    if (normalizedName.isEmpty || normalizedTag.isEmpty) {
      return null;
    }

    final others = history.where((item) => item.id != currentAnimalId);
    final nameExists = others.any((item) => item.animalName.trim().toLowerCase() == normalizedName);
    final tagExists = others.any((item) => item.tagNumber.trim().toLowerCase() == normalizedTag);

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

  Future<bool> sellAnimal(AnimalHistoryItem item, {double? sellingPrice}) async {
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer not found. Please login again.');
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse('${Api.animalSell}/${item.id}'),
        headers: {'Accept': 'application/json'},
        body: {
          'farmer_id': farmerId.toString(),
          if (sellingPrice != null)
            'selling_price': sellingPrice.toStringAsFixed(2),
        },
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        Get.snackbar('Success', data['message']?.toString() ?? 'Animal listed for sale');
        await fetchHistory();
        return true;
      }

      Get.snackbar('Error', data['message']?.toString() ?? 'Failed to list animal for sale');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelSellingAnimal(AnimalHistoryItem item) async {
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer not found. Please login again.');
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse('${Api.animalCancelSell}/${item.id}/cancel'),
        headers: {'Accept': 'application/json'},
        body: {'farmer_id': farmerId.toString()},
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        Get.snackbar('Success', data['message']?.toString() ?? 'Animal selling cancelled successfully');
        await fetchHistory();
        return true;
      }

      Get.snackbar('Error', data['message']?.toString() ?? 'Failed to cancel animal selling');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class AnimalHistoryItem {
  final int id;
  final String uniqueId;
  final String animalName;
  final String tagNumber;
  final int animalTypeId;
  final String animalTypeName;
  final String panName;
  final String motherAnimalName;
  final String motherTagNumber;
  final String lactationNumber;
  final String aiDate;
  final String breedName;
  final String age;
  final String birthDate;
  final String purchaseDate;
  final String gender;
  final String weight;
  final String defaultMilkPerSession;
  final String lifecycleStatus;
  final bool isActive;
  final String image;
  final bool isForSale;
  final String sellingPrice;

  AnimalHistoryItem({
    required this.id,
    required this.uniqueId,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeId,
    required this.animalTypeName,
    required this.panName,
    required this.motherAnimalName,
    required this.motherTagNumber,
    required this.lactationNumber,
    required this.aiDate,
    required this.breedName,
    required this.age,
    required this.birthDate,
    required this.purchaseDate,
    required this.gender,
    required this.weight,
    required this.defaultMilkPerSession,
    required this.lifecycleStatus,
    required this.isActive,
    required this.image,
    required this.isForSale,
    required this.sellingPrice,
  });

  String get motherLabel {
    final name = motherAnimalName.trim();
    final tag = motherTagNumber.trim();
    if (name.isEmpty && tag.isEmpty) return '';
    if (tag.isEmpty) return name;
    if (name.isEmpty) return tag;
    return '$name ($tag)';
  }

  String get searchText => [
        uniqueId,
        animalName,
        tagNumber,
        animalTypeName,
        panName,
        motherAnimalName,
        motherTagNumber,
        lactationNumber,
        aiDate,
        breedName,
        age,
        birthDate,
        purchaseDate,
        gender,
        weight,
        defaultMilkPerSession,
        lifecycleStatus,
        sellingPrice,
      ].join(' ').toLowerCase();

  factory AnimalHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnimalHistoryItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      uniqueId: json['unique_id']?.toString() ?? '',
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeId: int.tryParse(json['animal_type_id'].toString()) ?? 0,
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      panName: json['pan_name']?.toString() ?? '',
      motherAnimalName: json['mother_animal_name']?.toString() ?? '',
      motherTagNumber: json['mother_tag_number']?.toString() ?? '',
      lactationNumber: json['lactation_number']?.toString() ?? '',
      aiDate: json['ai_date']?.toString() ?? '',
      breedName: json['breed_name']?.toString() ?? '',
      age: json['age_display']?.toString() ?? json['age']?.toString() ?? '',
      birthDate: json['birth_date']?.toString() ?? '',
      purchaseDate: json['purchase_date']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      defaultMilkPerSession: json['default_milk_per_session']?.toString() ?? '',
      lifecycleStatus: json['lifecycle_status']?.toString() ?? 'active',
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      image: json['image']?.toString() ?? '',
      isForSale: json['is_for_sale'] == true || json['is_for_sale']?.toString() == '1',
      sellingPrice: json['selling_price']?.toString() ?? '',
    );
  }
}

class AnimalTypeOption {
  final int id;
  final String name;

  AnimalTypeOption({required this.id, required this.name});

  factory AnimalTypeOption.fromJson(Map<String, dynamic> json) {
    return AnimalTypeOption(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
