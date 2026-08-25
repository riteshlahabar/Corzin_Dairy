import 'feeding_pan_model.dart';

class FeedingAnimalModel {
  final int id;
  final String animalName;
  final String tagNumber;
  final int panId;
  final String panName;

  FeedingAnimalModel({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.panId,
    required this.panName,
  });

  String get displayName {
    final name = animalName.trim().isEmpty ? 'Unnamed Animal' : animalName;
    final tag = tagNumber.trim().isEmpty ? '' : ' - Tag $tagNumber';
    return '$name$tag';
  }

  bool belongsToPan(FeedingPanModel pan) {
    if (panId > 0 && pan.id > 0) {
      return panId == pan.id;
    }
    final animalPan = panName.trim().toLowerCase();
    final selectedPanName = pan.name.trim().toLowerCase();
    if (animalPan.isEmpty || selectedPanName.isEmpty) {
      return false;
    }
    return animalPan == selectedPanName;
  }

  factory FeedingAnimalModel.fromJson(Map<String, dynamic> json) {
    final panFromFlat = json['pan_name']?.toString() ?? '';
    final panFromNested = json['pan'] is Map
        ? ((json['pan'] as Map)['name']?.toString() ?? '')
        : '';
    return FeedingAnimalModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      panId: int.tryParse((json['pan_id'] ?? '').toString()) ?? 0,
      panName: panFromFlat.trim().isNotEmpty ? panFromFlat : panFromNested,
    );
  }
}
