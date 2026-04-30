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
  final RxBool isScheduleLoading = false.obs;

  final RxList<FeedingAnimalModel> animals = <FeedingAnimalModel>[].obs;
  final RxList<FeedingPanModel> pans = <FeedingPanModel>[].obs;
  final RxList<FeedTypeModel> feedTypes = <FeedTypeModel>[].obs;
  final Rxn<FeedingAnimalModel> selectedAnimal = Rxn<FeedingAnimalModel>();
  final Rxn<FeedingPanModel> selectedPan = Rxn<FeedingPanModel>();
  final Rxn<FeedTypeModel> selectedFeedType = Rxn<FeedTypeModel>();
  final RxString selectedUnit = 'Kg'.obs;
  final RxString selectedFeedingTime = 'Morning'.obs;
  final RxDouble packageQuantity = 0.0.obs;
  final RxDouble totalSubtypeQuantity = 0.0.obs;
  final RxDouble balanceQuantity = 0.0.obs;

  final RxMap<int, bool> subtypeSelected = <int, bool>{}.obs;
  final Map<int, TextEditingController> subtypeQuantityControllers = {};

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    quantityController.addListener(_recalculateBalance);
    initData();
  }

  Future<void> initData() async {
    await loadFarmerId();
    await Future.wait([fetchAnimals(), fetchFeedTypes(), refreshAutoSchedule()]);
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

  Future<void> fetchFeedTypes() async {
    if (farmerId == 0) return;
    try {
      final uri = Uri.parse('${Api.feedingTypes}?farmer_id=$farmerId');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        feedTypes.assignAll(
          list.map((item) => FeedTypeModel.fromJson(item)).toList(),
        );
        if (feedTypes.isNotEmpty) {
          onFeedTypeChanged(selectedFeedType.value ?? feedTypes.first);
        } else {
          _clearSubtypeInputs();
        }
      } else {
        feedTypes.clear();
        _clearSubtypeInputs();
      }
    } catch (_) {
      feedTypes.clear();
      _clearSubtypeInputs();
    }
  }

  Future<void> pickDate() async {
    // Feeding date and time are automatically managed in sequence.
  }

  Future<void> submitFeeding() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedAnimal.value == null && selectedPan.value == null) {
      Get.snackbar('Error', 'Please select an animal or PAN');
      return;
    }
    if (selectedFeedType.value == null) {
      Get.snackbar('Error', 'Please select feed type');
      return;
    }

    final feedingQty = double.tryParse(quantityController.text.trim()) ?? 0;
    if (feedingQty <= 0) {
      Get.snackbar('Error', 'Please enter feeding quantity');
      return;
    }

    final subtypePayload = _selectedSubtypePayload();
    if (subtypePayload.isEmpty) {
      Get.snackbar('Error', 'Please select at least one subtype with quantity');
      return;
    }

    if (selectedPan.value != null) {
      final pan = selectedPan.value!;
      final panAnimals = animals.where((animal) => animal.belongsToPan(pan)).toList();
      if (panAnimals.isEmpty) {
        Get.snackbar('Error', 'No animals found in selected PAN');
        return;
      }

      final perAnimalDivider = panAnimals.length;
      final perAnimalFeedingQty = feedingQty / perAnimalDivider;
      final perAnimalPackageQty = packageQuantity.value / perAnimalDivider;
      final perAnimalBalanceQty = balanceQuantity.value / perAnimalDivider;
      final perAnimalSubtypePayload = subtypePayload
          .map(
            (item) => <String, dynamic>{
              if (item['subtype_id'] != null) 'subtype_id': item['subtype_id'],
              'name': item['name'],
              'quantity':
                  (double.tryParse(item['quantity'].toString()) ?? 0) / perAnimalDivider,
            },
          )
          .toList();

      final perAnimalQtyText = _formatDistributedValue(perAnimalFeedingQty);
      final quantityByAnimal = <int, String>{
        for (final animal in panAnimals) animal.id: perAnimalQtyText,
      };

      final result = await submitBulkFeeding(
        quantityByAnimal,
        packageQuantityPerAnimal: perAnimalPackageQty,
        balanceQuantityPerAnimal: perAnimalBalanceQty,
        subtypePayloadPerAnimal: perAnimalSubtypePayload,
      );
      final successCount = result['success'] ?? 0;
      final failedCount = result['failed'] ?? 0;

      if (successCount > 0 && failedCount == 0) {
        final successMessage = 'Feeding entry saved successfully for $successCount animals in ${pan.name}';
        await refreshAutoSchedule();
        clearForm();
        Get.back(
          result: {
            'success': true,
            'message': successMessage,
          },
        );
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
          'Failed to save feeding for selected PAN.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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
        'package_quantity': packageQuantity.value.toStringAsFixed(2),
        'feeding_quantity': quantityController.text.trim(),
        'balance_quantity': balanceQuantity.value.toStringAsFixed(2),
        'feed_subtype_details': subtypePayload,
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
        final successMessage = data['message']?.toString() ?? 'Feeding entry saved successfully';
        await refreshAutoSchedule();
        clearForm();
        Get.back(
          result: {
            'success': true,
            'message': successMessage,
          },
        );
        Future.delayed(const Duration(milliseconds: 120), () {
          Get.snackbar(
            'Success',
            successMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
        });
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
    {
    double? packageQuantityPerAnimal,
    double? balanceQuantityPerAnimal,
    List<Map<String, dynamic>>? subtypePayloadPerAnimal,
  }
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

    final subtypePayload = subtypePayloadPerAnimal ?? _selectedSubtypePayload();
    if (subtypePayload.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select at least one subtype with quantity.',
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
          'package_quantity':
              (packageQuantityPerAnimal ?? packageQuantity.value).toStringAsFixed(2),
          'feeding_quantity': entry.value,
          'balance_quantity':
              (balanceQuantityPerAnimal ?? balanceQuantity.value).toStringAsFixed(2),
          'feed_subtype_details': subtypePayload,
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

  Future<void> refreshAutoSchedule() async {
    if (farmerId == 0) return;
    try {
      isScheduleLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.feedingList}/$farmerId'),
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
      final morningDone = sameDateRows.any((row) => (row['feeding_time'] ?? '').toString().trim().toLowerCase() == 'morning');
      final afternoonDone = sameDateRows.any((row) => (row['feeding_time'] ?? '').toString().trim().toLowerCase() == 'afternoon');
      final eveningDone = sameDateRows.any((row) => (row['feeding_time'] ?? '').toString().trim().toLowerCase() == 'evening');

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

      dateController.text = DateFormat('dd/MM/yyyy').format(targetDate);
      selectedFeedingTime.value = targetShift;
    } catch (_) {
      _setDefaultSchedule();
    } finally {
      isScheduleLoading.value = false;
    }
  }

  void _setDefaultSchedule() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    selectedFeedingTime.value = 'Morning';
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

  String _formatDate(String value) {
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

  void onFeedTypeChanged(FeedTypeModel? value) {
    selectedFeedType.value = value;
    if (value != null) {
      selectedUnit.value = value.defaultUnit;
      packageQuantity.value = 0;
      _resetSubtypeInputs(value.subtypes);
    } else {
      selectedUnit.value = 'Kg';
      packageQuantity.value = 0;
      _clearSubtypeInputs();
    }
    _recalculateBalance();
  }

  void onSubtypeChecked(int subtypeId, bool isChecked) {
    subtypeSelected[subtypeId] = isChecked;
    if (!isChecked) {
      subtypeQuantityControllers[subtypeId]?.clear();
    }
    _recalculateSubtypeTotal();
  }

  void _resetSubtypeInputs(List<FeedSubtypeModel> subtypes) {
    _clearSubtypeInputs();
    for (final subtype in subtypes) {
      subtypeSelected[subtype.id] = false;
      final controller = TextEditingController();
      controller.addListener(_recalculateSubtypeTotal);
      subtypeQuantityControllers[subtype.id] = controller;
    }
    _recalculateSubtypeTotal();
  }

  void _clearSubtypeInputs() {
    for (final controller in subtypeQuantityControllers.values) {
      controller.removeListener(_recalculateSubtypeTotal);
      controller.dispose();
    }
    subtypeQuantityControllers.clear();
    subtypeSelected.clear();
    totalSubtypeQuantity.value = 0;
  }

  void _recalculateSubtypeTotal() {
    double total = 0;
    subtypeSelected.forEach((subtypeId, selected) {
      if (!selected) return;
      final qty = double.tryParse(subtypeQuantityControllers[subtypeId]?.text.trim() ?? '') ?? 0;
      if (qty > 0) {
        total += qty;
      }
    });
    totalSubtypeQuantity.value = total;
    packageQuantity.value = total;
    _recalculateBalance();
  }

  List<Map<String, dynamic>> _selectedSubtypePayload() {
    final currentType = selectedFeedType.value;
    if (currentType == null) return [];
    final payload = <Map<String, dynamic>>[];

    for (final subtype in currentType.subtypes) {
      if (!(subtypeSelected[subtype.id] ?? false)) continue;
      final quantity = double.tryParse(subtypeQuantityControllers[subtype.id]?.text.trim() ?? '') ?? 0;
      if (quantity <= 0) continue;
      payload.add({
        'subtype_id': subtype.id,
        'name': subtype.name,
        'quantity': quantity,
      });
    }
    return payload;
  }

  void _recalculateBalance() {
    final qty = double.tryParse(quantityController.text.trim()) ?? 0;
    final balance = packageQuantity.value - qty;
    balanceQuantity.value = balance < 0 ? 0 : balance;
  }

  void clearForm() {
    selectedAnimal.value = null;
    selectedPan.value = null;
    selectedFeedType.value = feedTypes.isNotEmpty ? feedTypes.first : null;
    if (selectedFeedType.value != null) {
      onFeedTypeChanged(selectedFeedType.value);
    } else {
      selectedUnit.value = 'Kg';
      packageQuantity.value = 0;
      _clearSubtypeInputs();
    }
    quantityController.clear();
    notesController.clear();
    balanceQuantity.value = packageQuantity.value;
  }

  void _rebuildPansFromAnimals() {
    final unique = <String, FeedingPanModel>{};
    for (final animal in animals) {
      final panName = animal.panName.trim();
      if (panName.isEmpty) continue;
      final key = animal.panId > 0 ? 'id_${animal.panId}' : 'name_${panName.toLowerCase()}';
      unique.putIfAbsent(
        key,
        () => FeedingPanModel(id: animal.panId, name: panName),
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

  @override
  void onClose() {
    quantityController.removeListener(_recalculateBalance);
    dateController.dispose();
    quantityController.dispose();
    notesController.dispose();
    _clearSubtypeInputs();
    super.onClose();
  }
}

class FeedingAnimalModel {
  final int id;
  final String animalName;
  final String tagNumber;
  final int panId;
  final String panName;

  FeedingAnimalModel({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.panId,
    required this.panName,
  });

  String get displayName {
    final name = animalName.trim().isEmpty ? 'Unnamed Animal' : animalName;
    final tag = tagNumber.trim().isEmpty ? '' : ' - Tag $tagNumber';
    return '$name$tag';
  }

  bool belongsToPan(FeedingPanModel pan) {
    if (panId > 0 && pan.id > 0) {
      return panId == pan.id;
    }
    final animalPan = panName.trim().toLowerCase();
    final selectedPanName = pan.name.trim().toLowerCase();
    if (animalPan.isEmpty || selectedPanName.isEmpty) {
      return false;
    }
    return animalPan == selectedPanName;
  }

  factory FeedingAnimalModel.fromJson(Map<String, dynamic> json) {
    final panFromFlat = json['pan_name']?.toString() ?? '';
    final panFromNested = json['pan'] is Map
        ? ((json['pan'] as Map)['name']?.toString() ?? '')
        : '';
    return FeedingAnimalModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      panId: int.tryParse((json['pan_id'] ?? '').toString()) ?? 0,
      panName: panFromFlat.trim().isNotEmpty ? panFromFlat : panFromNested,
    );
  }
}

class FeedingPanModel {
  final int id;
  final String name;

  FeedingPanModel({required this.id, required this.name});

  bool matches(FeedingPanModel other) {
    if (id > 0 && other.id > 0) {
      return id == other.id;
    }
    return name.trim().toLowerCase() == other.name.trim().toLowerCase();
  }
}

class FeedTypeModel {
  final int id;
  final String name;
  final String defaultUnit;
  final double packageQuantity;
  final List<FeedSubtypeModel> subtypes;

  FeedTypeModel({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.packageQuantity,
    required this.subtypes,
  });

  factory FeedTypeModel.fromJson(Map<String, dynamic> json) {
    final List list = json['subtypes'] is List ? (json['subtypes'] as List) : const [];
    return FeedTypeModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      defaultUnit: json['default_unit']?.toString() ?? 'Kg',
      packageQuantity: double.tryParse((json['package_quantity'] ?? '0').toString()) ?? 0,
      subtypes: list
          .map((item) => FeedSubtypeModel.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class FeedSubtypeModel {
  final int id;
  final String name;

  FeedSubtypeModel({required this.id, required this.name});

  factory FeedSubtypeModel.fromJson(Map<String, dynamic> json) {
    return FeedSubtypeModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
