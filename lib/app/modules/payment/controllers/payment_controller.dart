import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class PaymentController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  int farmerId = 0;

  final RxList<PaymentDairySummary> payments = <PaymentDairySummary>[].obs;
  final RxList<PaymentDairyOption> dairyOptions = <PaymentDairyOption>[].obs;

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
      dairyOptions.clear();
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
        final items = list
            .whereType<Map>()
            .map((item) => PaymentDairySummary.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        payments.assignAll(items);
        dairyOptions.assignAll(
          items
              .map((item) => PaymentDairyOption(id: item.id, dairyName: item.dairyName))
              .toList()
            ..sort((a, b) => a.dairyName.toLowerCase().compareTo(b.dairyName.toLowerCase())),
        );
      } else {
        payments.clear();
        dairyOptions.clear();
      }
    } catch (_) {
      payments.clear();
      dairyOptions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPaymentEntry({
    required int dairyId,
    required double totalAmount,
    required double paidAmount,
    required String notes,
  }) async {
    if (farmerId == 0) {
      throw Exception('Farmer ID not found. Please login again.');
    }

    try {
      isSaving.value = true;
      final response = await http.post(
        Uri.parse(Api.dairyPaymentEntry),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_id': farmerId,
          'dairy_id': dairyId,
          'payment_date': _todayDateIso(),
          'total_amount': totalAmount.toStringAsFixed(2),
          'paid_amount': paidAmount.toStringAsFixed(2),
          'notes': notes.trim(),
        }),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || data['status'] != true) {
        throw Exception(_extractApiMessage(data) ?? 'Failed to save payment entry.');
      }
      await loadPayments();
    } finally {
      isSaving.value = false;
    }
  }

  PaymentDairySummary? summaryByDairyId(int dairyId) {
    for (final item in payments) {
      if (item.id == dairyId) return item;
    }
    return null;
  }

  double previousBalanceForDairy(int dairyId) {
    final summary = summaryByDairyId(dairyId);
    if (summary == null || summary.history.isEmpty) {
      return 0;
    }
    final latest = summary.history.first;
    if (latest.dateKey == _todayDateIso()) {
      return latest.previousBalance;
    }
    return latest.balanceAmount;
  }

  double previewBalance({
    required int dairyId,
    required double totalAmount,
    required double paidAmount,
  }) {
    final previous = previousBalanceForDairy(dairyId);
    return (previous + totalAmount - paidAmount).clamp(-999999999.0, 999999999.0).toDouble();
  }

  String _todayDateIso() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String? _extractApiMessage(dynamic data) {
    if (data is! Map) return null;
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    if (msg is Map) {
      final firstValue = msg.values.isNotEmpty ? msg.values.first : null;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first?.toString();
      }
      if (firstValue != null) return firstValue.toString();
    }
    return null;
  }
}

class PaymentDairyOption {
  final int id;
  final String dairyName;

  const PaymentDairyOption({
    required this.id,
    required this.dairyName,
  });
}

class PaymentDairySummary {
  final int id;
  final String dairyName;
  final double currentBalance;
  final List<PaymentDayEntry> history;

  const PaymentDairySummary({
    required this.id,
    required this.dairyName,
    required this.currentBalance,
    required this.history,
  });

  PaymentDayEntry? get latest => history.isEmpty ? null : history.first;

  factory PaymentDairySummary.fromJson(Map<String, dynamic> json) {
    final rawHistory = (json['history'] as List?) ?? const [];
    final history = rawHistory
        .whereType<Map>()
        .map((item) => PaymentDayEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));

    return PaymentDairySummary(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      dairyName: (json['dairy_name'] ?? '-').toString(),
      currentBalance: _toDouble(json['current_balance']),
      history: history,
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class PaymentDayEntry {
  final String date;
  final String dateKey;
  final double previousBalance;
  final double dayTotalAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String notes;

  const PaymentDayEntry({
    required this.date,
    required this.dateKey,
    required this.previousBalance,
    required this.dayTotalAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.notes,
  });

  factory PaymentDayEntry.fromJson(Map<String, dynamic> json) {
    return PaymentDayEntry(
      date: (json['date'] ?? '-').toString(),
      dateKey: (json['date_key'] ?? '').toString(),
      previousBalance: _toDouble(json['previous_balance']),
      dayTotalAmount: _toDouble(json['day_total_amount']),
      totalAmount: _toDouble(json['total_amount']),
      paidAmount: _toDouble(json['paid_amount']),
      balanceAmount: _toDouble(json['balance_amount']),
      notes: (json['notes'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

