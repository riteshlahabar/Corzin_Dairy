import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class PaymentController extends GetxController {
  final RxBool isLoading = false.obs;
  int farmerId = 0;

  final RxList<PaymentModel> payments = <PaymentModel>[
    const PaymentModel(
      dairyName: 'Green Valley Dairy',
      amount: '₹12,480',
      date: '01 Apr 2026',
      status: 'Paid',
    ),
    const PaymentModel(
      dairyName: 'Shree Milk Center',
      amount: '₹9,250',
      date: '28 Mar 2026',
      status: 'Paid',
    ),
    const PaymentModel(
      dairyName: 'Sai Dairy Point',
      amount: '₹7,980',
      date: '24 Mar 2026',
      status: 'Pending',
    ),
  ].obs;

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
      final response = await http.get(
        Uri.parse('${Api.dairyPayments}/$farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? <dynamic>[];
        payments.assignAll(
          list.map((item) => PaymentModel.fromJson(item)).toList(),
        );
      } else {
        payments.clear();
      }
    } catch (_) {
      payments.clear();
    } finally {
      isLoading.value = false;
    }
  }
}

class PaymentModel {
  final String dairyName;
  final String amount;
  final String date;
  final String status;

  const PaymentModel({
    required this.dairyName,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final totalPayment =
        double.tryParse(json['total_payment']?.toString() ?? '0') ?? 0;
    final todayPayment =
        double.tryParse(json['today_payment']?.toString() ?? '0') ?? 0;

    return PaymentModel(
      dairyName: json['dairy_name']?.toString() ?? '-',
      amount: 'Rs ${totalPayment.toStringAsFixed(2)}',
      date: 'Today: Rs ${todayPayment.toStringAsFixed(2)}',
      status: totalPayment > 0 ? 'Paid' : 'Pending',
    );
  }
}
