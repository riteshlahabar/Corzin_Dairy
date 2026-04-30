import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/api.dart';

class MilkHistoryView extends StatefulWidget {
  const MilkHistoryView({super.key});

  @override
  State<MilkHistoryView> createState() => _MilkHistoryViewState();
}

class _MilkHistoryViewState extends State<MilkHistoryView> {
  bool _isLoading = true;
  int _farmerId = 0;
  final List<_MilkHistoryItem> _history = <_MilkHistoryItem>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _farmerId = prefs.getInt('farmer_id') ?? 0;
      if (_farmerId == 0) {
        if (mounted) {
          Get.snackbar('Error', 'Farmer not found. Please login again.');
        }
        setState(() => _isLoading = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${Api.milkList}/$_farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final List items = (data['data'] as List?) ?? [];

      _history
        ..clear()
        ..addAll(items.map((e) => _MilkHistoryItem.fromJson((e as Map).cast<String, dynamic>())).toList());

      _history.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    } catch (_) {
      _history.clear();
      if (mounted) {
        Get.snackbar('Error', 'Unable to load milk history');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onEditTap(_MilkHistoryItem item) async {
    final dateController = TextEditingController(text: item.date);
    final fatController = TextEditingController(text: item.fat);
    final snfController = TextEditingController(text: item.snf);
    final rateController = TextEditingController(text: item.rate);
    final quantityController = TextEditingController(text: item.editQuantity);
    final selectedShift = item.editShift.obs;
    final isSaving = false.obs;

    Future<void> pickDate() async {
      DateTime initialDate = DateTime.now();
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(dateController.text.trim());
      } catch (_) {}
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      }
    }

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (_, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Milk Entry',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedShift.value,
                        decoration: _inputDecoration('Shift'),
                        items: const [
                          DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                          DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                        ],
                        onChanged: (value) {
                          selectedShift.value = value ?? 'Morning';
                          quantityController.text = item.quantityForShift(selectedShift.value);
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Quantity'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: _inputDecoration('Date').copyWith(
                          suffixIcon: const Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fatController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration('FAT'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: snfController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration('SNF'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Rate'),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving.value
                              ? null
                              : () async {
                                  final qty = quantityController.text.trim();
                                  if (qty.isEmpty || (double.tryParse(qty) ?? -1) < 0) {
                                    Get.snackbar(
                                      'Error',
                                      'Please enter valid quantity',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }

                                  try {
                                    isSaving.value = true;
                                    final payload = {
                                      'farmer_id': _farmerId.toString(),
                                      'dairy_id': item.dairyId > 0 ? item.dairyId.toString() : '',
                                      'date': _formatDateForApi(dateController.text.trim()),
                                      'shift': selectedShift.value,
                                      'quantity': qty,
                                      'fat': fatController.text.trim(),
                                      'snf': snfController.text.trim(),
                                      'rate': rateController.text.trim(),
                                    };

                                    final response = await http.post(
                                      Uri.parse('${Api.milkUpdate}/${item.id}'),
                                      headers: {
                                        'Accept': 'application/json',
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode(payload),
                                    );
                                    final data = response.body.isNotEmpty
                                        ? jsonDecode(response.body)
                                        : {};

                                    if (response.statusCode == 200 && data['status'] == true) {
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        data['message']?.toString() ??
                                            'Milk entry updated successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      await _loadHistory();
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        data['message']?.toString() ??
                                            'Failed to update milk entry',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    }
                                  } catch (e) {
                                    Get.snackbar(
                                      'Error',
                                      e.toString(),
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } finally {
                                    isSaving.value = false;
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: isSaving.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Update Entry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );

    dateController.dispose();
    fatController.dispose();
    snfController.dispose();
    rateController.dispose();
    quantityController.dispose();
  }

  String _formatDateForApi(String value) {
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(value);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
                ? const Center(
                    child: Text(
                      'No milk history found',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = _history[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F8F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.animalDisplay,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _onEditTap(item),
                                  icon: const Icon(Icons.edit_rounded),
                                  color: AppColors.primary,
                                  tooltip: 'Edit',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dairy: ${item.dairyName}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: ${item.date}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Morning: ${item.morningMilk} L  |  Afternoon: ${item.afternoonMilk} L  |  Evening: ${item.eveningMilk} L',
                              style: const TextStyle(fontSize: 13.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${item.totalMilk} L  |  FAT: ${item.fat}  |  SNF: ${item.snf}  |  Rate: ${item.rate}',
                              style: const TextStyle(
                                fontSize: 13.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _MilkHistoryItem {
  _MilkHistoryItem({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.dairyId,
    required this.date,
    required this.sortDate,
    required this.dairyName,
    required this.morningMilk,
    required this.afternoonMilk,
    required this.eveningMilk,
    required this.totalMilk,
    required this.fat,
    required this.snf,
    required this.rate,
  });

  final int id;
  final String animalName;
  final String tagNumber;
  final int dairyId;
  final String date;
  final DateTime sortDate;
  final String dairyName;
  final String morningMilk;
  final String afternoonMilk;
  final String eveningMilk;
  final String totalMilk;
  final String fat;
  final String snf;
  final String rate;

  String get animalDisplay {
    if (tagNumber.trim().isEmpty) return animalName;
    return '$animalName (Tag: $tagNumber)';
  }

  String get editShift {
    final morning = double.tryParse(morningMilk) ?? 0;
    final afternoon = double.tryParse(afternoonMilk) ?? 0;
    final evening = double.tryParse(eveningMilk) ?? 0;
    if (morning > 0) return 'Morning';
    if (afternoon > 0) return 'Afternoon';
    if (evening > 0) return 'Evening';
    return 'Morning';
  }

  String get editQuantity => quantityForShift(editShift);

  String quantityForShift(String shift) {
    switch (shift) {
      case 'Morning':
        return morningMilk;
      case 'Afternoon':
        return afternoonMilk;
      case 'Evening':
        return eveningMilk;
      default:
        return morningMilk;
    }
  }

  factory _MilkHistoryItem.fromJson(Map<String, dynamic> json) {
    final dateText = (json['date'] ?? '').toString();
    DateTime parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      parsedDate = DateFormat('dd/MM/yyyy').parse(dateText);
    } catch (_) {}

    return _MilkHistoryItem(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      dairyId: int.tryParse((json['dairy_id'] ?? '0').toString()) ?? 0,
      date: dateText,
      sortDate: parsedDate,
      dairyName: (json['dairy_name'] ?? '-').toString(),
      morningMilk: (json['morning_milk'] ?? '0').toString(),
      afternoonMilk: (json['afternoon_milk'] ?? '0').toString(),
      eveningMilk: (json['evening_milk'] ?? '0').toString(),
      totalMilk: (json['total_milk'] ?? '0').toString(),
      fat: (json['fat'] ?? '-').toString(),
      snf: (json['snf'] ?? '-').toString(),
      rate: (json['rate'] ?? '-').toString(),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FBF8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
