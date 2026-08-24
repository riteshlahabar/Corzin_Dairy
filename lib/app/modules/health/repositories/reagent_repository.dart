part of '../controllers/health_controller.dart';

class ReagentRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<ReagentRecordsResult?> fetchReagentRecords(int farmerId) async {
    final response = await _api.get(Uri.parse('${Api.healthReagent}/$farmerId'));
    if (!response.hasTrueStatus) return null;
    final List list = response.data['data'] ?? [];
    return ReagentRecordsResult(
      balanceMl: double.tryParse((response.data['balance_ml'] ?? '0').toString()) ?? 0,
      usages: list.map((item) => ReagentUsageItem.fromJson(item)).toList(),
    );
  }

  Future<HealthApiResponse> addReagent({
    required int farmerId,
    required double quantityMl,
  }) {
    return _api.post(Api.healthReagent, {
      'farmer_id': farmerId.toString(),
      'quantity_ml': quantityMl.toStringAsFixed(2),
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });
  }
}

class ReagentRecordsResult {
  const ReagentRecordsResult({
    required this.balanceMl,
    required this.usages,
  });

  final double balanceMl;
  final List<ReagentUsageItem> usages;
}
