import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class PaymentController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString fromDateText = ''.obs;
  final RxString toDateText = ''.obs;
  int farmerId = 0;

  final RxList<PaymentDairySummary> payments = <PaymentDairySummary>[].obs;
  final RxList<PaymentDairyOption> dairyOptions = <PaymentDairyOption>[].obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
    });
    loadPayments();
  }

  bool get hasActiveDateFilter =>
      fromDateText.value.trim().isNotEmpty || toDateText.value.trim().isNotEmpty;

  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty || hasActiveDateFilter;

  List<PaymentDairySummary> get filteredPayments {
    final query = searchQuery.value.trim().toLowerCase();
    return payments.where((summary) {
      final nameMatches =
          query.isEmpty || summary.dairyName.toLowerCase().contains(query);
      if (!nameMatches) return false;
      if (!hasActiveDateFilter) return true;
      return filteredHistoryForSummary(summary).isNotEmpty;
    }).toList();
  }

  List<PaymentDayEntry> filteredHistoryForSummary(PaymentDairySummary summary) {
    if (!hasActiveDateFilter) return summary.history;
    final start = _parseFilterDate(fromDateText.value.trim());
    final end = _parseFilterDate(toDateText.value.trim());
    return summary.history.where((entry) {
      final date = _parsePaymentDate(entry);
      if (date == null) return false;
      if (start != null && date.isBefore(start)) return false;
      if (end != null && date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  PaymentDayEntry? latestVisibleEntry(PaymentDairySummary summary) {
    final visibleHistory = filteredHistoryForSummary(summary);
    return visibleHistory.isEmpty ? null : visibleHistory.first;
  }

  Future<void> pickFromDate(BuildContext context) async {
    final picked = await _pickDate(context, fromDateText.value.trim());
    if (picked == null) return;
    final formatted = _displayDate(picked);
    fromDateController.text = formatted;
    fromDateText.value = formatted;
  }

  Future<void> pickToDate(BuildContext context) async {
    final picked = await _pickDate(context, toDateText.value.trim());
    if (picked == null) return;
    final formatted = _displayDate(picked);
    toDateController.text = formatted;
    toDateText.value = formatted;
  }

  void clearFilters() {
    searchController.clear();
    fromDateController.clear();
    toDateController.clear();
    searchQuery.value = '';
    fromDateText.value = '';
    toDateText.value = '';
  }

  Future<void> loadPayments({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    if (farmerId == 0) {
      payments.clear();
      dairyOptions.clear();
      return;
    }

    try {
      if (!silent) {
        isLoading.value = true;
      }
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
        final seen = <int>{};
        final options = <PaymentDairyOption>[];
        for (final item in items) {
          if (item.id <= 0) continue;
          if (!seen.add(item.id)) continue;
          options.add(PaymentDairyOption(id: item.id, dairyName: item.dairyName));
        }
        dairyOptions.assignAll(
          options..sort((a, b) => a.dairyName.toLowerCase().compareTo(b.dairyName.toLowerCase())),
        );
      } else {
        payments.clear();
        dairyOptions.clear();
      }
    } catch (_) {
      payments.clear();
      dairyOptions.clear();
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
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
      await loadPayments(silent: true);
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

  PaymentDairyOption? dairyOptionById(int dairyId) {
    for (final item in dairyOptions) {
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
    return latest.previousBalance;
  }

  double todayBalanceForDairy(int dairyId) {
    final summary = summaryByDairyId(dairyId);
    if (summary == null || summary.history.isEmpty) {
      return 0;
    }
    return summary.history.first.todayBalance;
  }

  double totalBalanceForDairy(int dairyId) {
    final summary = summaryByDairyId(dairyId);
    if (summary == null || summary.history.isEmpty) {
      return 0;
    }
    final latest = summary.history.first;
    return latest.totalBalance > 0 || latest.paidAmount > 0
        ? latest.totalBalance
        : latest.balanceAmount;
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

  Future<DateTime?> _pickDate(BuildContext context, String existingText) async {
    final initialDate = _parseFilterDate(existingText) ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E7D32),
            surface: Color(0xFFF2FAF2),
          ),
        ),
        child: child!,
      ),
    );
  }

  DateTime? _parseFilterDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parsePaymentDate(PaymentDayEntry entry) {
    final dateKey = entry.dateKey.trim();
    if (dateKey.isNotEmpty) {
      final parsedKey = DateTime.tryParse(dateKey);
      if (parsedKey != null) {
        return DateTime(parsedKey.year, parsedKey.month, parsedKey.day);
      }
    }

    final raw = entry.date.trim();
    if (raw.isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null) {
      return DateTime(direct.year, direct.month, direct.day);
    }

    const patterns = <String>[
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
    ];
    for (final pattern in patterns) {
      try {
        final parsed = DateFormat(pattern).parseStrict(raw);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {}
    }
    return null;
  }

  String _displayDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void onClose() {
    searchController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    super.onClose();
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
  final double totalMilk;
  final double rate;
  final double previousBalance;
  final double todayBalance;
  final double dayTotalAmount;
  final double totalAmount;
  final double paidAmount;
  final String paidDate;
  final double totalBalance;
  final double balanceAmount;
  final String notes;
  final List<PaymentLedgerAnimal> animals;

  const PaymentDayEntry({
    required this.date,
    required this.dateKey,
    required this.totalMilk,
    required this.rate,
    required this.previousBalance,
    required this.todayBalance,
    required this.dayTotalAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.paidDate,
    required this.totalBalance,
    required this.balanceAmount,
    required this.notes,
    required this.animals,
  });

  factory PaymentDayEntry.fromJson(Map<String, dynamic> json) {
    final rawAnimals = (json['animals'] as List?) ?? const [];
    final animals = rawAnimals
        .whereType<Map>()
        .map((item) => PaymentLedgerAnimal.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final previousBalance = _toDouble(json['previous_balance']);
    final todayBalance = _toDouble(json['today_balance']);
    final dayTotalAmountRaw = _toDouble(json['day_total_amount']);
    final paidAmount = _toDouble(json['paid_amount']);
    final totalBalance = _toDouble(json['total_balance']);
    final totalAmount = _toDouble(json['total_amount']);
    final balanceAmount = _toDouble(json['balance_amount']);

    return PaymentDayEntry(
      date: (json['date'] ?? '-').toString(),
      dateKey: (json['date_key'] ?? '').toString(),
      totalMilk: _toDouble(json['total_milk']),
      rate: _toDouble(json['rate']),
      previousBalance: previousBalance,
      todayBalance: todayBalance > 0 ? todayBalance : dayTotalAmountRaw,
      dayTotalAmount: dayTotalAmountRaw > 0 ? dayTotalAmountRaw : todayBalance,
      totalAmount: totalAmount > 0 ? totalAmount : (previousBalance + (todayBalance > 0 ? todayBalance : dayTotalAmountRaw)),
      paidAmount: paidAmount,
      paidDate: (json['paid_date'] ?? '').toString(),
      totalBalance: totalBalance > 0 || paidAmount > 0
          ? totalBalance
          : _toDouble(json['balance_amount']),
      balanceAmount: balanceAmount > 0 || paidAmount > 0
          ? balanceAmount
          : (totalBalance > 0 || paidAmount > 0 ? totalBalance : (previousBalance + (todayBalance > 0 ? todayBalance : dayTotalAmountRaw) - paidAmount)),
      notes: (json['notes'] ?? '').toString(),
      animals: animals,
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class PaymentLedgerAnimal {
  final String animalName;
  final String tagNumber;
  final int panId;
  final String panName;
  final double morningMilk;
  final double afternoonMilk;
  final double eveningMilk;
  final double totalMilk;

  const PaymentLedgerAnimal({
    required this.animalName,
    required this.tagNumber,
    this.panId = 0,
    this.panName = '',
    required this.morningMilk,
    required this.afternoonMilk,
    required this.eveningMilk,
    required this.totalMilk,
  });

  factory PaymentLedgerAnimal.fromJson(Map<String, dynamic> json) {
    return PaymentLedgerAnimal(
      animalName: (json['animal_name'] ?? '-').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      panId: _toInt(json['pan_id']),
      panName: (json['pan_name'] ?? '').toString(),
      morningMilk: _toDouble(json['morning_milk']),
      afternoonMilk: _toDouble(json['afternoon_milk']),
      eveningMilk: _toDouble(json['evening_milk']),
      totalMilk: _toDouble(json['total_milk']),
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
