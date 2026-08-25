class FeedDietSubtypeDetail {
  final int subtypeId;
  final int feedTypeId;
  final String feedTypeName;
  final String name;
  final double quantity;
  final double dmPercent;
  final double dryMatterQuantity;

  FeedDietSubtypeDetail({
    required this.subtypeId,
    required this.feedTypeId,
    required this.feedTypeName,
    required this.name,
    required this.quantity,
    required this.dmPercent,
    required this.dryMatterQuantity,
  });

  factory FeedDietSubtypeDetail.fromJson(Map<String, dynamic> json) {
    final qty = double.tryParse((json['quantity'] ?? '0').toString()) ?? 0;
    final dm = double.tryParse((json['dm_percent'] ?? '0').toString()) ?? 0;
    return FeedDietSubtypeDetail(
      subtypeId: int.tryParse((json['subtype_id'] ?? '').toString()) ?? 0,
      feedTypeId: int.tryParse((json['feed_type_id'] ?? '').toString()) ?? 0,
      feedTypeName: (json['feed_type_name'] ?? json['feed_type'] ?? '')
          .toString(),
      name: (json['name'] ?? '').toString(),
      quantity: qty,
      dmPercent: dm,
      dryMatterQuantity:
          double.tryParse((json['dry_matter_quantity'] ?? '').toString()) ??
          ((qty * dm) / 100),
    );
  }
}
