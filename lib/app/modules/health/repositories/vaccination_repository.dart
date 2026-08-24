part of '../controllers/health_controller.dart';

class VaccinationRepository {
  final HealthApiService _api = HealthApiService.instance;

  Future<List<HealthVaccineItem>?> fetchVaccines() async {
    final response = await _api.get(Uri.parse(Api.healthVaccines));
    if (!response.hasTrueStatus) return null;
    final List list = response.data['data'] ?? [];
    final seenIds = <int>{};
    return list
        .map((item) => HealthVaccineItem.fromJson(item))
        .where((item) => item.id > 0 && seenIds.add(item.id))
        .toList();
  }

  Future<List<VaccinationRecordItem>?> fetchVaccinationRecords(int farmerId) async {
    final response = await _api.get(Uri.parse('${Api.healthVaccination}/$farmerId'));
    if (!response.hasTrueStatus) return null;
    final List list = response.data['data'] ?? [];
    return list.map((item) => VaccinationRecordItem.fromJson(item)).toList();
  }

  Future<HealthApiResponse> saveVaccination({
    required int farmerId,
    required int animalId,
    required int vaccineId,
    required String doses,
    required DateTime vaccinationDate,
    required String notes,
  }) {
    return _api.post(Api.healthVaccination, {
      'farmer_id': farmerId.toString(),
      'animal_id': animalId.toString(),
      'vaccine_id': vaccineId.toString(),
      'doses': doses,
      'vaccination_date': DateFormat('yyyy-MM-dd').format(vaccinationDate),
      'notes': notes,
    });
  }
}
