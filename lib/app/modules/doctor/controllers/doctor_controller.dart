import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/api.dart';

class DoctorController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<DoctorModel> doctors = <DoctorModel>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  List<DoctorModel> get filteredDoctors {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return doctors;
    return doctors.where((doctor) => doctor.searchText.contains(query)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    loadDoctors();
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

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class DoctorModel {
  final String name;
  final String speciality;
  final String location;
  final String phone;
  final String experience;
  final bool availableToday;

  const DoctorModel({
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
