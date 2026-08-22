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
  final Rx<DateTime> entryCalendarMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final RxMap<String, int> monthEntryCounts = <String, int>{}.obs;
  final RxDouble packageQuantity = 0.0.obs;
  final RxDouble totalSubtypeQuantity = 0.0.obs;
  final RxDouble balanceQuantity = 0.0.obs;
  final RxDouble feedingCost = 0.0.obs;
  final RxInt dietPlanDays = 0.obs;
  final RxInt dietPlanDaysRemaining = 0.obs;

  final RxMap<int, bool> subtypeSelected = <int, bool>{}.obs;
  final Map<int, TextEditingController> subtypeQuantityControllers = {};

  int farmerId = 0;
  int _dietPlanRequestSerial = 0;
  List<Map<String, dynamic>> _feedingRows = <Map<String, dynamic>>[];
  static const List<String> _allFeedingTimes = <String>['Morning', 'Evening'];

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

    final requestedAnimalId = selectedAnimal.value?.id ?? 0;
    final requestedPanId = requestedAnimalId == 0
        ? (selectedPan.value?.id ?? 0)
        : 0;
    final requestedFeedTypeId = selectedFeedType.value?.id ?? 0;
    final requestId = ++_dietPlanRequestSerial;
    final query = <String, String>{};
    if (requestedAnimalId > 0) {
      query['animal_id'] = requestedAnimalId.toString();
    } else if (requestedPanId > 0) {
      query['pan_id'] = requestedPanId.toString();
    }
    if (requestedFeedTypeId > 0) {
      query['feed_type_id'] = requestedFeedTypeId.toString();
    }

    try {
      final uri = Uri.parse('${Api.feedingDietPlans}/$farmerId')
          .replace(queryParameters: query.isEmpty ? null : query);
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      if (requestId != _dietPlanRequestSerial) {
        return;
      }
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        final parsed = list
            .map((item) => FeedDietPlanModel.fromJson(item))
            .where(
              (plan) => _matchesDietPlanSelection(
                plan,
                animalId: requestedAnimalId,
                panId: requestedPanId,
                feedTypeId: requestedFeedTypeId,
              ),
            )
            .toList();
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
      if (requestId != _dietPlanRequestSerial) {
        return;
      }
      dietPlans.clear();
    }

    if (requestId != _dietPlanRequestSerial) {
      return;
    }
    final current = selectedDietPlan.value;
    if (current != null) {
      final matched = dietPlans.firstWhereOrNull((plan) => plan.id == current.id);
      if (matched == null) {
        selectDietPlan(null);
      } else {
        selectDietPlan(matched);
      }
    } else if (selectedDietPlanId.value != null) {
      final matched = dietPlans.firstWhereOrNull(
        (plan) => plan.id == selectedDietPlanId.value,
      );
      if (matched == null) {
        selectDietPlan(null);
      } else {
        selectDietPlan(matched);
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
    dietPlans.clear();
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
    dietPlans.clear();
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
      selectedFeedType.value = null;
      selectedUnit.value = 'Kg';
      packageQuantity.value = 0;
      totalSubtypeQuantity.value = 0;
      _clearSubtypeInputs();
      _recalculateBalance();
      return;
    }

    final matchedType = feedTypes.firstWhereOrNull(
      (item) => item.id == value.feedTypeId,
    );

    if (matchedType != null) {
      selectedFeedType.value = matchedType;
      selectedUnit.value = value.unit;
      _resetSubtypeInputs(matchedType.subtypes);
    } else {
      selectedFeedType.value = null;
      selectedUnit.value = value.unit;
      _clearSubtypeInputs();
    }

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

  String dietPlanDisplayLabel(FeedDietPlanModel plan) {
    final planName = plan.dietPlanName.trim();
    final title = planName.isNotEmpty
        ? planName
        : (plan.feedType.trim().isEmpty ? 'Diet Plan' : plan.feedType.trim());
    final availableToday = _availablePackageQuantityForPlan(plan);
    return '$title | ${availableToday.toStringAsFixed(2)} ${plan.unit}';
  }

  String feedingQuantityHalfShiftNote() {
    final plan = selectedDietPlan.value;
    if (plan == null || plan.planQuantity <= 0) {
      return 'feeding_quantity_half_shift_note'.tr;
    }

    final halfDailyQuantity = plan.planQuantity / 2;
    final quantity = _formatDistributedValue(halfDailyQuantity);
    final unit = _compactQuantityUnit(plan.unit);

    return 'Enter half ($quantity$unit) of the daily diet quantity for this shift.';
  }

  String _compactQuantityUnit(String value) {
    final unit = value.trim();
    if (unit.isEmpty) return '';
    if (unit.toLowerCase() == 'kg') return 'kg';
    return unit;
  }

  void _applyDietPlanToSubtypeInputs(FeedDietPlanModel plan) {
    final availableToday = _availablePackageQuantityForPlan(plan);
    packageQuantity.value = availableToday;
    totalSubtypeQuantity.value = availableToday;
    balanceQuantity.value = availableToday;

    final currentType = selectedFeedType.value;
    if (currentType == null) {
      _recalculateBalance();
      return;
    }

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

    final ratio = plan.planQuantity > 0
        ? (availableToday / plan.planQuantity).clamp(0.0, 1.0)
        : 0.0;

    for (final detail in plan.subtypeDetails) {
      FeedSubtypeModel? target;
      if (detail.subtypeId > 0) {
        target = byId[detail.subtypeId];
      }
      target ??= byName[detail.name.trim().toLowerCase()];
      if (target == null) continue;
      subtypeSelected[target.id] = true;
      final scaledQuantity = plan.planQuantity > 0
          ? (detail.quantity * ratio)
          : detail.quantity;
      subtypeQuantityControllers[target.id]?.text =
          scaledQuantity.toStringAsFixed(2);
    }

    _recalculateBalance();
  }

  Future<void> submitFeeding() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedAnimal.value == null && selectedPan.value == null) {
      Get.snackbar('error'.tr, 'please_select_animal_or_pan'.tr);
      return;
    }
    final effectiveFeedType = _effectiveFeedType();
    if (effectiveFeedType == null) {
      Get.snackbar('error'.tr, 'no_feed_type_found_selected_diet_plan'.tr);
      return;
    }
    if (selectedDietPlan.value == null && selectedDietPlanId.value != null) {
      selectDietPlanById(selectedDietPlanId.value);
    }
    if (dietPlans.isNotEmpty && selectedDietPlan.value == null) {
      Get.snackbar('error'.tr, 'please_select_diet_plan_for_selected_animal_pan'.tr);
      return;
    }
    if (selectedFeedingTime.value.trim().isEmpty || !availableFeedingTimes.contains(selectedFeedingTime.value)) {
      Get.snackbar('info'.tr, 'no_feeding_time_available_selected_date'.tr);
      return;
    }

    final feedingQty = double.tryParse(quantityController.text.trim()) ?? 0;
    if (feedingQty <= 0) {
      Get.snackbar('error'.tr, 'please_enter_feeding_quantity'.tr);
      return;
    }
    final rateText = ratePerUnitController.text.trim();
    if (rateText.isEmpty) {
      Get.snackbar('error'.tr, 'please_enter_rate_per_unit'.tr);
      return;
    }
    final ratePerUnit = double.tryParse(rateText) ?? -1;
    if (ratePerUnit < 0) {
      Get.snackbar('error'.tr, 'please_enter_valid_rate_per_unit'.tr);
      return;
    }
    final calculatedFeedingCost = feedingQty * ratePerUnit;

    final plan = selectedDietPlan.value;
    if (plan != null) {
      final availableQty = packageQuantity.value;
      if (availableQty <= 0.000001) {
        Get.snackbar(
          'error'.tr,
          'no_balance_package_quantity_left'.tr,
        );
        return;
      }
      if ((feedingQty - availableQty) > 0.000001) {
        Get.snackbar(
          'error'.tr,
          'feeding_quantity_cannot_exceed_balance'.tr,
        );
        return;
      }
    }

    final subtypePayload = _dietSubtypePayload();
    if (subtypePayload.isEmpty) {
      Get.snackbar('error'.tr, 'selected_diet_plan_has_no_subtype_quantity'.tr);
      return;
    }

    if (selectedPan.value != null) {
      final pan = selectedPan.value!;
      final panAnimals = animals.where((animal) => animal.belongsToPan(pan)).toList();
      if (panAnimals.isEmpty) {
        Get.snackbar('error'.tr, 'no_animals_found_in_selected_pan_msg'.tr);
        return;
      }

      final subtypePayloadByAnimal =
          _distributeSubtypePayloadAcrossAnimals(subtypePayload, panAnimals);
      final packageQuantityByAnimal = <int, double>{
        for (final animal in panAnimals)
          animal.id: _sumSubtypeQuantity(subtypePayloadByAnimal[animal.id] ?? const []),
      };
      final feedingQuantityByAnimal = _distributeFeedingAcrossAnimals(
        totalFeedingQuantity: feedingQty,
        panAnimals: panAnimals,
        packageQuantityByAnimal: packageQuantityByAnimal,
      );
      final balanceQuantityByAnimal = <int, double>{
        for (final animal in panAnimals)
          animal.id: double.parse(
            (packageQuantityByAnimal[animal.id]! - feedingQuantityByAnimal[animal.id]!)
                .clamp(0.0, double.infinity)
                .toStringAsFixed(2),
          ),
      };
      final quantityByAnimal = <int, String>{
        for (final animal in panAnimals)
          animal.id: _formatDistributedValue(feedingQuantityByAnimal[animal.id] ?? 0),
      };

      final result = await submitBulkFeeding(
        quantityByAnimal,
        packageQuantityByAnimal: packageQuantityByAnimal,
        balanceQuantityByAnimal: balanceQuantityByAnimal,
        subtypePayloadByAnimal: subtypePayloadByAnimal,
        ratePerUnitForAll: ratePerUnit,
        includeDietPlanId: true,
      );
      final successCount = result['success'] ?? 0;
      final failedCount = result['failed'] ?? 0;

      if (successCount > 0 && failedCount == 0) {
        final successMessage = 'feeding_saved_for_animals'.trParams({
          'count': '$successCount',
          'pan': pan.name,
        });
        await refreshAutoSchedule();
        clearForm();
        _goToHomeAfterSave();
        Future.delayed(const Duration(milliseconds: 120), () {
          Get.snackbar(
            'success'.tr,
            successMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else if (successCount > 0) {
        Get.snackbar(
          'partial_success'.tr,
          'feeding_saved_partial'.trParams({
            'success': '$successCount',
            'failed': '$failedCount',
          }),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_save_feeding_selected_pan'.tr,
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
        'package_quantity': _recordPackageQuantity().toStringAsFixed(2),
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
        final successMessage =
            data['message']?.toString() ?? 'feeding_entry_saved_successfully'.tr;
        await refreshAutoSchedule();
        clearForm();
        _goToHomeAfterSave();
        Future.delayed(const Duration(milliseconds: 120), () {
          Get.snackbar(
            'success'.tr,
            successMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'error'.tr,
          data['message']?.toString() ?? 'failed_save_feeding_entry'.tr,
        );
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<Map<String, int>> submitBulkFeeding(
    Map<int, String> quantityByAnimal,
    {
    Map<int, double>? packageQuantityByAnimal,
    Map<int, double>? balanceQuantityByAnimal,
    double? ratePerUnitForAll,
    Map<int, List<Map<String, dynamic>>>? subtypePayloadByAnimal,
    bool includeDietPlanId = true,
  }
  ) async {
    if (farmerId == 0) {
      Get.snackbar(
        'error'.tr,
        'farmer_id_not_found_login_again'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return {'success': 0, 'failed': 0};
    }
    final effectiveFeedType = _effectiveFeedType();
    if (effectiveFeedType == null) {
      Get.snackbar(
        'error'.tr,
        'no_feed_type_found_selected_diet_plan'.tr,
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
        'error'.tr,
        'please_enter_at_least_one_valid_quantity'.tr,
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
        final subtypePayload = subtypePayloadByAnimal?[entry.key] ?? _dietSubtypePayload();
        if (subtypePayload.isEmpty) {
          failedCount++;
          continue;
        }
        final packageQtyForAnimal =
            packageQuantityByAnimal?[entry.key] ?? packageQuantity.value;
        final balanceQtyForAnimal =
            balanceQuantityByAnimal?[entry.key] ?? balanceQuantity.value;
        final payload = {
          'farmer_id': farmerId.toString(),
          'animal_id': entry.key.toString(),
          'feed_type_id': effectiveFeedType.id.toString(),
          if (includeDietPlanId && selectedDietPlan.value != null)
            'diet_plan_id': selectedDietPlan.value!.id.toString(),
          'feed_type': effectiveFeedType.name,
          'quantity': entry.value,
          'package_quantity': packageQtyForAnimal.toStringAsFixed(2),
          'feeding_quantity': entry.value,
          'balance_quantity': balanceQtyForAnimal.toStringAsFixed(2),
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
        _refreshMonthEntryCounts();
        updateAvailableFeedingTimes();
        return;
      }

      final List list = data['data'] ?? [];
      _feedingRows = list.whereType<Map>().map((e) => e.map((k, v) => MapEntry(k.toString(), v))).toList();
      _refreshMonthEntryCounts();
      updateAvailableFeedingTimes();
    } catch (_) {
      _feedingRows = <Map<String, dynamic>>[];
      _refreshMonthEntryCounts();
      updateAvailableFeedingTimes();
    } finally {
      isScheduleLoading.value = false;
    }
  }

  int entryCountForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return monthEntryCounts[key] ?? 0;
  }

  void moveEntryCalendarMonth(int offset) {
    final current = entryCalendarMonth.value;
    final next = DateTime(current.year, current.month + offset);
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    if (next.isAfter(currentMonth)) return;
    entryCalendarMonth.value = next;
  }

  bool get canMoveEntryCalendarForward {
    final current = entryCalendarMonth.value;
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    return current.year < currentMonth.year || current.month < currentMonth.month;
  }

  void _refreshMonthEntryCounts() {
    final shiftsByDate = <String, Set<String>>{};

    for (final row in _feedingRows) {
      final date = _parseApiDate(row['date']);
      if (date == null) continue;

      final shift = _normalizedFeedingShift(row['feeding_time']);
      if (shift.isEmpty) continue;

      final key = DateFormat('yyyy-MM-dd').format(date);
      shiftsByDate.putIfAbsent(key, () => <String>{}).add(shift);
    }

    monthEntryCounts.assignAll(
      shiftsByDate.map((key, value) => MapEntry(key, value.length)),
    );
  }

  void updateAvailableFeedingTimes() {
    final date = _selectedFeedingDate() ?? DateTime.now();
    final rows = _rowsForSelectedTarget(date);
    final hasMorning =
        rows.any((row) => _isFeedingTime(row['feeding_time'], 'Morning'));
    final hasAfternoon =
        rows.any((row) => _isFeedingTime(row['feeding_time'], 'Afternoon'));
    final hasEvening =
        rows.any((row) => _isFeedingTime(row['feeding_time'], 'Evening'));
    final done = <String, bool>{
      'Morning': hasMorning || hasAfternoon,
      'Evening': hasEvening,
    };

    if (!done.values.any((value) => value)) {
      availableFeedingTimes.assignAll(<String>['Morning']);
      if (selectedFeedingTime.value != 'Morning') {
        selectedFeedingTime.value = 'Morning';
      }
      _refreshSelectedDietPlanForCurrentDay();
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
    _refreshSelectedDietPlanForCurrentDay();
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

  String _normalizedFeedingShift(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    if (text.contains('evening')) return 'Evening';
    if (text.contains('morning') || text.contains('afternoon')) return 'Morning';
    return '';
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

  Map<int, List<Map<String, dynamic>>> _distributeSubtypePayloadAcrossAnimals(
    List<Map<String, dynamic>> subtypePayload,
    List<FeedingAnimalModel> panAnimals,
  ) {
    final distributed = <int, List<Map<String, dynamic>>>{
      for (final animal in panAnimals) animal.id: <Map<String, dynamic>>[],
    };
    if (panAnimals.isEmpty) {
      return distributed;
    }

    for (final item in subtypePayload) {
      final totalQuantity = double.tryParse(item['quantity'].toString()) ?? 0;
      final splits = _distributeAmountAcrossAnimals(totalQuantity, panAnimals);
      for (final animal in panAnimals) {
        final splitQuantity = splits[animal.id] ?? 0;
        if (splitQuantity <= 0) continue;
        distributed[animal.id]!.add({
          if (item['subtype_id'] != null) 'subtype_id': item['subtype_id'],
          if (item['feed_type_id'] != null) 'feed_type_id': item['feed_type_id'],
          if (item['feed_type_name'] != null) 'feed_type_name': item['feed_type_name'],
          'name': item['name'],
          'quantity': splitQuantity,
          if (item['dm_percent'] != null) 'dm_percent': item['dm_percent'],
        });
      }
    }

    return distributed;
  }

  Map<int, double> _distributeFeedingAcrossAnimals({
    required double totalFeedingQuantity,
    required List<FeedingAnimalModel> panAnimals,
    required Map<int, double> packageQuantityByAnimal,
  }) {
    final capacities = <int, int>{
      for (final animal in panAnimals)
        animal.id: _toCents(packageQuantityByAnimal[animal.id] ?? 0),
    };
    final targetCents = _toCents(totalFeedingQuantity);
    final distributedCents = _distributeCentsWithCap(
      totalCents: targetCents,
      capacitiesByAnimal: capacities,
      panAnimals: panAnimals,
    );
    return {
      for (final animal in panAnimals)
        animal.id: _fromCents(distributedCents[animal.id] ?? 0),
    };
  }

  Map<int, double> _distributeAmountAcrossAnimals(
    double totalQuantity,
    List<FeedingAnimalModel> panAnimals,
  ) {
    final cents = _toCents(totalQuantity);
    final count = panAnimals.length;
    if (count == 0) return <int, double>{};
    final base = cents ~/ count;
    final remainder = cents % count;
    return {
      for (var index = 0; index < panAnimals.length; index++)
        panAnimals[index].id: _fromCents(base + (index < remainder ? 1 : 0)),
    };
  }

  Map<int, int> _distributeCentsWithCap({
    required int totalCents,
    required Map<int, int> capacitiesByAnimal,
    required List<FeedingAnimalModel> panAnimals,
  }) {
    final allocations = <int, int>{
      for (final animal in panAnimals) animal.id: 0,
    };
    if (panAnimals.isEmpty || totalCents <= 0) {
      return allocations;
    }

    final base = totalCents ~/ panAnimals.length;
    for (final animal in panAnimals) {
      final capacity = capacitiesByAnimal[animal.id] ?? 0;
      allocations[animal.id] = base > capacity ? capacity : base;
    }

    var allocated = allocations.values.fold<int>(0, (sum, value) => sum + value);
    var remaining = totalCents - allocated;
    while (remaining > 0) {
      var distributedAny = false;
      for (final animal in panAnimals) {
        if (remaining <= 0) break;
        final id = animal.id;
        final capacity = capacitiesByAnimal[id] ?? 0;
        final current = allocations[id] ?? 0;
        if (current >= capacity) continue;
        allocations[id] = current + 1;
        remaining--;
        distributedAny = true;
      }
      if (!distributedAny) {
        break;
      }
    }

    return allocations;
  }

  double _sumSubtypeQuantity(List<Map<String, dynamic>> payload) {
    var total = 0.0;
    for (final item in payload) {
      total += double.tryParse(item['quantity'].toString()) ?? 0;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  int _toCents(double value) => (value * 100).round();

  double _fromCents(int cents) => double.parse((cents / 100).toStringAsFixed(2));

  bool _matchesDietPlanSelection(
    FeedDietPlanModel plan, {
    required int animalId,
    required int panId,
    required int feedTypeId,
  }) {
    if (panId > 0 && plan.panId != panId) {
      return false;
    }
    if (animalId > 0) {
      if (plan.animalId != animalId) {
        return false;
      }
      if (plan.panId > 0) {
        return false;
      }
    }
    if (feedTypeId > 0 && plan.feedTypeId != feedTypeId) {
      return false;
    }
    return true;
  }

  void onFeedTypeChanged(
    FeedTypeModel? value, {
    bool clearSelectedDietPlan = true,
  }) {
    selectedFeedType.value = value;
    if (clearSelectedDietPlan) {
      dietPlans.clear();
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
    if (selectedDietPlan.value == null) {
      packageQuantity.value = total;
    }
    _recalculateBalance();
  }

  List<Map<String, dynamic>> _dietSubtypePayload() {
    final selectedPlan = selectedDietPlan.value;
    if (selectedPlan != null && selectedPlan.subtypeDetails.isNotEmpty) {
      final recordPackageQuantity = _recordPackageQuantity();
      if (recordPackageQuantity <= 0 || selectedPlan.planQuantity <= 0) {
        return <Map<String, dynamic>>[];
      }

      final ratio =
          (recordPackageQuantity / selectedPlan.planQuantity).clamp(0.0, 1.0);

      return selectedPlan.subtypeDetails
          .where((detail) => detail.quantity > 0)
          .map((detail) {
            final scaledQuantity = double.parse(
              (detail.quantity * ratio).toStringAsFixed(2),
            );
            return <String, dynamic>{
              if (detail.subtypeId > 0) 'subtype_id': detail.subtypeId,
              if (detail.feedTypeId > 0) 'feed_type_id': detail.feedTypeId,
              if (detail.feedTypeName.trim().isNotEmpty)
                'feed_type_name': detail.feedTypeName,
              'name': detail.name,
              'quantity': scaledQuantity,
              if (detail.dmPercent > 0)
                'dm_percent': double.parse(detail.dmPercent.toStringAsFixed(2)),
            };
          })
          .where((item) => (item['quantity'] as double) > 0)
          .toList();
    }

    final payload = <Map<String, dynamic>>[];
    final feedType = _effectiveFeedType();
    final subtypeById = <int, FeedSubtypeModel>{
      for (final subtype in (feedType?.subtypes ?? const <FeedSubtypeModel>[]))
        subtype.id: subtype,
    };
    final dmPercentBySubtypeId = <int, double>{};
    final dmPercentBySubtypeName = <String, double>{};
    for (final detail in selectedPlan?.subtypeDetails ?? const <FeedDietSubtypeDetail>[]) {
      if (detail.subtypeId > 0) {
        dmPercentBySubtypeId[detail.subtypeId] = detail.dmPercent;
      }
      final nameKey = detail.name.trim().toLowerCase();
      if (nameKey.isNotEmpty) {
        dmPercentBySubtypeName[nameKey] = detail.dmPercent;
      }
    }

    for (final entry in subtypeSelected.entries) {
      if (!entry.value) continue;
      final qty = double.tryParse(
            subtypeQuantityControllers[entry.key]?.text.trim() ?? '',
          ) ??
          0;
      if (qty <= 0) continue;
      final subtype = subtypeById[entry.key];
      if (subtype == null) continue;
      final dmPercent = dmPercentBySubtypeId[subtype.id] ??
          dmPercentBySubtypeName[subtype.name.trim().toLowerCase()] ??
          0;
      payload.add({
        'subtype_id': subtype.id,
        'name': subtype.name,
        'quantity': double.parse(qty.toStringAsFixed(2)),
        if (dmPercent > 0)
          'dm_percent': double.parse(dmPercent.toStringAsFixed(2)),
      });
    }
    return payload;
  }

  void _recalculateBalance() {
    final qty = double.tryParse(quantityController.text.trim()) ?? 0;
    final balance = packageQuantity.value - qty;
    balanceQuantity.value = balance < 0 ? 0 : balance;
  }

  void _refreshSelectedDietPlanForCurrentDay() {
    final current = selectedDietPlan.value;
    if (current == null) {
      _recalculateBalance();
      return;
    }
    final matched =
        dietPlans.firstWhereOrNull((plan) => plan.id == current.id) ?? current;
    selectedDietPlan.value = matched;
    _applyDietPlanToSubtypeInputs(matched);
  }

  double _availablePackageQuantityForPlan(FeedDietPlanModel plan) {
    final fullDailyQuantity = plan.planQuantity > 0
        ? plan.planQuantity
        : (plan.remainingQuantity > 0 ? plan.remainingQuantity : 0);
    final consumedToday = _consumedQuantityForSelectedDay(plan);
    final remaining = fullDailyQuantity - consumedToday;
    return remaining > 0 ? remaining : 0;
  }

  double _consumedQuantityForSelectedDay(FeedDietPlanModel plan) {
    final date = _selectedFeedingDate() ?? DateTime.now();
    final rows = _rowsForSelectedTarget(date);
    var total = 0.0;
    for (final row in rows) {
      if (!_rowMatchesDietPlan(row, plan)) continue;
      total += _asDouble(row['feeding_quantity']);
    }
    return total;
  }

  bool _rowMatchesDietPlan(Map<String, dynamic> row, FeedDietPlanModel plan) {
    final rowPlanId = int.tryParse((row['diet_plan_id'] ?? '').toString()) ?? 0;
    if (plan.id > 0 && rowPlanId > 0) {
      return rowPlanId == plan.id;
    }

    final rowPlanName = (row['diet_plan_name'] ?? row['plan_name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final planName = plan.dietPlanName.trim().toLowerCase();
    if (rowPlanName.isNotEmpty && planName.isNotEmpty) {
      return rowPlanName == planName;
    }

    final rowFeedTypeId =
        int.tryParse((row['feed_type_id'] ?? '').toString()) ?? 0;
    return plan.feedTypeId > 0 && rowFeedTypeId == plan.feedTypeId;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().trim()) ?? 0;
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

  double _recordPackageQuantity() {
    final plan = selectedDietPlan.value;
    if (plan != null) {
      if (packageQuantity.value > 0) {
        return packageQuantity.value;
      }
      if (plan.planQuantity > 0) {
        return plan.planQuantity;
      }
    }
    return packageQuantity.value;
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
  final double actualDmi;
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
    required this.actualDmi,
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
    return '$title | ${planQuantity.toStringAsFixed(2)} $unit';
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
      actualDmi: double.tryParse((json['actual_dmi'] ?? '0').toString()) ?? 0,
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
