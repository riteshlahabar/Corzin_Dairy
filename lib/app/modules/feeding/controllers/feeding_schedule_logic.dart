part of 'feeding_controller.dart';

extension FeedingScheduleLogic on FeedingController {
  Future<void> refreshAutoSchedule({bool forceRefresh = false}) async {
    if (farmerId == 0) return;
    try {
      isScheduleLoading.value = true;

      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List list = data['data'] ?? [];
        _feedingRows = list
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
        _refreshMonthEntryCounts();
        updateAvailableFeedingTimes();
        isScheduleLoading.value = false;
      }

      final data = await _repository.fetchSchedule(
        farmerId: farmerId,
        onCached: apply,
        forceRefresh: forceRefresh,
      );
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (_feedingRows.isEmpty) {
        _feedingRows = <Map<String, dynamic>>[];
        _refreshMonthEntryCounts();
        updateAvailableFeedingTimes();
        return;
      }
    } catch (_) {
      if (_feedingRows.isEmpty) {
        _feedingRows = <Map<String, dynamic>>[];
        _refreshMonthEntryCounts();
        updateAvailableFeedingTimes();
      }
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
    return current.year < currentMonth.year ||
        current.month < currentMonth.month;
  }

  void _refreshMonthEntryCounts() {
    monthEntryCounts.assignAll(_scheduleService.monthEntryCounts(_feedingRows));
  }

  void updateAvailableFeedingTimes() {
    final date = _selectedFeedingDate() ?? DateTime.now();
    final rows = _scheduleService.rowsForTarget(
      rows: _feedingRows,
      date: date,
      animals: animals,
      selectedAnimal: selectedAnimal.value,
      selectedPan: selectedPan.value,
    );
    final next = _scheduleService.availableFeedingTimesForRows(rows);
    availableFeedingTimes.assignAll(next);
    if (!next.contains(selectedFeedingTime.value)) {
      selectedFeedingTime.value = next.isEmpty ? '' : next.first;
    }
    _refreshSelectedDietPlanForCurrentDay();
  }

  DateTime? _selectedFeedingDate() {
    return _dateService.selectedDateFromText(dateController.text);
  }
}
