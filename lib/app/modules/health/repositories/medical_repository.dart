part of '../controllers/health_controller.dart';

class MedicalRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<List<HealthAnimalItem>?> fetchAnimals(
    int farmerId, {
    void Function(List<HealthAnimalItem> records)? onCached,
    bool forceRefresh = false,
  }) async {
    final data = await CachedApiService.instance.getMap(
      key: 'animal_list_$farmerId',
      uri: Uri.parse('${Api.animalList}/$farmerId'),
      onCached: (cached) {
        if (cached['status'] != true) return;
        onCached?.call(_parseAnimals(cached['data']));
      },
      forceRefresh: forceRefresh,
    );
    if (data == null || data['status'] != true) return null;
    return _parseAnimals(data['data']);
  }

  Future<List<MedicalRecordItem>?> fetchMedicalRecords(int farmerId) async {
    final response = await _api.get(Uri.parse('${Api.healthMedical}/$farmerId'));
    if (!response.hasTrueStatus) return null;
    final List list = response.data['data'] ?? [];
    return list.map((item) => MedicalRecordItem.fromJson(item)).toList();
  }

  Future<HealthApiResponse> saveMedical({
    required int farmerId,
    required int animalId,
    required String medicineName,
    required String dose,
    required DateTime date,
    required String disease,
    required String notes,
  }) {
    return _api.post(Api.healthMedical, {
      'farmer_id': farmerId.toString(),
      'animal_id': animalId.toString(),
      'medicine_name': medicineName,
      'dose': dose,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'disease': disease,
      'notes': notes,
    });
  }

  List<HealthAnimalItem> _parseAnimals(dynamic raw) {
    final list = raw is List ? raw : const [];
    return list
        .whereType<Map>()
        .map((item) => HealthAnimalItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}
