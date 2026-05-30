import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/api.dart';
import '../../home/controllers/home_controller.dart';

class UpgradeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString adminContactName = ''.obs;
  final RxString adminContactNumber = ''.obs;

  final RxList<PlanModel> plans = <PlanModel>[
    const PlanModel(
      name: 'free_plan',
      price: '₹0',
      features: ['limited_animals', 'limited_pans', 'basic_dashboard'],
      highlighted: false,
    ),
    const PlanModel(
      name: 'paid_plan',
      price: '₹999 / year',
      features: ['unlimited_animals', 'unlimited_pans', 'advanced_reports'],
      highlighted: true,
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([loadPlans(), loadAdminContact()]);
  }

  Future<void> loadPlans() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse(Api.subscriptionPlans),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? <dynamic>[];
        if (list.isNotEmpty) {
          plans.assignAll(
            list.map((item) => PlanModel.fromJson(item)).toList(),
          );
        }
      }
    } catch (_) {
      // Keep fallback plans when API is not available.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAdminContact() async {
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.adminContactNumber.value.trim().isNotEmpty) {
        adminContactName.value = home.adminContactName.value;
        adminContactNumber.value = home.adminContactNumber.value;
        return;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(Api.farmerSettings),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final settings = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};
      final contact = settings['admin_contact'] is Map
          ? Map<String, dynamic>.from(settings['admin_contact'] as Map)
          : <String, dynamic>{};
      adminContactName.value = contact['name']?.toString().trim() ?? '';
      adminContactNumber.value = contact['number']?.toString().trim() ?? '';
    } catch (_) {}
  }

  Future<void> contactAdmin() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().callAdminSupport();
      return;
    }

    if (adminContactNumber.value.trim().isEmpty) {
      await loadAdminContact();
    }
    final number = adminContactNumber.value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) {
      Get.snackbar('Error', 'Admin contact number is not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      Get.snackbar('Error', 'Unable to open dialer.');
    }
  }
}

class PlanModel {
  final String name;
  final String price;
  final List<String> features;
  final bool highlighted;

  const PlanModel({
    required this.name,
    required this.price,
    required this.features,
    required this.highlighted,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['features'];
    final features = <String>[];
    if (featuresRaw is List) {
      for (final item in featuresRaw) {
        features.add(item.toString());
      }
    }

    final isHighlighted =
        json['highlighted'] == true || json['is_popular'] == true;
    final name = json['name']?.toString() ?? 'plan';
    final priceLabel = json['price_label']?.toString();
    final amount = json['price']?.toString();

    return PlanModel(
      name: name,
      price: priceLabel ?? (amount != null ? 'Rs $amount' : 'Rs 0'),
      features: features,
      highlighted: isHighlighted,
    );
  }
}
