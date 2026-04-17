import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';

class DoctorController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isLoadingRequests = false.obs;
  final RxBool isSubmittingRequest = false.obs;
  final RxBool isUpdatingRequestStatus = false.obs;

  final RxList<DoctorModel> doctors = <DoctorModel>[].obs;
  final RxList<VetAnimalModel> animals = <VetAnimalModel>[].obs;
  final RxList<VetRequestModel> requests = <VetRequestModel>[].obs;
  final RxList<DiseaseOption> diseases = <DiseaseOption>[].obs;

  final RxList<int> selectedDiseaseIds = <int>[].obs;
  final TextEditingController concernDescriptionController = TextEditingController();
  final TextEditingController diseaseDetailsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  Timer? _requestsPollingTimer;

  int farmerId = 0;
  String farmerName = '';
  String farmerPhone = '';
  Map<String, String> farmerProfile = const {};

  List<DoctorModel> get filteredDoctors {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return doctors;
    return doctors.where((doctor) => doctor.searchText.contains(query)).toList();
  }

  List<VetRequestModel> get sortedRequests {
    final copied = requests.toList();
    copied.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return copied;
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    initData();
  }

  Future<void> initData() async {
    await _loadFarmerData();
    await Future.wait([loadDoctors(), fetchAnimals(), fetchDiseases()]);
    await fetchFarmerRequests();
  }

  Future<void> _loadFarmerData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    if (farmerId <= 0) {
      farmerId = await SessionService.getFarmerId();
      if (farmerId > 0) {
        await prefs.setInt('farmer_id', farmerId);
      }
    }
    farmerName = await SessionService.getFarmerName();
    farmerPhone = await SessionService.getMobile();
    farmerProfile = await SessionService.getFarmerProfile();
    if (farmerId <= 0 && farmerPhone.trim().isNotEmpty) {
      await _loadFarmerIdFromProfileApi(farmerPhone.trim(), prefs);
    }
  }

  Future<void> _loadFarmerIdFromProfileApi(String mobile, SharedPreferences prefs) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200 || response.body.isEmpty) return;

      final data = jsonDecode(response.body);
      if (data is! Map || data['status'] != true) return;

      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};
      final idRaw = payload['id'];
      final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
      if (id <= 0) return;

      farmerId = id;
      await SessionService.saveFarmerId(id);
      await prefs.setInt('farmer_id', id);
    } catch (_) {}
  }

  Future<void> loadDoctors() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(Api.doctorList),
        headers: {'Accept': 'application/json'},
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        doctors.assignAll(
          list.map((item) => DoctorModel.fromJson(item)).toList(),
        );
      } else {
        doctors.clear();
      }
    } catch (_) {
      doctors.clear();
    } finally {
      isLoading.value = false;
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
        animals.assignAll(list.map((item) => VetAnimalModel.fromJson(item)).toList());
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    }
  }

  Future<void> fetchDiseases() async {
    try {
      final response = await http.get(
        Uri.parse(Api.doctorDiseases),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        diseases.assignAll(
          list.map((item) => DiseaseOption.fromJson(item)).where((e) => e.id > 0 && e.name.isNotEmpty).toList(),
        );
      } else {
        diseases.clear();
      }
    } catch (_) {
      diseases.clear();
    }
  }

  Future<void> fetchFarmerRequests() async {
    if (farmerId == 0) {
      final prefs = await SharedPreferences.getInstance();
      if (farmerPhone.trim().isNotEmpty) {
        await _loadFarmerIdFromProfileApi(farmerPhone.trim(), prefs);
      }
      if (farmerId == 0) {
        requests.clear();
        return;
      }
    }

    try {
      isLoadingRequests.value = true;
      Future<http.Response> getRequests() {
        return http.get(
          Uri.parse('${Api.doctorAppointmentsByFarmer}/$farmerId'),
          headers: {'Accept': 'application/json'},
        );
      }

      var response = await getRequests();
      var data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (!(response.statusCode == 200 && data['status'] == true) && farmerPhone.trim().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await _loadFarmerIdFromProfileApi(farmerPhone.trim(), prefs);
        if (farmerId > 0) {
          response = await getRequests();
          data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        }
      }

      if (response.statusCode == 200 && data['status'] == true) {
        final Map<int, String> doctorNameById = {
          for (final doctor in doctors) doctor.id: doctor.name,
        };

        final List list = data['data'] ?? [];
        requests.assignAll(
          list.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final doctorId = int.tryParse(map['doctor_id']?.toString() ?? '') ?? 0;
            return VetRequestModel.fromJson(
              map,
              fallbackDoctorName: doctorNameById[doctorId] ?? 'Doctor',
            );
          }).toList(),
        );
      } else {
        requests.clear();
      }
    } catch (_) {
      requests.clear();
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<(double?, double?)> _tryFarmerGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return (null, null);
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return (null, null);
      }
      final pos = await Geolocator.getCurrentPosition();
      return (pos.latitude, pos.longitude);
    } catch (_) {
      return (null, null);
    }
  }

  Future<void> requestDoctorVisit({
    required VetAnimalModel animal,
  }) async {
    if (farmerId == 0) {
      final prefs = await SharedPreferences.getInstance();
      if (farmerPhone.trim().isNotEmpty) {
        await _loadFarmerIdFromProfileApi(farmerPhone.trim(), prefs);
      }
    }

    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer session not found. Please login again.');
      return;
    }
    if (animal.id <= 0) {
      Get.snackbar('Error', 'Animal details not found. Please refresh and try again.');
      return;
    }
    if (selectedDiseaseIds.isEmpty) {
      Get.snackbar('Error', 'Please select at least one disease.');
      return;
    }

    final mainDesc = concernDescriptionController.text.trim();
    final details = diseaseDetailsController.text.trim();
    final selectedDiseaseNames = diseases
        .where((disease) => selectedDiseaseIds.contains(disease.id))
        .map((disease) => disease.name)
        .toList();

    final concern = mainDesc.isNotEmpty
        ? mainDesc
        : selectedDiseaseNames.isNotEmpty
            ? selectedDiseaseNames.join(', ')
            : 'General consultation';

    try {
      isSubmittingRequest.value = true;
      final gps = await _tryFarmerGps();
      final payload = <String, dynamic>{
        'farmer_id': farmerId.toString(),
        'animal_id': animal.id.toString(),
        'farmer_name': farmerName,
        'farmer_phone': farmerPhone,
        'animal_name': animal.animalName,
        'concern': concern,
        'disease_ids': selectedDiseaseIds.toList(),
        'disease_details': details,
        'address': _farmerAddress(),
        'notes': notesController.text.trim(),
        'requested_at': DateTime.now().toIso8601String(),
      };
      if (gps.$1 != null && gps.$2 != null) {
        payload['latitude'] = gps.$1;
        payload['longitude'] = gps.$2;
      }

      final response = await http.post(
        Uri.parse(Api.doctorAppointments),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        concernDescriptionController.clear();
        diseaseDetailsController.clear();
        notesController.clear();
        selectedDiseaseIds.clear();
        Get.back();
        await fetchFarmerRequests();
        Get.snackbar('Success', data['message']?.toString() ?? 'Appointment created successfully.');
      } else {
        Get.snackbar('Error', _extractApiMessage(data) ?? 'Failed to submit request.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmittingRequest.value = false;
    }
  }

  Future<void> updateFarmerApproval({
    required VetRequestModel request,
    required bool approved,
  }) async {
    try {
      isUpdatingRequestStatus.value = true;
      final response = await http.post(
        Uri.parse('${Api.doctorAppointments}/${request.id}/farmer-approval'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'status': approved ? 'approved' : 'rejected'}),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        await fetchFarmerRequests();
        Get.snackbar('Success', data['message']?.toString() ?? 'Appointment updated.');
      } else {
        Get.snackbar('Error', data['message']?.toString() ?? 'Failed to update appointment.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isUpdatingRequestStatus.value = false;
    }
  }

  String _farmerAddress() {
    final parts = <String>[
      farmerProfile['village'] ?? '',
      farmerProfile['city'] ?? '',
      farmerProfile['taluka'] ?? '',
      farmerProfile['district'] ?? '',
      farmerProfile['state'] ?? '',
      farmerProfile['pincode'] ?? '',
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  VetRequestModel? latestRequestForAnimal(int animalId) {
    final matched = requests.where((request) => request.animalId == animalId).toList();
    if (matched.isEmpty) return null;
    matched.sort((a, b) {
      final statusCompare = _statusPriority(b.status).compareTo(_statusPriority(a.status));
      if (statusCompare != 0) return statusCompare;

      final dateCompare = b.sortDate.compareTo(a.sortDate);
      if (dateCompare != 0) return dateCompare;

      return b.id.compareTo(a.id);
    });
    return matched.first;
  }

  int _statusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 6;
      case 'followup':
      case 'follow_up':
        return 7;
      case 'in_progress':
        return 5;
      case 'approved':
        return 4;
      case 'proposed':
        return 3;
      case 'pending':
        return 2;
      case 'declined':
      case 'cancelled':
      case 'rejected':
        return 0;
      default:
        return 1;
    }
  }

  VetRequestModel? findRequestById(int appointmentId) {
    for (final request in requests) {
      if (request.id == appointmentId) return request;
    }
    return null;
  }

  DoctorModel? findDoctorById(int doctorId) {
    for (final doctor in doctors) {
      if (doctor.id == doctorId) return doctor;
    }
    return null;
  }

  @override
  void onClose() {
    _requestsPollingTimer?.cancel();
    concernDescriptionController.dispose();
    diseaseDetailsController.dispose();
    notesController.dispose();
    searchController.dispose();
    super.onClose();
  }

  String? _extractApiMessage(dynamic payload) {
    if (payload is! Map) return null;
    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    if (message is Map) {
      final buffer = <String>[];
      for (final entry in message.entries) {
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            final text = item?.toString().trim() ?? '';
            if (text.isNotEmpty) buffer.add(text);
          }
        } else {
          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) buffer.add(text);
        }
      }
      if (buffer.isNotEmpty) return buffer.join('\n');
    }
    return null;
  }
}

