import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/local_notification_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../models/pregnancy_record_model.dart';

class ManagePregnancyController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<PregnancyRecordModel> records = <PregnancyRecordModel>[].obs;
  final RxList<PregnancyAnimalOption> animals = <PregnancyAnimalOption>[].obs;
  final RxList<PregnancyAnimalOption> allAnimals =
      <PregnancyAnimalOption>[].obs;
  final RxString selectedStatus = 'pregnancy_check_due'.obs;
  final RxnInt selectedAnimalId = RxnInt();
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  int farmerId = 0;

  static const List<String> statuses = [
    'pregnancy_check_due',
    'pregnant',
    'calved',
    'aborted',
    'not_pregnant',
    'all',
  ];

  List<PregnancyRecordModel> get filteredRecords {
    final status = selectedStatus.value;
    final animalId = selectedAnimalId.value;
    final query = searchQuery.value.trim().toLowerCase();
    return records.where((item) {
      final matchesStatus = status == 'all' || item.status == status;
      final matchesAnimal =
          animalId == null || animalId <= 0 || item.animalId == animalId;
      final matchesSearch = query.isEmpty || item.searchText.contains(query);
      return matchesStatus && matchesAnimal && matchesSearch;
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
        final parsed = list
            .whereType<Map>()
            .map(
              (item) => PregnancyAnimalOption.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
        allAnimals.assignAll(parsed);
        animals.assignAll(parsed.where(_isPregnancyEligibleCow).toList());
      }
    } catch (_) {
      animals.clear();
      allAnimals.clear();
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
        final parsedRecords = list
            .whereType<Map>()
            .map(
              (item) => PregnancyRecordModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
        records.assignAll(parsedRecords);
        await _notifyDueBeforeTwoDays(parsedRecords);
      } else {
        records.clear();
      }
    } catch (e) {
      records.clear();
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveRecord({
    PregnancyRecordModel? record,
    required int animalId,
    required int lactationNumber,
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
      Get.snackbar('validation'.tr, 'please_select_cow'.tr);
      return false;
    }
    if (aiDate.trim().isEmpty) {
      Get.snackbar('validation'.tr, 'please_select_ai_date'.tr);
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
          if (lactationNumber >= 0)
            'lactation_number': lactationNumber.toString(),
          'pregnancy_no': pregnancyNo.toString(),
          'service_no': serviceNo.toString(),
          'heat_date': _apiDate(heatDate),
'ai_date': _apiDate(aiDate),
          'service_type': serviceType,
          'bull_name': bullName,
          'semen_no': semenNo,
          'doctor_name': doctorName,
          'pregnancy_check_due_date': _apiDate(pregnancyCheckDueDate),
'pregnancy_check_date': _apiDate(pregnancyCheckDate),
          'pregnancy_result': pregnancyResult,
          'expected_calving_date': _apiDate(expectedCalvingDate),
'dry_off_date': _apiDate(dryOffDate),
'calving_date': _apiDate(calvingDate),
          'status': status,
          'calf_animal_id': calfAnimalId > 0 ? calfAnimalId.toString() : '',
          'notes': notes,
          'is_current': isCurrent ? '1' : '0',
        },
      );
      final data = _decode(response.body);
      if (_isSuccessResponse(response, data)) {
        Get.snackbar(
          'success'.tr,
          _extractMessage(data, fallback: 'pregnancy_record_saved'.tr),
          duration: const Duration(seconds: 4),
        );
        await fetchRecords();
        return true;
      }
      Get.snackbar(
        'error'.tr,
        _extractMessage(data, fallback: 'unable_to_save'.tr),
      );
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateStatus(
    PregnancyRecordModel record, {
    required String status,
    required String pregnancyCheckDate,
    String calvingDate = '',
    String breedName = '',
    String abortDate = '',
    String abortReason = '',
  }) async {
    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse('${Api.pregnancyStatus}/${record.id}'),
        headers: {'Accept': 'application/json'},
        body: {
          'status': status,
          'pregnancy_result': resultForStatus(status, record.pregnancyResult),
          if (pregnancyCheckDate.trim().isNotEmpty)
  'pregnancy_check_date': _apiDate(pregnancyCheckDate),
          if (calvingDate.trim().isNotEmpty) 'calving_date': calvingDate.trim(),
          if (breedName.trim().isNotEmpty) 'breed_name': breedName.trim(),
          if (abortDate.trim().isNotEmpty) 'abort_date': abortDate.trim(),
          if (abortReason.trim().isNotEmpty) 'abort_reason': abortReason.trim(),
        },
      );
      final data = _decode(response.body);
      if (_isSuccessResponse(response, data)) {
        Get.snackbar(
          'success'.tr,
          _extractMessage(data, fallback: 'pregnancy_status_updated'.tr),
          duration: const Duration(seconds: 4),
        );
        await fetchRecords();
        return true;
      }
      Get.snackbar(
        'error'.tr,
        _extractMessage(data, fallback: 'unable_to_update'.tr),
      );
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
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
      if (_isSuccessResponse(response, data)) {
        Get.snackbar(
          'success'.tr,
          _extractMessage(data, fallback: 'pregnancy_record_deleted'.tr),
          duration: const Duration(seconds: 4),
        );
        await fetchRecords();
        return true;
      }
      Get.snackbar(
        'error'.tr,
        _extractMessage(data, fallback: 'unable_to_delete'.tr),
      );
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  ({int pregnancyNo, int serviceNo}) nextNumbers(int animalId) {
    final animalRecords =
        records.where((item) => item.animalId == animalId).toList()
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
    if (status == 'pregnant' || status == 'calved' || status == 'aborted') {
      return 'pregnant';
    }
    if (status == 'not_pregnant' || status == 'repeat_heat') {
      return 'not_pregnant';
    }
    return fallback.trim().isEmpty ? 'pending' : fallback;
  }

  String statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'all':
        return 'all'.tr;
      case 'pregnancy_check_due':
        return 'pregnancy_check_due'.tr;
      case 'pregnant':
        return 'pregnant'.tr;
      case 'calved':
        return 'delivery'.tr;
      case 'aborted':
        return 'abort'.tr;
      case 'not_pregnant':
        return 'non_pregnant'.tr;
      default:
        return status
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  String addDays(String date, int days) {
  final parsed = _parseDate(date);
  if (parsed == null) return '';
  return _formatDate(parsed.add(Duration(days: days)));
}

  String todayString() => _formatDate(DateTime.now());

 String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

DateTime? _parseDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  final formats = [
    RegExp(r'^\d{2}-\d{2}-\d{4}$'),
    RegExp(r'^\d{2}/\d{2}/\d{4}$'),
    RegExp(r'^\d{4}-\d{2}-\d{2}$'),
  ];

  try {
    if (formats[0].hasMatch(text)) {
      final parts = text.split('-');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }

    if (formats[1].hasMatch(text)) {
      final parts = text.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }

    if (formats[2].hasMatch(text)) {
      return DateTime.tryParse(text);
    }
  } catch (_) {}

  return DateTime.tryParse(text);
}

String _apiDate(String value) {
  final parsed = _parseDate(value);
  if (parsed == null) return '';

  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');

  return '${parsed.year}-$month-$day';
}

  Future<void> _notifyDueBeforeTwoDays(
    List<PregnancyRecordModel> loadedRecords,
  ) async {
    if (loadedRecords.isEmpty || farmerId <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final record in loadedRecords) {
      final status = record.status.trim().toLowerCase();
      if (!record.isCurrent) continue;
      if (status == 'not_pregnant' ||
          status == 'repeat_heat' ||
          status == 'aborted' ||
          status == 'calved') {
        continue;
      }

      final due = DateTime.tryParse(record.pregnancyCheckDueDate.trim());
      if (due == null) continue;

      final dueDate = DateTime(due.year, due.month, due.day);
      final diffDays = dueDate.difference(todayDate).inDays;
      if (diffDays != 2) continue;

      final reminderKey =
          'pregnancy_due_reminder_${farmerId}_${record.id}_${record.pregnancyCheckDueDate}';
      if (prefs.getBool(reminderKey) == true) continue;

      await LocalNotificationService.instance.showMessage(
        id: record.id + 700000,
        title: 'pregnancy_check_reminder'.tr,
        body: 'pregnancy_check_due_on'.trParams({
          'cow': record.cowLabel,
          'date': record.pregnancyCheckDueDate,
        }),
      );
      await prefs.setBool(reminderKey, true);
    }
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded as Map);
  }

  bool _isSuccessResponse(http.Response response, Map<String, dynamic> data) {
    final codeOk = response.statusCode >= 200 && response.statusCode < 300;
    final status = data['status'];
    final success = data['success'];
    final statusOk =
        status == true ||
        status == 1 ||
        status?.toString().toLowerCase() == 'true';
    final successOk =
        success == true ||
        success == 1 ||
        success?.toString().toLowerCase() == 'true';
    return codeOk && (statusOk || successOk || data.isEmpty);
  }

  String _extractMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
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
    return message.toString().trim().isEmpty
        ? fallback
        : message.toString().trim();
  }

  bool _isPregnancyEligibleCow(PregnancyAnimalOption animal) {
    final gender = animal.gender.trim().toLowerCase();
    final type = animal.animalTypeName.trim().toLowerCase();

    final isFemale =
        gender == 'female' ||
        gender == 'f' ||
        gender == 'cow' ||
        gender == 'heifer';
    final isCalfType =
        type.contains('calf') || type.contains('calves') || type == 'calves';

    return isFemale && !isCalfType;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
