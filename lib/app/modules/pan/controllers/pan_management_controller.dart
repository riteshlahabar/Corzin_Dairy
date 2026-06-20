import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class PanManagementController extends GetxController {
  final RxBool isLoadingAnimals = false.obs;
  final RxBool isLoadingPans = false.obs;
  final RxBool isSubmitting = false.obs;

  final TextEditingController panNameController = TextEditingController();

  final RxList<PanAnimalItem> animals = <PanAnimalItem>[].obs;
  final RxList<PanGroupItem> pans = <PanGroupItem>[].obs;
  final RxList<PanAnimalTypeOption> animalTypes = <PanAnimalTypeOption>[].obs;
  final RxList<int> selectedAnimalIds = <int>[].obs;
  final RxList<String> selectedMilkShifts = <String>['Morning', 'Afternoon', 'Evening'].obs;
  final RxString selectedPanType = panTypeMilking.obs;
  static const List<String> milkShiftOptions = <String>['Morning', 'Afternoon', 'Evening'];
  static const String panTypeMilking = 'milking';
  static const String panTypeNonMilking = 'non_milking';

  int farmerId = 0;

  bool get isMilkingPan => selectedPanType.value == panTypeMilking;

  List<PanAnimalItem> get filteredAnimals {
    final available = animals.where((item) => (item.panId ?? 0) <= 0).toList();
    return available
        .where((item) => item.matchesPanType(selectedPanType.value))
        .toList();
  }

  List<PanAnimalItem> editableAnimalsForPan(PanGroupItem pan) {
    return animals.where((item) {
      final panId = item.panId ?? 0;
      final isCurrentPanAnimal = panId == pan.id;
      final isUnassigned = panId <= 0;
      if (!(isCurrentPanAnimal || isUnassigned)) return false;
      return item.matchesPanType(pan.panType);
    }).toList();
  }

  String translatedAnimalTypeName(String rawName, {bool plural = false}) {
    final normalized = rawName.trim().toLowerCase();
    if (normalized.isEmpty) return rawName;

    if (_containsAny(normalized, const ['milking cow', 'milking cows']) ||
        (normalized.contains('milking') && !normalized.contains('non'))) {
      return plural ? 'milking_cows'.tr : 'milking_cow'.tr;
    }

    if (_containsAny(normalized, const [
          'non milking cow',
          'non-milking cow',
          'non milking cows',
          'non-milking cows',
          'dry cow',
          'dry cows',
        ]) ||
        normalized.contains('dry')) {
      return plural ? 'dry_cows'.tr : 'dry_cow'.tr;
    }

    if (_containsAny(normalized, const ['heifer', 'heifers'])) {
      return plural ? 'heifers'.tr : 'heifer'.tr;
    }

    if (_containsAny(normalized, const ['calf', 'calves'])) {
      return plural ? 'calves'.tr : 'calf'.tr;
    }

    if (_containsAny(normalized, const ['bull', 'bulls'])) {
      return plural ? 'bulls'.tr : 'bull'.tr;
    }

    if (_containsAny(normalized, const ['cow', 'cows'])) {
      return plural ? 'cow'.tr : 'cow_single'.tr;
    }

    return rawName;
  }

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await Future.wait([fetchAnimals(), fetchPans(), fetchAnimalTypes()]);
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) {
      animals.clear();
      return;
    }

    try {
      isLoadingAnimals.value = true;
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = (data['data'] as List?) ?? const [];
        animals.assignAll(
          list
              .whereType<Map>()
              .map((item) => PanAnimalItem.fromJson(Map<String, dynamic>.from(item)))
              .toList(),
        );
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      isLoadingAnimals.value = false;
    }
  }

  Future<void> fetchPans() async {
    if (farmerId == 0) {
      pans.clear();
      return;
    }

    try {
      isLoadingPans.value = true;
      final response = await http.get(
        Uri.parse('${Api.animalPanList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = (data['data'] as List?) ?? const [];
        final parsedPans =
          list
              .whereType<Map>()
              .map((item) => PanGroupItem.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        pans.assignAll(
          _applyPanTypeAnimalRules(_applyPanAnimalFallback(parsedPans)),
        );
      } else {
        pans.clear();
      }
    } catch (_) {
      pans.clear();
    } finally {
      isLoadingPans.value = false;
    }
  }

  Future<void> fetchAnimalTypes() async {
    try {
      final response = await http.get(
        Uri.parse(Api.animalTypes),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = (data['data'] as List?) ?? const [];
        animalTypes.assignAll(
          list
              .whereType<Map>()
              .map(
                (item) => PanAnimalTypeOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.id > 0 && item.name.trim().isNotEmpty)
              .toList(),
        );
      } else {
        animalTypes.clear();
      }
    } catch (_) {
      animalTypes.clear();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchAnimals(), fetchPans(), fetchAnimalTypes()]);
  }

  void toggleAnimalSelection(int animalId) {
    if (selectedAnimalIds.contains(animalId)) {
      selectedAnimalIds.remove(animalId);
    } else {
      selectedAnimalIds.add(animalId);
    }
  }

  void toggleMilkShift(String shift) {
    if (!isMilkingPan) {
      return;
    }
    if (selectedMilkShifts.contains(shift)) {
      if (selectedMilkShifts.length == 1) {
        Get.snackbar('info'.tr, 'please_keep_at_least_one_milk_shift_selected'.tr);
        return;
      }
      selectedMilkShifts.remove(shift);
    } else {
      selectedMilkShifts.add(shift);
      selectedMilkShifts.sort((a, b) => milkShiftOptions.indexOf(a).compareTo(milkShiftOptions.indexOf(b)));
    }
  }

  void setPanType(String value) {
    if (value != panTypeMilking && value != panTypeNonMilking) {
      return;
    }
    selectedPanType.value = value;
    if (isMilkingPan) {
      if (selectedMilkShifts.isEmpty) {
        selectedMilkShifts.assignAll(<String>['Morning']);
      }
      final allowedIds = filteredAnimals.map((item) => item.id).toSet();
      selectedAnimalIds.removeWhere((id) => !allowedIds.contains(id));
      return;
    }
    selectedMilkShifts.clear();
  }

  bool _containsAny(String value, List<String> checks) {
    for (final check in checks) {
      if (value.contains(check)) return true;
    }
    return false;
  }

  Future<bool> createPan() async {
    final panName = panNameController.text.trim();
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_session_not_found'.tr);
      return false;
    }
    if (panName.isEmpty) {
      Get.snackbar('error'.tr, 'please_enter_pan_name'.tr);
      return false;
    }
    if (selectedAnimalIds.length < 2) {
      Get.snackbar('error'.tr, 'select_minimum_2_animals_for_pan'.tr);
      return false;
    }
    if (isMilkingPan && selectedMilkShifts.isEmpty) {
      Get.snackbar('error'.tr, 'please_select_milk_shifts_for_milking_pan'.tr);
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse(Api.animalPanCreate),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'farmer_id': farmerId,
          'name': panName,
          'animal_ids': selectedAnimalIds.toList(),
          'pan_type': selectedPanType.value,
          'milk_shifts': isMilkingPan ? selectedMilkShifts.toList() : <String>[],
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        panNameController.clear();
        selectedAnimalIds.clear();
        selectedPanType.value = panTypeMilking;
        selectedMilkShifts.assignAll(<String>['Morning', 'Afternoon', 'Evening']);
        await refreshAll();
        Get.snackbar('success'.tr, data['message']?.toString() ?? 'pan_created_successfully'.tr);
        return true;
      }

      Get.snackbar('error'.tr, data['message']?.toString() ?? 'failed_to_create_pan'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updatePan({
    required int panId,
    required String name,
    required List<int> animalIds,
    required String panType,
    required List<String> milkShifts,
  }) async {
    final panName = name.trim();
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_session_not_found'.tr);
      return false;
    }
    if (panName.isEmpty) {
      Get.snackbar('error'.tr, 'please_enter_pan_name'.tr);
      return false;
    }
    if (animalIds.length < 2) {
      Get.snackbar('error'.tr, 'select_minimum_2_animals_for_pan'.tr);
      return false;
    }
    if (panType == panTypeMilking && milkShifts.isEmpty) {
      Get.snackbar('error'.tr, 'please_select_milk_shifts_for_milking_pan'.tr);
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse('${Api.animalPanList}/$panId/update'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'farmer_id': farmerId,
          'name': panName,
          'animal_ids': animalIds,
          'pan_type': panType,
          'milk_shifts': milkShifts,
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        await refreshAll();
        Get.snackbar('success'.tr, data['message']?.toString() ?? 'pan_updated_successfully'.tr);
        return true;
      }

      Get.snackbar('error'.tr, data['message']?.toString() ?? 'failed_to_update_pan'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  List<PanGroupItem> _applyPanAnimalFallback(List<PanGroupItem> source) {
    if (animals.isEmpty) return source;
    final byPanId = <int, List<PanAnimalItem>>{};
    for (final animal in animals) {
      final panId = animal.panId;
      if (panId == null || panId <= 0) continue;
      byPanId.putIfAbsent(panId, () => <PanAnimalItem>[]).add(animal);
    }

    return source.map((pan) {
      final fallback = byPanId[pan.id] ?? const <PanAnimalItem>[];
      final shouldUseFallback =
          (pan.animals.isEmpty && pan.animalsCount > 0) ||
          (pan.animals.length < pan.animalsCount && fallback.isNotEmpty);
      if (!shouldUseFallback) return pan;
      return pan.copyWith(animals: fallback);
    }).toList();
  }

  List<PanGroupItem> _applyPanTypeAnimalRules(List<PanGroupItem> source) {
    return source.map((pan) {
      final allowedAnimals = pan.animals
          .where((animal) => animal.matchesPanType(pan.panType))
          .toList();
      if (allowedAnimals.length == pan.animals.length) {
        return pan;
      }
      return pan.copyWith(
        animals: allowedAnimals,
        animalsCount: allowedAnimals.length,
      );
    }).toList();
  }

  Future<bool> transferAnimalToPan({
    required int animalId,
    required int toPanId,
    int? animalTypeId,
  }) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_session_not_found'.tr);
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse(Api.animalPanTransfer),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'farmer_id': farmerId,
          'animal_id': animalId,
          'to_pan_id': toPanId,
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        if (animalTypeId != null && animalTypeId > 0) {
          final typeChanged = await _updateAnimalType(
            animalId: animalId,
            animalTypeId: animalTypeId,
          );
          if (!typeChanged) {
            await refreshAll();
            Get.snackbar(
              'info'.tr,
              'animal_transferred_but_type_not_updated'.tr,
            );
            return true;
          }
        }
        await refreshAll();
        Get.snackbar('success'.tr, data['message']?.toString() ?? 'animal_pan_transferred_successfully'.tr);
        return true;
      }

      Get.snackbar('error'.tr, data['message']?.toString() ?? 'failed_to_transfer_pan'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> _updateAnimalType({
    required int animalId,
    required int animalTypeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.animalLifecycle}/$animalId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action': 'move_type',
          'animal_type_id': animalTypeId.toString(),
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return response.statusCode == 200 && data['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePan(int panId) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_session_not_found'.tr);
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await http.post(
        Uri.parse('${Api.animalPanDelete}/$panId/delete'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'farmer_id': farmerId,
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        await refreshAll();
        Get.snackbar(
          'success'.tr,
          data['message']?.toString() ?? 'pan_deleted_successfully'.tr,
        );
        return true;
      }

      final message = data['message'];
      if (message is Map) {
        final first = message.values.isNotEmpty ? message.values.first : null;
        if (first is List && first.isNotEmpty) {
          Get.snackbar('error'.tr, first.first.toString());
          return false;
        }
      }
      Get.snackbar('error'.tr, message?.toString() ?? 'failed_to_delete_pan'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    panNameController.dispose();
    super.onClose();
  }
}

class PanAnimalItem {
  final int id;
  final String animalName;
  final String tagNumber;
  final String image;
  final String lifecycleStatus;
  final int? panId;
  final String panName;
  final int animalTypeId;
  final String animalTypeName;

  PanAnimalItem({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.image,
    required this.lifecycleStatus,
    required this.panId,
    required this.panName,
    required this.animalTypeId,
    required this.animalTypeName,
  });

  factory PanAnimalItem.fromJson(Map<String, dynamic> json) {
    return PanAnimalItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      lifecycleStatus: (json['lifecycle_status'] ?? 'active').toString(),
      panId: int.tryParse('${json['pan_id'] ?? ''}'),
      panName: (json['pan_name'] ?? '').toString(),
      animalTypeId: int.tryParse('${json['animal_type_id'] ?? 0}') ?? 0,
      animalTypeName: (json['animal_type_name'] ?? '').toString(),
    );
  }

  bool get isMilkingAnimal {
    final type = animalTypeName.trim().toLowerCase();
    final hasMilking = type.contains('milking') || type.contains('milk');
    final hasNonMilking = type.contains('non-milking') ||
        type.contains('non milking') ||
        type.contains('dry');
    return hasMilking && !hasNonMilking;
  }

  bool matchesPanType(String panType) {
    if (panType == PanManagementController.panTypeMilking) {
      return isMilkingAnimal;
    }
    if (panType == PanManagementController.panTypeNonMilking) {
      return !isMilkingAnimal;
    }
    return true;
  }
}

class PanAnimalTypeOption {
  final int id;
  final String name;

  const PanAnimalTypeOption({
    required this.id,
    required this.name,
  });

  factory PanAnimalTypeOption.fromJson(Map<String, dynamic> json) {
    return PanAnimalTypeOption(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class PanGroupItem {
  final int id;
  final String name;
  final int animalsCount;
  final List<String> milkShifts;
  final String panType;
  final List<PanAnimalItem> animals;

  PanGroupItem({
    required this.id,
    required this.name,
    required this.animalsCount,
    required this.milkShifts,
    required this.panType,
    required this.animals,
  });

  factory PanGroupItem.fromJson(Map<String, dynamic> json) {
    final rawAnimals = (json['animals'] as List?) ?? const [];
    final panType = (json['pan_type'] ?? PanManagementController.panTypeMilking)
        .toString()
        .trim()
        .toLowerCase();
    return PanGroupItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: (json['name'] ?? '').toString(),
      animalsCount: int.tryParse('${json['animals_count'] ?? 0}') ?? 0,
      milkShifts: _parseMilkShifts(
        json['milk_shifts'],
        panType: panType,
      ),
      panType: panType,
      animals: rawAnimals
          .whereType<Map>()
          .map((item) => PanAnimalItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  PanGroupItem copyWith({
    int? id,
    String? name,
    int? animalsCount,
    List<String>? milkShifts,
    String? panType,
    List<PanAnimalItem>? animals,
  }) {
    return PanGroupItem(
      id: id ?? this.id,
      name: name ?? this.name,
      animalsCount: animalsCount ?? this.animalsCount,
      milkShifts: milkShifts ?? this.milkShifts,
      panType: panType ?? this.panType,
      animals: animals ?? this.animals,
    );
  }

  static List<String> _parseMilkShifts(
    dynamic value, {
    required String panType,
  }) {
    const allowed = ['Morning', 'Afternoon', 'Evening'];
    if (panType == PanManagementController.panTypeNonMilking) {
      return <String>[];
    }
    if (value is! List) return allowed;
    final parsed = value.map((item) => item.toString().trim()).where((item) => allowed.contains(item)).toList();
    return parsed.isEmpty ? allowed : parsed;
  }
}
