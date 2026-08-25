part of 'diet_plan_controller.dart';

extension DietPlanDataLogic on DietPlanController {
  List<FeedDietPlanModel> get filteredPlans {
    return _filterService.filterPlans(
      plans: plans,
      pans: pans,
      query: searchQuery.value,
    );
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  Future<void> loadData() async {
    await _loadFarmerId();
    await Future.wait([fetchAnimals(), fetchFeedTypes(), fetchPlans()]);
    _ensureAtLeastOneFeedBlock();
    _refreshDmiSummary();
    await refreshDietMetrics();
  }

  Future<void> _loadFarmerId() async {
    farmerId = await _repository.loadFarmerId();
  }

  Future<void> fetchAnimals({bool showLoader = true}) async {
    if (farmerId == 0) return;
    try {
      if (showLoader) {
        isLoading.value = animals.isEmpty;
      }

      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List list = data['data'] ?? [];
        animals.assignAll(
          list.map((item) => FeedingAnimalModel.fromJson(item)).toList(),
        );
        _rebuildPansFromAnimals();
        _syncSelectedAnimalAgainstPan();
        isLoading.value = false;
      }

      final result = await _repository.fetchAnimals(
        farmerId,
        onCached: apply,
      );
      final data = result.data;
      if (result.statusCode == 200 && data['status'] == true) {
        apply(data);
      } else if (animals.isEmpty) {
        animals.clear();
        pans.clear();
      }
    } catch (_) {
      if (animals.isEmpty) {
        animals.clear();
        pans.clear();
      }
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
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
        _pruneFeedBlocksForAvailableTypes();
        _ensureAtLeastOneFeedBlock();
      }

      final result = await _repository.fetchFeedTypes(
        farmerId,
        onCached: apply,
      );
      final data = result.data;
      if (result.statusCode == 200 && data['status'] == true) {
        apply(data);
      } else if (feedTypes.isEmpty) {
        feedTypes.clear();
      }
      _pruneFeedBlocksForAvailableTypes();
      _ensureAtLeastOneFeedBlock();
    } catch (_) {
      if (feedTypes.isEmpty) {
        feedTypes.clear();
        _clearFeedBlocks();
      }
      _ensureAtLeastOneFeedBlock();
    }
  }

  Future<void> fetchPlans({bool forceRefresh = false}) async {
    if (farmerId == 0) return;
    try {
      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List list = data['data'] ?? [];
        plans.assignAll(
          list
              .whereType<Map>()
              .map(
                (item) =>
                    FeedDietPlanModel.fromJson(item.cast<String, dynamic>()),
              )
              .toList(),
        );
        isLoading.value = false;
      }

      final result = await _repository.fetchPlans(
        farmerId,
        onCached: apply,
        forceRefresh: forceRefresh,
      );
      final data = result.data;
      if (result.statusCode == 200 && data['status'] == true) {
        apply(data);
      } else if (plans.isEmpty) {
        plans.clear();
      }
    } catch (_) {
      if (plans.isEmpty) {
        plans.clear();
      }
    }
  }

  Future<void> autoRefreshListIfStale({
    Duration staleAfter = const Duration(seconds: 2),
  }) async {
    if (_isAutoRefreshingList) return;
    if (farmerId == 0) {
      await _loadFarmerId();
      if (farmerId == 0) return;
    }

    final now = DateTime.now();
    final last = _lastListRefreshAt;
    if (last != null && now.difference(last) < staleAfter) {
      return;
    }

    _isAutoRefreshingList = true;
    try {
      await fetchAnimals(showLoader: false);
      await fetchPlans();
      _lastListRefreshAt = DateTime.now();
    } finally {
      _isAutoRefreshingList = false;
    }
  }
}
