part of '../controllers/health_controller.dart';

class MastitisRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<List<MastitisRecordItem>?> fetchMastitisRecords({
    required int farmerId,
    void Function(List<MastitisRecordItem> records)? onCached,
    bool forceRefresh = false,
  }) async {
    final uri = Uri.parse('${Api.healthMastitis}/$farmerId');
    final data = await CachedApiService.instance.getMap(
      key: 'health_mastitis_$farmerId',
      uri: uri,
      onCached: (cached) {
        if (cached['status'] != true) return;
        onCached?.call(_parseMastitisRecords(cached['data']));
      },
      forceRefresh: forceRefresh,
    );
    if (data == null || data['status'] != true) return null;
    return _parseMastitisRecords(data['data']);
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

  List<MastitisRecordItem> _parseMastitisRecords(dynamic raw) {
    final list = raw is List ? raw : const [];
    return list
        .whereType<Map>()
        .map((item) => MastitisRecordItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}
