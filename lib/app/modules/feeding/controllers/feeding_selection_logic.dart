part of 'feeding_controller.dart';

extension FeedingSelectionLogic on FeedingController {
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
    final quantity = _quantityService.formatDistributedValue(halfDailyQuantity);
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
      for (final subtype in currentType.subtypes)
        subtype.name.trim().toLowerCase(): subtype,
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
      subtypeQuantityControllers[target.id]?.text = scaledQuantity
          .toStringAsFixed(2);
    }

    _recalculateBalance();
  }

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

  void _rebuildPansFromAnimals() {
    final next = _selectionService.buildPansFromAnimals(animals);
    pans.assignAll(next);
    final current = selectedPan.value;

    // Re-bind Pan to the object from the latest list.
    // This is important when cached animals are replaced by fresh API data.
    if (current != null) {
      selectedPan.value = next.firstWhereOrNull((pan) => pan.matches(current));
    }
  }
}
