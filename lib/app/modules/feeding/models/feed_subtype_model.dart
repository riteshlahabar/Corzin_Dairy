class FeedSubtypeModel {
  final int id;
  final String name;

  FeedSubtypeModel({required this.id, required this.name});

  factory FeedSubtypeModel.fromJson(Map<String, dynamic> json) {
    return FeedSubtypeModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
