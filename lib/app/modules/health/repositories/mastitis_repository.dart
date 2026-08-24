part of '../controllers/health_controller.dart';

class MastitisRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<List<MastitisRecordItem>?> fetchMastitisRecords(int farmerId) async {
    final response = await _api.get(Uri.parse('${Api.healthMastitis}/$farmerId'));
    if (!response.hasTrueStatus) return null;
    final List list = response.data['data'] ?? [];
    return list.map((item) => MastitisRecordItem.fromJson(item)).toList();
  }

  Future<HealthApiResponse> saveMastitis({
    required int farmerId,
    required int animalId,
    required String testResult,
    required String notes,
  }) {
    return _api.post(Api.healthMastitis, {
      'farmer_id': farmerId.toString(),
      'animal_id': animalId.toString(),
      'test_result': testResult,
      'notes': notes,
    });
  }

  Future<HealthApiResponse> updateMastitis({
    required int farmerId,
    required int recordId,
    required int animalId,
    required String testResult,
    required String treatment,
    required String recoveryStatus,
    required DateTime date,
    required String notes,
  }) {
    return _api.post('${Api.healthMastitisUpdate}/$recordId', {
      'farmer_id': farmerId.toString(),
      'animal_id': animalId.toString(),
      'test_result': testResult,
      'treatment': treatment,
      'recovery_status': recoveryStatus,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'notes': notes,
    });
  }

  Future<HealthApiResponse> addTreatment({
    required int farmerId,
    int? mastitisRecordId,
    required int animalId,
    required String treatment,
    required DateTime date,
    required String notes,
  }) {
    final payload = {
      'farmer_id': farmerId.toString(),
      'animal_id': animalId.toString(),
      'treatment': treatment,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'notes': notes,
    };

    if (mastitisRecordId != null && mastitisRecordId > 0) {
      payload['mastitis_record_id'] = mastitisRecordId.toString();
    }

    return _api.post(Api.healthMastitisTreatment, payload);
  }

  Future<HealthApiResponse> markRecovered({
    required int farmerId,
    int? mastitisRecordId,
    required int animalId,
    required DateTime date,
  }) {
    final payload = {
      'farmer_id': farmerId.toString(),
      'animal_id': animalId.toString(),
      'date': DateFormat('yyyy-MM-dd').format(date),
    };

    if (mastitisRecordId != null && mastitisRecordId > 0) {
      payload['mastitis_record_id'] = mastitisRecordId.toString();
    }

    return _api.post(Api.healthMastitisRecover, payload);
  }
}
