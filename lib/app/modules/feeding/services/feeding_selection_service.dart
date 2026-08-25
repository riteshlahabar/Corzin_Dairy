import '../models/feeding_models.dart';

class FeedingSelectionService {
  const FeedingSelectionService();

  List<FeedingPanModel> buildPansFromAnimals(
    Iterable<FeedingAnimalModel> animals,
  ) {
    final unique = <String, FeedingPanModel>{};
    for (final animal in animals) {
      final panName = animal.panName.trim();
      if (panName.isEmpty) continue;
      final key = animal.panId > 0
          ? 'id_${animal.panId}'
          : 'name_${panName.toLowerCase()}';
      unique.putIfAbsent(
        key,
        () => FeedingPanModel(id: animal.panId, name: panName),
      );
    }
    return unique.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<FeedingAnimalModel> animalsForPan({
    required Iterable<FeedingAnimalModel> animals,
    FeedingPanModel? pan,
  }) {
    if (pan == null) return animals.toList();
    return animals.where((animal) => animal.belongsToPan(pan)).toList();
  }
}
