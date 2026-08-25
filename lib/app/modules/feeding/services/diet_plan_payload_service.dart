import '../models/feeding_models.dart';

class DietPlanPayloadService {
  const DietPlanPayloadService();

  List<Map<String, dynamic>> collectSubtypePayload(List<DietFeedBlock> blocks) {
    final combinedSubtypePayload = <Map<String, dynamic>>[];
    for (final block in blocks) {
      final selectedType = block.selectedFeedType;
      if (selectedType == null) continue;
      final subtypes = block.selectedSubtypePayload();
      for (final subtype in subtypes) {
        combinedSubtypePayload.add({
          'feed_type_id': selectedType.id,
          'feed_type_name': selectedType.name,
          'feed_unit': block.unit,
          ...subtype,
        });
      }
    }
    return combinedSubtypePayload;
  }
}
