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
  int _selectedTab = 0;
  bool _isLoading = true;
  bool _isFeedTypeLoading = true;
  int _farmerId = 0;
  final List<_FeedingHistoryItem> _history = <_FeedingHistoryItem>[];
  final List<_FeedTypeEditorItem> _feedTypes = <_FeedTypeEditorItem>[];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadFarmerId();
    await Future.wait([_loadHistory(), _loadFeedTypes()]);
  }

  Future<void> _loadFarmerId() async {
    if (_farmerId > 0) return;
    final prefs = await SharedPreferences.getInstance();
    _farmerId = prefs.getInt('farmer_id') ?? 0;
    if (_farmerId == 0 && mounted) {
      Get.snackbar('Error', 'Farmer not found. Please login again.');
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      await _loadFarmerId();
      if (_farmerId == 0) {
        _history.clear();
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
        ..addAll(items.map((e) => _FeedingHistoryItem.fromJson(e)).toList());
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

  Future<void> _loadFeedTypes() async {
    setState(() => _isFeedTypeLoading = true);
    try {
      await _loadFarmerId();
      if (_farmerId == 0) {
        _feedTypes.clear();
        return;
      }
      final response = await http.get(
        Uri.parse('${Api.feedingTypes}?farmer_id=$_farmerId'),
        headers: {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final List items = (data['data'] as List?) ?? [];

      _feedTypes
        ..clear()
        ..addAll(items.map((e) => _FeedTypeEditorItem.fromJson(e)).toList());
    } catch (_) {
      _feedTypes.clear();
      if (mounted) {
        Get.snackbar('Error', 'Unable to load feed type content');
      }
    } finally {
      if (mounted) {
        setState(() => _isFeedTypeLoading = false);
      }
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (_selectedTab == 0) {
      await _loadHistory();
    } else {
      await Future.wait([_loadFeedTypes(), _loadHistory()]);
    }
  }

  Future<void> _onEditTap(_FeedingHistoryItem item) async {
    final quantityController = TextEditingController(text: item.quantity);
    final unitController = TextEditingController(text: item.unit);
    final notesController = TextEditingController(text: item.notes);
    final dateController = TextEditingController(text: item.date);
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
                      TextField(
                        controller: unitController,
                        decoration: _inputDecoration('Unit'),
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
                                      dateController.text.trim().isEmpty ||
                                      unitController.text.trim().isEmpty) {
                                    Get.snackbar('Error', 'Quantity, unit and date are required');
                                    return;
                                  }

                                  try {
                                    isSaving.value = true;
                                    final payload = {
                                      'farmer_id': _farmerId.toString(),
                                      'quantity': quantityController.text.trim(),
                                      'unit': unitController.text.trim(),
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
    unitController.dispose();
    notesController.dispose();
    dateController.dispose();
  }

  Future<void> _onFeedContentEditTap(_FeedingHistoryItem item) async {
    final linkedType = _findLinkedFeedType(item);
    final subtypeNames = <String>{
      ...?linkedType?.subtypes.map((e) => e.trim()).where((e) => e.isNotEmpty),
      ...item.feedSubtypeDetails.map((e) => e.name.trim()).where((e) => e.isNotEmpty),
    }.toList();

    if (subtypeNames.isEmpty) {
      Get.snackbar('Error', 'No subtype data found to edit');
      return;
    }

    final subtypeControllers = <String, TextEditingController>{};
    final subtypeSelected = <String, bool>{}.obs;
    final subtypeIdByName = <String, int>{};
    final totalSubtypeQuantity = 0.0.obs;
    final balanceQuantity = 0.0.obs;
    final feedQuantityController = TextEditingController(
      text: item.feedingQuantityText,
    );
    final notesController = TextEditingController(text: item.notes);
    final isSaving = false.obs;

    _FeedSubtypeDetail? findDetailByName(String name) {
      for (final detail in item.feedSubtypeDetails) {
        if (detail.name.trim().toLowerCase() == name.trim().toLowerCase()) {
          return detail;
        }
      }
      return null;
    }

    for (final name in subtypeNames) {
      final detail = findDetailByName(name);
      final qty = detail?.quantity ?? 0;
      subtypeSelected[name] = qty > 0;
      if ((detail?.subtypeId ?? 0) > 0) {
        subtypeIdByName[name] = detail!.subtypeId;
      }
      final controller = TextEditingController(
        text: qty > 0 ? _formatQuantity(qty) : '',
      );
      controller.addListener(() {
        double total = 0;
        for (final entry in subtypeControllers.entries) {
          if (!(subtypeSelected[entry.key] ?? false)) continue;
          final value = double.tryParse(entry.value.text.trim()) ?? 0;
          if (value > 0) total += value;
        }
        totalSubtypeQuantity.value = total;
        final feeding = double.tryParse(feedQuantityController.text.trim()) ?? 0;
        final nextBalance = total - feeding;
        balanceQuantity.value = nextBalance > 0 ? nextBalance : 0;
      });
      subtypeControllers[name] = controller;
    }

    void recalculateTotals() {
      double total = 0;
      for (final entry in subtypeControllers.entries) {
        if (!(subtypeSelected[entry.key] ?? false)) continue;
        final value = double.tryParse(entry.value.text.trim()) ?? 0;
        if (value > 0) total += value;
      }
      totalSubtypeQuantity.value = total;
      final feeding = double.tryParse(feedQuantityController.text.trim()) ?? 0;
      final nextBalance = total - feeding;
      balanceQuantity.value = nextBalance > 0 ? nextBalance : 0;
    }

    feedQuantityController.addListener(recalculateTotals);
    recalculateTotals();

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Feed Type Content',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.feedType} • ${item.date} • ${item.feedingTime}',
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      ...subtypeNames.map(
                        (name) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: subtypeSelected[name] ?? false,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  subtypeSelected[name] = value ?? false;
                                  if (!(value ?? false)) {
                                    subtypeControllers[name]?.clear();
                                  }
                                  recalculateTotals();
                                  setModalState(() {});
                                },
                              ),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 96,
                                child: TextField(
                                  controller: subtypeControllers[name],
                                  enabled: subtypeSelected[name] ?? false,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration('Qty'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total ${item.unit}: ${totalSubtypeQuantity.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: feedQuantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Feeding Quantity'),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Balance: ${balanceQuantity.value.toStringAsFixed(2)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
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
                                  final feedingQty =
                                      double.tryParse(feedQuantityController.text.trim()) ?? 0;
                                  if (feedingQty <= 0) {
                                    Get.snackbar('Error', 'Please enter valid feeding quantity');
                                    return;
                                  }

                                  final subtypePayload = <Map<String, dynamic>>[];
                                  for (final name in subtypeNames) {
                                    if (!(subtypeSelected[name] ?? false)) continue;
                                    final qty = double.tryParse(
                                          subtypeControllers[name]?.text.trim() ?? '',
                                        ) ??
                                        0;
                                    if (qty <= 0) continue;
                                    subtypePayload.add({
                                      if ((subtypeIdByName[name] ?? 0) > 0)
                                        'subtype_id': subtypeIdByName[name],
                                      'name': name,
                                      'quantity': qty,
                                    });
                                  }

                                  if (subtypePayload.isEmpty) {
                                    Get.snackbar(
                                      'Error',
                                      'Please select at least one subtype with quantity',
                                    );
                                    return;
                                  }

                                  try {
                                    isSaving.value = true;

                                    final payload = {
                                      'farmer_id': _farmerId.toString(),
                                      if (item.animalId > 0) 'animal_id': item.animalId.toString(),
                                      if (item.feedTypeId > 0)
                                        'feed_type_id': item.feedTypeId.toString(),
                                      'feed_type': item.feedType,
                                      'quantity': feedQuantityController.text.trim(),
                                      'feeding_quantity': feedQuantityController.text.trim(),
                                      'package_quantity':
                                          totalSubtypeQuantity.value.toStringAsFixed(2),
                                      'balance_quantity':
                                          balanceQuantity.value.toStringAsFixed(2),
                                      'feed_subtype_details': subtypePayload,
                                      'unit': item.unit,
                                      'feeding_time': item.feedingTime,
                                      'date': item.date,
                                      'notes': notesController.text.trim(),
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
                                            'Feed content updated successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      await _loadHistory();
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        data['message']?.toString() ??
                                            'Failed to update feed content',
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
                              : const Text('Update Content'),
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

    feedQuantityController.removeListener(recalculateTotals);
    feedQuantityController.dispose();
    notesController.dispose();
    for (final controller in subtypeControllers.values) {
      controller.dispose();
    }
  }

  _FeedTypeEditorItem? _findLinkedFeedType(_FeedingHistoryItem item) {
    for (final type in _feedTypes) {
      if (type.id == item.feedTypeId) {
        return type;
      }
      if (type.name.trim().toLowerCase() == item.feedType.trim().toLowerCase()) {
        return type;
      }
    }
    return null;
  }

  String _formatQuantity(double value) {
    return _formatDoubleToText(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _segmentButton(
                    title: 'Feeding History',
                    selected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _segmentButton(
                    title: 'Edit Feed Type Content',
                    selected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _selectedTab == 0 ? _buildHistoryTab() : _buildFeedTypeTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: _isLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : _history.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 220),
                    Center(
                      child: Text(
                        'No feeding history found',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _history.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                            '${item.feedType} - ${item.quantity} ${item.unit}',
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
    );
  }

  Widget _buildFeedTypeTab() {
    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: (_isFeedTypeLoading || _isLoading)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F8F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Edit wrong subtype quantity from here.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No feed entries found',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ..._history.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _onFeedContentEditTap(item),
                              icon: const Icon(Icons.edit_rounded),
                              color: AppColors.primary,
                              tooltip: 'Edit Feed Content',
                            ),
                          ],
                        ),
                        Text(
                          '${item.feedType} • ${item.quantity} ${item.unit}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Time: ${item.feedingTime} | Date: ${item.date}',
                          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                        ),
                        if (item.feedSubtypeDetails.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.feedSubtypeDetails
                                .map(
                                  (detail) => Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${detail.name}: ${_formatQuantity(detail.quantity)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _segmentButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFE8EFE8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedingHistoryItem {
  _FeedingHistoryItem({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.feedType,
    required this.feedTypeId,
    required this.quantity,
    required this.feedingQuantity,
    required this.packageQuantity,
    required this.balanceQuantity,
    required this.unit,
    required this.feedingTime,
    required this.date,
    required this.notes,
    required this.feedSubtypeDetails,
  });

  final int id;
  final int animalId;
  final String animalName;
  final String tagNumber;
  final String feedType;
  final int feedTypeId;
  final String quantity;
  final double feedingQuantity;
  final double packageQuantity;
  final double balanceQuantity;
  final String unit;
  final String feedingTime;
  final String date;
  final String notes;
  final List<_FeedSubtypeDetail> feedSubtypeDetails;

  String get animalDisplay {
    if (tagNumber.trim().isEmpty) return animalName;
    return '$animalName (Tag: $tagNumber)';
  }

  String get feedingQuantityText {
    if (feedingQuantity > 0) return _formatDoubleToText(feedingQuantity);
    final parsed = double.tryParse(quantity.trim());
    if (parsed == null || parsed <= 0) return quantity;
    return _formatDoubleToText(parsed);
  }

  factory _FeedingHistoryItem.fromJson(Map<String, dynamic> json) {
    return _FeedingHistoryItem(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      animalId: int.tryParse((json['animal_id'] ?? '0').toString()) ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      feedType: (json['feed_type'] ?? '').toString(),
      feedTypeId: int.tryParse((json['feed_type_id'] ?? '0').toString()) ?? 0,
      quantity: (json['quantity'] ?? '').toString(),
      feedingQuantity: double.tryParse((json['feeding_quantity'] ?? '0').toString()) ?? 0,
      packageQuantity: double.tryParse((json['package_quantity'] ?? '0').toString()) ?? 0,
      balanceQuantity: double.tryParse((json['balance_quantity'] ?? '0').toString()) ?? 0,
      unit: (json['unit'] ?? '').toString(),
      feedingTime: (json['feeding_time'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      feedSubtypeDetails: _FeedSubtypeDetail.parse(json['feed_subtype_details']),
    );
  }
}

class _FeedSubtypeDetail {
  _FeedSubtypeDetail({
    required this.subtypeId,
    required this.name,
    required this.quantity,
  });

  final int subtypeId;
  final String name;
  final double quantity;

  factory _FeedSubtypeDetail.fromJson(Map<String, dynamic> json) {
    return _FeedSubtypeDetail(
      subtypeId: int.tryParse((json['subtype_id'] ?? '0').toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      quantity: double.tryParse((json['quantity'] ?? '0').toString()) ?? 0,
    );
  }

  static List<_FeedSubtypeDetail> parse(dynamic raw) {
    List<dynamic> list = <dynamic>[];

    if (raw is List) {
      list = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          list = decoded;
        }
      } catch (_) {}
    }

    return list
        .whereType<Map>()
        .map((item) => _FeedSubtypeDetail.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }
}

String _formatDoubleToText(double value) {
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

class _FeedTypeEditorItem {
  _FeedTypeEditorItem({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.subtypes,
  });

  final int id;
  final String name;
  final String defaultUnit;
  final List<String> subtypes;

  factory _FeedTypeEditorItem.fromJson(Map<String, dynamic> json) {
    final List rawSubtypes = json['subtypes'] is List ? (json['subtypes'] as List) : const [];
    return _FeedTypeEditorItem(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      defaultUnit: (json['default_unit'] ?? 'Kg').toString(),
      subtypes: rawSubtypes
          .map((item) => ((item as Map)['name'] ?? '').toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(),
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
