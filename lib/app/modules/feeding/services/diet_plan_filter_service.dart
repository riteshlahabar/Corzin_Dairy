import '../models/feeding_models.dart';

class DietPlanFilterService {
  const DietPlanFilterService();

  List<FeedDietPlanModel> filterPlans({
    required List<FeedDietPlanModel> plans,
    required List<FeedingPanModel> pans,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return plans;

    return plans.where((plan) {
      final owner = searchableOwnerLabel(plan: plan, pans: pans);
      final subtypeText = plan.subtypeDetails
          .map((detail) => '${detail.feedTypeName} ${detail.name}')
          .join(' ')
          .toLowerCase();
      final haystack = <String>[
        plan.dietPlanName,
        plan.feedType,
        plan.unit,
        plan.tagNumber,
        plan.animalName,
        owner,
        subtypeText,
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  String searchableOwnerLabel({
    required FeedDietPlanModel plan,
    required List<FeedingPanModel> pans,
  }) {
    if (plan.panId > 0) {
      for (final pan in pans) {
        if (pan.id == plan.panId) {
          return pan.name.trim();
        }
      }
      return 'pan ${plan.panId}';
    }
    return '${plan.animalName} ${plan.tagNumber}';
  }
}
