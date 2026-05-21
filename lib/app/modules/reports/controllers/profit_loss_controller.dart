import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class ProfitLossController extends GetxController {
  final RxBool isLoading = false.obs;
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final Rx<ProfitLossSummary> summary = ProfitLossSummary.zero().obs;
  final RxList<ProfitLossDetailRow> detailRows = <ProfitLossDetailRow>[].obs;

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDateController.text = DateFormat('dd/MM/yyyy').format(
      DateTime(now.year, now.month, 1),
    );
    toDateController.text = DateFormat('dd/MM/yyyy').format(now);
    unawaited(_boot());
  }

  Future<void> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
    await fetchSummary();
  }

  Future<void> pickFromDate(BuildContext context) async {
    final picked = await _pickDate(context, fromDateController.text);
    if (picked == null) return;
    fromDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    await fetchSummary();
  }

  Future<void> pickToDate(BuildContext context) async {
    final picked = await _pickDate(context, toDateController.text);
    if (picked == null) return;
    toDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    await fetchSummary();
  }

  Future<DateTime?> _pickDate(BuildContext context, String existingText) async {
    final parsed = _parseDisplayDate(existingText) ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: parsed,
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

  Future<void> fetchSummary() async {
    if (farmerId == 0) {
      summary.value = ProfitLossSummary.zero();
      detailRows.clear();
      return;
    }
    final query = <String, String>{
      'from_date': _apiDate(fromDateController.text.trim()),
      'to_date': _apiDate(toDateController.text.trim()),
    };

    try {
      isLoading.value = true;
      final uri = Uri.parse('${Api.profitLossReport}/$farmerId').replace(
        queryParameters: query,
      );
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || body['status'] != true) {
        summary.value = ProfitLossSummary.zero();
        return;
      }
      final data = body['data'] is Map ? Map<String, dynamic>.from(body['data']) : <String, dynamic>{};
      summary.value = ProfitLossSummary.fromJson(data);
      detailRows.assignAll(await _buildProfitLossRows());
    } catch (_) {
      summary.value = ProfitLossSummary.zero();
      detailRows.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ProfitLossDetailRow>> _buildProfitLossRows() async {
    final start = _parseDisplayDate(fromDateController.text.trim()) ?? DateTime.now();
    final end = _parseDisplayDate(toDateController.text.trim()) ?? DateTime.now();
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final results = await Future.wait<List<Map<String, dynamic>>>([
      _fetchList('${Api.animalList}/$farmerId'),
      _fetchList('${Api.milkList}/$farmerId'),
      _fetchList('${Api.doctorAppointmentsByFarmer}/$farmerId'),
    ]);

    final animals = results[0];
    final milk = results[1];
    final appointments = results[2];

    final animalInfo = <int, _ProfitAnimalInfo>{};
    for (final item in animals) {
      final id = _toInt(item['id']);
      if (id <= 0) continue;
      animalInfo[id] = _ProfitAnimalInfo(
        id: id,
        panName: _toText(item['pan_name']),
        animalName: _toText(item['animal_name']),
        tagNumber: _toText(item['tag_number']),
      );
    }

    final debitByKey = <String, double>{};
    for (final item in appointments) {
      final status = _toText(item['status']).toLowerCase();
      if (!(status == 'completed' || status == 'approved' || status == 'in_progress')) {
        continue;
      }
      final date = _parseAnyDate(item['completed_at']) ??
          _parseAnyDate(item['accepted_at']) ??
          _parseAnyDate(item['requested_at']);
      if (!_isInRange(date, startDate, endDate)) continue;
      final animalId = _toInt(item['animal_id']);
      if (animalId <= 0) continue;
      final fees = _toDouble(item['fees']);
      final med = _toDouble(item['on_site_medicine_charges']);
      final total = _toDouble(item['charges']) > 0 ? _toDouble(item['charges']) : (fees + med);
      final key = '${_dateKey(date)}|$animalId';
      debitByKey[key] = (debitByKey[key] ?? 0) + total;
    }

    final creditByKey = <String, double>{};
    for (final item in milk) {
      final date = _parseAnyDate(item['date']);
      if (!_isInRange(date, startDate, endDate)) continue;
      final animalId = _toInt(item['animal_id']);
      if (animalId <= 0) continue;
      final amount = _toDouble(item['total_milk']) * _toDouble(item['rate']);
      final key = '${_dateKey(date)}|$animalId';
      creditByKey[key] = (creditByKey[key] ?? 0) + amount;
    }

    final keys = <String>{...debitByKey.keys, ...creditByKey.keys}.toList()
      ..sort((a, b) => b.compareTo(a));
    final rows = <ProfitLossDetailRow>[];
    for (final key in keys) {
      final parts = key.split('|');
      if (parts.length != 2) continue;
      final date = _parseAnyDate(parts[0]);
      final animalId = int.tryParse(parts[1]) ?? 0;
      final animal = animalInfo[animalId];
      final debit = debitByKey[key] ?? 0;
      final credit = creditByKey[key] ?? 0;
      rows.add(
        ProfitLossDetailRow(
          date: _formatDate(date),
          penName: animal?.panName ?? '-',
          cowName: animal?.animalName ?? '-',
          cowTagNo: animal?.tagNumber ?? '-',
          id: animalId > 0 ? '$animalId' : '-',
          debit: debit,
          credit: credit,
          total: credit - debit,
        ),
      );
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> _fetchList(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
      );
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (response.statusCode != 200 || body is! Map || body['status'] != true) {
        return const <Map<String, dynamic>>[];
      }
      final data = body['data'];
      if (data is! List) return const <Map<String, dynamic>>[];
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  DateTime? _parseAnyDate(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    const formats = <String>[
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'd-M-yyyy H:mm',
    ];
    for (final format in formats) {
      try {
        return DateFormat(format).parse(value);
      } catch (_) {}
    }
    return null;
  }

  bool _isInRange(DateTime? date, DateTime start, DateTime end) {
    if (date == null) return false;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  String _dateKey(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _toText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  String _apiDate(String display) {
    final parsed = _parseDisplayDate(display) ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  DateTime? _parseDisplayDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(raw.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.onClose();
  }
}

class ProfitLossSummary {
  final double milkEarning;
  final double doctorCost;
  final double medicineCost;
  final double totalExpenses;
  final double netProfit;
  final int appointmentCount;

  const ProfitLossSummary({
    required this.milkEarning,
    required this.doctorCost,
    required this.medicineCost,
    required this.totalExpenses,
    required this.netProfit,
    required this.appointmentCount,
  });

  bool get isProfit => netProfit >= 0;

  factory ProfitLossSummary.fromJson(Map<String, dynamic> json) {
    return ProfitLossSummary(
      milkEarning: _toDouble(json['milk_earning']),
      doctorCost: _toDouble(json['doctor_cost']),
      medicineCost: _toDouble(json['medicine_cost']),
      totalExpenses: _toDouble(json['total_expenses']),
      netProfit: _toDouble(json['net_profit']),
      appointmentCount: int.tryParse((json['appointment_count'] ?? '').toString()) ?? 0,
    );
  }

  factory ProfitLossSummary.zero() {
    return const ProfitLossSummary(
      milkEarning: 0,
      doctorCost: 0,
      medicineCost: 0,
      totalExpenses: 0,
      netProfit: 0,
      appointmentCount: 0,
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class ProfitLossDetailRow {
  final String date;
  final String penName;
  final String cowName;
  final String cowTagNo;
  final String id;
  final double debit;
  final double credit;
  final double total;

  const ProfitLossDetailRow({
    required this.date,
    required this.penName,
    required this.cowName,
    required this.cowTagNo,
    required this.id,
    required this.debit,
    required this.credit,
    required this.total,
  });
}

class _ProfitAnimalInfo {
  final int id;
  final String panName;
  final String animalName;
  final String tagNumber;

  const _ProfitAnimalInfo({
    required this.id,
    required this.panName,
    required this.animalName,
    required this.tagNumber,
  });
}
