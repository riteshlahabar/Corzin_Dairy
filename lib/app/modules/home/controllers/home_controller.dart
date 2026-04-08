import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';

class HomeController extends GetxController {
  static final NumberFormat _numberFormat = NumberFormat('#,##0.##');

  final RxBool isLoadingAnimals = false.obs;
  final RxBool isLoadingDashboard = false.obs;
  final RxBool isUpdatingLifecycle = false.obs;
  final RxList<dynamic> animals = <dynamic>[].obs;
  final RxList<AnimalTypeOption> animalTypes = <AnimalTypeOption>[].obs;
  final RxMap<String, String> stats = <String, String>{
    'today_milk': '0 L',
    'today_feeding': '0 Kg',
    'total_milk': '0 L',
    'total_feeding': '0 Kg',
  }.obs;
  final RxList<HomePaymentModel> payments = <HomePaymentModel>[].obs;
  final Rx<FarmerPlanModel> currentPlan = const FarmerPlanModel(
    name: 'free_plan',
    amount: 'Rs 0',
    expiryDate: '-',
  ).obs;
  final RxString farmerName = ''.obs;
  final RxString farmerMobile = ''.obs;

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
    final savedName = await SessionService.getFarmerName();
    final profile = await SessionService.getFarmerProfile();
    farmerName.value = _formatFarmerName(
      firstName: profile['first_name'] ?? '',
      middleName: profile['middle_name'] ?? '',
      lastName: profile['last_name'] ?? '',
      fallbackName: savedName,
    );
    farmerMobile.value = await SessionService.getMobile();
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
    try {
      isLoadingDashboard.value = true;
      await Future.wait([
        _loadDairyPaymentsAndMilk(),
        _loadFeedingSummary(),
        _loadCurrentPlan(),
      ]);
    } finally {
      isLoadingDashboard.value = false;
    }
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

  Future<void> _loadDairyPaymentsAndMilk() async {
    if (farmerId == 0) {
      payments.clear();
      stats.addAll({
        'today_milk': _formatQuantity(0, 'L'),
        'total_milk': _formatQuantity(0, 'L'),
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Api.dairyPayments}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 || data['status'] != true) {
        payments.clear();
        stats.addAll({
          'today_milk': _formatQuantity(0, 'L'),
          'total_milk': _formatQuantity(0, 'L'),
        });
        return;
      }

      final list = data['data'] is List ? data['data'] as List : <dynamic>[];
      double todayMilkTotal = 0;
      double totalMilkTotal = 0;

      final mappedPayments = list.map((item) {
        final row = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map);

        final todayPayment = _asDouble(row['today_payment']);
        final totalPayment = _asDouble(row['total_payment']);
        final todayMilk = _asDouble(row['today_milk']);
        final totalMilk = _asDouble(row['total_milk']);

        todayMilkTotal += todayMilk;
        totalMilkTotal += totalMilk;

        return HomePaymentModel(
          dairyName: row['dairy_name']?.toString().trim().isNotEmpty == true
              ? row['dairy_name'].toString()
              : 'Dairy',
          todayPayment: _formatCurrency(todayPayment),
          totalPayment: _formatCurrency(totalPayment),
          todayMilk: _formatQuantity(todayMilk, 'L'),
          totalMilk: _formatQuantity(totalMilk, 'L'),
        );
      }).toList();

      payments.assignAll(mappedPayments);
      stats.addAll({
        'today_milk': _formatQuantity(todayMilkTotal, 'L'),
        'total_milk': _formatQuantity(totalMilkTotal, 'L'),
      });
    } catch (_) {
      payments.clear();
      stats.addAll({
        'today_milk': _formatQuantity(0, 'L'),
        'total_milk': _formatQuantity(0, 'L'),
      });
    }
  }

  Future<void> _loadFeedingSummary() async {
    if (farmerId == 0) {
      stats.addAll({
        'today_feeding': _formatQuantity(0, 'Kg'),
        'total_feeding': _formatQuantity(0, 'Kg'),
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Api.feedingSummary}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 || data['status'] != true) {
        stats.addAll({
          'today_feeding': _formatQuantity(0, 'Kg'),
          'total_feeding': _formatQuantity(0, 'Kg'),
        });
        return;
      }

      final summary = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : Map<String, dynamic>.from(data['data'] as Map? ?? {});
      final unit = (summary['unit']?.toString().trim().isNotEmpty == true)
          ? summary['unit'].toString()
          : 'Kg';

      stats.addAll({
        'today_feeding': _formatQuantity(_asDouble(summary['today_feeding']), unit),
        'total_feeding': _formatQuantity(_asDouble(summary['total_feeding']), unit),
      });
    } catch (_) {
      stats.addAll({
        'today_feeding': _formatQuantity(0, 'Kg'),
        'total_feeding': _formatQuantity(0, 'Kg'),
      });
    }
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final response = await http.get(
        Uri.parse(Api.subscriptionPlans),
        headers: {'Accept': 'application/json'},
      );
      final data = _decodeBody(response.body);
      if (response.statusCode != 200 || data['status'] != true || data['data'] is! List) {
        return;
      }

      final list = (data['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (list.isEmpty) return;

      final plan = list.firstWhere(
        (item) => item['is_popular'] == true,
        orElse: () => list.first,
      );

      final durationDays = int.tryParse(plan['duration_days']?.toString() ?? '') ?? 0;
      final amount = plan['price_label']?.toString().trim().isNotEmpty == true
          ? plan['price_label'].toString()
          : _formatCurrency(_asDouble(plan['price']));

      currentPlan.value = FarmerPlanModel(
        name: plan['name']?.toString().trim().isNotEmpty == true
            ? plan['name'].toString()
            : 'free_plan',
        amount: amount,
        expiryDate: durationDays > 0 ? '$durationDays days' : '-',
      );
    } catch (_) {
      // Keep existing plan data on API failure.
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(double amount) {
    return 'Rs ${_numberFormat.format(amount)}';
  }

  String _formatQuantity(double value, String unit) {
    return '${_numberFormat.format(value)} $unit';
  }

  String _formatFarmerName({
    required String firstName,
    required String middleName,
    required String lastName,
    required String fallbackName,
  }) {
    final first = firstName.trim();
    final middle = middleName.trim();
    final last = lastName.trim();

    final parts = <String>[
      if (first.isNotEmpty) first,
      if (middle.isNotEmpty) middle[0].toUpperCase(),
      if (last.isNotEmpty) last,
    ];

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return fallbackName.trim();
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
