import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../../../core/widget/bottom_navigation_bar.dart';

class FarmerDetailsController extends GetxController {
  late String lang;
  String mobile = "";
  final farmerName = "".obs;

  final firstName = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  final village = TextEditingController();
  final city = TextEditingController();
  final taluka = TextEditingController();
  final district = TextEditingController();
  final state = TextEditingController();
  final pincode = TextEditingController();
  final Rxn<XFile> selectedPhoto = Rxn<XFile>();

  final isLocationLoading = false.obs;
  final states = <String>[].obs;
  final districts = <String>[].obs;
  final talukas = <String>[].obs;
  int _stateRequestToken = 0;
  int _districtRequestToken = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    state.text = "Maharashtra";

    if (Get.arguments != null) {
      lang = Get.arguments["lang"] ?? "en";
      mobile = Get.arguments["mobile"] ?? "";
    } else {
      lang = "en";
      mobile = "";
    }

    loadFarmerName();
    _loadLocationCascade();
  }

  void loadFarmerName() async {
    farmerName.value = await SessionService.getFarmerName();
  }

  Future<void> pickFarmerPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      selectedPhoto.value = image;
    }
  }

  Future<void> _loadLocationCascade() async {
    isLocationLoading.value = true;
    try {
      final stateList = await fetchLocationStates();
      states.assignAll(_uniqueLocationValues(stateList));
      if (!states.contains(state.text.trim())) {
        state.text = states.contains("Maharashtra")
            ? "Maharashtra"
            : (states.isNotEmpty ? states.first : "Maharashtra");
      }
      await onStateChanged(state.text.trim());
    } catch (_) {
      if (states.isEmpty) {
        states.assignAll(["Maharashtra"]);
      }
      state.text = "Maharashtra";
    } finally {
      isLocationLoading.value = false;
    }
  }

  Future<void> onStateChanged(String value) async {
    final selected = value.trim();
    if (selected.isEmpty) return;
    final token = ++_stateRequestToken;
    _districtRequestToken++;

    state.text = selected;
    district.clear();
    taluka.clear();
    city.clear();
    districts.clear();
    talukas.clear();

    try {
      final districtList = await fetchLocationDistricts(selected);
      if (token != _stateRequestToken || state.text.trim() != selected) return;
      districts.assignAll(_uniqueLocationValues(districtList));
    } catch (_) {}
  }

  Future<void> onDistrictChanged(String value) async {
    final selectedState = state.text.trim();
    final selectedDistrict = value.trim();
    if (selectedState.isEmpty || selectedDistrict.isEmpty) return;
    final token = ++_districtRequestToken;

    district.text = selectedDistrict;
    taluka.clear();
    city.clear();
    talukas.clear();

    try {
      final talukaList = await fetchLocationTalukas(
        stateValue: selectedState,
        districtValue: selectedDistrict,
      );
      if (token != _districtRequestToken) return;
      if (state.text.trim() != selectedState) return;
      if (district.text.trim() != selectedDistrict) return;
      talukas.assignAll(_uniqueLocationValues(talukaList));
    } catch (_) {}
  }

  void onTalukaChanged(String value) {
    final selected = value.trim();
    if (selected.isEmpty) return;
    taluka.text = selected;
    city.text = selected;
  }

  Future<List<String>> fetchLocationStates() async {
    final response = await http.get(
      Uri.parse('${Api.baseUrl}/doctor/locations/states'),
      headers: {"Accept": "application/json"},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["data"] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
  }

  Future<List<String>> fetchLocationDistricts(String stateValue) async {
    final uri = Uri.parse('${Api.baseUrl}/doctor/locations/districts').replace(
      queryParameters: {"state": stateValue},
    );
    final response = await http.get(uri, headers: {"Accept": "application/json"});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["data"] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
  }

  Future<List<String>> fetchLocationTalukas({
    required String stateValue,
    required String districtValue,
  }) async {
    final uri = Uri.parse('${Api.baseUrl}/doctor/locations/talukas').replace(
      queryParameters: {
        "state": stateValue,
        "district": districtValue,
      },
    );
    final response = await http.get(uri, headers: {"Accept": "application/json"});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data["data"] as List<dynamic>? ?? const [])
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

  void submit() async {
    if (firstName.text.isEmpty) {
      Get.snackbar("Error", "Enter First Name");
      return;
    }
    if (selectedPhoto.value == null) {
      Get.snackbar("Error", "Upload farmer photo");
      return;
    }

    try {
      final request = http.MultipartRequest("POST", Uri.parse(Api.addFarmer));
      request.headers.addAll({
        "Accept": "application/json",
      });
      request.fields.addAll({
        "mobile": mobile,
        "first_name": firstName.text.trim(),
        "middle_name": middleName.text.trim(),
        "last_name": lastName.text.trim(),
        "village": village.text.trim(),
        "city": taluka.text.trim(),
        "taluka": taluka.text.trim(),
        "district": district.text.trim(),
        "state": state.text.trim(),
        "pincode": pincode.text.trim(),
      });
      final imagePath = selectedPhoto.value!.path;
      final fileName = imagePath.split(Platform.pathSeparator).last;
      request.files.add(
        await http.MultipartFile.fromPath(
          "farmer_photo",
          imagePath,
          filename: fileName,
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Success", "Farmer Added Successfully");

        final farmerId = int.tryParse(data['data']['id'].toString()) ?? 0;
        final farmerPhoto = data['data']['farmer_photo_url']?.toString() ??
            data['data']['farmer_photo']?.toString() ??
            '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('farmer_id', farmerId);

        await SessionService.saveFarmerId(farmerId);
        await SessionService.setRegistered(true);
        await SessionService.setLoggedIn(true);
        await SessionService.setSeenOnboarding(true);
        await SessionService.saveFarmerName(firstName.text.trim());
        await SessionService.saveMobile(mobile);
        await SessionService.saveFarmerProfile(
          firstName: firstName.text.trim(),
          middleName: middleName.text.trim(),
          lastName: lastName.text.trim(),
          village: village.text.trim(),
          city: taluka.text.trim(),
          taluka: taluka.text.trim(),
          district: district.text.trim(),
          state: state.text.trim(),
          pincode: pincode.text.trim(),
          farmerPhoto: farmerPhoto,
        );
        await _tryAutoFetchCurrentLocation(farmerId);

        farmerName.value = firstName.text.trim();

        Get.offAll(() => const MainBottomNavView());
      } else {
        Get.snackbar("Error", data['message'].toString());
      }
    } catch (_) {
      Get.snackbar("Error", "Something went wrong");
    }
  }

  Future<void> _tryAutoFetchCurrentLocation(int farmerId) async {
    if (farmerId <= 0) return;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final response = await http.post(
        Uri.parse('${Api.farmerLocation}/$farmerId'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || data['status'] != true || data['data'] == null) {
        return;
      }

      final payload = Map<String, dynamic>.from(data['data'] as Map);
      final latText =
          (payload['latitude']?.toString() ?? position.latitude.toStringAsFixed(7)).trim();
      final lngText =
          (payload['longitude']?.toString() ?? position.longitude.toStringAsFixed(7)).trim();
      final addressText =
          payload['current_location_address']?.toString().trim().isNotEmpty == true
              ? payload['current_location_address'].toString().trim()
              : 'Lat: $latText, Lng: $lngText';

      await SessionService.saveFarmerLocation(
        latitude: latText,
        longitude: lngText,
        currentLocationAddress: addressText,
      );
    } catch (_) {}
  }

  @override
  void onClose() {
    firstName.dispose();
    middleName.dispose();
    lastName.dispose();
    village.dispose();
    city.dispose();
    taluka.dispose();
    district.dispose();
    state.dispose();
    pincode.dispose();
    super.onClose();
  }
}
