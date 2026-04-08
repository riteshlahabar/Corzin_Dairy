import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../../home/controllers/home_controller.dart';

class ProfileController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isEditingFarmerInfo = false.obs;
  final RxBool isEditingLocation = false.obs;
  final RxMap<String, String> profile = <String, String>{}.obs;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController villageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController talukaController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final Rxn<XFile> selectedPhoto = Rxn<XFile>();

  final ImagePicker _picker = ImagePicker();

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    villageController.dispose();
    cityController.dispose();
    talukaController.dispose();
    districtController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    farmerId = await SessionService.getFarmerId();
    final saved = await SessionService.getFarmerProfile();
    final name = await SessionService.getFarmerName();
    final mobile = await SessionService.getMobile();

    profile.assignAll({
      'name': name,
      'mobile': mobile,
      'first_name': saved['first_name'] ?? '',
      'middle_name': saved['middle_name'] ?? '',
      'last_name': saved['last_name'] ?? '',
      'village': saved['village'] ?? '',
      'city': saved['city'] ?? '',
      'taluka': saved['taluka'] ?? '',
      'district': saved['district'] ?? '',
      'state': saved['state'] ?? '',
      'pincode': saved['pincode'] ?? '',
      'farmer_photo': saved['farmer_photo'] ?? '',
    });
    _fillControllersFromProfile();
    await _loadLatestProfileFromBackend(mobile);
    isLoading.value = false;
  }

  void toggleFarmerInfoEdit() {
    isEditingFarmerInfo.toggle();
    if (!isEditingFarmerInfo.value) {
      _fillControllersFromProfile();
    }
  }

  void toggleLocationEdit() {
    isEditingLocation.toggle();
    if (!isEditingLocation.value) {
      _fillControllersFromProfile();
    }
  }

  bool get isEditingAny => isEditingFarmerInfo.value || isEditingLocation.value;

  Future<void> pickProfilePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      selectedPhoto.value = image;
    }
  }

  Future<void> saveProfile() async {
    if (isSaving.value) return;
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer profile not found');
      return;
    }
    if (firstNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'First name is required');
      return;
    }

    try {
      isSaving.value = true;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Api.updateFarmer}/$farmerId'),
      );
      request.headers.addAll(const {
        'Accept': 'application/json',
      });
      request.fields.addAll({
        'first_name': firstNameController.text.trim(),
        'middle_name': middleNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'village': villageController.text.trim(),
        'city': cityController.text.trim(),
        'taluka': talukaController.text.trim(),
        'district': districtController.text.trim(),
        'state': stateController.text.trim(),
        'pincode': pincodeController.text.trim(),
      });
      if (selectedPhoto.value != null) {
        final imagePath = selectedPhoto.value!.path;
        final fileName = imagePath.split(Platform.pathSeparator).last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'farmer_photo',
            imagePath,
            filename: fileName,
          ),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final farmerPhoto = data['data']?['farmer_photo_url']?.toString() ??
            data['data']?['farmer_photo']?.toString() ??
            profile['farmer_photo'] ??
            '';
        profile.assignAll({
          'name': firstNameController.text.trim(),
          'mobile': profile['mobile'] ?? '',
          'first_name': firstNameController.text.trim(),
          'middle_name': middleNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'village': villageController.text.trim(),
          'city': cityController.text.trim(),
          'taluka': talukaController.text.trim(),
          'district': districtController.text.trim(),
          'state': stateController.text.trim(),
          'pincode': pincodeController.text.trim(),
          'farmer_photo': farmerPhoto,
        });

        await SessionService.saveFarmerName(firstNameController.text.trim());
        await SessionService.saveFarmerProfile(
          firstName: firstNameController.text.trim(),
          middleName: middleNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          village: villageController.text.trim(),
          city: cityController.text.trim(),
          taluka: talukaController.text.trim(),
          district: districtController.text.trim(),
          state: stateController.text.trim(),
          pincode: pincodeController.text.trim(),
          farmerPhoto: farmerPhoto,
        );

        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().loadBaseData();
        }

        isEditingFarmerInfo.value = false;
        isEditingLocation.value = false;
        selectedPhoto.value = null;
        Get.snackbar('Success', data['message']?.toString() ?? 'Profile updated successfully');
        return;
      }

      Get.snackbar('Error', data['message']?.toString() ?? 'Failed to update profile');
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong while updating profile');
    } finally {
      isSaving.value = false;
    }
  }

  String fullName() {
    final values = [
      profile['first_name'],
      profile['middle_name'],
      profile['last_name'],
    ].where((value) => (value ?? '').trim().isNotEmpty).join(' ').trim();

    if (values.isNotEmpty) return values;
    return (profile['name'] ?? '').trim();
  }

  void _fillControllersFromProfile() {
    firstNameController.text = profile['first_name'] ?? '';
    middleNameController.text = profile['middle_name'] ?? '';
    lastNameController.text = profile['last_name'] ?? '';
    villageController.text = profile['village'] ?? '';
    cityController.text = profile['city'] ?? '';
    talukaController.text = profile['taluka'] ?? '';
    districtController.text = profile['district'] ?? '';
    stateController.text = profile['state'] ?? '';
    pincodeController.text = profile['pincode'] ?? '';
  }

  Future<void> _loadLatestProfileFromBackend(String mobile) async {
    if (mobile.trim().isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: const {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || data['status'] != true || data['data'] == null) {
        return;
      }

      final farmer = Map<String, dynamic>.from(data['data']);
      final farmerPhoto = farmer['farmer_photo_url']?.toString() ??
          farmer['farmer_photo']?.toString() ??
          '';

      profile.assignAll({
        'name': farmer['first_name']?.toString() ?? profile['name'] ?? '',
        'mobile': farmer['mobile']?.toString() ?? profile['mobile'] ?? '',
        'first_name': farmer['first_name']?.toString() ?? '',
        'middle_name': farmer['middle_name']?.toString() ?? '',
        'last_name': farmer['last_name']?.toString() ?? '',
        'village': farmer['village']?.toString() ?? '',
        'city': farmer['city']?.toString() ?? '',
        'taluka': farmer['taluka']?.toString() ?? '',
        'district': farmer['district']?.toString() ?? '',
        'state': farmer['state']?.toString() ?? '',
        'pincode': farmer['pincode']?.toString() ?? '',
        'farmer_photo': farmerPhoto,
      });
      _fillControllersFromProfile();

      await SessionService.saveFarmerName(farmer['first_name']?.toString() ?? '');
      await SessionService.saveFarmerProfile(
        firstName: farmer['first_name']?.toString() ?? '',
        middleName: farmer['middle_name']?.toString() ?? '',
        lastName: farmer['last_name']?.toString() ?? '',
        village: farmer['village']?.toString() ?? '',
        city: farmer['city']?.toString() ?? '',
        taluka: farmer['taluka']?.toString() ?? '',
        district: farmer['district']?.toString() ?? '',
        state: farmer['state']?.toString() ?? '',
        pincode: farmer['pincode']?.toString() ?? '',
        farmerPhoto: farmerPhoto,
      );
    } catch (_) {
      // Keep local session profile if backend fetch fails.
    }
  }
}