class DoctorModel {
  final int id;
  final String name;
  final String speciality;
  final String location;
  final String phone;
  final String experience;
  final bool availableToday;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.speciality,
    required this.location,
    required this.phone,
    required this.experience,
    required this.availableToday,
  });

  String get searchText => [
        name,
        speciality,
        location,
        phone,
        experience,
      ].join(' ').toLowerCase();

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      speciality: json['speciality']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      availableToday:
          json['available_today'] == true ||
          json['available_today'].toString() == '1',
    );
  }
}

class VetAnimalModel {
  final int id;
  final String animalName;
  final String tagNumber;
  final String imageUrl;

  VetAnimalModel({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.imageUrl,
  });

  String get displayName {
    final name = animalName.trim().isEmpty ? 'Animal' : animalName;
    final tag = tagNumber.trim().isEmpty ? '' : ' - Tag $tagNumber';
    return '$name$tag';
  }

  factory VetAnimalModel.fromJson(Map<String, dynamic> json) {
    return VetAnimalModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      animalName: json['animal_name']?.toString() ?? '',
      tagNumber: json['tag_number']?.toString() ?? '',
      imageUrl: (json['image'] ?? json['image_url'] ?? json['animal_photo_url'] ?? '').toString(),
    );
  }
}

class DiseaseOption {
  final int id;
  final String name;
  final String description;

