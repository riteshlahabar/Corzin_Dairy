import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  @override
  void onInit() {
    super.onInit();

    /// ✅ SAFE ARGUMENT HANDLING
    if (Get.arguments != null) {
      lang = Get.arguments["lang"] ?? "en";
      mobile = Get.arguments["mobile"] ?? "";
    } else {
      /// WHEN OPENING DIRECTLY (HOME / RESTART)
      lang = "en";
      mobile = "";
    }

    print("🌐 Lang: $lang");
    print("📱 Mobile: $mobile");
    loadFarmerName();
  }

  void loadFarmerName() async {
    farmerName.value = await SessionService.getFarmerName();
  }

  void submit() async {
    if (firstName.text.isEmpty) {
      Get.snackbar("Error", "Enter First Name");
      return;
    }
    print("📱 farmer mobile: $mobile");
    try {
      var response = await http.post(
        Uri.parse(Api.addFarmer),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "mobile": mobile,
          "first_name": firstName.text,
          "middle_name": middleName.text,
          "last_name": lastName.text,
          "village": village.text,
          "city": city.text,
          "taluka": taluka.text,
          "district": district.text,
          "state": state.text,
          "pincode": pincode.text,
        }),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Success", "Farmer Added Successfully");

        final farmerId = int.tryParse(data['data']['id'].toString()) ?? 0;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('farmer_id', farmerId);

        await SessionService.saveFarmerId(farmerId);
        await SessionService.setRegistered(true);
        await SessionService.setLoggedIn(true);
        await SessionService.setSeenOnboarding(true);
        await SessionService.saveFarmerName(firstName.text);
        await SessionService.saveMobile(mobile);
        await SessionService.saveFarmerProfile(
          firstName: firstName.text,
          middleName: middleName.text,
          lastName: lastName.text,
          village: village.text,
          city: city.text,
          taluka: taluka.text,
          district: district.text,
          state: state.text,
          pincode: pincode.text,
        );

        farmerName.value = firstName.text;

        Get.offAll(() => const MainBottomNavView());
      } else {
        Get.snackbar("Error", data['message'].toString());
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong");
    }
  }
}
