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
  final FocusNode dairyNameFocus = FocusNode();
  final FocusNode contactFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode cityFocus = FocusNode();
  final FocusNode pincodeFocus = FocusNode();

  final RxBool isPageLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLocationLoading = false.obs;
  final RxList<DairyModel> dairies = <DairyModel>[].obs;
  final RxList<String> states = <String>[].obs;
  final RxList<String> districts = <String>[].obs;
  final RxList<String> talukas = <String>[].obs;
  final RxString searchQuery = ''.obs;
  int _stateRequestToken = 0;
  int _districtRequestToken = 0;

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
    await Future.wait([
      fetchDairies(),
      _loadLocationCascade(),
    ]);
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
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return;
    }

    final selectedState = stateController.text.trim();
    final selectedDistrict = districtController.text.trim();
    final selectedTaluka = talukaController.text.trim();
    final mobile = contactController.text.trim();
    final pin = pincodeController.text.trim();

    if (selectedState.isEmpty ||
        selectedDistrict.isEmpty ||
        selectedTaluka.isEmpty) {
      Get.snackbar('error'.tr, 'please_select_state_district_subdistrict'.tr);
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      Get.snackbar('error'.tr, 'mobile_10_digits'.tr);
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      Get.snackbar('error'.tr, 'pincode_6_digits'.tr);
      return;
    }

    try {
      isSubmitting.value = true;
      final payload = {
        'farmer_id': farmerId.toString(),
        'dairy_name': dairyNameController.text.trim(),
        'gst_no': gstNoController.text.trim(),
        'contact_number': mobile,
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'taluka': selectedTaluka,
        'district': selectedDistrict,
        'state': selectedState,
        'pincode': pin,
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
        final successMessage = data['message']?.toString() ?? 'dairy_added_successfully'.tr;
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
            Get.snackbar('success'.tr, successMessage);
          });
          return;
        }

        Get.offAllNamed(Routes.HOME);
        Future.delayed(const Duration(milliseconds: 120), () {
          Get.snackbar('success'.tr, successMessage);
        });
      } else {
        Get.snackbar(
          'error'.tr,
          data['message']?.toString() ?? 'failed_add_dairy'.tr,
        );
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
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

  Future<void> _loadLocationCascade() async {
    isLocationLoading.value = true;
    try {
      final stateList = await fetchLocationStates();
      states.assignAll(_uniqueLocationValues(stateList));
      if (!states.contains(stateController.text.trim())) {
        stateController.text = states.contains('Maharashtra')
            ? 'Maharashtra'
            : (states.isNotEmpty ? states.first : '');
      }
      if (stateController.text.trim().isNotEmpty) {
        await onStateChanged(stateController.text.trim());
      }
    } catch (_) {
      states.clear();
      districts.clear();
      talukas.clear();
    } finally {
      isLocationLoading.value = false;
    }
  }

  Future<void> onStateChanged(String value) async {
    final selected = value.trim();
    if (selected.isEmpty) return;

    final token = ++_stateRequestToken;
    _districtRequestToken++;

    stateController.text = selected;
    districtController.clear();
    talukaController.clear();
    districts.clear();
    talukas.clear();

    try {
      final districtList = await fetchLocationDistricts(selected);
      if (token != _stateRequestToken || stateController.text.trim() != selected) {
        return;
      }
      districts.assignAll(_uniqueLocationValues(districtList));
    } catch (_) {}
  }

  Future<void> onDistrictChanged(String value) async {
    final selectedState = stateController.text.trim();
    final selectedDistrict = value.trim();
    if (selectedState.isEmpty || selectedDistrict.isEmpty) return;

    final token = ++_districtRequestToken;
    districtController.text = selectedDistrict;
    talukaController.clear();
    talukas.clear();

    try {
      final talukaList = await fetchLocationTalukas(
        stateValue: selectedState,
        districtValue: selectedDistrict,
      );
      if (token != _districtRequestToken) return;
      if (stateController.text.trim() != selectedState) return;
      if (districtController.text.trim() != selectedDistrict) return;
      talukas.assignAll(_uniqueLocationValues(talukaList));
    } catch (_) {}
  }

  void onTalukaChanged(String value) {
    final selected = value.trim();
    if (selected.isEmpty) return;
    talukaController.text = selected;
  }

  Future<List<String>> fetchLocationStates() async {
    final response = await http.get(
      Uri.parse('${Api.baseUrl}/doctor/locations/states'),
      headers: {'Accept': 'application/json'},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
  }

  Future<List<String>> fetchLocationDistricts(String stateValue) async {
    final uri = Uri.parse('${Api.baseUrl}/doctor/locations/districts').replace(
      queryParameters: {'state': stateValue},
    );
    final response = await http.get(uri, headers: {'Accept': 'application/json'});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
  }

  Future<List<String>> fetchLocationTalukas({
    required String stateValue,
    required String districtValue,
  }) async {
    final uri = Uri.parse('${Api.baseUrl}/doctor/locations/talukas').replace(
      queryParameters: {'state': stateValue, 'district': districtValue},
    );
    final response = await http.get(uri, headers: {'Accept': 'application/json'});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
  }

  List<String> _uniqueLocationValues(List<String> values) {
    final unique = <String, String>{};
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      unique.putIfAbsent(value.toLowerCase(), () => value);
    }
    return unique.values.toList(growable: false);
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
    dairyNameFocus.dispose();
    contactFocus.dispose();
    addressFocus.dispose();
    cityFocus.dispose();
    pincodeFocus.dispose();
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
