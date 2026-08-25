class FeedingPanModel {
  final int id;
  final String name;

  FeedingPanModel({required this.id, required this.name});

  bool matches(FeedingPanModel other) {
    if (id > 0 && other.id > 0) {
      return id == other.id;
    }
    return name.trim().toLowerCase() == other.name.trim().toLowerCase();
  }
}
