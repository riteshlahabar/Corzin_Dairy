import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

enum HealthSection { dmi, mastitis, vaccination }

class HealthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final Rx<HealthSection> selectedSection = HealthSection.dmi.obs;
  final RxList<HealthAnimalItem> animals = <HealthAnimalItem>[].obs;
  final RxList<HealthVaccineItem> vaccines = <HealthVaccineItem>[].obs;
  final RxList<MedicalRecordItem> medicalRecords = <MedicalRecordItem>[].obs;
  final RxList<MastitisRecordItem> mastitisRecords = <MastitisRecordItem>[].obs;
  final RxList<VaccinationRecordItem> vaccinationRecords = <VaccinationRecordItem>[].obs;
  final RxList<DmiRecordItem> dmiRecords = <DmiRecordItem>[].obs;
  final RxString dmiSearchQuery = ''.obs;
  final RxString dmiAnimalTypeFilter = 'all'.obs;
  final Rx<DateTime> dmiFromDate = DateTime.now().obs;
  final Rx<DateTime> dmiToDate = DateTime.now().obs;
  final RxString mastitisSearchQuery = ''.obs;
  final RxString mastitisResultFilter = 'positive'.obs;
  final Rxn<DateTime> mastitisFromDate = Rxn<DateTime>();
  final Rxn<DateTime> mastitisToDate = Rxn<DateTime>();
  final RxString vaccinationSearchQuery = ''.obs;
  final Rx<DateTime> vaccinationFromDate = DateTime.now().obs;
  final Rx<DateTime> vaccinationToDate = DateTime.now().obs;
  String lastSubmitMessage = '';

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await Future.wait([
      fetchAnimals(),
      fetchVaccines(),
      fetchMedicalRecords(),
      fetchMastitisRecords(),
      fetchVaccinationRecords(),
      fetchDmiRecords(),
    ]);
  }

  void setSection(HealthSection section) {
    if (selectedSection.value == section) return;
    selectedSection.value = section;
  }

  Future<void> refreshSelectedSection() async {
    switch (selectedSection.value) {
      case HealthSection.mastitis:
        await fetchMastitisRecords();
        break;
      case HealthSection.vaccination:
        await fetchVaccinationRecords();
        break;
      case HealthSection.dmi:
        await fetchDmiRecords();
        break;
    }
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) {
      animals.clear();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Api.animalList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animals.assignAll(
          list.map((item) => HealthAnimalItem.fromJson(item)).toList(),
        );
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    }
  }

  Future<void> fetchMedicalRecords() async {
    if (farmerId == 0) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.healthMedical}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        medicalRecords.assignAll(
          list.map((item) => MedicalRecordItem.fromJson(item)).toList(),
        );
      } else {
        medicalRecords.clear();
      }
    } catch (_) {
      medicalRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchVaccines() async {
    try {
      final response = await http.get(
        Uri.parse(Api.healthVaccines),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        final seenIds = <int>{};
        vaccines.assignAll(
          list
              .map((item) => HealthVaccineItem.fromJson(item))
              .where((item) => item.id > 0 && seenIds.add(item.id))
              .toList(),
        );
      } else {
        vaccines.clear();
      }
    } catch (_) {
      vaccines.clear();
    }
  }

  Future<void> fetchMastitisRecords() async {
    if (farmerId == 0) return;
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.healthMastitis}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        mastitisRecords.assignAll(
          list.map((item) => MastitisRecordItem.fromJson(item)).toList(),
        );
      } else {
        mastitisRecords.clear();
      }
    } catch (_) {
      mastitisRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchVaccinationRecords() async {
    if (farmerId == 0) {
      vaccinationRecords.clear();
      return;
    }

    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.healthVaccination}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        vaccinationRecords.assignAll(
          list.map((item) => VaccinationRecordItem.fromJson(item)).toList(),
        );
      } else {
        vaccinationRecords.clear();
      }
    } catch (_) {
      vaccinationRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDmiRecords() async {
    if (farmerId == 0) {
      dmiRecords.clear();
      return;
    }
    try {
      isLoading.value = true;
      final uri = Uri.parse('${Api.healthDmi}/$farmerId').replace(
        queryParameters: {
          'from_date': DateFormat('yyyy-MM-dd').format(dmiFromDate.value),
          'to_date': DateFormat('yyyy-MM-dd').format(dmiToDate.value),
        },
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        dmiRecords.assignAll(
          list.map((item) => DmiRecordItem.fromJson(item)).toList(),
        );
      } else {
        dmiRecords.clear();
      }
    } catch (_) {
      dmiRecords.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveMedical({
    required int animalId,
    required String medicineName,
    required String dose,
    required DateTime date,
    required String disease,
    String notes = '',
  }) async {
    return _submit(
      endpoint: Api.healthMedical,
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'medicine_name': medicineName,
        'dose': dose,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'disease': disease,
        'notes': notes,
      },
      successMessage: 'Medical record saved successfully',
      onSuccess: fetchMedicalRecords,
    );
  }

  Future<bool> saveMastitis({
    required int animalId,
    required String testResult,
    String notes = '',
  }) async {
    return _submit(
      endpoint: Api.healthMastitis,
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'test_result': testResult,
        'notes': notes,
      },
      successMessage: 'Mastitis record saved successfully',
      onSuccess: fetchMastitisRecords,
      showSuccessSnackbar: false,
    );
  }

  Future<bool> saveVaccination({
    required int animalId,
    required int vaccineId,
    required String doses,
    required DateTime vaccinationDate,
    String notes = '',
  }) async {
    return _submit(
      endpoint: Api.healthVaccination,
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'vaccine_id': vaccineId.toString(),
        'doses': doses,
        'vaccination_date': DateFormat('yyyy-MM-dd').format(vaccinationDate),
        'notes': notes,
      },
      successMessage: 'Vaccination record saved successfully',
      onSuccess: fetchVaccinationRecords,
      showSuccessSnackbar: false,
    );
  }

  Future<bool> updateMastitis({
    required int recordId,
    required int animalId,
    required String testResult,
    required String treatment,
    required String recoveryStatus,
    required DateTime date,
    String notes = '',
  }) async {
    return _submit(
      endpoint: '${Api.healthMastitisUpdate}/$recordId',
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'test_result': testResult,
        'treatment': treatment,
        'recovery_status': recoveryStatus,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'notes': notes,
      },
      successMessage: 'Mastitis record updated successfully',
      onSuccess: fetchMastitisRecords,
      showSuccessSnackbar: false,
    );
  }

  Future<bool> addMastitisTreatment({
  int? mastitisRecordId,
  required int animalId,
  required String treatment,
  required DateTime date,
  String notes = '',
}) async {
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

  return _submit(
    endpoint: Api.healthMastitisTreatment,
    payload: payload,
    successMessage: 'Treatment added successfully',
    onSuccess: fetchMastitisRecords,
    showSuccessSnackbar: false,
  );
}

 Future<bool> markMastitisRecovered({
  int? mastitisRecordId,
  required int animalId,
  required DateTime date,
}) async {
  final payload = {
    'farmer_id': farmerId.toString(),
    'animal_id': animalId.toString(),
    'date': DateFormat('yyyy-MM-dd').format(date),
  };

  if (mastitisRecordId != null && mastitisRecordId > 0) {
    payload['mastitis_record_id'] = mastitisRecordId.toString();
  }

  return _submit(
    endpoint: Api.healthMastitisRecover,
    payload: payload,
    successMessage: 'Animal marked as recovered',
    onSuccess: fetchMastitisRecords,
    showSuccessSnackbar: false,
  );
}

  List<MastitisRecordItem> get filteredMastitisRecords {
    final query = mastitisSearchQuery.value.trim().toLowerCase();
    final filter = mastitisResultFilter.value.trim().toLowerCase();

    return mastitisRecords.where((item) {
      final result = item.testResult.trim().toLowerCase();
      if (filter != 'all' && result != filter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        item.animalName,
        item.tagNumber,
        item.testResult,
        item.treatment,
        item.recoveryStatus,
        item.date,
        item.notes,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  List<MastitisGroupItem> get allMastitisGroups {
    final grouped = <int, List<MastitisRecordItem>>{};

    for (final item in mastitisRecords) {
      if (item.animalId <= 0) continue;

      final groupKey = item.caseId > 0 ? item.caseId : item.id;
      grouped.putIfAbsent(groupKey, () => <MastitisRecordItem>[]).add(item);
    }

    final groups = grouped.values.map((rows) {
      rows.sort((a, b) {
        final dateCompare =
            _parseMastitisDate(b.date).compareTo(_parseMastitisDate(a.date));
        if (dateCompare != 0) return dateCompare;
        return b.id.compareTo(a.id);
      });

      return MastitisGroupItem(records: rows);
    }).toList();

    groups.sort((a, b) {
      final dateCompare = _parseMastitisDate(b.latestDate)
          .compareTo(_parseMastitisDate(a.latestDate));
      if (dateCompare != 0) return dateCompare;
      return b.caseId.compareTo(a.caseId);
    });

    return groups;
  }

  List<MastitisGroupItem> get filteredMastitisGroups {
    final query = mastitisSearchQuery.value.trim().toLowerCase();
    final filter = mastitisResultFilter.value.trim().toLowerCase();
    final from = mastitisFromDate.value == null
        ? null
        : DateTime(
            mastitisFromDate.value!.year,
            mastitisFromDate.value!.month,
            mastitisFromDate.value!.day,
          );
    final to = mastitisToDate.value == null
        ? null
        : DateTime(
            mastitisToDate.value!.year,
            mastitisToDate.value!.month,
            mastitisToDate.value!.day,
          );

    return allMastitisGroups.where((group) {
      if (filter != 'all' && group.effectiveTestResult != filter) {
        return false;
      }

      if (from != null || to != null) {
        final hasDateInRange = group.records.any((row) {
          final parsed = _parseMastitisDate(row.date);
          final rowDate = DateTime(parsed.year, parsed.month, parsed.day);
          if (from != null && rowDate.isBefore(from)) {
            return false;
          }
          if (to != null && rowDate.isAfter(to)) {
            return false;
          }
          return true;
        });

        if (!hasDateInRange) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      return group.searchText.contains(query);
    }).toList();
  }

  void setMastitisDateRange({DateTime? from, DateTime? to}) {
    var nextFrom = from ?? mastitisFromDate.value;
    var nextTo = to ?? mastitisToDate.value;

    if (nextFrom != null) {
      nextFrom = DateTime(nextFrom.year, nextFrom.month, nextFrom.day);
    }
    if (nextTo != null) {
      nextTo = DateTime(nextTo.year, nextTo.month, nextTo.day);
    }

    if (nextFrom != null && nextTo != null && nextFrom.isAfter(nextTo)) {
      if (from != null) {
        nextTo = nextFrom;
      } else {
        nextFrom = nextTo;
      }
    }

    mastitisFromDate.value = nextFrom;
    mastitisToDate.value = nextTo;
  }

  List<HealthAnimalItem> get milkingAnimals {
    return animals.where((animal) => animal.isMilkingCow).toList();
  }

  Set<int> get activeMastitisAnimalIds {
    return allMastitisGroups
        .where(
          (group) =>
              group.effectiveTestResult == 'positive' &&
              group.recoveryStatus != 'recovered' &&
              group.recoveryStatus != 'recoverd',
        )
        .map((group) => group.animalId)
        .where((animalId) => animalId > 0)
        .toSet();
  }

  List<HealthAnimalItem> get availableMastitisAnimals {
    final activeIds = activeMastitisAnimalIds;
    final seenIds = <int>{};
    return milkingAnimals
        .where((animal) => animal.id > 0 && !activeIds.contains(animal.id))
        .where((animal) => seenIds.add(animal.id))
        .toList();
  }

  List<VaccinationRecordItem> get filteredVaccinationRecords {
    final query = vaccinationSearchQuery.value.trim().toLowerCase();
    final from = DateTime(
      vaccinationFromDate.value.year,
      vaccinationFromDate.value.month,
      vaccinationFromDate.value.day,
    );
    final to = DateTime(
      vaccinationToDate.value.year,
      vaccinationToDate.value.month,
      vaccinationToDate.value.day,
    );

    return vaccinationRecords.where((item) {
      final parsedDate = _parseDmiDate(item.date);
      if (parsedDate != null) {
        final rowDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        if (rowDate.isBefore(from) || rowDate.isAfter(to)) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      return item.searchText.contains(query);
    }).toList();
  }

  List<VaccinationGroupItem> get filteredVaccinationGroups {
    final grouped = <int, List<VaccinationRecordItem>>{};

    for (final item in filteredVaccinationRecords) {
      final key = item.animalId > 0 ? item.animalId : item.id;
      grouped.putIfAbsent(key, () => <VaccinationRecordItem>[]).add(item);
    }

    final groups = grouped.values
        .map((rows) {
          rows.sort((a, b) {
            final dateCompare = _parseMastitisDate(b.date).compareTo(_parseMastitisDate(a.date));
            if (dateCompare != 0) return dateCompare;
            return b.id.compareTo(a.id);
          });
          return VaccinationGroupItem(records: rows);
        })
        .toList();

    groups.sort((a, b) {
      final dateCompare = _parseMastitisDate(b.latestDate).compareTo(_parseMastitisDate(a.latestDate));
      if (dateCompare != 0) return dateCompare;
      return a.animalName.toLowerCase().compareTo(b.animalName.toLowerCase());
    });

    return groups;
  }

  List<DmiRecordItem> get filteredDmiRecords {
    final query = dmiSearchQuery.value.trim().toLowerCase();
    final selectedType = dmiAnimalTypeFilter.value.trim().toLowerCase();
    final from = DateTime(
      dmiFromDate.value.year,
      dmiFromDate.value.month,
      dmiFromDate.value.day,
    );
    final to = DateTime(
      dmiToDate.value.year,
      dmiToDate.value.month,
      dmiToDate.value.day,
    );

    return groupedDmiRecords.where((item) {
      if (selectedType != 'all' && !item.matchesAnimalTypeFilter(selectedType)) {
        return false;
      }

      final parsedDate = _parseDmiDate(item.date);
      if (parsedDate != null) {
        final rowDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
        if (rowDate.isBefore(from) || rowDate.isAfter(to)) {
          return false;
        }
      }

      if (query.isEmpty) {
        return true;
      }

      return item.searchText.contains(query);
    }).toList();
  }

  List<DmiRecordItem> get groupedDmiRecords {
    if (dmiRecords.isEmpty) {
      return const <DmiRecordItem>[];
    }

    final animalById = <int, HealthAnimalItem>{
      for (final animal in animals)
        if (animal.id > 0) animal.id: animal,
    };
    final grouped = <String, List<DmiRecordItem>>{};

    for (final item in dmiRecords) {
      final animal = animalById[item.animalId];
      final resolvedPanId = animal?.panId ?? item.panId;
      final resolvedPanName = animal?.panName.trim().isNotEmpty == true
          ? animal!.panName.trim()
          : item.panName.trim();
      final key = resolvedPanId > 0
          ? 'pan_${resolvedPanId}_${item.date}'
          : 'animal_${item.animalId}_${item.date}';

      grouped.putIfAbsent(key, () => <DmiRecordItem>[]).add(
        item.copyWith(
          panId: resolvedPanId,
          panName: resolvedPanName,
          animalTypeNames: item.animalTypeNames.isEmpty
              ? <String>[item.animalTypeName]
              : item.animalTypeNames,
          searchAliases: item.searchAliases.isEmpty
              ? <String>[
                  item.animalName,
                  item.tagNumber,
                  item.animalTypeName,
                  resolvedPanName,
                ]
              : item.searchAliases,
        ),
      );
    }

    final results = grouped.entries.map((entry) {
      final rows = entry.value;
      final first = rows.first;
      if (!first.isPanGroup) {
        return first.copyWith(
          animalCount: first.animalCount > 0 ? first.animalCount : 1,
        );
      }

      final panName = first.panName.trim().isNotEmpty
          ? first.panName.trim()
          : 'PAN #${first.panId}';
      final animalIds = rows
          .map((row) => row.animalId)
          .where((id) => id > 0)
          .toSet();
      final typeNames = rows
          .expand(
            (row) => row.animalTypeNames.isEmpty
                ? <String>[row.animalTypeName]
                : row.animalTypeNames,
          )
          .map((type) => type.trim())
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final aliases = rows
          .expand((row) => <String>[
                row.animalName,
                row.tagNumber,
                ...row.searchAliases,
              ])
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty && text != '-')
          .toSet()
          .toList();
      final bodyWeight = rows.fold<double>(0, (sum, row) => sum + row.bodyWeightValue);
      final totalMilk = rows.fold<double>(0, (sum, row) => sum + row.totalMilkValue);
      final requiredDmi = rows.fold<double>(0, (sum, row) => sum + row.requiredDmiValue);
      final actualDmi = rows.fold<double>(0, (sum, row) => sum + row.actualDmiValue);
      final difference = double.parse((actualDmi - requiredDmi).toStringAsFixed(2));
      final alertStatus = difference.abs() <= 0.5
          ? 'Balanced'
          : (difference < 0 ? 'Low' : 'High');
      final notes = rows
          .map((row) => row.notes.trim())
          .where((note) => note.isNotEmpty)
          .toSet()
          .join(' | ');

      return DmiRecordItem(
        animalId: 0,
        animalName: panName,
        tagNumber: 'PAN',
        animalTypeName: typeNames.length == 1 ? typeNames.first : 'Mixed',
        dmiType: 'Pan Wise',
        bodyWeight: bodyWeight.toStringAsFixed(2),
        totalMilk: totalMilk.toStringAsFixed(2),
        requiredDmi: requiredDmi.toStringAsFixed(2),
        actualDmi: actualDmi.toStringAsFixed(2),
        alertStatus: alertStatus,
        date: first.date,
        notes: notes,
        panId: first.panId,
        panName: panName,
        animalCount: animalIds.isEmpty ? rows.length : animalIds.length,
        animalTypeNames: typeNames,
        searchAliases: aliases,
      );
    }).toList();

    results.sort((a, b) {
      final aDate = _parseDmiDate(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _parseDmiDate(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateCompare = bDate.compareTo(aDate);
      if (dateCompare != 0) return dateCompare;
      return a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
    });

    return results;
  }

  List<String> get dmiAnimalTypes {
    final types = groupedDmiRecords
        .expand((item) => item.animalTypeNames)
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty && type != '-')
        .toSet()
        .toList();
    types.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return types;
  }

  Future<void> setDmiDateRange({DateTime? from, DateTime? to}) async {
    var nextFrom = from ?? dmiFromDate.value;
    var nextTo = to ?? dmiToDate.value;

    nextFrom = DateTime(nextFrom.year, nextFrom.month, nextFrom.day);
    nextTo = DateTime(nextTo.year, nextTo.month, nextTo.day);

    if (nextFrom.isAfter(nextTo)) {
      nextTo = nextFrom;
    }

    dmiFromDate.value = nextFrom;
    dmiToDate.value = nextTo;
    await fetchDmiRecords();
  }

  Future<void> setVaccinationDateRange({DateTime? from, DateTime? to}) async {
    var nextFrom = from ?? vaccinationFromDate.value;
    var nextTo = to ?? vaccinationToDate.value;

    nextFrom = DateTime(nextFrom.year, nextFrom.month, nextFrom.day);
    nextTo = DateTime(nextTo.year, nextTo.month, nextTo.day);

    if (nextFrom.isAfter(nextTo)) {
      nextTo = nextFrom;
    }

    vaccinationFromDate.value = nextFrom;
    vaccinationToDate.value = nextTo;
  }

  DateTime? _parseDmiDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd').parseStrict(text);
      } catch (_) {
        return null;
      }
    }
  }

  DateTime _parseMastitisDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd').parseStrict(text);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
  }

  Future<bool> saveDmi({
    required int animalId,
    required double bodyWeight,
    required double totalMilk,
    required double actualDmi,
    required DateTime date,
    String notes = '',
  }) async {
    return _submit(
      endpoint: Api.healthDmi,
      payload: {
        'farmer_id': farmerId.toString(),
        'animal_id': animalId.toString(),
        'body_weight': bodyWeight.toString(),
        'total_milk': totalMilk.toString(),
        'actual_dmi': actualDmi.toString(),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'notes': notes,
      },
      successMessage: 'DMI record saved successfully',
      onSuccess: fetchDmiRecords,
    );
  }

  Future<bool> _submit({
    required String endpoint,
    required Map<String, String> payload,
    required String successMessage,
    required Future<void> Function() onSuccess,
    bool showSuccessSnackbar = true,
  }) async {
    try {
      isSubmitting.value = true;
      lastSubmitMessage = '';
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (_isSuccessResponse(response, data)) {
        await onSuccess();
        lastSubmitMessage = _extractMessage(data, fallback: successMessage);
        if (showSuccessSnackbar) {
          Get.snackbar(
            'Success',
            lastSubmitMessage,
            duration: const Duration(seconds: 4),
          );
        }
        return true;
      }
      lastSubmitMessage = _extractMessage(
        data,
        fallback: 'failed_to_save_record'.tr,
      );
      Get.snackbar('error'.tr, lastSubmitMessage);
      return false;
    } catch (e) {
      lastSubmitMessage = e.toString();
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _isSuccessResponse(http.Response response, dynamic data) {
    final codeOk = response.statusCode >= 200 && response.statusCode < 300;
    if (!codeOk) return false;
    if (data is! Map) return true;
    final status = data['status'];
    final success = data['success'];
    final statusOk =
        status == true ||
        status == 1 ||
        status?.toString().toLowerCase() == 'true';
    final successOk =
        success == true ||
        success == 1 ||
        success?.toString().toLowerCase() == 'true';
    return statusOk || successOk || data.isEmpty;
  }

  String _extractMessage(dynamic data, {required String fallback}) {
    if (data is! Map) return fallback;
    final message = data['message'];
    if (message == null) return fallback;
    if (message is String && message.trim().isNotEmpty) return message.trim();
    if (message is Map) {
      final first = message.values.firstWhere(
        (value) => value != null && value.toString().trim().isNotEmpty,
        orElse: () => '',
      );
      final text = first.toString().trim();
      return text.isEmpty ? fallback : text;
    }
    final text = message.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double calculateRequiredDmi(double bodyWeight, double totalMilk) {
    if (totalMilk <= 0) {
      return bodyWeight * 0.025;
    }
    return (bodyWeight * 0.02) + (totalMilk * 0.33);
  }

  bool isMilkingByMilk(double totalMilk) => totalMilk > 0;
}

class HealthAnimalItem {
  final int id;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;
  final int panId;
  final String panName;

  HealthAnimalItem({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
    required this.panId,
    required this.panName,
  });

  String get displayName =>
      '${animalName.trim().isEmpty ? 'Animal' : animalName} - Tag ${tagNumber.trim().isEmpty ? '-' : tagNumber}';

  bool get isMilkingCow {
    final type = animalTypeName.trim().toLowerCase();
    if (type.isEmpty) return false;
    return type.contains('milking') &&
        !type.contains('non') &&
        !type.contains('dry') &&
        !type.contains('calf') &&
        !type.contains('heifer');
  }

  factory HealthAnimalItem.fromJson(Map<String, dynamic> json) {
    return HealthAnimalItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      panId: int.tryParse((json['pan_id'] ?? '0').toString()) ?? 0,
      panName: json['pan_name']?.toString() ?? '',
    );
  }
}

class MedicalRecordItem {
  final String animalName;
  final String tagNumber;
  final String medicineName;
  final String dose;
  final String date;
  final String disease;
  final String notes;

  MedicalRecordItem({
    required this.animalName,
    required this.tagNumber,
    required this.medicineName,
    required this.dose,
    required this.date,
    required this.disease,
    required this.notes,
  });

  factory MedicalRecordItem.fromJson(Map<String, dynamic> json) {
    return MedicalRecordItem(
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      medicineName: json['medicine_name']?.toString() ?? '',
      dose: json['dose']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      disease: json['disease']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class HealthVaccineItem {
  final int id;
  final String name;
  final String description;

  HealthVaccineItem({
    required this.id,
    required this.name,
    required this.description,
  });

  factory HealthVaccineItem.fromJson(Map<String, dynamic> json) {
    return HealthVaccineItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class MastitisRecordItem {
  final int id;
  final int caseId;
  final int animalId;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;
  final String testResult;
  final String treatment;
  final String recoveryStatus;
  final String date;
  final String notes;

  MastitisRecordItem({
    required this.id,
    required this.caseId,
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
    required this.testResult,
    required this.treatment,
    required this.recoveryStatus,
    required this.date,
    required this.notes,
  });

  factory MastitisRecordItem.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    return MastitisRecordItem(
      id: id,
      caseId: int.tryParse(json['case_id']?.toString() ?? '') ?? id,
      animalId: int.tryParse(json['animal_id']?.toString() ?? '0') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      testResult: json['test_result']?.toString() ?? '',
      treatment: json['treatment']?.toString() ?? '',
      recoveryStatus: json['recovery_status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class MastitisGroupItem {
  final List<MastitisRecordItem> records;

  MastitisGroupItem({required this.records});

  MastitisRecordItem get caseRecord {
    return records.firstWhere(
      (row) => row.id == row.caseId,
      orElse: () => records.first,
    );
  }

  MastitisRecordItem get latest {
    final rows = [...records];
    rows.sort((a, b) {
      final dateCompare = _dateSort(b.date, a.date);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
    });
    return rows.first;
  }

  int get caseId => caseRecord.caseId > 0 ? caseRecord.caseId : caseRecord.id;
  int get animalId => caseRecord.animalId;
  String get animalName => caseRecord.animalName;
  String get tagNumber => caseRecord.tagNumber;
  String get animalTypeName => caseRecord.animalTypeName;
  String get testResult => _normalize(caseRecord.testResult);
  String get positiveFoundDate => caseRecord.date;
  String get effectiveTestResult {
    if (recoveryStatus == 'recovered' || recoveryStatus == 'recoverd') {
      return 'negative';
    }

    final latestResult = _normalize(latest.testResult);
    if (latestResult.isNotEmpty) {
      return latestResult;
    }

    return testResult;
  }
  String get latestDate => latest.date;

  String get recoveryStatus {
    final caseStatus = _normalize(caseRecord.recoveryStatus);

    if (caseStatus == 'recovered' || caseStatus == 'recoverd') {
      return caseStatus;
    }

    final hasRecoveredRow = records.any((row) {
      return _normalize(row.recoveryStatus) == 'recovered' ||
          _normalize(row.recoveryStatus) == 'recoverd' ||
          _normalize(row.testResult) == 'negative' ||
          row.treatment.trim().toLowerCase() == 'recovered' ||
          row.treatment.trim().toLowerCase() == 'recoverd';
    });

    return hasRecoveredRow ? 'recovered' : caseStatus;
  }

  List<MastitisRecordItem> get treatments {
    final rows = records.where((row) {
      final treatment = row.treatment.trim();
      if (treatment.isEmpty) return false;

      final lower = treatment.toLowerCase();
      if (lower == 'recovered' || lower == 'recoverd') return false;

      return true;
    }).toList();

    rows.sort((a, b) {
      final dateCompare = _dateSort(b.date, a.date);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
    });
    return rows;
  }

  List<MastitisRecordItem> get recoveredRows {
    final rows = records.where((row) {
      return _normalize(row.recoveryStatus) == 'recovered' ||
          _normalize(row.recoveryStatus) == 'recoverd' ||
          _normalize(row.testResult) == 'negative' ||
          row.treatment.trim().toLowerCase() == 'recovered' ||
          row.treatment.trim().toLowerCase() == 'recoverd';
    }).toList();

    rows.sort((a, b) {
      final dateCompare = _dateSort(b.date, a.date);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
    });
    return rows;
  }

  String get searchText {
    return [
      animalName,
      tagNumber,
      animalTypeName,
      testResult,
      recoveryStatus,
      ...records.expand((row) => [row.date, row.treatment, row.notes]),
    ].join(' ').toLowerCase();
  }

  static String _normalize(String value) => value.trim().toLowerCase();

  static int _dateSort(String a, String b) {
    DateTime parse(String value) {
      final text = value.trim();
      if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

      try {
        return DateFormat('dd/MM/yyyy').parseStrict(text);
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd').parseStrict(text);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
    }

    return parse(a).compareTo(parse(b));
  }
}

class DmiRecordItem {
  final int animalId;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;
  final String dmiType;
  final String bodyWeight;
  final String totalMilk;
  final String requiredDmi;
  final String actualDmi;
  final String alertStatus;
  final String date;
  final String notes;
  final int panId;
  final String panName;
  final int animalCount;
  final List<String> animalTypeNames;
  final List<String> searchAliases;

  DmiRecordItem({
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
    required this.dmiType,
    required this.bodyWeight,
    required this.totalMilk,
    required this.requiredDmi,
    required this.actualDmi,
    required this.alertStatus,
    required this.date,
    required this.notes,
    this.panId = 0,
    this.panName = '',
    this.animalCount = 1,
    this.animalTypeNames = const <String>[],
    this.searchAliases = const <String>[],
  });

  factory DmiRecordItem.fromJson(Map<String, dynamic> json) {
    return DmiRecordItem(
      animalId: int.tryParse(json['animal_id']?.toString() ?? '0') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      dmiType: json['dmi_type']?.toString() ?? '',
      bodyWeight: json['body_weight']?.toString() ?? '',
      totalMilk: json['total_milk']?.toString() ?? '',
      requiredDmi: json['required_dmi']?.toString() ?? '',
      actualDmi: json['actual_dmi']?.toString() ?? '',
      alertStatus: json['alert_status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      panId: int.tryParse((json['pan_id'] ?? '0').toString()) ?? 0,
      panName: json['pan_name']?.toString() ?? '',
      animalTypeNames: [
        json['animal_type_name']?.toString() ?? '',
      ].where((value) => value.trim().isNotEmpty).toList(),
      searchAliases: [
        json['animal_name']?.toString() ?? '',
        json['tag_number']?.toString() ?? '',
        json['animal_type_name']?.toString() ?? '',
        json['pan_name']?.toString() ?? '',
      ].where((value) => value.trim().isNotEmpty).toList(),
    );
  }

  DmiRecordItem copyWith({
    int? animalId,
    String? animalName,
    String? tagNumber,
    String? animalTypeName,
    String? dmiType,
    String? bodyWeight,
    String? totalMilk,
    String? requiredDmi,
    String? actualDmi,
    String? alertStatus,
    String? date,
    String? notes,
    int? panId,
    String? panName,
    int? animalCount,
    List<String>? animalTypeNames,
    List<String>? searchAliases,
  }) {
    return DmiRecordItem(
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      tagNumber: tagNumber ?? this.tagNumber,
      animalTypeName: animalTypeName ?? this.animalTypeName,
      dmiType: dmiType ?? this.dmiType,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      totalMilk: totalMilk ?? this.totalMilk,
      requiredDmi: requiredDmi ?? this.requiredDmi,
      actualDmi: actualDmi ?? this.actualDmi,
      alertStatus: alertStatus ?? this.alertStatus,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      panId: panId ?? this.panId,
      panName: panName ?? this.panName,
      animalCount: animalCount ?? this.animalCount,
      animalTypeNames: animalTypeNames ?? this.animalTypeNames,
      searchAliases: searchAliases ?? this.searchAliases,
    );
  }

  bool get isPanGroup => panId > 0;

  double get bodyWeightValue => double.tryParse(bodyWeight.trim()) ?? 0;

  double get totalMilkValue => double.tryParse(totalMilk.trim()) ?? 0;

  double get requiredDmiValue => double.tryParse(requiredDmi.trim()) ?? 0;

  double get actualDmiValue => double.tryParse(actualDmi.trim()) ?? 0;

  String get displayTitle {
    if (isPanGroup) {
      final label = panName.trim().isNotEmpty ? panName.trim() : animalName.trim();
      return animalCount > 1 ? '$label ($animalCount ${'animals'.tr})' : label;
    }
    return '${animalName.trim().isEmpty ? 'animal'.tr : animalName} - ${'tag'.tr} ${tagNumber.trim().isEmpty ? '-' : tagNumber}';
  }

  String get displaySubtitle {
    if (isPanGroup || dmiType.trim().toLowerCase() == 'pan wise') {
      return 'pan_wise'.tr;
    }
    return dmiType.isEmpty ? '-' : dmiType;
  }

  bool matchesAnimalTypeFilter(String selectedType) {
    final normalized = selectedType.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') return true;
    return animalTypeNames.any((type) => type.trim().toLowerCase() == normalized) ||
        animalTypeName.trim().toLowerCase() == normalized;
  }

  String get searchText {
    return [
      animalName,
      tagNumber,
      animalTypeName,
      dmiType,
      date,
      panName,
      ...animalTypeNames,
      ...searchAliases,
    ].join(' ').toLowerCase();
  }

  bool get isNonMilking {
    if (isPanGroup) {
      final types = animalTypeNames
          .map((type) => type.trim().toLowerCase())
          .where((type) => type.isNotEmpty)
          .toList();
      if (types.isNotEmpty) {
        return types.every(_isNonMilkingType);
      }
    }
    return _isNonMilkingType('$dmiType $animalTypeName'.toLowerCase());
  }

  bool _isNonMilkingType(String text) {
    return text.contains('non') ||
        text.contains('dry') ||
        text.contains('heifer') ||
        text.contains('calf') ||
        text.contains('bull');
  }
}

class VaccinationRecordItem {
  final int id;
  final int animalId;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;
  final int panId;
  final String panName;
  final int vaccineId;
  final String vaccineName;
  final String doses;
  final String date;
  final String notes;

  VaccinationRecordItem({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
    required this.panId,
    required this.panName,
    required this.vaccineId,
    required this.vaccineName,
    required this.doses,
    required this.date,
    required this.notes,
  });

  factory VaccinationRecordItem.fromJson(Map<String, dynamic> json) {
    return VaccinationRecordItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      animalId: int.tryParse(json['animal_id']?.toString() ?? '0') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      panId: int.tryParse((json['pan_id'] ?? '0').toString()) ?? 0,
      panName: json['pan_name']?.toString() ?? '',
      vaccineId: int.tryParse(json['vaccine_id']?.toString() ?? '0') ?? 0,
      vaccineName: json['vaccine_name']?.toString() ?? '',
      doses: json['doses']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  String get displayTitle =>
      '${animalName.trim().isEmpty ? 'animal'.tr : animalName} - ${'tag'.tr} ${tagNumber.trim().isEmpty ? '-' : tagNumber}';

  String get searchText {
    return [
      animalName,
      tagNumber,
      animalTypeName,
      panName,
      vaccineName,
      doses,
      date,
      notes,
    ].join(' ').toLowerCase();
  }
}

class VaccinationGroupItem {
  final List<VaccinationRecordItem> records;

  VaccinationGroupItem({required this.records});

  VaccinationRecordItem get latest {
    final rows = [...records];
    rows.sort((a, b) {
      final dateCompare = _dateSort(b.date, a.date);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
    });
    return rows.first;
  }

  int get animalId => latest.animalId;
  String get animalName => latest.animalName;
  String get tagNumber => latest.tagNumber;
  String get animalTypeName => latest.animalTypeName;
  String get panName => latest.panName;
  String get latestDate => latest.date;

  String get displayTitle =>
      '${animalName.trim().isEmpty ? 'animal'.tr : animalName} - ${'tag'.tr} ${tagNumber.trim().isEmpty ? '-' : tagNumber}';

  String get displaySubtitle => animalTypeName.trim().isEmpty ? '-' : animalTypeName;

  static int _dateSort(String a, String b) {
    DateTime parse(String value) {
      final text = value.trim();
      if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

      try {
        return DateFormat('dd/MM/yyyy').parseStrict(text);
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd').parseStrict(text);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
    }

    return parse(a).compareTo(parse(b));
  }
}
