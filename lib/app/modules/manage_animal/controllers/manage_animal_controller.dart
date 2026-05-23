import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class ManageAnimalController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<ManageAnimalItem> animals = <ManageAnimalItem>[].obs;
  final RxList<ManageAnimalType> animalTypes = <ManageAnimalType>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs;

  int farmerId = 0;
  int selectedAnimalId = 0;
  String selectedAnimalName = '';

  List<ManageAnimalItem> get filteredAnimals {
    final query = searchQuery.value.trim().toLowerCase();
    return animals.where((item) {
      final matchesSearch = query.isEmpty || item.searchText.contains(query);
      final filter = selectedFilter.value;
      final matchesFilter = filter == 'all' || item.lifecycleStatus == filter;
      final matchesSelectedAnimal = selectedAnimalId <= 0 || item.id == selectedAnimalId;
      return matchesSearch && matchesFilter && matchesSelectedAnimal;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      selectedAnimalId = int.tryParse((args['animal_id'] ?? '0').toString()) ?? 0;
      selectedAnimalName = (args['animal_name'] ?? '').toString();
    }
    searchController.addListener(() => searchQuery.value = searchController.text);
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await Future.wait([fetchAnimalTypes(), fetchAnimals()]);
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
          list.map((item) => ManageAnimalType.fromJson(item)).toList(),
        );
      } else {
        animalTypes.clear();
      }
    } catch (_) {
      animalTypes.clear();
    }
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) {
      animals.clear();
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
        animals.assignAll(
          list.map((item) => ManageAnimalItem.fromJson(item)).toList(),
        );
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateAnimalLifecycle({
    required int animalId,
    required String action,
    int? animalTypeId,
    String? notes,
  }) async {
    try {
      isSubmitting.value = true;
      final payload = {
        'action': action,
        if (animalTypeId != null) 'animal_type_id': animalTypeId.toString(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final response = await http.post(
        Uri.parse('${Api.animalLifecycle}/$animalId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        await fetchAnimals();
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Animal status updated successfully',
        );
        return true;
      }

      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to update animal status',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> sellAnimal(
    ManageAnimalItem item, {
    required double sellingPrice,
  }) async {
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
          'selling_price': sellingPrice.toStringAsFixed(2),
        },
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        await fetchAnimals();
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? '${item.animalName.isEmpty ? 'Animal' : item.animalName} listed for sale',
        );
        return true;
      }

      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to list animal for sale',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cancelSellingAnimal(ManageAnimalItem item) async {
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
        await fetchAnimals();
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? '${item.animalName.isEmpty ? 'Animal' : item.animalName} removed from sale',
        );
        return true;
      }

      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to cancel animal selling',
      );
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

class ManageAnimalItem {
  final int id;
  final String animalName;
  final String tagNumber;
  final String uniqueId;
  final String animalTypeName;
  final String lifecycleStatus;
  final String gender;
  final String age;
  final String birthDate;
  final String weight;
  final String image;
  final bool isForSale;

  ManageAnimalItem({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.uniqueId,
    required this.animalTypeName,
    required this.lifecycleStatus,
    required this.gender,
    required this.age,
    required this.birthDate,
    required this.weight,
    required this.image,
    required this.isForSale,
  });

  String get searchText => [
    animalName,
    tagNumber,
    uniqueId,
    animalTypeName,
    lifecycleStatus,
    gender,
    age,
  ].join(' ').toLowerCase();

  factory ManageAnimalItem.fromJson(Map<String, dynamic> json) {
    return ManageAnimalItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      uniqueId: json['unique_id']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      lifecycleStatus: (json['lifecycle_status']?.toString() ?? 'active')
          .toLowerCase(),
      gender: json['gender']?.toString() ?? '',
      age: json['age_display']?.toString() ?? json['age']?.toString() ?? '',
      birthDate: json['birth_date']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      isForSale: json['is_for_sale'] == true || json['is_for_sale']?.toString() == '1',
    );
  }
}

class ManageAnimalType {
  final int id;
  final String name;

  ManageAnimalType({required this.id, required this.name});

  factory ManageAnimalType.fromJson(Map<String, dynamic> json) {
    return ManageAnimalType(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
