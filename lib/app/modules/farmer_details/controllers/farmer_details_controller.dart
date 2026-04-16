import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/api.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/session_service.dart';

class FarmerDetailsController extends GetxController {
  late String lang;
  String mobile = "";
  var farmerName = "".obs;

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

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    state.text = "Maharashtra";

    /// ✅ SAFE ARGUMENT HANDLING
    if (Get.arguments != null) {
      lang = Get.arguments["lang"] ?? "en";
      mobile = Get.arguments["mobile"] ?? "";
    } else {
      /// WHEN OPENING DIRECTLY (HOME / RESTART)
      lang = "en";
      mobile = "";
    }

    debugPrint("🌐 Lang: $lang");
    debugPrint("📱 Mobile: $mobile");
    loadFarmerName();
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

  void submit() async {
    if (firstName.text.isEmpty) {
      Get.snackbar("Error", "Enter First Name");
      return;
    }
    if (selectedPhoto.value == null) {
      Get.snackbar("Error", "Upload farmer photo");
      return;
    }
    debugPrint("📱 farmer mobile: $mobile");
    try {
      final request = http.MultipartRequest('POST', Uri.parse(Api.addFarmer));
      request.headers.addAll({
        "Accept": "application/json",
      });
      request.fields.addAll({
        "mobile": mobile,
        "first_name": firstName.text.trim(),
        "middle_name": middleName.text.trim(),
        "last_name": lastName.text.trim(),
        "village": village.text.trim(),
        "city": city.text.trim(),
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
          city: city.text.trim(),
          taluka: taluka.text.trim(),
          district: district.text.trim(),
          state: state.text.trim(),
          pincode: pincode.text.trim(),
          farmerPhoto: farmerPhoto,
        );

        farmerName.value = firstName.text.trim();

        Get.offAll(() => const MainBottomNavView());
      } else {
        Get.snackbar("Error", data['message'].toString());
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong");
    }
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

