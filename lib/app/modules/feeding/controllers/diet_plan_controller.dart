import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/api.dart';
import 'feeding_controller.dart';

class DietPlanController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isMetricsLoading = false.obs;
  final RxList<FeedingAnimalModel> animals = <FeedingAnimalModel>[].obs;
  final RxList<FeedingPanModel> pans = <FeedingPanModel>[].obs;
  final RxList<FeedTypeModel> feedTypes = <FeedTypeModel>[].obs;
  final Rxn<FeedingAnimalModel> selectedAnimal = Rxn<FeedingAnimalModel>();
  final Rxn<FeedingPanModel> selectedPan = Rxn<FeedingPanModel>();
  final RxList<DietFeedBlock> feedBlocks = <DietFeedBlock>[].obs;
  final RxList<FeedDietPlanModel> plans = <FeedDietPlanModel>[].obs;
  final TextEditingController dietPlanNameController = TextEditingController();
  final TextEditingController referenceDateController = TextEditingController();
  final FocusNode dietPlanNameFocus = FocusNode();
  final RxDouble bodyWeight = 0.0.obs;
  final RxDouble milkProduction = 0.0.obs;
  final RxDouble targetDmi = 0.0.obs;
  final RxDouble plannedDryMatter = 0.0.obs;
  final RxDouble dmiGap = 0.0.obs;

  int farmerId = 0;
  int _nextFeedBlockId = 1;

  List<FeedingAnimalModel> get animalsForSelection {
    final pan = selectedPan.value;
    if (pan == null) return animals;
    return animals.where((animal) => animal.belongsToPan(pan)).toList();
  }

  FeedingAnimalModel? _resolvedAnimalForPlan() {
    final direct = selectedAnimal.value;
    if (direct != null) return direct;

    final pan = selectedPan.value;
    if (pan == null) return null;

    for (final animal in animals) {
      if (animal.belongsToPan(pan)) {
        return animal;
      }
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    referenceDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    loadData();
  }

  Future<void> loadData() async {
    await _loadFarmerId();
    await Future.wait([fetchAnimals(), fetchFeedTypes(), fetchPlans()]);
    _ensureAtLeastOneFeedBlock();
    _refreshDmiSummary();
    await refreshDietMetrics();
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
      _rebuildPansFromAnimals();
      _syncSelectedAnimalAgainstPan();
    } catch (_) {
      animals.clear();
      pans.clear();
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
      _pruneFeedBlocksForAvailableTypes();
      _ensureAtLeastOneFeedBlock();
    } catch (_) {
      feedTypes.clear();
      _clearFeedBlocks();
      _ensureAtLeastOneFeedBlock();
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

  void onAnimalChanged(FeedingAnimalModel? value) {
    selectedAnimal.value = value;
    if (value != null) {
      selectedPan.value = null;
    }
    unawaited(refreshDietMetrics());
  }

  void onPanChanged(FeedingPanModel? value) {
    selectedPan.value = value;
    if (value != null) {
      selectedAnimal.value = null;
    } else {
      _syncSelectedAnimalAgainstPan();
    }
    unawaited(refreshDietMetrics());
  }

  void _syncSelectedAnimalAgainstPan() {
    // Always remap selected values to the current list instances so dropdowns
    // don't hold stale object references after API refresh.
    final currentAnimal = selectedAnimal.value;
    if (currentAnimal != null) {
      FeedingAnimalModel? matchedAnimal;
      for (final animal in animals) {
        if (animal.id == currentAnimal.id) {
          matchedAnimal = animal;
          break;
        }
      }
      selectedAnimal.value = matchedAnimal;
    }

    final currentPan = selectedPan.value;
    if (currentPan != null) {
      FeedingPanModel? matchedPan;
      for (final pan in pans) {
        if (pan.matches(currentPan)) {
          matchedPan = pan;
          break;
        }
      }
      selectedPan.value = matchedPan;
    }

    final animal = selectedAnimal.value;
    final pan = selectedPan.value;
    if (animal == null || pan == null) return;
    if (!animal.belongsToPan(pan)) {
      selectedAnimal.value = null;
    }
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

  void _ensureAtLeastOneFeedBlock() {
    if (feedBlocks.isNotEmpty) return;
    feedBlocks.add(DietFeedBlock(id: _nextFeedBlockId++));
  }

  void addFeedBlock() {
    final selectedTypeIds = feedBlocks
        .map((block) => block.selectedFeedType?.id)
        .whereType<int>()
        .toSet();
    if (feedTypes.isEmpty || selectedTypeIds.length >= feedTypes.length) {
      Get.snackbar('error'.tr, 'no_more_feed_types_available'.tr);
      return;
    }
    feedBlocks.add(DietFeedBlock(id: _nextFeedBlockId++));
    feedBlocks.refresh();
    _refreshDmiSummary();
  }

  void removeFeedBlock(DietFeedBlock block) {
    if (feedBlocks.length <= 1) {
      block.configureForFeedType(null, _onFeedBlockChanged);
      feedBlocks.refresh();
      return;
    }
    block.dispose();
    feedBlocks.remove(block);
    feedBlocks.refresh();
    _refreshDmiSummary();
  }

  List<FeedTypeModel> availableFeedTypesForBlock(DietFeedBlock block) {
    final blockedIds = feedBlocks
        .where((item) => item.id != block.id)
        .map((item) => item.selectedFeedType?.id)
        .whereType<int>()
        .toSet();
    return feedTypes.where((type) {
      if (block.selectedFeedType?.id == type.id) return true;
      return !blockedIds.contains(type.id);
    }).toList();
  }

  void onFeedTypeChangedForBlock(DietFeedBlock block, FeedTypeModel? value) {
    block.configureForFeedType(value, _onFeedBlockChanged);
    _pruneDuplicateSelectionsKeepingBlock(block);
    feedBlocks.refresh();
    _refreshDmiSummary();
  }

  void onSubtypeToggleForBlock(DietFeedBlock block, int subtypeId, bool checked) {
    block.setSubtypeSelected(subtypeId, checked);
    feedBlocks.refresh();
    _refreshDmiSummary();
  }

  void _onFeedBlockChanged() {
    feedBlocks.refresh();
    _refreshDmiSummary();
  }

  void _pruneDuplicateSelectionsKeepingBlock(DietFeedBlock anchor) {
    final anchorTypeId = anchor.selectedFeedType?.id;
    if (anchorTypeId == null) return;
    for (final block in feedBlocks) {
      if (block.id == anchor.id) continue;
      if (block.selectedFeedType?.id == anchorTypeId) {
        block.configureForFeedType(null, _onFeedBlockChanged);
      }
    }
  }

  void _pruneFeedBlocksForAvailableTypes() {
    final availableIds = feedTypes.map((item) => item.id).toSet();
    for (final block in feedBlocks) {
      final selectedId = block.selectedFeedType?.id;
      if (selectedId != null && !availableIds.contains(selectedId)) {
        block.configureForFeedType(null, _onFeedBlockChanged);
      }
    }
    feedBlocks.refresh();
    _refreshDmiSummary();
  }

  double get plannedDryMatterTotal => plannedDryMatter.value;

  void _refreshDmiSummary() {
    double totalDryMatter = 0;
    for (final block in feedBlocks) {
      totalDryMatter += block.totalDryMatter;
    }
    plannedDryMatter.value = double.parse(totalDryMatter.toStringAsFixed(2));
    dmiGap.value = double.parse((plannedDryMatter.value - targetDmi.value).toStringAsFixed(2));
  }

  Future<void> pickReferenceDate() async {
    final today = DateTime.now();
    DateTime initialDate = today;
    final current = _selectedReferenceDate();
    if (current != null && !current.isAfter(today)) {
      initialDate = current;
    }

    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Select reference date',
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
    if (picked == null) return;
    referenceDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    await refreshDietMetrics();
  }

  DateTime? _selectedReferenceDate() {
    final text = referenceDateController.text.trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      return null;
    }
  }

  String get selectedReferenceDateApi {
    final parsed = _selectedReferenceDate() ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  Future<void> refreshDietMetrics() async {
    final resolvedAnimal = _resolvedAnimalForPlan();
    if (farmerId == 0 || resolvedAnimal == null) {
      bodyWeight.value = 0;
      milkProduction.value = 0;
      targetDmi.value = 0;
      _refreshDmiSummary();
      return;
    }

    try {
      isMetricsLoading.value = true;
      final params = <String, String>{
        'farmer_id': farmerId.toString(),
        'animal_id': resolvedAnimal.id.toString(),
        'date': selectedReferenceDateApi,
      };
      final pan = selectedPan.value;
      if (pan != null && pan.id > 0) {
        params['pan_id'] = pan.id.toString();
      }

      final uri = Uri.parse(Api.feedingDietMetrics).replace(queryParameters: params);
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final payload = data['data'] as Map? ?? {};
        bodyWeight.value = double.tryParse((payload['body_weight'] ?? '0').toString()) ?? 0;
        milkProduction.value = double.tryParse((payload['milk_production'] ?? '0').toString()) ?? 0;
        targetDmi.value = double.tryParse((payload['target_dmi'] ?? '0').toString()) ?? 0;
      } else {
        bodyWeight.value = 0;
        milkProduction.value = 0;
        targetDmi.value = 0;
      }
    } catch (_) {
      bodyWeight.value = 0;
      milkProduction.value = 0;
      targetDmi.value = 0;
    } finally {
      isMetricsLoading.value = false;
      _refreshDmiSummary();
    }
  }

  Future<void> savePlan() async {
    if (!formKey.currentState!.validate()) return;
    final resolvedAnimal = _resolvedAnimalForPlan();
    if (resolvedAnimal == null) {
      Get.snackbar('error'.tr, 'please_select_animal_or_pan'.tr);
      return;
    }
    if (dietPlanNameController.text.trim().isEmpty) {
      dietPlanNameFocus.requestFocus();
      Get.snackbar('error'.tr, 'Diet plan name is required');
      return;
    }

    final pan = selectedPan.value;
    if (pan != null && !resolvedAnimal.belongsToPan(pan)) {
      Get.snackbar('error'.tr, 'pan_not_match_animal'.tr);
      return;
    }

    final blocks = feedBlocks.toList();
    for (final block in blocks) {
      if (block.selectedFeedType == null) {
        Get.snackbar('error'.tr, 'please_select_feed_type_for_all'.tr);
        return;
      }
      final subtypeValidationMessage = block.validateSelectedSubtypeInputs();
      if (subtypeValidationMessage != null) {
        final feedName = block.selectedFeedType?.name ?? '-';
        Get.snackbar(
          'error'.tr,
          '$feedName: $subtypeValidationMessage',
        );
        return;
      }
      if (block.selectedSubtypePayload().isEmpty) {
        final feedName = block.selectedFeedType?.name ?? '-';
        Get.snackbar('error'.tr, 'please_add_subtype_for_feed'.trParams({'feed': feedName}));
        return;
      }
    }

    try {
      isSaving.value = true;
      final combinedSubtypePayload = <Map<String, dynamic>>[];
      for (final block in blocks) {
        final selectedType = block.selectedFeedType;
        if (selectedType == null) continue;
        final subtypes = block.selectedSubtypePayload();
        for (final subtype in subtypes) {
          combinedSubtypePayload.add({
            'feed_type_id': selectedType.id,
            'feed_type_name': selectedType.name,
            'feed_unit': block.unit,
            ...subtype,
          });
        }
      }

      if (combinedSubtypePayload.isEmpty) {
        Get.snackbar('error'.tr, 'please_add_subtype_for_feed'.trParams({'feed': '-'}));
        return;
      }

      final primaryType = blocks.firstWhere(
        (block) => block.selectedFeedType != null,
        orElse: () => blocks.first,
      ).selectedFeedType;
      if (primaryType == null) {
        Get.snackbar('error'.tr, 'please_select_feed_type_for_all'.tr);
        return;
      }

      final response = await http.post(
        Uri.parse(Api.feedingDietPlans),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_id': farmerId.toString(),
          'animal_id': resolvedAnimal.id.toString(),
          if (selectedPan.value != null && selectedPan.value!.id > 0)
            'pan_id': selectedPan.value!.id.toString(),
          'reference_date': selectedReferenceDateApi,
          'diet_plan_name': dietPlanNameController.text.trim(),
          // Keep compatibility with existing backend schema while sending
          // merged subtype payload for one-plan creation.
          'feed_type_id': primaryType.id.toString(),
          'unit': primaryType.defaultUnit,
          'subtype_details': combinedSubtypePayload,
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPlans();
        _clearForm();
        final message = data is Map ? data['message']?.toString() : null;
        Get.snackbar('success'.tr, (message != null && message.trim().isNotEmpty) ? message.trim() : 'diet_plan_saved'.tr);
        return;
      }

      Get.snackbar('error'.tr, _extractApiMessage(data) ?? 'unable_save_diet_plan'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updatePlan({
    required int planId,
    int? daysCount,
    int? panId,
    String? referenceDate,
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
      if (panId != null && panId > 0) {
        payload['pan_id'] = panId.toString();
      }
      if (referenceDate != null && referenceDate.trim().isNotEmpty) {
        payload['reference_date'] = referenceDate.trim();
      }
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
    selectedPan.value = null;
    dietPlanNameController.clear();
    referenceDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    bodyWeight.value = 0;
    milkProduction.value = 0;
    targetDmi.value = 0;
    plannedDryMatter.value = 0;
    dmiGap.value = 0;
    _clearFeedBlocks();
    _ensureAtLeastOneFeedBlock();
    feedBlocks.refresh();
  }

  void _clearFeedBlocks() {
    for (final block in feedBlocks) {
      block.dispose();
    }
    feedBlocks.clear();
  }

  @override
  void onClose() {
    dietPlanNameController.dispose();
    referenceDateController.dispose();
    dietPlanNameFocus.dispose();
    _clearFeedBlocks();
    super.onClose();
  }
}

class DietFeedBlock {
  DietFeedBlock({required this.id});

  final int id;
  FeedTypeModel? selectedFeedType;
  String unit = 'Kg';
  final Map<int, bool> subtypeSelected = <int, bool>{};
  final Map<int, TextEditingController> subtypeQtyControllers = <int, TextEditingController>{};
  final Map<int, TextEditingController> subtypeDmPercentControllers = <int, TextEditingController>{};
  VoidCallback? _listener;

  double get totalQuantity {
    double total = 0;
    subtypeSelected.forEach((subtypeId, selected) {
      if (!selected) return;
      total += double.tryParse(subtypeQtyControllers[subtypeId]?.text.trim() ?? '') ?? 0;
    });
    return total;
  }

  double get totalDryMatter {
    double total = 0;
    subtypeSelected.forEach((subtypeId, selected) {
      if (!selected) return;
      final qty = double.tryParse(subtypeQtyControllers[subtypeId]?.text.trim() ?? '') ?? 0;
      final dmPercent = double.tryParse(subtypeDmPercentControllers[subtypeId]?.text.trim() ?? '') ?? 0;
      if (qty > 0 && dmPercent > 0 && dmPercent <= 100) {
        total += (qty * dmPercent) / 100;
      }
    });
    return total;
  }

  void configureForFeedType(FeedTypeModel? value, VoidCallback onChanged) {
    _disposeSubtypeControllers();
    selectedFeedType = value;
    unit = value?.defaultUnit ?? 'Kg';
    _listener = onChanged;

    if (value == null) return;

    for (final subtype in value.subtypes) {
      subtypeSelected[subtype.id] = false;
      final ctrl = TextEditingController();
      final dmCtrl = TextEditingController();
      ctrl.addListener(onChanged);
      dmCtrl.addListener(onChanged);
      subtypeQtyControllers[subtype.id] = ctrl;
      subtypeDmPercentControllers[subtype.id] = dmCtrl;
    }
  }

  void setSubtypeSelected(int subtypeId, bool selected) {
    subtypeSelected[subtypeId] = selected;
    if (!selected) {
      subtypeQtyControllers[subtypeId]?.clear();
      subtypeDmPercentControllers[subtypeId]?.clear();
    }
  }

  String? validateSelectedSubtypeInputs() {
    bool hasSelected = false;
    subtypeSelected.forEach((subtypeId, selected) {
      if (selected) {
        hasSelected = true;
      }
    });
    if (!hasSelected) {
      return 'Please select at least one subtype.';
    }

    for (final entry in subtypeSelected.entries) {
      if (!entry.value) continue;
      final qty = double.tryParse(subtypeQtyControllers[entry.key]?.text.trim() ?? '') ?? 0;
      if (qty <= 0) {
        return 'Enter valid subtype quantity.';
      }
      final dmPercent = double.tryParse(subtypeDmPercentControllers[entry.key]?.text.trim() ?? '') ?? -1;
      if (dmPercent <= 0 || dmPercent > 100) {
        return 'Enter DM% between 0 and 100.';
      }
    }
    return null;
  }

  List<Map<String, dynamic>> selectedSubtypePayload() {
    final type = selectedFeedType;
    if (type == null) return <Map<String, dynamic>>[];
    final payload = <Map<String, dynamic>>[];
    for (final subtype in type.subtypes) {
      if (!(subtypeSelected[subtype.id] ?? false)) continue;
      final qty = double.tryParse(subtypeQtyControllers[subtype.id]?.text.trim() ?? '') ?? 0;
      final dmPercent = double.tryParse(subtypeDmPercentControllers[subtype.id]?.text.trim() ?? '') ?? 0;
      if (qty <= 0 || dmPercent <= 0 || dmPercent > 100) continue;
      payload.add({
        'subtype_id': subtype.id,
        'name': subtype.name,
        'quantity': qty,
        'dm_percent': dmPercent,
      });
    }
    return payload;
  }

  void _disposeSubtypeControllers() {
    for (final ctrl in subtypeQtyControllers.values) {
      if (_listener != null) {
        ctrl.removeListener(_listener!);
      }
      ctrl.dispose();
    }
    for (final ctrl in subtypeDmPercentControllers.values) {
      if (_listener != null) {
        ctrl.removeListener(_listener!);
      }
      ctrl.dispose();
    }
    subtypeQtyControllers.clear();
    subtypeDmPercentControllers.clear();
    subtypeSelected.clear();
  }

  void dispose() {
    _disposeSubtypeControllers();
    _listener = null;
  }
}
