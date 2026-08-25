part of '../controllers/health_controller.dart';

class ReagentRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<ReagentRecordsResult?> fetchReagentRecords(
    int farmerId, {
    void Function(ReagentRecordsResult records)? onCached,
    bool forceRefresh = false,
    bool summaryOnly = false,
  }) async {
    final uri = Uri.parse('${Api.healthReagent}/$farmerId').replace(
      queryParameters: summaryOnly ? {'summary_only': '1'} : null,
    );
    final data = await CachedApiService.instance.getMap(
      key: summaryOnly
          ? 'health_reagent_summary_$farmerId'
          : 'health_reagent_$farmerId',
      uri: uri,
      onCached: (cached) {
        if (cached['status'] != true) return;
        onCached?.call(_parseReagentRecords(cached));
      },
      forceRefresh: forceRefresh,
    );
    if (data == null || data['status'] != true) return null;
    return _parseReagentRecords(data);
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

  ReagentRecordsResult _parseReagentRecords(Map<String, dynamic> data) {
    final List list = data['data'] ?? [];
    return ReagentRecordsResult(
      balanceMl: double.tryParse((data['balance_ml'] ?? '0').toString()) ?? 0,
      usages: list.map((item) => ReagentUsageItem.fromJson(item)).toList(),
    );
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
