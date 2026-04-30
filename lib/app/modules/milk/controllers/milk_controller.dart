import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';
import '../../../routes/app_pages.dart';

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
  final RxList<MilkPanModel> pans = <MilkPanModel>[].obs;
  final RxList<MilkDairyModel> dairies = <MilkDairyModel>[].obs;
  final Rxn<MilkAnimalModel> selectedAnimal = Rxn<MilkAnimalModel>();
  final Rxn<MilkPanModel> selectedPan = Rxn<MilkPanModel>();
  final Rxn<MilkDairyModel> selectedDairy = Rxn<MilkDairyModel>();
  final RxString selectedShift = 'Morning'.obs;
  final RxBool isScheduleLoading = false.obs;

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    milkDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    initData();
  }

  Future<void> initData() async {
    await loadFarmerId();
    await Future.wait([fetchAnimals(), fetchDairies(), refreshAutoSchedule()]);
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
        final fetched = list.map((item) => MilkAnimalModel.fromJson(item)).toList();
        final milkingOnly = fetched.where((animal) => _isMilkingAnimalType(animal.animalTypeName)).toList();
        animals.assignAll(milkingOnly);
        final currentAnimal = selectedAnimal.value;
        if (currentAnimal != null && !milkingOnly.any((animal) => animal.id == currentAnimal.id)) {
          selectedAnimal.value = null;
        }
        _rebuildPansFromAnimals();
      } else {
        animals.clear();
        pans.clear();
        selectedPan.value = null;
      }
    } catch (_) {
      animals.clear();
      pans.clear();
      selectedPan.value = null;
    } finally {
      isPageLoading.value = false;
    }
  }

  bool _isMilkingAnimalType(String typeName) {
    final value = typeName.trim().toLowerCase();
    if (value.isEmpty) return false;
    return value.contains('milking') ||
        value.contains('milky') ||
        value.contains('दूध') ||
        value.contains('दुध');
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

  Future<void> openAddDairyFromMilk() async {
    final result = await Get.toNamed(
      Routes.DAIRY,
      arguments: {'opened_from_milk': true},
    );

    await fetchDairies();

    final selectedId = _extractDairyIdFromResult(result);
    if (selectedId != null) {
      final matched = dairies.firstWhereOrNull((dairy) => dairy.id == selectedId);
      if (matched != null) {
        selectedDairy.value = matched;
        return;
      }
    }

    if (result is Map && result['dairy_added'] == true && dairies.isNotEmpty) {
      selectedDairy.value ??= dairies.first;
    }
  }

  Future<void> pickMilkDate() async {
    // Shift/date flow is fully automatic now by farmer entry progression.
  }

  Future<void> submitMilk() async {
    if (!formKey.currentState!.validate()) return;
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer ID not found. Please login again.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedAnimal.value == null) {
      if (selectedPan.value == null) {
        Get.snackbar('Error', 'Please select an animal or PAN', snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }
    if (selectedPan.value != null) {
      final pan = selectedPan.value!;
      final panAnimals = animals.where((animal) => animal.belongsToPan(pan)).toList();
      if (panAnimals.isEmpty) {
        Get.snackbar('Error', 'No animals found in selected PAN', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final totalQty = double.tryParse(quantityController.text.trim()) ?? 0;
      if (totalQty <= 0) {
        Get.snackbar('Error', 'Please enter valid milk quantity', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final perAnimalQty = totalQty / panAnimals.length;
      final qty = _formatDistributedValue(perAnimalQty);
      final quantityByAnimal = <int, String>{
        for (final animal in panAnimals) animal.id: qty,
      };

      final result = await submitBulkMilk(quantityByAnimal);
      final successCount = result['success'] ?? 0;
      final failedCount = result['failed'] ?? 0;

      if (successCount > 0 && failedCount == 0) {
        final successMessage = 'Milk record saved successfully for $successCount animals in ${pan.name}';
        await refreshAutoSchedule();
        clearForm();
        Get.back(result: {'success': true, 'message': successMessage});
        Future.delayed(const Duration(milliseconds: 120), () {
          Get.snackbar(
            'Success',
            successMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else if (successCount > 0) {
        Get.snackbar(
          'Partial Success',
          'Saved for $successCount animals, failed for $failedCount.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to save milk for selected PAN.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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
        await refreshAutoSchedule();
        clearForm();
        Get.back(result: {'success': true, 'message': successMessage});
        Future.delayed(const Duration(milliseconds: 120), () {
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

  String _formatDistributedValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> refreshAutoSchedule() async {
    if (farmerId == 0) return;
    try {
      isScheduleLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.milkList}/$farmerId'),
        headers: const {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || data['status'] != true) {
        _setDefaultSchedule();
        return;
      }

      final List list = data['data'] ?? [];
      if (list.isEmpty) {
        _setDefaultSchedule();
        return;
      }

      final rows = list.whereType<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();
      final latestDate = _latestRecordedDate(rows);
      if (latestDate == null) {
        _setDefaultSchedule();
        return;
      }

      final sameDateRows = rows.where((row) => _isSameDate(_parseApiDate(row['date']), latestDate)).toList();
      final morningDone = sameDateRows.any((row) => _isShiftValuePresent(row['morning_milk']));
      final afternoonDone = sameDateRows.any((row) => _isShiftValuePresent(row['afternoon_milk']));
      final eveningDone = sameDateRows.any((row) => _isShiftValuePresent(row['evening_milk']));

      DateTime targetDate = latestDate;
      String targetShift = 'Morning';

      if (!morningDone) {
        targetShift = 'Morning';
      } else if (!afternoonDone) {
        targetShift = 'Afternoon';
      } else if (!eveningDone) {
        targetShift = 'Evening';
      } else {
        targetDate = latestDate.add(const Duration(days: 1));
        targetShift = 'Morning';
      }

      milkDateController.text = DateFormat('dd/MM/yyyy').format(targetDate);
      selectedShift.value = targetShift;
    } catch (_) {
      _setDefaultSchedule();
    } finally {
      isScheduleLoading.value = false;
    }
  }

  void _setDefaultSchedule() {
    milkDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    selectedShift.value = 'Morning';
  }

  DateTime? _latestRecordedDate(List<Map<String, dynamic>> rows) {
    DateTime? latest;
    for (final row in rows) {
      final parsed = _parseApiDate(row['date']);
      if (parsed == null) continue;
      if (latest == null || parsed.isAfter(latest)) {
        latest = parsed;
      }
    }
    return latest;
  }

  DateTime? _parseApiDate(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {}
    try {
      return DateFormat('d/M/yyyy').parseStrict(text);
    } catch (_) {}
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(text);
    } catch (_) {}
    return null;
  }

  bool _isSameDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) return false;
    return first.year == second.year && first.month == second.month && first.day == second.day;
  }

  bool _isShiftValuePresent(dynamic value) {
    final parsed = double.tryParse((value ?? '').toString().trim()) ?? 0;
    return parsed > 0;
  }

  int? _extractDairyIdFromResult(dynamic result) {
    if (result is! Map) return null;
    final parsed = int.tryParse((result['dairy_id'] ?? '').toString());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return null;
  }

  void clearForm() {
    selectedAnimal.value = null;
    selectedPan.value = null;
    selectedDairy.value = null;
    quantityController.clear();
    fatController.clear();
    snfController.clear();
    rateController.clear();
    notesController.clear();
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

  void _rebuildPansFromAnimals() {
    final unique = <String, MilkPanModel>{};
    for (final animal in animals) {
      final panName = animal.panName.trim();
      if (panName.isEmpty) continue;
      final key = animal.panId > 0 ? 'id_${animal.panId}' : 'name_${panName.toLowerCase()}';
      unique.putIfAbsent(
        key,
        () => MilkPanModel(id: animal.panId, name: panName),
      );
    }
    final next = unique.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    pans.assignAll(next);
    final current = selectedPan.value;
    if (current != null && !next.any((pan) => pan.matches(current))) {
      selectedPan.value = null;
    }
  }
}

class MilkAnimalModel {
  final int id;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;
  final int panId;
  final String panName;

  MilkAnimalModel({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
    required this.panId,
    required this.panName,
  });

  String get displayName {
    final name = animalName.trim().isEmpty ? 'Unnamed Animal' : animalName;
    final tag = tagNumber.trim().isEmpty ? '' : ' - Tag $tagNumber';
    return '$name$tag';
  }

  bool belongsToPan(MilkPanModel pan) {
    if (panId > 0 && pan.id > 0) {
      return panId == pan.id;
    }
    final animalPan = panName.trim().toLowerCase();
    final selectedPan = pan.name.trim().toLowerCase();
    if (animalPan.isEmpty || selectedPan.isEmpty) {
      return false;
    }
    return animalPan == selectedPan;
  }

  factory MilkAnimalModel.fromJson(Map<String, dynamic> json) {
    final panFromFlat = json['pan_name']?.toString() ?? '';
    final panFromNested = json['pan'] is Map
        ? ((json['pan'] as Map)['name']?.toString() ?? '')
        : '';

    return MilkAnimalModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      panId: int.tryParse((json['pan_id'] ?? '').toString()) ?? 0,
      panName: panFromFlat.trim().isNotEmpty ? panFromFlat : panFromNested,
    );
  }
}

class MilkPanModel {
  final int id;
  final String name;

  MilkPanModel({required this.id, required this.name});

  bool matches(MilkPanModel other) {
    if (id > 0 && other.id > 0) {
      return id == other.id;
    }
    return name.trim().toLowerCase() == other.name.trim().toLowerCase();
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

