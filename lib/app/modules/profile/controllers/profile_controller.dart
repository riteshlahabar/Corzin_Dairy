import 'package:get/get.dart';

import '../../../core/services/session_service.dart';

class ProfileController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxMap<String, String> profile = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
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
    });
    isLoading.value = false;
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
}
