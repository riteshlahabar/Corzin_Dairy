part of '../controllers/health_controller.dart';

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

class ReagentUsageItem {
  final int id;
  final int animalId;
  final String animalName;
  final String tagNumber;
  final double quantityMl;
  final double balanceAfterMl;
  final String date;
  final String notes;

  ReagentUsageItem({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.quantityMl,
    required this.balanceAfterMl,
    required this.date,
    required this.notes,
  });

  factory ReagentUsageItem.fromJson(Map<String, dynamic> json) {
    return ReagentUsageItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      animalId: int.tryParse(json['animal_id']?.toString() ?? '0') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      quantityMl: double.tryParse((json['quantity_ml'] ?? '0').toString()) ?? 0,
      balanceAfterMl:
          double.tryParse((json['balance_after_ml'] ?? '0').toString()) ?? 0,
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
      quantityMl.toStringAsFixed(2),
      balanceAfterMl.toStringAsFixed(2),
      date,
      notes,
    ].join(' ').toLowerCase();
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
