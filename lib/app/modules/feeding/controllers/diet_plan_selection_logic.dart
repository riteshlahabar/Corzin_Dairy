part of 'diet_plan_controller.dart';

extension DietPlanSelectionLogic on DietPlanController {
  List<FeedingAnimalModel> get animalsForSelection {
    return _selectionService.animalsForPan(
      animals: animals,
      pan: selectedPan.value,
    );
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
    final next = _selectionService.buildPansFromAnimals(animals);
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

  void onSubtypeToggleForBlock(
    DietFeedBlock block,
    int subtypeId,
    bool checked,
  ) {
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

  FeedTypeModel? _findFeedTypeById(int id) {
    if (id <= 0) return null;
    for (final type in feedTypes) {
      if (type.id == id) return type;
    }
    return null;
  }

  FeedTypeModel? _resolveFeedTypeForSubtypeDetail(
    FeedDietSubtypeDetail detail,
    FeedDietPlanModel plan,
  ) {
    if (detail.feedTypeId > 0) {
      final byId = _findFeedTypeById(detail.feedTypeId);
      if (byId != null) return byId;
    }

    final feedTypeNameFromSubtype = detail.feedTypeName.trim();
    if (feedTypeNameFromSubtype.isNotEmpty) {
      final wanted = feedTypeNameFromSubtype.toLowerCase();
      for (final type in feedTypes) {
        if (type.name.trim().toLowerCase() == wanted) return type;
      }
    }

    if (detail.subtypeId > 0) {
      for (final type in feedTypes) {
        for (final subtype in type.subtypes) {
          if (subtype.id == detail.subtypeId) {
            return type;
          }
        }
      }
    }

    if (plan.feedTypeId > 0) {
      return _findFeedTypeById(plan.feedTypeId);
    }
    return null;
  }
}
