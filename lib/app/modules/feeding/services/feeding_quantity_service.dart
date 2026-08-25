import '../models/feeding_models.dart';

class FeedingQuantityService {
  const FeedingQuantityService();

  String formatDistributedValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Map<int, List<Map<String, dynamic>>> distributeSubtypePayloadAcrossAnimals(
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
      final splits = distributeAmountAcrossAnimals(totalQuantity, panAnimals);
      for (final animal in panAnimals) {
        final splitQuantity = splits[animal.id] ?? 0;
        if (splitQuantity <= 0) continue;
        distributed[animal.id]!.add({
          if (item['subtype_id'] != null) 'subtype_id': item['subtype_id'],
          if (item['feed_type_id'] != null)
            'feed_type_id': item['feed_type_id'],
          if (item['feed_type_name'] != null)
            'feed_type_name': item['feed_type_name'],
          'name': item['name'],
          'quantity': splitQuantity,
          if (item['dm_percent'] != null) 'dm_percent': item['dm_percent'],
        });
      }
    }

    return distributed;
  }

  Map<int, double> distributeFeedingAcrossAnimals({
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

  Map<int, double> distributeAmountAcrossAnimals(
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

  double sumSubtypeQuantity(List<Map<String, dynamic>> payload) {
    var total = 0.0;
    for (final item in payload) {
      total += double.tryParse(item['quantity'].toString()) ?? 0;
    }
    return double.parse(total.toStringAsFixed(2));
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

    var allocated = allocations.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
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

  int _toCents(double value) => (value * 100).round();

  double _fromCents(int cents) =>
      double.parse((cents / 100).toStringAsFixed(2));
}
