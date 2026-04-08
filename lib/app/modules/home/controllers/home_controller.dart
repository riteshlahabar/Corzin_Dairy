import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';

class HomeController extends GetxController {
  final RxBool isLoadingAnimals = false.obs;
  final RxBool isLoadingDashboard = false.obs;
  final RxBool isUpdatingLifecycle = false.obs;
  final RxList<dynamic> animals = <dynamic>[].obs;
  final RxList<AnimalTypeOption> animalTypes = <AnimalTypeOption>[].obs;
  final RxMap<String, String> stats = <String, String>{
    'today_milk': '18 L',
    'today_feeding': '9 Kg',
    'total_milk': '245 L',
    'total_feeding': '124 Kg',
  }.obs;
  final RxList<HomePaymentModel> payments = <HomePaymentModel>[].obs;
  final Rx<FarmerPlanModel> currentPlan = const FarmerPlanModel(
    name: 'paid_plan',
    amount: 'Rs 999 / year',
    expiryDate: '31 Mar 2027',
  ).obs;
  final RxString farmerName = ''.obs;

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    initHome();
  }

  Future<void> initHome() async {
    await loadBaseData();
    await Future.wait([fetchAnimalTypes(), fetchAnimals(), loadDashboard()]);
  }

  Future<void> loadBaseData() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    farmerName.value = await SessionService.getFarmerName();
  }

  Future<void> fetchAnimalTypes() async {
    try {
      final response = await http.get(Uri.parse(Api.animalTypes), headers: {'Accept': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        animalTypes.assignAll(list.map((item) => AnimalTypeOption.fromJson(item)).toList());
      }
    } catch (_) {
      animalTypes.clear();
    }
  }

  Future<void> fetchAnimals() async {
    if (farmerId == 0) return;

    try {
      isLoadingAnimals.value = true;
      final response = await http.get(Uri.parse('${Api.animalList}/$farmerId'), headers: {'Accept': 'application/json'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        animals.value = data['data'] ?? [];
      } else {
        animals.clear();
      }
    } catch (_) {
      animals.clear();
    } finally {
      isLoadingAnimals.value = false;
    }
  }

  Future<void> loadDashboard() async {
    isLoadingDashboard.value = true;
    await Future.delayed(const Duration(milliseconds: 200));
    payments.assignAll(const [
      HomePaymentModel(dairyName: 'Green Valley Dairy', todayPayment: 'Rs 2480', totalPayment: 'Rs 12480', todayMilk: '18 L', totalMilk: '245 L'),
      HomePaymentModel(dairyName: 'Shree Milk Center', todayPayment: 'Rs 1950', totalPayment: 'Rs 9250', todayMilk: '14 L', totalMilk: '188 L'),
      HomePaymentModel(dairyName: 'Sai Dairy Point', todayPayment: 'Rs 1680', totalPayment: 'Rs 7980', todayMilk: '11 L', totalMilk: '162 L'),
    ]);
    isLoadingDashboard.value = false;
  }

  Future<bool> updateAnimalLifecycle({
    required int animalId,
    required String action,
    int? animalTypeId,
    String? notes,
  }) async {
    try {
      isUpdatingLifecycle.value = true;
      final payload = {
        'action': action,
        if (animalTypeId != null) 'animal_type_id': animalTypeId.toString(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      final response = await http.post(
        Uri.parse('${Api.animalLifecycle}/$animalId'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        await fetchAnimals();
        Get.snackbar('Success', data['message']?.toString() ?? 'Animal lifecycle updated');
        return true;
      }
      Get.snackbar('Error', data['message']?.toString() ?? 'Failed to update animal lifecycle');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isUpdatingLifecycle.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await Future.wait([fetchAnimals(), loadDashboard()]);
  }
}

class AnimalTypeOption {
  final int id;
  final String name;

  AnimalTypeOption({required this.id, required this.name});

  factory AnimalTypeOption.fromJson(Map<String, dynamic> json) {
    return AnimalTypeOption(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class HomePaymentModel {
  final String dairyName;
  final String todayPayment;
  final String totalPayment;
  final String todayMilk;
  final String totalMilk;

  const HomePaymentModel({
    required this.dairyName,
    required this.todayPayment,
    required this.totalPayment,
    required this.todayMilk,
    required this.totalMilk,
  });
}

class FarmerPlanModel {
  final String name;
  final String amount;
  final String expiryDate;

  const FarmerPlanModel({
    required this.name,
    required this.amount,
    required this.expiryDate,
  });
}
