import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class ManagePregnancyController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<PregnancyAnimalItem> animals = <PregnancyAnimalItem>[].obs;
  final RxList<PregnancyRecordItem> records = <PregnancyRecordItem>[].obs;

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await Future.wait([fetchAnimals(), fetchRecords()]);
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
        animals.assignAll(
          list.map((item) => PregnancyAnimalItem.fromJson(item)).toList(),
        );
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    }
  }

  Future<void> fetchRecords() async {
    if (farmerId == 0) {
      records.clear();
      return;
    }

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.reproductive}/list/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        records.assignAll(
          list.map((item) => PregnancyRecordItem.fromJson(item)).toList(),
        );
      } else {
        records.clear();
      }
    } catch (_) {
      records.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveRecord({
    required int animalId,
    int? lactationNumber,
    DateTime? aiDate,
    String breedName = '',
    required bool pregnancyConfirmation,
    DateTime? calvingDate,
    String notes = '',
  }) async {
    try {
      isSubmitting.value = true;
      final payload = {
        'animal_id': animalId,
        'lactation_number': lactationNumber,
        'ai_date': aiDate != null ? DateFormat('yyyy-MM-dd').format(aiDate) : null,
        'breed_name': breedName.trim().isEmpty ? null : breedName.trim(),
        'pregnancy_confirmation': pregnancyConfirmation,
        'calving_date': calvingDate != null ? DateFormat('yyyy-MM-dd').format(calvingDate) : null,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
      };

      final response = await http.post(
        Uri.parse(Api.reproductive),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == true) {
        await fetchRecords();
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Pregnancy record saved successfully',
        );
        return true;
      }
      Get.snackbar(
        'Error',
        data['message']?.toString() ?? 'Failed to save pregnancy record',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}

class PregnancyAnimalItem {
  final int id;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;

  PregnancyAnimalItem({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
  });

  String get displayName =>
      '${animalName.trim().isEmpty ? 'Animal' : animalName} - Tag ${tagNumber.trim().isEmpty ? '-' : tagNumber}';

  factory PregnancyAnimalItem.fromJson(Map<String, dynamic> json) {
    return PregnancyAnimalItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
    );
  }
}

class PregnancyRecordItem {
  final String animalName;
  final String tagNumber;
  final String lactationNumber;
  final String aiDate;
  final String breedName;
  final bool pregnancyConfirmation;
  final String calvingDate;
  final String notes;

  PregnancyRecordItem({
    required this.animalName,
    required this.tagNumber,
    required this.lactationNumber,
    required this.aiDate,
    required this.breedName,
    required this.pregnancyConfirmation,
    required this.calvingDate,
    required this.notes,
  });

  factory PregnancyRecordItem.fromJson(Map<String, dynamic> json) {
    final animal = json['animal'] is Map<String, dynamic>
        ? json['animal'] as Map<String, dynamic>
        : <String, dynamic>{};
    return PregnancyRecordItem(
      animalName: animal['animal_name']?.toString() ?? '',
      tagNumber: animal['tag_number']?.toString() ?? '',
      lactationNumber: json['lactation_number']?.toString() ?? '',
      aiDate: _formatDate(json['ai_date']?.toString()),
      breedName: json['breed_name']?.toString() ?? '',
      pregnancyConfirmation: json['pregnancy_confirmation'] == true || json['pregnancy_confirmation'].toString() == '1',
      calvingDate: _formatDate(json['calving_date']?.toString()),
      notes: json['notes']?.toString() ?? '',
    );
  }

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }
}
