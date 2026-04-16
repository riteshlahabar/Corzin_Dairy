import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/api.dart';

class FeedingHistoryView extends StatefulWidget {
  const FeedingHistoryView({super.key});

  @override
  State<FeedingHistoryView> createState() => _FeedingHistoryViewState();
}

class _FeedingHistoryViewState extends State<FeedingHistoryView> {
  bool _isLoading = true;
  int _farmerId = 0;
  final List<_FeedingHistoryItem> _history = <_FeedingHistoryItem>[];

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
        Uri.parse('${Api.feedingList}/$_farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final List items = (data['data'] as List?) ?? [];

      _history
        ..clear()
        ..addAll(
          items.map((e) => _FeedingHistoryItem.fromJson(e)).toList(),
        );
    } catch (_) {
      _history.clear();
      if (mounted) {
        Get.snackbar('Error', 'Unable to load feeding history');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onEditTap(_FeedingHistoryItem item) async {
    final quantityController = TextEditingController(text: item.quantity);
    final notesController = TextEditingController(text: item.notes);
    final dateController = TextEditingController(text: item.date);
    final selectedUnit = item.unit.obs;
    final selectedFeedingTime = item.feedingTime.obs;
    final isSaving = false.obs;

    Future<void> pickDate() async {
      DateTime initialDate = DateTime.now();
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(dateController.text.trim());
      } catch (_) {}
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      }
    }

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setModalState) {
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
                        'Edit Feeding Entry',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Quantity'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedUnit.value,
                        decoration: _inputDecoration('Unit'),
                        items: const [
                          DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                          DropdownMenuItem(value: 'Gram', child: Text('Gram')),
                        ],
                        onChanged: (value) {
                          selectedUnit.value = value ?? 'Kg';
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFeedingTime.value,
                        decoration: _inputDecoration('Feeding Time'),
                        items: const [
                          DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                          DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                          DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                        ],
                        onChanged: (value) {
                          selectedFeedingTime.value = value ?? 'Morning';
                          setModalState(() {});
                        },
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
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: _inputDecoration('Notes'),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving.value
                              ? null
                              : () async {
                                  if (quantityController.text.trim().isEmpty ||
                                      dateController.text.trim().isEmpty) {
                                    Get.snackbar('Error', 'Quantity and date are required');
                                    return;
                                  }

                                  try {
                                    isSaving.value = true;
                                    final payload = {
                                      'farmer_id': _farmerId.toString(),
                                      'quantity': quantityController.text.trim(),
                                      'unit': selectedUnit.value,
                                      'feeding_time': selectedFeedingTime.value,
                                      'date': dateController.text.trim(),
                                      'notes': notesController.text.trim(),
                                      if (item.feedTypeId > 0)
                                        'feed_type_id': item.feedTypeId.toString(),
                                    };

                                    final response = await http.post(
                                      Uri.parse('${Api.feedingUpdate}/${item.id}'),
                                      headers: {
                                        'Accept': 'application/json',
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode(payload),
                                    );
                                    final data = response.body.isNotEmpty
                                        ? jsonDecode(response.body)
                                        : {};

                                    if (response.statusCode == 200 &&
                                        data['status'] == true) {
                                      Get.back();
                                      Get.snackbar(
                                        'Success',
                                        data['message']?.toString() ??
                                            'Feeding entry updated successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      await _loadHistory();
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        data['message']?.toString() ??
                                            'Failed to update feeding entry',
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

    quantityController.dispose();
    notesController.dispose();
    dateController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding History'),
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
                  'No feeding history found',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _history.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
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
                          '${item.feedType}  •  ${item.quantity} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: ${item.feedingTime}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Date: ${item.date}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (item.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${item.notes}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _FeedingHistoryItem {
  _FeedingHistoryItem({
    required this.id,
    required this.animalName,
    required this.tagNumber,
    required this.feedType,
    required this.feedTypeId,
    required this.quantity,
    required this.unit,
    required this.feedingTime,
    required this.date,
    required this.notes,
  });

  final int id;
  final String animalName;
  final String tagNumber;
  final String feedType;
  final int feedTypeId;
  final String quantity;
  final String unit;
  final String feedingTime;
  final String date;
  final String notes;

  String get animalDisplay {
    if (tagNumber.trim().isEmpty) return animalName;
    return '$animalName (Tag: $tagNumber)';
  }

  factory _FeedingHistoryItem.fromJson(Map<String, dynamic> json) {
    return _FeedingHistoryItem(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      feedType: (json['feed_type'] ?? '').toString(),
      feedTypeId: int.tryParse((json['feed_type_id'] ?? '0').toString()) ?? 0,
      quantity: (json['quantity'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      feedingTime: (json['feeding_time'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
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
