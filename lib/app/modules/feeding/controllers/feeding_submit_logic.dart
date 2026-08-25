part of 'feeding_controller.dart';

extension FeedingSubmitLogic on FeedingController {
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
      Get.snackbar(
        'error'.tr,
        'please_select_diet_plan_for_selected_animal_pan'.tr,
      );
      return;
    }
    if (selectedFeedingTime.value.trim().isEmpty ||
        !availableFeedingTimes.contains(selectedFeedingTime.value)) {
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
        Get.snackbar('error'.tr, 'no_balance_package_quantity_left'.tr);
        return;
      }
      if ((feedingQty - availableQty) > 0.000001) {
        Get.snackbar('error'.tr, 'feeding_quantity_cannot_exceed_balance'.tr);
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
      final panAnimals = animals
          .where((animal) => animal.belongsToPan(pan))
          .toList();
      if (panAnimals.isEmpty) {
        Get.snackbar('error'.tr, 'no_animals_found_in_selected_pan_msg'.tr);
        return;
      }

      final subtypePayloadByAnimal = _quantityService
          .distributeSubtypePayloadAcrossAnimals(subtypePayload, panAnimals);
      final packageQuantityByAnimal = <int, double>{
        for (final animal in panAnimals)
          animal.id: _quantityService.sumSubtypeQuantity(
            subtypePayloadByAnimal[animal.id] ?? const [],
          ),
      };
      final feedingQuantityByAnimal = _quantityService
          .distributeFeedingAcrossAnimals(
            totalFeedingQuantity: feedingQty,
            panAnimals: panAnimals,
            packageQuantityByAnimal: packageQuantityByAnimal,
          );
      final balanceQuantityByAnimal = <int, double>{
        for (final animal in panAnimals)
          animal.id: double.parse(
            (packageQuantityByAnimal[animal.id]! -
                    feedingQuantityByAnimal[animal.id]!)
                .clamp(0.0, double.infinity)
                .toStringAsFixed(2),
          ),
      };
      final quantityByAnimal = <int, String>{
        for (final animal in panAnimals)
          animal.id: _quantityService.formatDistributedValue(
            feedingQuantityByAnimal[animal.id] ?? 0,
          ),
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
        await refreshAutoSchedule(forceRefresh: true);
        await fetchDietPlans(forceRefresh: true);
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
        'date': _dateService.formatForApi(dateController.text.trim()),
        'notes': notesController.text.trim(),
      };

      final result = await _repository.submitFeeding(payload);
      final data = result.data;
      if (result.isSuccess) {
        final successMessage =
            data['message']?.toString() ??
            'feeding_entry_saved_successfully'.tr;
        await refreshAutoSchedule(forceRefresh: true);
        await fetchDietPlans(forceRefresh: true);
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
    Map<int, String> quantityByAnimal, {
    Map<int, double>? packageQuantityByAnimal,
    Map<int, double>? balanceQuantityByAnimal,
    double? ratePerUnitForAll,
    Map<int, List<Map<String, dynamic>>>? subtypePayloadByAnimal,
    bool includeDietPlanId = true,
  }) async {
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
        final subtypePayload =
            subtypePayloadByAnimal?[entry.key] ?? _dietSubtypePayload();
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
          'feeding_cost': (feedingQty * effectiveRatePerUnit).toStringAsFixed(
            2,
          ),
          'feed_subtype_details': subtypePayload,
          'unit': selectedUnit.value,
          'feeding_time': selectedFeedingTime.value,
          'date': _dateService.formatForApi(dateController.text.trim()),
          'notes': notesController.text.trim(),
        };

        final result = await _repository.submitFeeding(payload);
        if (result.isSuccess) {
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
}
