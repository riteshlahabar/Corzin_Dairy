part of 'diet_plan_controller.dart';

extension DietPlanFormLogic on DietPlanController {
  void prepareAddForm() {
    if (_isAddFormPrepared) return;
    _isAddFormPrepared = true;

    // If this controller instance was previously used for edit/list,
    // force clean add form so add/edit state never gets mixed.
    final hasStaleState =
        editingPlanId > 0 ||
        selectedAnimal.value != null ||
        selectedPan.value != null ||
        dietPlanNameController.text.trim().isNotEmpty ||
        feedBlocks.any((block) {
          if (block.selectedFeedType != null) return true;
          if (block.subtypeSelected.values.any((selected) => selected)) {
            return true;
          }
          if (block.totalQuantity > 0) return true;
          return false;
        });

    if (hasStaleState) {
      _clearForm();
    } else {
      _ensureAtLeastOneFeedBlock();
      feedBlocks.refresh();
    }
  }

  Future<void> prepareEditForm(FeedDietPlanModel? plan) async {
    if (plan == null || plan.id <= 0) return;
    if (_isPreparingEditForm ||
        (editingPlanId == plan.id && isEditModeReady.value)) {
      return;
    }

    _isPreparingEditForm = true;
    _isAddFormPrepared = false;
    isEditModeReady.value = false;
    try {
      if (farmerId == 0) {
        await _loadFarmerId();
      }
      await Future.wait([
        fetchAnimals(showLoader: false),
        fetchFeedTypes(),
        fetchPlans(),
      ]);

      editingPlanId = plan.id;
      dietPlanNameController.text = plan.dietPlanName.trim();
      if (plan.referenceDate.trim().isNotEmpty) {
        try {
          final parsed = DateFormat(
            'yyyy-MM-dd',
          ).parseStrict(plan.referenceDate.trim());
          referenceDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(parsed);
        } catch (_) {
          referenceDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(DateTime.now());
        }
      } else {
        referenceDateController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.now());
      }

      selectedPan.value = null;
      selectedAnimal.value = null;
      if (plan.panId > 0) {
        FeedingPanModel? matchedPan;
        for (final pan in pans) {
          if (pan.id == plan.panId) {
            matchedPan = pan;
            break;
          }
        }
        selectedPan.value = matchedPan;
      } else if (plan.animalId > 0) {
        FeedingAnimalModel? matchedAnimal;
        for (final animal in animals) {
          if (animal.id == plan.animalId) {
            matchedAnimal = animal;
            break;
          }
        }
        selectedAnimal.value = matchedAnimal;
      }

      final grouped = <int, List<FeedDietSubtypeDetail>>{};
      final orderedTypeIds = <int>[];
      for (final detail in plan.subtypeDetails) {
        final resolvedType = _resolveFeedTypeForSubtypeDetail(detail, plan);
        final typeId = resolvedType?.id ?? plan.feedTypeId;
        if (typeId <= 0) continue;
        if (!grouped.containsKey(typeId)) {
          grouped[typeId] = <FeedDietSubtypeDetail>[];
          orderedTypeIds.add(typeId);
        }
        grouped[typeId]!.add(detail);
      }

      _clearFeedBlocks();
      if (orderedTypeIds.isEmpty) {
        final block = DietFeedBlock(id: _nextFeedBlockId++);
        final fallbackType = _findFeedTypeById(plan.feedTypeId);
        block.configureForFeedType(fallbackType, _onFeedBlockChanged);
        feedBlocks.add(block);
      } else {
        for (final typeId in orderedTypeIds) {
          final block = DietFeedBlock(id: _nextFeedBlockId++);
          final type = _findFeedTypeById(typeId);
          block.configureForFeedType(type, _onFeedBlockChanged);
          for (final detail
              in grouped[typeId] ?? const <FeedDietSubtypeDetail>[]) {
            int resolvedSubtypeId = detail.subtypeId;
            if (resolvedSubtypeId <= 0 && type != null) {
              final targetName = detail.name.trim().toLowerCase();
              for (final subtype in type.subtypes) {
                if (subtype.name.trim().toLowerCase() == targetName) {
                  resolvedSubtypeId = subtype.id;
                  break;
                }
              }
            }
            if (resolvedSubtypeId <= 0) continue;
            if (!block.subtypeSelected.containsKey(resolvedSubtypeId)) continue;
            block.setSubtypeSelected(resolvedSubtypeId, true);
            block.subtypeQtyControllers[resolvedSubtypeId]?.text = detail
                .quantity
                .toStringAsFixed(2);
            block.subtypeDmPercentControllers[resolvedSubtypeId]?.text = detail
                .dmPercent
                .toStringAsFixed(2);
          }
          feedBlocks.add(block);
        }
      }

      _ensureAtLeastOneFeedBlock();
      feedBlocks.refresh();
      await refreshDietMetrics();
      isEditModeReady.value = true;
    } finally {
      _isPreparingEditForm = false;
    }
  }

  void clearEditContext() {
    editingPlanId = 0;
    isEditModeReady.value = false;
    _isAddFormPrepared = false;
  }

  void _clearForm() {
    editingPlanId = 0;
    isEditModeReady.value = false;
    _isAddFormPrepared = true;
    selectedAnimal.value = null;
    selectedPan.value = null;
    dietPlanNameController.clear();
    referenceDateController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.now());
    bodyWeight.value = 0;
    milkProduction.value = 0;
    actualDmi.value = 0;
    targetDmi.value = 0;
    plannedDryMatter.value = 0;
    dmiGap.value = 0;
    actualDmiGap.value = 0;
    isNonMilkingContext.value = false;
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
}
