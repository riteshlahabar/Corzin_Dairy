import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../models/pregnancy_record_model.dart';

class ManagePregnancyController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<PregnancyRecordModel> records = <PregnancyRecordModel>[].obs;
  final RxList<PregnancyAnimalOption> animals = <PregnancyAnimalOption>[].obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  int farmerId = 0;

  static const List<String> statuses = [
    'all',
    'served',
    'pregnancy_check_due',
    'pregnant',
    'not_pregnant',
    'repeat_heat',
    'calved',
    'aborted',
  ];

  List<PregnancyRecordModel> get filteredRecords {
    final status = selectedStatus.value;
    final query = searchQuery.value.trim().toLowerCase();
    return records.where((item) {
      final matchesStatus = status == 'all' || item.status == status;
      final matchesSearch = query.isEmpty || item.searchText.contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(
      () => searchQuery.value = searchController.text,
    );
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? await SessionService.getFarmerId();
    await Future.wait([fetchAnimals(), fetchRecords()]);
  }

  Future<void> fetchAnimals() async {
    if (farmerId <= 0) return;
    try {
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final list = data['data'] is List ? data['data'] as List : <dynamic>[];
        animals.assignAll(
          list
              .whereType<Map>()
              .map(
                (item) => PregnancyAnimalOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      }
    } catch (_) {
      animals.clear();
    }
  }

  Future<void> fetchRecords() async {
    if (farmerId <= 0) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.pregnancyList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final list = data['data'] is List ? data['data'] as List : <dynamic>[];
        records.assignAll(
          list
              .whereType<Map>()
              .map(
                (item) => PregnancyRecordModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
        );
      } else {
        records.clear();
      }
    } catch (e) {
      records.clear();
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveRecord({
    PregnancyRecordModel? record,
    required int animalId,
    required int pregnancyNo,
    required int serviceNo,
    required String heatDate,
    required String aiDate,
    required String serviceType,
    required String bullName,
    required String semenNo,
    required String doctorName,
    required String pregnancyCheckDueDate,
    required String pregnancyCheckDate,
    required String pregnancyResult,
    required String expectedCalvingDate,
    required String dryOffDate,
    required String calvingDate,
    required String status,
    required int calfAnimalId,
    required String notes,
    required bool isCurrent,
  }) async {
    if (animalId <= 0) {
      Get.snackbar('Validation', 'Please select cow');
      return false;
    }
    if (aiDate.trim().isEmpty) {
      Get.snackbar('Validation', 'Please select AI date');
      return false;
    }

    try {
      isSubmitting.value = true;
      final endpoint = record == null
          ? Api.pregnancyStore
          : '${Api.pregnancyUpdate}/${record.id}';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
        body: {
          'animal_id': animalId.toString(),
          'pregnancy_no': pregnancyNo.toString(),
          'service_no': serviceNo.toString(),
          'heat_date': heatDate,
          'ai_date': aiDate,
          'service_type': serviceType,
          'bull_name': bullName,
          'semen_no': semenNo,
          'doctor_name': doctorName,
          'pregnancy_check_due_date': pregnancyCheckDueDate,
          'pregnancy_check_date': pregnancyCheckDate,
          'pregnancy_result': pregnancyResult,
          'expected_calving_date': expectedCalvingDate,
          'dry_off_date': dryOffDate,
          'calving_date': calvingDate,
          'status': status,
          'calf_animal_id': calfAnimalId > 0 ? calfAnimalId.toString() : '',
          'notes': notes,
          'is_current': isCurrent ? '1' : '0',
        },
      );
      final data = _decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == true) {
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Pregnancy record saved',
        );
        await fetchRecords();
        return true;
      }
      Get.snackbar('Error', data['message']?.toString() ?? 'Unable to save');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateStatus(
    PregnancyRecordModel record, {
    required String status,
  }) async {
    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse('${Api.pregnancyStatus}/${record.id}'),
        headers: {'Accept': 'application/json'},
        body: {
          'status': status,
          'pregnancy_result': resultForStatus(status, record.pregnancyResult),
          if (status == 'calved') 'calving_date': todayString(),
        },
      );
      final data = _decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Pregnancy status updated',
        );
        await fetchRecords();
        return true;
      }
      Get.snackbar('Error', data['message']?.toString() ?? 'Unable to update');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteRecord(PregnancyRecordModel record) async {
    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse('${Api.pregnancyDelete}/${record.id}'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Pregnancy record deleted',
        );
        await fetchRecords();
        return true;
      }
      Get.snackbar('Error', data['message']?.toString() ?? 'Unable to delete');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  ({int pregnancyNo, int serviceNo}) nextNumbers(int animalId) {
    final animalRecords = records
        .where((item) => item.animalId == animalId)
        .toList()
      ..sort((a, b) {
        final pregnancyCompare = b.pregnancyNo.compareTo(a.pregnancyNo);
        if (pregnancyCompare != 0) return pregnancyCompare;
        final serviceCompare = b.serviceNo.compareTo(a.serviceNo);
        if (serviceCompare != 0) return serviceCompare;
        return b.id.compareTo(a.id);
      });
    if (animalRecords.isEmpty) {
      return (pregnancyNo: 1, serviceNo: 1);
    }
    final latest = animalRecords.first;
    if (latest.status == 'calved') {
      return (pregnancyNo: latest.pregnancyNo + 1, serviceNo: 1);
    }
    return (pregnancyNo: latest.pregnancyNo, serviceNo: latest.serviceNo + 1);
  }

  String resultForStatus(String status, String fallback) {
    if (status == 'pregnant' || status == 'calved') return 'pregnant';
    if (status == 'not_pregnant' || status == 'repeat_heat') {
      return 'not_pregnant';
    }
    return fallback.trim().isEmpty ? 'pending' : fallback;
  }

  String statusLabel(String status) {
    if (status == 'all') return 'All';
    return status
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String addDays(String date, int days) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return '';
    return _formatDate(parsed.add(Duration(days: days)));
  }

  String todayString() => _formatDate(DateTime.now());

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
