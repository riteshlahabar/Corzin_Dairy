import 'feed_subtype_model.dart';

class FeedTypeModel {
  final int id;
  final String name;
  final String defaultUnit;
  final double packageQuantity;
  final List<FeedSubtypeModel> subtypes;

  FeedTypeModel({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.packageQuantity,
    required this.subtypes,
  });

  factory FeedTypeModel.fromJson(Map<String, dynamic> json) {
    final List list = json['subtypes'] is List
        ? (json['subtypes'] as List)
        : const [];
    return FeedTypeModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      defaultUnit: json['default_unit']?.toString() ?? 'Kg',
      packageQuantity:
          double.tryParse((json['package_quantity'] ?? '0').toString()) ?? 0,
      subtypes: list
          .map(
            (item) => FeedSubtypeModel.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}
