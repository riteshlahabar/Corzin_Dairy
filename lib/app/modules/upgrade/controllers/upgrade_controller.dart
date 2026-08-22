import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/razorpay_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';
import '../../home/controllers/home_controller.dart';

class UpgradeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isPurchasingPlan = false.obs;
  final RxInt purchasingPlanId = 0.obs;
  final RxInt selectedPlanId = 0.obs;
  final RxString adminContactName = ''.obs;
  final RxString adminContactNumber = ''.obs;

  int farmerId = 0;
  String farmerName = '';
  String mobileNumber = '';

  final RxList<PlanModel> plans = <PlanModel>[
    const PlanModel(
      name: 'free_plan',
      price: 'Rs 0',
      amount: 0,
      features: ['limited_animals', 'limited_pans', 'basic_dashboard'],
      highlighted: false,
    ),
    const PlanModel(
      name: 'paid_plan',
      price: 'Rs 999 / year',
      amount: 999,
      features: ['unlimited_animals', 'unlimited_pans', 'advanced_reports'],
      highlighted: true,
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _initialise();
  }

  Future<void> _initialise() async {
    await _loadSessionContext();
    await loadData();
  }

  Future<void> _loadSessionContext() async {
    farmerId = await SessionService.getFarmerId();
    farmerName = await SessionService.getFarmerName();
    mobileNumber = await SessionService.getMobile();
  }

  Future<void> loadData() async {
    await Future.wait([loadPlans(), loadAdminContact()]);
  }

  Future<void> loadPlans() async {
    try {
      isLoading.value = true;
      final uri = farmerId > 0
          ? Uri.parse('${Api.subscriptionPlans}?farmer_id=$farmerId')
          : Uri.parse(Api.subscriptionPlans);
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? <dynamic>[];
        if (list.isNotEmpty) {
          plans.assignAll(
            list.map((item) => PlanModel.fromJson(item)).toList(),
          );
          _ensureSelectedPlan();
        }
      }
    } catch (_) {
      // Keep fallback plans when API is not available.
    } finally {
      _ensureSelectedPlan();
      isLoading.value = false;
    }
  }

  void _ensureSelectedPlan() {
    if (plans.isEmpty) {
      selectedPlanId.value = 0;
      return;
    }

    final currentId = selectedPlanId.value;
    if (currentId != 0 && plans.any((plan) => plan.id == currentId)) {
      return;
    }

    final highlighted = plans.firstWhereOrNull((plan) => plan.highlighted);
    selectedPlanId.value = (highlighted ?? plans.first).id;
  }

  void selectPlan(PlanModel plan) {
    selectedPlanId.value = plan.id;
  }

  PlanModel get selectedPlan {
    if (plans.isEmpty) {
      return const PlanModel(
        name: 'paid_plan',
        price: 'Rs 0',
        amount: 0,
        features: <String>[],
        highlighted: false,
      );
    }

    return plans.firstWhereOrNull((plan) => plan.id == selectedPlanId.value) ??
        plans.first;
  }

  Future<void> continueWithSelectedPlan() async {
    final plan = selectedPlan;
    if (plan.amount > 0) {
      await purchasePlan(plan);
      return;
    }
    await contactAdmin();
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
      Get.snackbar('error'.tr, 'admin_contact_number_not_available'.tr);
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      Get.snackbar('error'.tr, 'unable_open_dialer'.tr);
    }
  }

  Future<void> purchasePlan(PlanModel plan) async {
    if (isPurchasingPlan.value) return;

    if (plan.amount <= 0) {
      Get.snackbar('info'.tr, 'free_plan_no_payment'.tr);
      return;
    }
    if (farmerId <= 0) {
      Get.snackbar('error'.tr, 'please_login_again'.tr);
      return;
    }

    try {
      isPurchasingPlan.value = true;
      purchasingPlanId.value = plan.id;

      final order = await _createSubscriptionOrder(plan);
      if (order == null || !order.isValid) {
        Get.snackbar('payment'.tr, 'Unable to create payment order.');
        return;
      }

      final paymentResult = await RazorpayService.instance.openCheckout(
        amount: order.amount,
        keyId: order.keyId,
        orderId: order.orderId,
        customerName: farmerName,
        contact: mobileNumber,
        description: 'Subscription - ${plan.name.tr}',
        notes: {
          'flow': 'subscription',
          'farmer_id': '$farmerId',
          'plan_id': '${plan.id}',
        },
      );

      if (!paymentResult.success) {
        if (paymentResult.message.trim().isNotEmpty &&
            paymentResult.message.trim() != 'payment_cancelled'.tr) {
          Get.snackbar('payment'.tr, paymentResult.message.trim());
        }
        return;
      }

      final paymentMeta = paymentResult.toApiPayload();
      if ((paymentMeta['razorpay_order_id'] ?? '').toString().trim().isEmpty) {
        paymentMeta['razorpay_order_id'] = order.orderId;
      }

      final saved = await _saveSubscriptionPurchase(
        plan: plan,
        paymentMeta: paymentMeta,
      );

      if (saved) {
        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().loadDashboard(silent: true);
        }
        Get.snackbar('success'.tr, 'subscription_payment_success'.tr);
      } else {
        Get.snackbar('info'.tr, 'subscription_activation_pending'.tr);
      }
    } finally {
      isPurchasingPlan.value = false;
      purchasingPlanId.value = 0;
    }
  }

  Future<RazorpayOrderModel?> _createSubscriptionOrder(PlanModel plan) async {
    try {
      final response = await http.post(
        Uri.parse(Api.subscriptionOrder),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'farmer_id': farmerId,
          'plan_id': plan.id,
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 ||
          data['status'] != true ||
          data['data'] is! Map) {
        final message = data['message']?.toString().trim();
        if (message?.isNotEmpty == true) {
          Get.snackbar('payment'.tr, message!);
        }
        return null;
      }

      return RazorpayOrderModel.fromJson(
        Map<String, dynamic>.from(data['data']),
      );
    } catch (e) {
      Get.snackbar('payment'.tr, e.toString());
      return null;
    }
  }

  Future<bool> _saveSubscriptionPurchase({
    required PlanModel plan,
    required Map<String, dynamic> paymentMeta,
  }) async {
    try {
      final payload = <String, dynamic>{
        'farmer_id': farmerId,
        'plan_id': plan.id,
        'plan_name': plan.name,
        'amount': double.parse(plan.amount.toStringAsFixed(2)),
        'payment_method': 'razorpay',
        'payment_status': 'paid',
        ...paymentMeta,
      };

      final response = await http.post(
        Uri.parse(Api.subscriptionPurchase),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return (response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == true;
    } catch (_) {
      return false;
    }
  }

  FarmerPlanModel get currentPlan {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>().currentPlan.value;
    }
    return const FarmerPlanModel(
      name: 'free_plan',
      amount: 'Rs 0',
      expiryDate: '30 days',
      startDate: '-',
      renewDate: '-',
    );
  }

  bool get isPlanLocked {
    return Get.isRegistered<HomeController>() &&
        Get.find<HomeController>().isPlanLocked.value;
  }

  String get planLockMessage {
    if (!Get.isRegistered<HomeController>()) return '';
    return Get.find<HomeController>().planLockMessage.value;
  }

  int get planDaysLeft {
    if (!Get.isRegistered<HomeController>()) return 0;
    return Get.find<HomeController>().planDaysLeft.value;
  }
}

