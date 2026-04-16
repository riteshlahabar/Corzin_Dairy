import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class PaymentController extends GetxController {
  final RxBool isLoading = false.obs;
  int farmerId = 0;

  final RxList<PaymentModel> payments = <PaymentModel>[].obs;
  final RxList<PaymentModel> manualEntries = <PaymentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPayments();
  }

  Future<void> loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    if (farmerId == 0) {
      payments.clear();
      return;
    }

    try {
      isLoading.value = true;
      await _loadManualEntries();
      final response = await http.get(
        Uri.parse('${Api.dairyPayments}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? <dynamic>[];
        final apiItems = list.map((item) => PaymentModel.fromJson(item)).toList();
        payments.assignAll([...manualEntries, ...apiItems]);
      } else {
        payments.assignAll(manualEntries);
      }
    } catch (_) {
      payments.assignAll(manualEntries);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPaymentEntry({
    required String dairyName,
    required String amount,
    required String pendingAmount,
    required String status,
  }) async {
    final entry = PaymentModel(
      dairyName: dairyName.trim(),
      amount: amount.trim(),
      pendingAmount: pendingAmount.trim(),
      date: _todayDate(),
      status: status.trim(),
      isManual: true,
    );
    manualEntries.insert(0, entry);
    payments.insert(0, entry);
    await _saveManualEntries();
  }

  Future<void> _loadManualEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('manual_dairy_payments_$farmerId');
    if (raw == null || raw.trim().isEmpty) {
      manualEntries.clear();
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      manualEntries.clear();
      return;
    }
    manualEntries.assignAll(
      decoded
          .whereType<Map>()
          .map((e) => PaymentModel.fromManualJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<void> _saveManualEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'manual_dairy_payments_$farmerId',
      jsonEncode(manualEntries.map((e) => e.toManualJson()).toList()),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day/$month/$year';
  }
}

class PaymentModel {
  final String dairyName;
  final String amount;
  final String pendingAmount;
  final String date;
  final String status;
  final bool isManual;

  const PaymentModel({
    required this.dairyName,
    required this.amount,
    required this.pendingAmount,
    required this.date,
    required this.status,
    this.isManual = false,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final totalPayment = double.tryParse(json['total_payment']?.toString() ?? '0') ?? 0;
    final todayPayment = double.tryParse(json['today_payment']?.toString() ?? '0') ?? 0;
    final pendingFromApi = double.tryParse(json['pending_payment']?.toString() ?? '0') ?? 0;
    final pendingPayment = pendingFromApi > 0
        ? pendingFromApi
        : (totalPayment - todayPayment).clamp(0, double.infinity).toDouble();

    return PaymentModel(
      dairyName: json['dairy_name']?.toString() ?? '-',
      amount: 'Rs ${totalPayment.toStringAsFixed(2)}',
      pendingAmount: 'Rs ${pendingPayment.toStringAsFixed(2)}',
      date: 'Today: Rs ${todayPayment.toStringAsFixed(2)}',
      status: pendingPayment > 0 ? 'Pending' : 'Paid',
    );
  }

  factory PaymentModel.fromManualJson(Map<String, dynamic> json) {
    return PaymentModel(
      dairyName: (json['dairy_name'] ?? '-').toString(),
      amount: (json['amount'] ?? 'Rs 0.00').toString(),
      pendingAmount: (json['pending_amount'] ?? 'Rs 0.00').toString(),
      date: (json['date'] ?? '-').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      isManual: true,
    );
  }

  Map<String, dynamic> toManualJson() {
    return {
      'dairy_name': dairyName,
      'amount': amount,
      'pending_amount': pendingAmount,
      'date': date,
      'status': status,
    };
  }
}
