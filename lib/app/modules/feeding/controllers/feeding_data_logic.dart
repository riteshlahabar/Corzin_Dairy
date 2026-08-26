part of 'feeding_controller.dart';

extension FeedingDataLogic on FeedingController {
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
    farmerId = await _repository.loadFarmerId();
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) return;

    try {
      isPageLoading.value = animals.isEmpty;

      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List list = data['data'] ?? [];
        final refreshedAnimals = list
            .map((item) => FeedingAnimalModel.fromJson(item))
            .toList();

        animals.assignAll(refreshedAnimals);

        // Re-bind selected animal to latest refreshed object.
        // Prevents stale DropdownButtonFormField value after cache refresh.
        final currentAnimal = selectedAnimal.value;
        if (currentAnimal != null) {
          selectedAnimal.value = refreshedAnimals.firstWhereOrNull(
            (animal) => animal.id == currentAnimal.id,
          );
        }

        _rebuildPansFromAnimals();
        updateAvailableFeedingTimes();
        isPageLoading.value = false;
      }

      final data = await _repository.fetchAnimals(
        farmerId: farmerId,
        onCached: apply,
      );
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (animals.isEmpty) {
        animals.clear();
        pans.clear();
        selectedPan.value = null;
        updateAvailableFeedingTimes();
        dietPlans.clear();
        selectedDietPlan.value = null;
        selectedDietPlanId.value = null;
      }
    } catch (_) {
      if (animals.isEmpty) {
        animals.clear();
        pans.clear();
        selectedPan.value = null;
        updateAvailableFeedingTimes();
        dietPlans.clear();
        selectedDietPlan.value = null;
        selectedDietPlanId.value = null;
      }
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> fetchFeedTypes() async {
    if (farmerId == 0) return;
    try {
      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
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
      }

      final data = await _repository.fetchFeedTypes(
        farmerId: farmerId,
        onCached: apply,
      );
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (feedTypes.isEmpty) {
        feedTypes.clear();
        _clearSubtypeInputs();
        dietPlans.clear();
        selectedDietPlan.value = null;
        selectedDietPlanId.value = null;
      }
    } catch (_) {
      if (feedTypes.isEmpty) {
        feedTypes.clear();
        _clearSubtypeInputs();
        dietPlans.clear();
        selectedDietPlan.value = null;
        selectedDietPlanId.value = null;
      }
    }
  }

  Future<void> fetchDietPlans({bool forceRefresh = false}) async {
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
      void apply(Map<String, dynamic> data) {
        if (requestId != _dietPlanRequestSerial || data['status'] != true) {
          return;
        }
        final List list = data['data'] ?? [];
        final parsed = list
            .whereType<Map>()
            .map(
              (item) =>
                  FeedDietPlanModel.fromJson(item.cast<String, dynamic>()),
            )
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
      }

      final data = await _repository.fetchDietPlans(
        farmerId: farmerId,
        query: query,
        onCached: apply,
        forceRefresh: forceRefresh,
      );
      if (requestId != _dietPlanRequestSerial) {
        return;
      }
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (dietPlans.isEmpty) {
        dietPlans.clear();
      }
    } catch (_) {
      if (requestId != _dietPlanRequestSerial) {
        return;
      }
      if (dietPlans.isEmpty) {
        dietPlans.clear();
      }
    }

    if (requestId != _dietPlanRequestSerial) {
      return;
    }
    final current = selectedDietPlan.value;
    if (current != null) {
      final matched = dietPlans.firstWhereOrNull(
        (plan) => plan.id == current.id,
      );
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
}