class PlanModel {
  const PlanModel({
    this.id = 0,
    required this.name,
    required this.price,
    required this.amount,
    required this.features,
    required this.highlighted,
  });

  final int id;
  final String name;
  final String price;
  final double amount;
  final List<String> features;
  final bool highlighted;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['features'];
    final features = <String>[];
    if (featuresRaw is List) {
      for (final item in featuresRaw) {
        features.add(item.toString());
      }
    } else if (featuresRaw is String && featuresRaw.trim().isNotEmpty) {
      features.add(featuresRaw.trim());
    }

    final isHighlighted =
        json['highlighted'] == true || json['is_popular'] == true;
    final name = json['name']?.toString() ?? 'plan';
    final priceAmount = double.tryParse(json['price']?.toString() ?? '0') ?? 0;
    final priceLabel = json['price_label']?.toString().trim();

    return PlanModel(
      id: int.tryParse(
            json['id']?.toString() ??
                json['plan_id']?.toString() ??
                json['farmer_plan_id']?.toString() ??
                '0',
          ) ??
          0,
      name: name,
      price: (priceLabel?.isNotEmpty == true)
          ? priceLabel!
          : 'Rs ${priceAmount.toStringAsFixed(0)}',
      amount: priceAmount,
      features: features,
      highlighted: isHighlighted,
    );
  }
}

class RazorpayOrderModel {
  const RazorpayOrderModel({
    required this.keyId,
    required this.orderId,
    required this.amount,
  });

  final String keyId;
  final String orderId;
  final double amount;

  bool get isValid => keyId.isNotEmpty && orderId.isNotEmpty && amount > 0;

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderModel(
      keyId: json['key_id']?.toString().trim() ?? '',
      orderId: json['order_id']?.toString().trim() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    );
  }
}
