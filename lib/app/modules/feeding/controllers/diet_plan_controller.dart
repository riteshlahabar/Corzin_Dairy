import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';
import 'feeding_controller.dart';

class DietPlanController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxList<FeedingAnimalModel> animals = <FeedingAnimalModel>[].obs;
  final RxList<FeedTypeModel> feedTypes = <FeedTypeModel>[].obs;
  final Rxn<FeedingAnimalModel> selectedAnimal = Rxn<FeedingAnimalModel>();
  final Rxn<FeedTypeModel> selectedFeedType = Rxn<FeedTypeModel>();
  final RxList<FeedDietPlanModel> plans = <FeedDietPlanModel>[].obs;
  final TextEditingController dietPlanNameController = TextEditingController();
  final FocusNode dietPlanNameFocus = FocusNode();

  final RxMap<int, bool> subtypeSelected = <int, bool>{}.obs;
  final Map<int, TextEditingController> subtypeQtyControllers = {};
  final RxDouble totalQuantity = 0.0.obs;
  final RxString unit = 'Kg'.obs;
  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await _loadFarmerId();
    await Future.wait([fetchAnimals(), fetchFeedTypes(), fetchPlans()]);
  }

  Future<void> _loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animals.assignAll(list.map((item) => FeedingAnimalModel.fromJson(item)).toList());
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFeedTypes() async {
    if (farmerId == 0) return;
    try {
      final response = await http.get(
        Uri.parse('${Api.feedingTypes}?farmer_id=$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        feedTypes.assignAll(list.map((item) => FeedTypeModel.fromJson(item)).toList());
      } else {
        feedTypes.clear();
      }
    } catch (_) {
      feedTypes.clear();
    }
  }

  Future<void> fetchPlans() async {
    if (farmerId == 0) return;
    try {
      final response = await http.get(
        Uri.parse('${Api.feedingDietPlans}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        plans.assignAll(list.map((item) => FeedDietPlanModel.fromJson(item)).toList());
      } else {
        plans.clear();
      }
    } catch (_) {
      plans.clear();
    }
  }

  void onFeedTypeChanged(FeedTypeModel? value) {
    selectedFeedType.value = value;
    _clearSubtypeFields();
    if (value == null) {
      unit.value = 'Kg';
      totalQuantity.value = 0;
      return;
    }
    unit.value = value.defaultUnit;
    for (final subtype in value.subtypes) {
      subtypeSelected[subtype.id] = false;
      final ctrl = TextEditingController();
      ctrl.addListener(_recalculateTotal);
      subtypeQtyControllers[subtype.id] = ctrl;
    }
    _recalculateTotal();
  }

  void onSubtypeToggle(int subtypeId, bool checked) {
    subtypeSelected[subtypeId] = checked;
    if (!checked) {
      subtypeQtyControllers[subtypeId]?.clear();
    }
    _recalculateTotal();
  }

  void _recalculateTotal() {
    double total = 0;
    subtypeSelected.forEach((subtypeId, selected) {
      if (!selected) return;
      total += double.tryParse(subtypeQtyControllers[subtypeId]?.text.trim() ?? '') ?? 0;
    });
    totalQuantity.value = total;
  }

  List<Map<String, dynamic>> _selectedSubtypePayload() {
    final type = selectedFeedType.value;
    if (type == null) return <Map<String, dynamic>>[];
    final payload = <Map<String, dynamic>>[];
    for (final subtype in type.subtypes) {
      if (!(subtypeSelected[subtype.id] ?? false)) continue;
      final qty = double.tryParse(subtypeQtyControllers[subtype.id]?.text.trim() ?? '') ?? 0;
      if (qty <= 0) continue;
      payload.add({
        'subtype_id': subtype.id,
        'name': subtype.name,
        'quantity': qty,
      });
    }
    return payload;
  }

  Future<void> savePlan() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedAnimal.value == null) {
      Get.snackbar('error'.tr, 'please_select_animal_for_diet'.tr);
      return;
    }
    if (selectedFeedType.value == null) {
      Get.snackbar('error'.tr, 'select_feed_type_error'.tr);
      return;
    }
    if (dietPlanNameController.text.trim().isEmpty) {
      dietPlanNameFocus.requestFocus();
      Get.snackbar('error'.tr, 'Diet plan name is required');
      return;
    }
    final subtypes = _selectedSubtypePayload();
    if (subtypes.isEmpty) {
      Get.snackbar('error'.tr, 'please_add_subtype_quantity'.tr);
      return;
    }
    try {
      isSaving.value = true;
      final response = await http.post(
        Uri.parse(Api.feedingDietPlans),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_id': farmerId.toString(),
          'animal_id': selectedAnimal.value!.id.toString(),
          'diet_plan_name': dietPlanNameController.text.trim(),
          'feed_type_id': selectedFeedType.value!.id.toString(),
          'unit': unit.value,
          'subtype_details': subtypes,
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPlans();
        _clearForm();
        Get.snackbar('success'.tr, data['message']?.toString() ?? 'diet_plan_saved'.tr);
      } else {
        Get.snackbar('error'.tr, _extractApiMessage(data) ?? 'unable_save_diet_plan'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updatePlan({
    required int planId,
    int? daysCount,
    required List<Map<String, dynamic>> subtypeDetails,
  }) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return false;
    }
    if (planId <= 0 || subtypeDetails.isEmpty) {
      Get.snackbar('error'.tr, 'invalid_diet_plan_update_payload'.tr);
      return false;
    }
    try {
      isSaving.value = true;
      final uri = Uri.parse('${Api.feedingDietPlanUpdate}/$planId/update');
      final payload = <String, dynamic>{
        'farmer_id': farmerId.toString(),
        'subtype_details': subtypeDetails,
      };
      if (daysCount != null && daysCount > 0) {
        payload['days_count'] = daysCount.toString();
      }
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPlans();
        return true;
      }
      Get.snackbar('error'.tr, _extractApiMessage(data) ?? 'unable_update_diet_plan'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deletePlan({required int planId}) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return false;
    }
    if (planId <= 0) {
      Get.snackbar('error'.tr, 'invalid_diet_plan_id'.tr);
      return false;
    }
    try {
      isSaving.value = true;
      final uri = Uri.parse('${Api.feedingDietPlanDelete}/$planId/delete');
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_id': farmerId.toString(),
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPlans();
        return true;
      }
      Get.snackbar('error'.tr, _extractApiMessage(data) ?? 'unable_delete_diet_plan'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  String? _extractApiMessage(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    if (message is Map) {
      final values = message.values.toList();
      if (values.isNotEmpty) {
        final first = values.first;
        if (first is List && first.isNotEmpty) return first.first?.toString();
        return first?.toString();
      }
    }
    return null;
  }

  void _clearForm() {
    selectedAnimal.value = null;
    selectedFeedType.value = null;
    dietPlanNameController.clear();
    unit.value = 'Kg';
    _clearSubtypeFields();
    totalQuantity.value = 0;
  }

  void _clearSubtypeFields() {
    for (final ctrl in subtypeQtyControllers.values) {
      ctrl.removeListener(_recalculateTotal);
      ctrl.dispose();
    }
    subtypeQtyControllers.clear();
    subtypeSelected.clear();
  }

  @override
  void onClose() {
    dietPlanNameController.dispose();
    dietPlanNameFocus.dispose();
    _clearSubtypeFields();
    super.onClose();
  }
}
