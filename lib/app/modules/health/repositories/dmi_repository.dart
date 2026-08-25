part of '../controllers/health_controller.dart';

class DmiRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<List<DmiRecordItem>?> fetchDmiRecords({
    required int farmerId,
    required DateTime fromDate,
    required DateTime toDate,
    void Function(List<DmiRecordItem> records)? onCached,
    bool forceRefresh = false,
  }) async {
    final from = DateFormat('yyyy-MM-dd').format(fromDate);
    final to = DateFormat('yyyy-MM-dd').format(toDate);
    final uri = Uri.parse('${Api.healthDmi}/$farmerId').replace(
      queryParameters: {
        'from_date': from,
        'to_date': to,
      },
    );
    final data = await CachedApiService.instance.getMap(
      key: 'health_dmi_${farmerId}_${from}_$to',
      uri: uri,
      onCached: (cached) {
        if (cached['status'] != true) return;
        onCached?.call(_parseDmiRecords(cached['data']));
      },
      forceRefresh: forceRefresh,
    );
    if (data == null || data['status'] != true) return null;
    return _parseDmiRecords(data['data']);
  }

  Future<HealthApiResponse> saveDmi({
    required int farmerId,
    required int animalId,
    required double bodyWeight,
    required double totalMilk,
    required double actualDmi,
    required DateTime date,
    required String notes,
  }) {
    return _api.post(Api.healthDmi, {
      'farmer_id': farmerId.toString(),
      'animal_id': animalId.toString(),
      'body_weight': bodyWeight.toString(),
      'total_milk': totalMilk.toString(),
      'actual_dmi': actualDmi.toString(),
      'date': DateFormat('yyyy-MM-dd').format(date),
      'notes': notes,
    });
  }

  double calculateRequiredDmi(double bodyWeight, double totalMilk) {
    if (totalMilk <= 0) {
      return bodyWeight * 0.025;
    }
    return (bodyWeight * 0.02) + (totalMilk * 0.33);
  }

  List<DmiRecordItem> _parseDmiRecords(dynamic raw) {
    final list = raw is List ? raw : const [];
    return list
        .whereType<Map>()
        .map((item) => DmiRecordItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}
