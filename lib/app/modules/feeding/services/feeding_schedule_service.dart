import 'package:intl/intl.dart';

import '../models/feeding_models.dart';
import 'feeding_date_service.dart';

class FeedingScheduleService {
  const FeedingScheduleService({this.dateService = const FeedingDateService()});

  final FeedingDateService dateService;

  static const List<String> allFeedingTimes = <String>['Morning', 'Evening'];

  Map<String, int> monthEntryCounts(List<Map<String, dynamic>> rows) {
    final shiftsByDate = <String, Set<String>>{};

    for (final row in rows) {
      final date = dateService.parseApiDate(row['date']);
      if (date == null) continue;

      final shift = dateService.normalizedFeedingShift(row['feeding_time']);
      if (shift.isEmpty) continue;

      final key = DateFormat('yyyy-MM-dd').format(date);
      shiftsByDate.putIfAbsent(key, () => <String>{}).add(shift);
    }

    return shiftsByDate.map((key, value) => MapEntry(key, value.length));
  }

  List<Map<String, dynamic>> rowsForTarget({
    required List<Map<String, dynamic>> rows,
    required DateTime date,
    required List<FeedingAnimalModel> animals,
    FeedingAnimalModel? selectedAnimal,
    FeedingPanModel? selectedPan,
  }) {
    final animalIds = <int>{};

    if (selectedAnimal != null) {
      animalIds.add(selectedAnimal.id);
    } else if (selectedPan != null) {
      animalIds.addAll(
        animals
            .where((item) => item.belongsToPan(selectedPan))
            .map((item) => item.id),
      );
    }

    if (animalIds.isEmpty) return <Map<String, dynamic>>[];
    return rows.where((row) {
      final rowAnimalId =
          int.tryParse((row['animal_id'] ?? '').toString()) ?? 0;
      return animalIds.contains(rowAnimalId) &&
          dateService.isSameDate(dateService.parseApiDate(row['date']), date);
    }).toList();
  }

  List<String> availableFeedingTimesForRows(List<Map<String, dynamic>> rows) {
    final hasMorning = rows.any(
      (row) => dateService.isFeedingTime(row['feeding_time'], 'Morning'),
    );
    final hasAfternoon = rows.any(
      (row) => dateService.isFeedingTime(row['feeding_time'], 'Afternoon'),
    );
    final hasEvening = rows.any(
      (row) => dateService.isFeedingTime(row['feeding_time'], 'Evening'),
    );
    final done = <String, bool>{
      'Morning': hasMorning || hasAfternoon,
      'Evening': hasEvening,
    };

    if (!done.values.any((value) => value)) {
      return <String>['Morning'];
    }

    var lastDoneIndex = -1;
    for (var index = 0; index < allFeedingTimes.length; index++) {
      if (done[allFeedingTimes[index]] == true) {
        lastDoneIndex = index;
      }
    }

    return allFeedingTimes
        .asMap()
        .entries
        .where((entry) => entry.key > lastDoneIndex)
        .map((entry) => entry.value)
        .toList();
  }
}
