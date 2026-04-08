import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String seenOnboardingKey = "seen_onboarding";
  static const String isLoggedInKey = "is_logged_in";
  static const String isRegisteredKey = "is_registered";
  static const String mobileKey = "mobile";
  static const String farmerNameKey = "farmer_name";
  static const String farmerIdKey = "farmer_id";
  static const String firstNameKey = "first_name";
  static const String middleNameKey = "middle_name";
  static const String lastNameKey = "last_name";
  static const String villageKey = "village";
  static const String cityKey = "city";
  static const String talukaKey = "taluka";
  static const String districtKey = "district";
  static const String stateKey = "state";
  static const String pincodeKey = "pincode";

  static Future<void> setSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenOnboardingKey, value);
  }

  static Future<bool> getSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(seenOnboardingKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, value);
  }

  static Future<bool> getLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isLoggedInKey) ?? false;
  }

  static Future<void> setRegistered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isRegisteredKey, value);
  }

  static Future<bool> getRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isRegisteredKey) ?? false;
  }

  static Future<void> saveMobile(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(mobileKey, mobile);
  }

  static Future<String> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(mobileKey) ?? "";
  }

  static Future<void> saveFarmerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(farmerNameKey, name);
  }

  static Future<String> getFarmerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(farmerNameKey) ?? "";
  }

  static Future<void> saveFarmerId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(farmerIdKey, id);
  }

  static Future<int> getFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(farmerIdKey) ?? 0;
  }

  static Future<void> saveFarmerProfile({
    required String firstName,
    String middleName = "",
    String lastName = "",
    String village = "",
    String city = "",
    String taluka = "",
    String district = "",
    String state = "",
    String pincode = "",
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(firstNameKey, firstName);
    await prefs.setString(middleNameKey, middleName);
    await prefs.setString(lastNameKey, lastName);
    await prefs.setString(villageKey, village);
    await prefs.setString(cityKey, city);
    await prefs.setString(talukaKey, taluka);
    await prefs.setString(districtKey, district);
    await prefs.setString(stateKey, state);
    await prefs.setString(pincodeKey, pincode);
  }

  static Future<Map<String, String>> getFarmerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "first_name": prefs.getString(firstNameKey) ?? "",
      "middle_name": prefs.getString(middleNameKey) ?? "",
      "last_name": prefs.getString(lastNameKey) ?? "",
      "village": prefs.getString(villageKey) ?? "",
      "city": prefs.getString(cityKey) ?? "",
      "taluka": prefs.getString(talukaKey) ?? "",
      "district": prefs.getString(districtKey) ?? "",
      "state": prefs.getString(stateKey) ?? "",
      "pincode": prefs.getString(pincodeKey) ?? "",
    };
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, false);
    await prefs.setBool(isRegisteredKey, true);
    await prefs.setBool(seenOnboardingKey, false);
  }
}