  const DiseaseOption({
    required this.id,
    required this.name,
    required this.description,
  });

  factory DiseaseOption.fromJson(Map<String, dynamic> json) {
    return DiseaseOption(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
    );
  }
}

class VetRequestModel {
  final int id;
  final String appointmentCode;
  final int doctorId;
  final int farmerId;
  final int animalId;
  final String doctorName;
  final String animalName;
  final String concern;
  final String status;
  final String requestedAt;
  final String scheduledAt;
  final String completedAt;
  final String nextFollowupDate;
  final String charges;
  final List<String> diseaseNames;
  final String diseaseDetails;
  final String visitOtp;
  final bool otpVerified;
  final String treatmentDetails;
  final String onsiteTreatment;
  final String notes;
  final String address;
  final double? destLatitude;
  final double? destLongitude;
  final double? doctorLiveLatitude;
  final double? doctorLiveLongitude;
  final String doctorLiveUpdatedAt;

  VetRequestModel({
    required this.id,
    required this.appointmentCode,
    required this.doctorId,
    required this.farmerId,
    required this.animalId,
    required this.doctorName,
    required this.animalName,
    required this.concern,
    required this.status,
    required this.requestedAt,
    required this.scheduledAt,
    required this.completedAt,
    required this.nextFollowupDate,
    required this.charges,
    required this.diseaseNames,
    required this.diseaseDetails,
    required this.visitOtp,
    required this.otpVerified,
    required this.treatmentDetails,
    required this.onsiteTreatment,
    required this.notes,
    required this.address,
    this.destLatitude,
    this.destLongitude,
    this.doctorLiveLatitude,
    this.doctorLiveLongitude,
    this.doctorLiveUpdatedAt = '',
  });

