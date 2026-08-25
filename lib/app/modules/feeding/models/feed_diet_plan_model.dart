import 'feed_diet_subtype_detail.dart';

class FeedDietPlanModel {
  final int id;
  final int animalId;
  final int panId;
  final String animalName;
  final String tagNumber;
  final String dietPlanName;
  final int feedTypeId;
  final String feedType;
  final String referenceDate;
  final double bodyWeight;
  final double milkProduction;
  final double actualDmi;
  final double targetDmi;
  final String unit;
  final int daysCount;
  final int daysRemaining;
  final double planQuantity;
  final double consumedQuantity;
  final double remainingQuantity;
  final double planDryMatterQuantity;
  final double remainingDryMatterQuantity;
  final double dmiGap;
  final List<FeedDietSubtypeDetail> subtypeDetails;

  FeedDietPlanModel({
    required this.id,
    required this.animalId,
    required this.panId,
    required this.animalName,
    required this.tagNumber,
    required this.dietPlanName,
    required this.feedTypeId,
    required this.feedType,
    required this.referenceDate,
    required this.bodyWeight,
    required this.milkProduction,
    required this.actualDmi,
    required this.targetDmi,
    required this.unit,
    required this.daysCount,
    required this.daysRemaining,
    required this.planQuantity,
    required this.consumedQuantity,
    required this.remainingQuantity,
    required this.planDryMatterQuantity,
    required this.remainingDryMatterQuantity,
    required this.dmiGap,
    required this.subtypeDetails,
  });

  String get displayLabel {
    final planName = dietPlanName.trim();
    final title = planName.isNotEmpty
        ? planName
        : (feedType.trim().isEmpty ? 'Diet Plan' : feedType.trim());
    return '$title | ${planQuantity.toStringAsFixed(2)} $unit';
  }

  factory FeedDietPlanModel.fromJson(Map<String, dynamic> json) {
    final rawSubtypes = json['subtype_details'] is List
        ? json['subtype_details'] as List
        : const [];
    return FeedDietPlanModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      animalId: int.tryParse((json['animal_id'] ?? '').toString()) ?? 0,
      panId: int.tryParse((json['pan_id'] ?? '').toString()) ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      dietPlanName: (json['diet_plan_name'] ?? json['plan_name'] ?? '')
          .toString(),
      feedTypeId: int.tryParse((json['feed_type_id'] ?? '').toString()) ?? 0,
      feedType: (json['feed_type'] ?? '').toString(),
      referenceDate: (json['reference_date'] ?? '').toString(),
      bodyWeight: double.tryParse((json['body_weight'] ?? '0').toString()) ?? 0,
      milkProduction:
          double.tryParse((json['milk_production'] ?? '0').toString()) ?? 0,
      actualDmi: double.tryParse((json['actual_dmi'] ?? '0').toString()) ?? 0,
      targetDmi: double.tryParse((json['target_dmi'] ?? '0').toString()) ?? 0,
      unit: (json['unit'] ?? 'Kg').toString(),
      daysCount: int.tryParse((json['days_count'] ?? '').toString()) ?? 0,
      daysRemaining:
          int.tryParse((json['days_remaining'] ?? '').toString()) ?? 0,
      planQuantity:
          double.tryParse((json['plan_quantity'] ?? '0').toString()) ?? 0,
      consumedQuantity:
          double.tryParse((json['consumed_quantity'] ?? '0').toString()) ?? 0,
      remainingQuantity:
          double.tryParse((json['remaining_quantity'] ?? '0').toString()) ?? 0,
      planDryMatterQuantity:
          double.tryParse(
            (json['plan_dry_matter_quantity'] ?? '0').toString(),
          ) ??
          0,
      remainingDryMatterQuantity:
          double.tryParse(
            (json['remaining_dry_matter_quantity'] ?? '0').toString(),
          ) ??
          0,
      dmiGap: double.tryParse((json['dmi_gap'] ?? '0').toString()) ?? 0,
      subtypeDetails: rawSubtypes
          .whereType<Map>()
          .map(
            (item) =>
                FeedDietSubtypeDetail.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}
