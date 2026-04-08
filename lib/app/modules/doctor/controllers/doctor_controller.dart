import 'dart:convert';

import 'package:flutter/material.dart';
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

  final Rxn<VetAnimalModel> selectedAnimal = Rxn<VetAnimalModel>();
  final TextEditingController concernController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

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
    await Future.wait([loadDoctors(), fetchAnimals()]);
    await fetchFarmerRequests();
  }

  Future<void> _loadFarmerData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    farmerName = await SessionService.getFarmerName();
    farmerPhone = await SessionService.getMobile();
    farmerProfile = await SessionService.getFarmerProfile();
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

  Future<void> fetchFarmerRequests() async {
    if (farmerId == 0 || doctors.isEmpty) {
      requests.clear();
      return;
    }

    try {
      isLoadingRequests.value = true;
      final collected = <VetRequestModel>[];

      for (final doctor in doctors) {
        if (doctor.id <= 0) continue;
        try {
          final response = await http.get(
            Uri.parse('${Api.doctorAppointments}/${doctor.id}'),
            headers: {'Accept': 'application/json'},
          );
          final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          if (response.statusCode == 200 && data['status'] == true) {
            final List list = data['data'] ?? [];
            for (final item in list) {
              final model = VetRequestModel.fromJson(
                item,
                fallbackDoctorName: doctor.name,
              );
              if (model.farmerId == farmerId) {
                collected.add(model);
              }
            }
          }
        } catch (_) {}
      }

      requests.assignAll(collected);
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> requestDoctorVisit(DoctorModel doctor) async {
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer session not found. Please login again.');
      return;
    }
    if (selectedAnimal.value == null) {
      Get.snackbar('Error', 'Please select an animal.');
      return;
    }
    if (concernController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter concern details.');
      return;
    }

    try {
      isSubmittingRequest.value = true;
      final payload = {
        'doctor_id': doctor.id.toString(),
        'farmer_id': farmerId.toString(),
        'animal_id': selectedAnimal.value!.id.toString(),
        'farmer_name': farmerName,
        'farmer_phone': farmerPhone,
        'animal_name': selectedAnimal.value!.animalName,
        'concern': concernController.text.trim(),
        'address': _farmerAddress(),
        'notes': notesController.text.trim(),
        'requested_at': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(Api.doctorAppointments),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        concernController.clear();
        notesController.clear();
        selectedAnimal.value = null;
        Get.back();
        await fetchFarmerRequests();
        Get.snackbar('Success', data['message']?.toString() ?? 'Request submitted successfully.');
      } else {
        Get.snackbar('Error', data['message']?.toString() ?? 'Failed to submit request.');
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

  @override
  void onClose() {
    concernController.dispose();
    notesController.dispose();
    searchController.dispose();
    super.onClose();
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

  VetAnimalModel({
    required this.id,
    required this.animalName,
    required this.tagNumber,
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
    );
  }
}

class VetRequestModel {
  final int id;
  final int doctorId;
  final int farmerId;
  final String doctorName;
  final String animalName;
  final String concern;
  final String status;
  final String requestedAt;
  final String scheduledAt;
  final String completedAt;
  final String charges;

  VetRequestModel({
    required this.id,
    required this.doctorId,
    required this.farmerId,
    required this.doctorName,
    required this.animalName,
    required this.concern,
    required this.status,
    required this.requestedAt,
    required this.scheduledAt,
    required this.completedAt,
    required this.charges,
  });

  DateTime get sortDate {
    final iso = requestedAt.trim().isNotEmpty ? requestedAt : scheduledAt;
    return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
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

    return VetRequestModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      doctorId: int.tryParse(json['doctor_id']?.toString() ?? '') ?? 0,
      farmerId: int.tryParse(json['farmer_id']?.toString() ?? '') ?? 0,
      doctorName: json['doctor_name']?.toString().trim().isNotEmpty == true
          ? json['doctor_name'].toString()
          : fallbackDoctorName,
      animalName: json['animal_name']?.toString() ?? '-',
      concern: json['concern']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'pending',
      requestedAt: json['requested_at']?.toString() ?? '',
      scheduledAt: json['scheduled_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString() ?? '',
      charges: chargeLabel,
    );
  }
}
