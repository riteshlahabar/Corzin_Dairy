part of '../controllers/health_controller.dart';

class DmiRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<List<DmiRecordItem>?> fetchDmiRecords({
    required int farmerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final uri = Uri.parse('${Api.healthDmi}/$farmerId').replace(
      queryParameters: {
        'from_date': DateFormat('yyyy-MM-dd').format(fromDate),
        'to_date': DateFormat('yyyy-MM-dd').format(toDate),
      },
    );
    final response = await _api.get(uri);
    if (!response.hasTrueStatus) return null;
    final List list = response.data['data'] ?? [];
    return list.map((item) => DmiRecordItem.fromJson(item)).toList();
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
}
