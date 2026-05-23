class PregnancyRecordModel {
  final int id;
  final int farmerId;
  final int animalId;
  final String animalName;
  final String tagNumber;
  final String animalTypeName;
  final int pregnancyNo;
  final int serviceNo;
  final String heatDate;
  final String aiDate;
  final String serviceType;
  final String bullName;
  final String semenNo;
  final String doctorName;
  final String pregnancyCheckDueDate;
  final String pregnancyCheckDate;
  final String pregnancyResult;
  final String expectedCalvingDate;
  final String dryOffDate;
  final String calvingDate;
  final String status;
  final int calfAnimalId;
  final String calfAnimalName;
  final String notes;
  final bool isCurrent;
  final int? remainingDays;

  const PregnancyRecordModel({
    required this.id,
    required this.farmerId,
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.animalTypeName,
    required this.pregnancyNo,
    required this.serviceNo,
    required this.heatDate,
    required this.aiDate,
    required this.serviceType,
    required this.bullName,
    required this.semenNo,
    required this.doctorName,
    required this.pregnancyCheckDueDate,
    required this.pregnancyCheckDate,
    required this.pregnancyResult,
    required this.expectedCalvingDate,
    required this.dryOffDate,
    required this.calvingDate,
    required this.status,
    required this.calfAnimalId,
    required this.calfAnimalName,
    required this.notes,
    required this.isCurrent,
    required this.remainingDays,
  });

  factory PregnancyRecordModel.fromJson(Map<String, dynamic> json) {
    return PregnancyRecordModel(
      id: _asInt(json['id']),
      farmerId: _asInt(json['farmer_id']),
      animalId: _asInt(json['animal_id']),
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
      pregnancyNo: _asInt(json['pregnancy_no'], fallback: 1),
      serviceNo: _asInt(json['service_no'], fallback: 1),
      heatDate: json['heat_date']?.toString() ?? '',
      aiDate: json['ai_date']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? 'ai',
      bullName: json['bull_name']?.toString() ?? '',
      semenNo: json['semen_no']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      pregnancyCheckDueDate:
          json['pregnancy_check_due_date']?.toString() ?? '',
      pregnancyCheckDate: json['pregnancy_check_date']?.toString() ?? '',
      pregnancyResult: json['pregnancy_result']?.toString() ?? 'pending',
      expectedCalvingDate: json['expected_calving_date']?.toString() ?? '',
      dryOffDate: json['dry_off_date']?.toString() ?? '',
      calvingDate: json['calving_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'served',
      calfAnimalId: _asInt(json['calf_animal_id']),
      calfAnimalName: json['calf_animal_name']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      isCurrent:
          json['is_current'] == true || json['is_current']?.toString() == '1',
      remainingDays: json['remaining_days'] == null
          ? null
          : int.tryParse(json['remaining_days'].toString()),
    );
  }

  String get cowLabel {
    if (animalName.trim().isEmpty && tagNumber.trim().isEmpty) return '-';
    if (tagNumber.trim().isEmpty) return animalName;
    if (animalName.trim().isEmpty) return tagNumber;
    return '$animalName ($tagNumber)';
  }

  String get searchText => [
        animalName,
        tagNumber,
        animalTypeName,
        pregnancyNo,
        serviceNo,
        aiDate,
        pregnancyCheckDueDate,
        expectedCalvingDate,
        pregnancyResult,
        status,
        doctorName,
        bullName,
        semenNo,
        notes,
      ].join(' ').toLowerCase();

  static int _asInt(dynamic value, {int fallback = 0}) {
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class PregnancyAnimalOption {
  final int id;
  final String name;
  final String tagNumber;
  final String animalTypeName;

  const PregnancyAnimalOption({
    required this.id,
    required this.name,
    required this.tagNumber,
    required this.animalTypeName,
  });

  factory PregnancyAnimalOption.fromJson(Map<String, dynamic> json) {
    return PregnancyAnimalOption(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      animalTypeName: json['animal_type_name']?.toString() ?? '',
    );
  }

  String get label {
    final base = name.trim().isEmpty ? 'Animal' : name.trim();
    return tagNumber.trim().isEmpty ? base : '$base ($tagNumber)';
  }
}
