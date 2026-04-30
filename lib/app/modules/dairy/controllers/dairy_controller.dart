import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';
import '../../../routes/app_pages.dart';

class DairyController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dairyNameController = TextEditingController();
  final TextEditingController gstNoController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController talukaController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<DairyModel> dairies = <DairyModel>[].obs;
  final RxString searchQuery = ''.obs;

  int farmerId = 0;
  bool openedFromMilkFlow = false;

  List<DairyModel> get filteredDairies {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return dairies;
    return dairies.where((dairy) => dairy.searchText.contains(query)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _readArguments();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    initData();
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args is Map) {
      openedFromMilkFlow = args['opened_from_milk'] == true || args['from']?.toString() == 'milk';
    }
  }

  Future<void> initData() async {
    await loadFarmerId();
    await fetchDairies();
  }

  Future<void> loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> fetchDairies() async {
    if (farmerId == 0) {
      dairies.clear();
      return;
    }

    try {
      isPageLoading.value = true;
      final response = await http.get(
        Uri.parse('${Api.dairyList}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        dairies.assignAll(
          list.map((item) => DairyModel.fromJson(item)).toList(),
        );
      } else {
        dairies.clear();
      }
    } catch (_) {
      dairies.clear();
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> submitDairy() async {
    if (!formKey.currentState!.validate()) return;
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer ID not found. Please login again.');
      return;
    }

    try {
      isSubmitting.value = true;
      final payload = {
        'farmer_id': farmerId.toString(),
        'dairy_name': dairyNameController.text.trim(),
        'gst_no': gstNoController.text.trim(),
        'contact_number': contactController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'taluka': talukaController.text.trim(),
        'district': districtController.text.trim(),
        'state': stateController.text.trim(),
        'pincode': pincodeController.text.trim(),
      };

      final response = await http.post(
        Uri.parse(Api.addDairy),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        final successMessage = data['message']?.toString() ?? 'Dairy added successfully';
        final createdDairyId = _extractCreatedDairyId(data);
        clearForm();
        await fetchDairies();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }

        if (openedFromMilkFlow) {
          if (Get.currentRoute == Routes.DAIRY) {
            Get.back(result: {'dairy_added': true, 'dairy_id': createdDairyId});
          } else {
            Get.back(result: {'dairy_added': true, 'dairy_id': createdDairyId});
          }
          Future.delayed(const Duration(milliseconds: 120), () {
            Get.snackbar('Success', successMessage);
          });
          return;
        }

        Get.offAllNamed(Routes.HOME);
        Future.delayed(const Duration(milliseconds: 120), () {
          Get.snackbar('Success', successMessage);
        });
      } else {
        Get.snackbar(
          'Error',
          data['message']?.toString() ?? 'Failed to add dairy',
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  int? _extractCreatedDairyId(dynamic data) {
    if (data is! Map) return null;

    final direct = int.tryParse((data['id'] ?? '').toString());
    if (direct != null && direct > 0) {
      return direct;
    }

    final payload = data['data'];
    if (payload is Map) {
      final fromPayload = int.tryParse((payload['id'] ?? '').toString());
      if (fromPayload != null && fromPayload > 0) {
        return fromPayload;
      }
    }

    return null;
  }

  void clearForm() {
    dairyNameController.clear();
    gstNoController.clear();
    contactController.clear();
    addressController.clear();
    cityController.clear();
    talukaController.clear();
    districtController.clear();
    stateController.clear();
    pincodeController.clear();
  }

  @override
  void onClose() {
    searchController.dispose();
    dairyNameController.dispose();
    gstNoController.dispose();
    contactController.dispose();
    addressController.dispose();
    cityController.dispose();
    talukaController.dispose();
    districtController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.onClose();
  }
}

class DairyModel {
  final int id;
  final String dairyName;
  final String farmerName;
  final String gstNo;
  final String contactNumber;
  final String address;
  final String city;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final bool isActive;

  DairyModel({
    required this.id,
    required this.dairyName,
    required this.farmerName,
    required this.gstNo,
    required this.contactNumber,
    required this.address,
    required this.city,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
    required this.isActive,
  });

  String get searchText => [
    dairyName,
    farmerName,
    gstNo,
    contactNumber,
    address,
    city,
    taluka,
    district,
    state,
    pincode,
  ].join(' ').toLowerCase();

  factory DairyModel.fromJson(Map<String, dynamic> json) {
    return DairyModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      dairyName: json['dairy_name']?.toString() ?? '',
      farmerName: json['farmer_name']?.toString() ?? '',
      gstNo: json['gst_no']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      taluka: json['taluka']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      isActive: json['is_active'] == true || json['is_active'].toString() == '1',
    );
  }
}
