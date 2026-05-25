import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/api.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../routes/app_pages.dart';

class FeedingController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController ratePerUnitController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final FocusNode quantityFocus = FocusNode();
  final FocusNode ratePerUnitFocus = FocusNode();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isScheduleLoading = false.obs;

  final RxList<FeedingAnimalModel> animals = <FeedingAnimalModel>[].obs;
  final RxList<FeedingPanModel> pans = <FeedingPanModel>[].obs;
  final RxList<FeedTypeModel> feedTypes = <FeedTypeModel>[].obs;
  final RxList<FeedDietPlanModel> dietPlans = <FeedDietPlanModel>[].obs;
  final Rxn<FeedingAnimalModel> selectedAnimal = Rxn<FeedingAnimalModel>();
  final Rxn<FeedingPanModel> selectedPan = Rxn<FeedingPanModel>();
  final Rxn<FeedTypeModel> selectedFeedType = Rxn<FeedTypeModel>();
  final Rxn<FeedDietPlanModel> selectedDietPlan = Rxn<FeedDietPlanModel>();
  final RxnInt selectedDietPlanId = RxnInt();
  final RxString selectedUnit = 'Kg'.obs;
  final RxString selectedFeedingTime = 'Morning'.obs;
  final RxList<String> availableFeedingTimes = <String>['Morning'].obs;
  final RxDouble packageQuantity = 0.0.obs;
  final RxDouble totalSubtypeQuantity = 0.0.obs;
  final RxDouble balanceQuantity = 0.0.obs;
  final RxDouble feedingCost = 0.0.obs;
  final RxInt dietPlanDays = 0.obs;
  final RxInt dietPlanDaysRemaining = 0.obs;

  final RxMap<int, bool> subtypeSelected = <int, bool>{}.obs;
  final Map<int, TextEditingController> subtypeQuantityControllers = {};

  int farmerId = 0;
  List<Map<String, dynamic>> _feedingRows = <Map<String, dynamic>>[];
  static const List<String> _allFeedingTimes = <String>['Morning', 'Afternoon', 'Evening'];

  @override
  void onInit() {
    super.onInit();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    quantityController.addListener(_recalculateBalance);
    quantityController.addListener(_recalculateFeedingCost);
    ratePerUnitController.addListener(_recalculateFeedingCost);
    initData();
  }

  Future<void> initData() async {
    await loadFarmerId();
    await Future.wait([
      fetchAnimals(),
      fetchFeedTypes(),
      fetchDietPlans(),
      refreshAutoSchedule(),
    ]);
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
        updateAvailableFeedingTimes();
        await fetchDietPlans();
      } else {
        animals.clear();
        pans.clear();
        selectedPan.value = null;
        updateAvailableFeedingTimes();
        dietPlans.clear();
        selectedDietPlan.value = null;
        selectedDietPlanId.value = null;
      }
    } catch (_) {
      animals.clear();
      pans.clear();
      selectedPan.value = null;
      updateAvailableFeedingTimes();
      dietPlans.clear();
      selectedDietPlan.value = null;
      selectedDietPlanId.value = null;
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
        if (selectedFeedType.value != null &&
            feedTypes.any((type) => type.id == selectedFeedType.value!.id)) {
          onFeedTypeChanged(selectedFeedType.value);
        } else {
          onFeedTypeChanged(null);
        }
        await fetchDietPlans();
      } else {
        feedTypes.clear();
        _clearSubtypeInputs();
        dietPlans.clear();
        selectedDietPlan.value = null;
        selectedDietPlanId.value = null;
      }
    } catch (_) {
      feedTypes.clear();
      _clearSubtypeInputs();
      dietPlans.clear();
      selectedDietPlan.value = null;
      selectedDietPlanId.value = null;
    }
  }

  Future<void> fetchDietPlans() async {
    if (farmerId == 0) return;

    final query = <String, String>{};
    if (selectedAnimal.value != null) {
      query['animal_id'] = selectedAnimal.value!.id.toString();
    } else if (selectedPan.value != null && selectedPan.value!.id > 0) {
      query['pan_id'] = selectedPan.value!.id.toString();
    }
    if (selectedFeedType.value != null) {
      query['feed_type_id'] = selectedFeedType.value!.id.toString();
    }

    try {
      final uri = Uri.parse('${Api.feedingDietPlans}/$farmerId')
          .replace(queryParameters: query.isEmpty ? null : query);
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        final parsed = list.map((item) => FeedDietPlanModel.fromJson(item)).toList();
        final uniqueById = <int, FeedDietPlanModel>{};
        for (final plan in parsed) {
          if (plan.id <= 0) continue;
          uniqueById[plan.id] = plan;
        }
        dietPlans.assignAll(uniqueById.values.toList());
      } else {
        dietPlans.clear();
      }
    } catch (_) {
      dietPlans.clear();
    }

    final current = selectedDietPlan.value;
    if (current != null) {
      final matched = dietPlans.firstWhereOrNull((plan) => plan.id == current.id);
      if (matched == null) {
        selectedDietPlan.value = null;
        selectedDietPlanId.value = null;
        dietPlanDays.value = 0;
        dietPlanDaysRemaining.value = 0;
      } else {
        selectedDietPlan.value = matched;
        selectedDietPlanId.value = matched.id;
      }
    } else if (selectedDietPlanId.value != null) {
      final matched = dietPlans.firstWhereOrNull(
        (plan) => plan.id == selectedDietPlanId.value,
      );
      if (matched == null) {
        selectedDietPlanId.value = null;
        dietPlanDays.value = 0;
        dietPlanDaysRemaining.value = 0;
      } else {
        selectedDietPlan.value = matched;
        selectedDietPlanId.value = matched.id;
      }
    }
  }

  Future<void> pickDate() async {
    final today = DateTime.now();
    final current = _selectedFeedingDate() ?? today;
    final initialDate = current.isAfter(today) ? today : current;
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Select feeding date',
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

    dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    updateAvailableFeedingTimes();
  }

  void selectAnimal(FeedingAnimalModel? value) {
    selectedAnimal.value = value;
    if (value != null) {
      selectedPan.value = null;
    }
    selectedDietPlan.value = null;
    selectedDietPlanId.value = null;
    dietPlanDays.value = 0;
    dietPlanDaysRemaining.value = 0;
    updateAvailableFeedingTimes();
    unawaited(fetchDietPlans());
  }

  void selectPan(FeedingPanModel? value) {
    selectedPan.value = value;
    if (value != null) {
      selectedAnimal.value = null;
    }
    selectedDietPlan.value = null;
    selectedDietPlanId.value = null;
    dietPlanDays.value = 0;
    dietPlanDaysRemaining.value = 0;
    updateAvailableFeedingTimes();
    unawaited(fetchDietPlans());
  }

  void selectDietPlan(FeedDietPlanModel? value) {
    selectedDietPlan.value = value;
    selectedDietPlanId.value = value?.id;
    dietPlanDays.value = value?.daysCount ?? 0;
    dietPlanDaysRemaining.value = value?.daysRemaining ?? 0;
    if (value == null) {
      return;
    }
    final matchedType = feedTypes.firstWhereOrNull(
      (item) => item.id == value.feedTypeId,
    );
    if (matchedType != null) {
      if (selectedFeedType.value?.id != matchedType.id) {
        onFeedTypeChanged(matchedType, clearSelectedDietPlan: false);
      } else {
        selectedUnit.value = value.unit;
      }
    }
    selectedUnit.value = value.unit;
    _applyDietPlanToSubtypeInputs(value);
  }

  void selectDietPlanById(int? planId) {
    if (planId == null) {
      selectDietPlan(null);
      return;
    }
    final plan = dietPlans.firstWhereOrNull((item) => item.id == planId);
    selectDietPlan(plan);
  }

  void _applyDietPlanToSubtypeInputs(FeedDietPlanModel plan) {
    final currentType = selectedFeedType.value;
    if (currentType == null) return;

    final byId = <int, FeedSubtypeModel>{
      for (final subtype in currentType.subtypes) subtype.id: subtype,
    };
    final byName = <String, FeedSubtypeModel>{
      for (final subtype in currentType.subtypes) subtype.name.trim().toLowerCase(): subtype,
    };

    for (final subtype in currentType.subtypes) {
      subtypeSelected[subtype.id] = false;
      subtypeQuantityControllers[subtype.id]?.clear();
    }

    for (final detail in plan.subtypeDetails) {
      FeedSubtypeModel? target;
      if (detail.subtypeId > 0) {
        target = byId[detail.subtypeId];
      }
      target ??= byName[detail.name.trim().toLowerCase()];
      if (target == null) continue;
      subtypeSelected[target.id] = true;
      subtypeQuantityControllers[target.id]?.text = detail.quantity.toStringAsFixed(2);
    }

    // In Add Feeding, package quantity should reflect current remaining balance
    // from selected diet plan (not original total planned quantity).
    packageQuantity.value = plan.remainingQuantity;
    totalSubtypeQuantity.value = plan.remainingQuantity;
    balanceQuantity.value = plan.remainingQuantity;
    _recalculateBalance();
  }

  Future<void> submitFeeding() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedAnimal.value == null && selectedPan.value == null) {
      Get.snackbar('Error', 'Please select an animal or PAN');
      return;
    }
    final effectiveFeedType = _effectiveFeedType();
    if (effectiveFeedType == null) {
      Get.snackbar('Error', 'No feed type found for selected diet plan');
      return;
    }
    if (selectedDietPlan.value == null && selectedDietPlanId.value != null) {
      selectDietPlanById(selectedDietPlanId.value);
    }
    if (dietPlans.isNotEmpty && selectedDietPlan.value == null) {
      Get.snackbar('Error', 'Please select diet plan for selected animal/PAN.');
      return;
    }
    if (selectedFeedingTime.value.trim().isEmpty || !availableFeedingTimes.contains(selectedFeedingTime.value)) {
      Get.snackbar('Info', 'No feeding time is available for selected date.');
      return;
    }

    final feedingQty = double.tryParse(quantityController.text.trim()) ?? 0;
    if (feedingQty <= 0) {
      Get.snackbar('Error', 'Please enter feeding quantity');
      return;
    }
    final rateText = ratePerUnitController.text.trim();
    if (rateText.isEmpty) {
      Get.snackbar('Error', 'Please enter rate per unit');
      return;
    }
    final ratePerUnit = double.tryParse(rateText) ?? -1;
    if (ratePerUnit < 0) {
      Get.snackbar('Error', 'Please enter a valid rate per unit');
      return;
    }
    final calculatedFeedingCost = feedingQty * ratePerUnit;

    final plan = selectedDietPlan.value;
    if (plan != null) {
      final availableQty = packageQuantity.value;
      if (availableQty <= 0.000001) {
        Get.snackbar(
          'Error',
          'No balance package quantity is left. Please update this diet plan or create a new diet plan.',
        );
        return;
      }
      if ((feedingQty - availableQty) > 0.000001) {
        Get.snackbar(
          'Error',
          'Feeding quantity cannot be greater than balance package quantity. Please update this diet plan or create a new diet plan.',
        );
        return;
      }
    }

    final subtypePayload = _dietSubtypePayload();
    if (subtypePayload.isEmpty) {
      Get.snackbar('Error', 'Selected diet plan has no subtype quantity');
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
        ratePerUnitForAll: ratePerUnit,
        includeDietPlanId: true,
      );
      final successCount = result['success'] ?? 0;
      final failedCount = result['failed'] ?? 0;

      if (successCount > 0 && failedCount == 0) {
        final successMessage = 'Feeding entry saved successfully for $successCount animals in ${pan.name}';
        await refreshAutoSchedule();
        clearForm();
        _goToHomeAfterSave();
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
        'feed_type_id': effectiveFeedType.id.toString(),
        if (selectedDietPlan.value != null)
          'diet_plan_id': selectedDietPlan.value!.id.toString(),
        'feed_type': effectiveFeedType.name,
        'quantity': quantityController.text.trim(),
        'package_quantity': packageQuantity.value.toStringAsFixed(2),
        'feeding_quantity': quantityController.text.trim(),
        'balance_quantity': balanceQuantity.value.toStringAsFixed(2),
        'rate_per_unit': ratePerUnit.toStringAsFixed(2),
        'feeding_cost': calculatedFeedingCost.toStringAsFixed(2),
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
        _goToHomeAfterSave();
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
    double? ratePerUnitForAll,
    List<Map<String, dynamic>>? subtypePayloadPerAnimal,
    bool includeDietPlanId = true,
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
    final effectiveFeedType = _effectiveFeedType();
    if (effectiveFeedType == null) {
      Get.snackbar(
        'Error',
        'No feed type found for selected diet plan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return {'success': 0, 'failed': 0};
    }

    final subtypePayload = subtypePayloadPerAnimal ?? _dietSubtypePayload();
    if (subtypePayload.isEmpty) {
      Get.snackbar(
        'Error',
        'Selected diet plan has no subtype quantity.',
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
    final parsedRate = double.tryParse(ratePerUnitController.text.trim());
    final effectiveRatePerUnit = ratePerUnitForAll ?? (parsedRate ?? 0);

    for (final entry in entries) {
      try {
        final feedingQty = double.tryParse(entry.value) ?? 0;
        final payload = {
          'farmer_id': farmerId.toString(),
          'animal_id': entry.key.toString(),
          'feed_type_id': effectiveFeedType.id.toString(),
          if (includeDietPlanId && selectedDietPlan.value != null)
            'diet_plan_id': selectedDietPlan.value!.id.toString(),
          'feed_type': effectiveFeedType.name,
          'quantity': entry.value,
          'package_quantity':
              (packageQuantityPerAnimal ?? packageQuantity.value).toStringAsFixed(2),
          'feeding_quantity': entry.value,
          'balance_quantity':
              (balanceQuantityPerAnimal ?? balanceQuantity.value).toStringAsFixed(2),
          'rate_per_unit': effectiveRatePerUnit.toStringAsFixed(2),
          'feeding_cost': (feedingQty * effectiveRatePerUnit).toStringAsFixed(2),
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

  void _goToHomeAfterSave() {
    if (Get.isRegistered<BottomNavController>()) {
      final nav = Get.find<BottomNavController>();
      nav.activeDrawerPage.value = null;
      nav.changeTab(0);
      nav.resetTabHistory();
      nav.runSilentSyncNow();
      return;
    }
    Get.offAllNamed(Routes.HOME);
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
        _feedingRows = <Map<String, dynamic>>[];
        updateAvailableFeedingTimes();
        return;
      }

      final List list = data['data'] ?? [];
      _feedingRows = list.whereType<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();
      updateAvailableFeedingTimes();
    } catch (_) {
      _feedingRows = <Map<String, dynamic>>[];
      updateAvailableFeedingTimes();
    } finally {
      isScheduleLoading.value = false;
    }
  }

  void updateAvailableFeedingTimes() {
    final date = _selectedFeedingDate() ?? DateTime.now();
    final rows = _rowsForSelectedTarget(date);
    final done = <String, bool>{
      'Morning': rows.any((row) => _isFeedingTime(row['feeding_time'], 'Morning')),
      'Afternoon': rows.any((row) => _isFeedingTime(row['feeding_time'], 'Afternoon')),
      'Evening': rows.any((row) => _isFeedingTime(row['feeding_time'], 'Evening')),
    };

    if (!done.values.any((value) => value)) {
      availableFeedingTimes.assignAll(<String>['Morning']);
      if (selectedFeedingTime.value != 'Morning') {
        selectedFeedingTime.value = 'Morning';
      }
      return;
    }

    var lastDoneIndex = -1;
    for (var index = 0; index < _allFeedingTimes.length; index++) {
      if (done[_allFeedingTimes[index]] == true) {
        lastDoneIndex = index;
      }
    }

    final next = _allFeedingTimes
        .asMap()
        .entries
        .where((entry) => entry.key > lastDoneIndex)
        .map((entry) => entry.value)
        .toList();
    availableFeedingTimes.assignAll(next);
    if (!next.contains(selectedFeedingTime.value)) {
      selectedFeedingTime.value = next.isEmpty ? '' : next.first;
    }
  }

  List<Map<String, dynamic>> _rowsForSelectedTarget(DateTime date) {
    final animal = selectedAnimal.value;
    final pan = selectedPan.value;
    final animalIds = <int>{};

    if (animal != null) {
      animalIds.add(animal.id);
    } else if (pan != null) {
      animalIds.addAll(animals.where((item) => item.belongsToPan(pan)).map((item) => item.id));
    }

    if (animalIds.isEmpty) return <Map<String, dynamic>>[];
    return _feedingRows.where((row) {
      final rowAnimalId = int.tryParse((row['animal_id'] ?? '').toString()) ?? 0;
      return animalIds.contains(rowAnimalId) && _isSameDate(_parseApiDate(row['date']), date);
    }).toList();
  }

  DateTime? _selectedFeedingDate() {
    final text = dateController.text.trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      return _parseApiDate(text);
    }
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

  bool _isFeedingTime(dynamic value, String expected) {
    return (value ?? '').toString().trim().toLowerCase() == expected.toLowerCase();
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

  void onFeedTypeChanged(
    FeedTypeModel? value, {
    bool clearSelectedDietPlan = true,
  }) {
    selectedFeedType.value = value;
    if (clearSelectedDietPlan) {
      selectedDietPlan.value = null;
      selectedDietPlanId.value = null;
      dietPlanDays.value = 0;
      dietPlanDaysRemaining.value = 0;
    }
    if (value != null) {
      selectedUnit.value = value.defaultUnit;
      packageQuantity.value = 0;
      _resetSubtypeInputs(value.subtypes);
    } else {
      selectedUnit.value = 'Kg';
      packageQuantity.value = 0;
      _clearSubtypeInputs();
    }
    unawaited(fetchDietPlans());
    _recalculateBalance();
  }

  FeedTypeModel? _effectiveFeedType() {
    if (selectedFeedType.value != null) return selectedFeedType.value;
    final diet = selectedDietPlan.value;
    if (diet == null) return null;
    return feedTypes.firstWhereOrNull((item) => item.id == diet.feedTypeId);
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

  List<Map<String, dynamic>> _dietSubtypePayload() {
    final plan = selectedDietPlan.value;
    if (plan == null) return [];
    final payload = <Map<String, dynamic>>[];
    for (final detail in plan.subtypeDetails) {
      if (detail.quantity <= 0) continue;
      payload.add({
        if (detail.subtypeId > 0) 'subtype_id': detail.subtypeId,
        'name': detail.name,
        'quantity': detail.quantity,
      });
    }
    return payload;
  }

  void _recalculateBalance() {
    final qty = double.tryParse(quantityController.text.trim()) ?? 0;
    final balance = packageQuantity.value - qty;
    balanceQuantity.value = balance < 0 ? 0 : balance;
  }

  void _recalculateFeedingCost() {
    final qty = double.tryParse(quantityController.text.trim()) ?? 0;
    final rate = double.tryParse(ratePerUnitController.text.trim()) ?? 0;
    if (qty <= 0 || rate < 0) {
      feedingCost.value = 0;
      return;
    }
    feedingCost.value = qty * rate;
  }

  void clearForm() {
    selectedAnimal.value = null;
    selectedPan.value = null;
    selectedFeedType.value = null;
    selectedDietPlan.value = null;
    selectedDietPlanId.value = null;
    selectedUnit.value = 'Kg';
    packageQuantity.value = 0;
    dietPlanDays.value = 0;
    dietPlanDaysRemaining.value = 0;
    _clearSubtypeInputs();
    quantityController.clear();
    ratePerUnitController.clear();
    notesController.clear();
    feedingCost.value = 0;
    balanceQuantity.value = packageQuantity.value;
    updateAvailableFeedingTimes();
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
    quantityController.removeListener(_recalculateFeedingCost);
    ratePerUnitController.removeListener(_recalculateFeedingCost);
    dateController.dispose();
    quantityController.dispose();
    ratePerUnitController.dispose();
    notesController.dispose();
    quantityFocus.dispose();
    ratePerUnitFocus.dispose();
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

class FeedDietPlanModel {
  final int id;
  final int animalId;
  final int panId;
  final String animalName;
  final String tagNumber;
  final String dietPlanName;
  final int feedTypeId;
  final String feedType;
  final String referenceDate;
  final double bodyWeight;
  final double milkProduction;
  final double targetDmi;
  final String unit;
  final int daysCount;
  final int daysRemaining;
  final double planQuantity;
  final double consumedQuantity;
  final double remainingQuantity;
  final double planDryMatterQuantity;
  final double remainingDryMatterQuantity;
  final double dmiGap;
  final List<FeedDietSubtypeDetail> subtypeDetails;

  FeedDietPlanModel({
    required this.id,
    required this.animalId,
    required this.panId,
    required this.animalName,
    required this.tagNumber,
    required this.dietPlanName,
    required this.feedTypeId,
    required this.feedType,
    required this.referenceDate,
    required this.bodyWeight,
    required this.milkProduction,
    required this.targetDmi,
    required this.unit,
    required this.daysCount,
    required this.daysRemaining,
    required this.planQuantity,
    required this.consumedQuantity,
    required this.remainingQuantity,
    required this.planDryMatterQuantity,
    required this.remainingDryMatterQuantity,
    required this.dmiGap,
    required this.subtypeDetails,
  });

  String get displayLabel {
    final planName = dietPlanName.trim();
    final title = planName.isNotEmpty ? planName : (feedType.trim().isEmpty ? 'Diet Plan' : feedType.trim());
    return '$title | ${remainingQuantity.toStringAsFixed(2)} $unit';
  }

  factory FeedDietPlanModel.fromJson(Map<String, dynamic> json) {
    final rawSubtypes = json['subtype_details'] is List
        ? json['subtype_details'] as List
        : const [];
    return FeedDietPlanModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      animalId: int.tryParse((json['animal_id'] ?? '').toString()) ?? 0,
      panId: int.tryParse((json['pan_id'] ?? '').toString()) ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      dietPlanName: (json['diet_plan_name'] ?? json['plan_name'] ?? '').toString(),
      feedTypeId: int.tryParse((json['feed_type_id'] ?? '').toString()) ?? 0,
      feedType: (json['feed_type'] ?? '').toString(),
      referenceDate: (json['reference_date'] ?? '').toString(),
      bodyWeight: double.tryParse((json['body_weight'] ?? '0').toString()) ?? 0,
      milkProduction: double.tryParse((json['milk_production'] ?? '0').toString()) ?? 0,
      targetDmi: double.tryParse((json['target_dmi'] ?? '0').toString()) ?? 0,
      unit: (json['unit'] ?? 'Kg').toString(),
      daysCount: int.tryParse((json['days_count'] ?? '').toString()) ?? 0,
      daysRemaining: int.tryParse((json['days_remaining'] ?? '').toString()) ?? 0,
      planQuantity: double.tryParse((json['plan_quantity'] ?? '0').toString()) ?? 0,
      consumedQuantity:
          double.tryParse((json['consumed_quantity'] ?? '0').toString()) ?? 0,
      remainingQuantity:
          double.tryParse((json['remaining_quantity'] ?? '0').toString()) ?? 0,
      planDryMatterQuantity:
          double.tryParse((json['plan_dry_matter_quantity'] ?? '0').toString()) ?? 0,
      remainingDryMatterQuantity:
          double.tryParse((json['remaining_dry_matter_quantity'] ?? '0').toString()) ?? 0,
      dmiGap: double.tryParse((json['dmi_gap'] ?? '0').toString()) ?? 0,
      subtypeDetails: rawSubtypes
          .whereType<Map>()
          .map((item) => FeedDietSubtypeDetail.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class FeedDietSubtypeDetail {
  final int subtypeId;
  final int feedTypeId;
  final String feedTypeName;
  final String name;
  final double quantity;
  final double dmPercent;
  final double dryMatterQuantity;

  FeedDietSubtypeDetail({
    required this.subtypeId,
    required this.feedTypeId,
    required this.feedTypeName,
    required this.name,
    required this.quantity,
    required this.dmPercent,
    required this.dryMatterQuantity,
  });

  factory FeedDietSubtypeDetail.fromJson(Map<String, dynamic> json) {
    final qty = double.tryParse((json['quantity'] ?? '0').toString()) ?? 0;
    final dm = double.tryParse((json['dm_percent'] ?? '0').toString()) ?? 0;
    return FeedDietSubtypeDetail(
      subtypeId: int.tryParse((json['subtype_id'] ?? '').toString()) ?? 0,
      feedTypeId: int.tryParse((json['feed_type_id'] ?? '').toString()) ?? 0,
      feedTypeName: (json['feed_type_name'] ?? json['feed_type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: qty,
      dmPercent: dm,
      dryMatterQuantity:
          double.tryParse((json['dry_matter_quantity'] ?? '').toString()) ??
              ((qty * dm) / 100),
    );
  }
}