  bool get canTrackVisit {
    final s = status.toLowerCase();
    return ['approved', 'in_progress', 'followup', 'follow_up'].contains(s);
  }

  DateTime get sortDate {
    final iso = requestedAt.trim().isNotEmpty ? requestedAt : scheduledAt;
    return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String get displayAppointmentCode {
    final code = appointmentCode.trim();
    if (code.isNotEmpty) return code;
    return 'C/APP/${id.toString().padLeft(2, '0')}';
  }

  factory VetRequestModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackDoctorName,
  }) {
    final chargeRaw = json['charges'];
    String chargeLabel = '-';
    if (chargeRaw != null) {
      final parsed = double.tryParse(chargeRaw.toString());
      chargeLabel = parsed == null ? chargeRaw.toString() : 'Rs ${parsed.toStringAsFixed(2)}';
    }

    final diseaseList = <String>[];
    final diseasesRaw = json['diseases'];
    if (diseasesRaw is List) {
      for (final row in diseasesRaw) {
        if (row is Map && row['name'] != null) {
          final name = row['name'].toString().trim();
          if (name.isNotEmpty) diseaseList.add(name);
        }
      }
    }

    final otpVerifiedAt = (json['otp_verified_at'] ?? '').toString().trim();

    double? pDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return VetRequestModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      appointmentCode: json['appointment_code']?.toString() ?? '',
      doctorId: int.tryParse(json['doctor_id']?.toString() ?? '') ?? 0,
      farmerId: int.tryParse(json['farmer_id']?.toString() ?? '') ?? 0,
      animalId: int.tryParse(json['animal_id']?.toString() ?? '') ?? 0,
      doctorName: json['doctor_name']?.toString().trim().isNotEmpty == true
          ? json['doctor_name'].toString()
          : fallbackDoctorName,
      animalName: json['animal_name']?.toString() ?? '-',
      concern: json['concern']?.toString() ?? '-',
      status: json['effective_status']?.toString() ?? json['status']?.toString() ?? 'pending',
      requestedAt: json['requested_at']?.toString() ?? '',
      scheduledAt: json['scheduled_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString() ?? '',
      nextFollowupDate: json['next_followup_date']?.toString() ?? '',
      charges: chargeLabel,
      diseaseNames: diseaseList,
      diseaseDetails: json['disease_details']?.toString() ?? '',
      visitOtp: json['visit_otp']?.toString() ?? '',
      otpVerified: otpVerifiedAt.isNotEmpty,
      treatmentDetails: json['treatment_details']?.toString() ?? '',
      onsiteTreatment: json['onsite_treatment']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      destLatitude: pDouble(json['latitude'] ?? json['lat']),
      destLongitude: pDouble(json['longitude'] ?? json['lng']),
      doctorLiveLatitude: pDouble(json['doctor_live_latitude']),
      doctorLiveLongitude: pDouble(json['doctor_live_longitude']),
      doctorLiveUpdatedAt: json['doctor_live_updated_at']?.toString() ?? '',
    );
  }
}
