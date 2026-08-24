part of '../controllers/health_controller.dart';

class MedicalRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<List<HealthAnimalItem>?> fetchAnimals(int farmerId) async {
    final response = await _api.get(Uri.parse('${Api.animalList}/$farmerId'));
    if (!response.hasTrueStatus) return null;
    final List list = response.data['data'] ?? [];
    return list.map((item) => HealthAnimalItem.fromJson(item)).toList();
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
}
