class PlanModel {
  const PlanModel({
    this.id = 0,
    required this.name,
    required this.price,
    required this.amount,
    required this.features,
    required this.highlighted,
    this.isFreePlan = false,
    this.isFreeUsed = false,
    this.isSelectable = true,
  });

  final int id;
  final String name;
  final String price;
  final double amount;
  final List<String> features;
  final bool highlighted;
  final bool isFreePlan;
  final bool isFreeUsed;
  final bool isSelectable;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['features'];
    final features = <String>[];
    if (featuresRaw is List) {
      for (final item in featuresRaw) {
        features.add(item.toString());
      }
    } else if (featuresRaw is String && featuresRaw.trim().isNotEmpty) {
      features.add(featuresRaw.trim());
    }

    final isHighlighted =
        json['highlighted'] == true || json['is_popular'] == true;
    final name = json['name']?.toString() ?? 'plan';
    final priceAmount = double.tryParse(json['price']?.toString() ?? '0') ?? 0;
    final priceLabel = json['price_label']?.toString().trim();

    return PlanModel(
      id:
          int.tryParse(
            json['id']?.toString() ??
                json['plan_id']?.toString() ??
                json['farmer_plan_id']?.toString() ??
                '0',
          ) ??
          0,
      name: name,
      price: (priceLabel?.isNotEmpty == true)
          ? priceLabel!
          : 'Rs ${priceAmount.toStringAsFixed(0)}',
      amount: priceAmount,
      features: features,
      highlighted: isHighlighted,
      isFreePlan: json['is_free_plan'] == true || priceAmount <= 0,
      isFreeUsed: json['is_free_used'] == true,
      isSelectable: json['is_selectable'] != false,
    );
  }
}
