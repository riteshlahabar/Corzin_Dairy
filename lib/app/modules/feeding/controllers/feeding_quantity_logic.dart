part of 'feeding_controller.dart';

extension FeedingQuantityLogic on FeedingController {
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
      final qty =
          double.tryParse(
            subtypeQuantityControllers[subtypeId]?.text.trim() ?? '',
          ) ??
          0;
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

      final ratio = (recordPackageQuantity / selectedPlan.planQuantity).clamp(
        0.0,
        1.0,
      );

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
    for (final detail
        in selectedPlan?.subtypeDetails ?? const <FeedDietSubtypeDetail>[]) {
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
      final qty =
          double.tryParse(
            subtypeQuantityControllers[entry.key]?.text.trim() ?? '',
          ) ??
          0;
      if (qty <= 0) continue;
      final subtype = subtypeById[entry.key];
      if (subtype == null) continue;
      final dmPercent =
          dmPercentBySubtypeId[subtype.id] ??
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
    final rows = _scheduleService.rowsForTarget(
      rows: _feedingRows,
      date: date,
      animals: animals,
      selectedAnimal: selectedAnimal.value,
      selectedPan: selectedPan.value,
    );
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
}
