import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cached_api_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../core/utils/api.dart';

class MilkHistoryView extends StatefulWidget {
  const MilkHistoryView({
    super.key,
    this.initialAnimalId,
    this.initialAnimalName = '',
    this.initialTagNumber = '',
  });

  final int? initialAnimalId;
  final String initialAnimalName;
  final String initialTagNumber;

  @override
  State<MilkHistoryView> createState() => _MilkHistoryViewState();
}

class _MilkHistoryViewState extends State<MilkHistoryView> {
  bool _isLoading = true;
  int _farmerId = 0;
  final List<_MilkHistoryItem> _history = <_MilkHistoryItem>[];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  List<_MilkHistoryItem> get _visibleHistory {
    final query = _searchController.text.trim().toLowerCase();
    final selectedAnimalId = widget.initialAnimalId ?? 0;
    final selectedName = widget.initialAnimalName.trim();
    final selectedTag = widget.initialTagNumber.trim();
    return _history.where((item) {
      final matchesAnimalFilter =
          (selectedAnimalId <= 0 &&
              selectedName.isEmpty &&
              selectedTag.isEmpty) ||
          item.matchesAnimal(
            animalId: selectedAnimalId,
            animalName: selectedName,
            tagNumber: selectedTag,
          );
      if (!matchesAnimalFilter) {
        return false;
      }

      final itemDate = _dateOnly(item.sortDate);
      if (_fromDate != null && itemDate.isBefore(_dateOnly(_fromDate!))) {
        return false;
      }
      if (_toDate != null && itemDate.isAfter(_dateOnly(_toDate!))) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }
      return item.matchesSearch(query);
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _fromDate != null ||
      _toDate != null;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _farmerId = prefs.getInt('farmer_id') ?? 0;
      if (_farmerId == 0) {
        if (mounted) {
          Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
        }
        setState(() => _isLoading = false);
        return;
      }

      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List items = (data['data'] as List?) ?? [];
        _history
          ..clear()
          ..addAll(
            items
                .map(
                  (e) => _MilkHistoryItem.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList(),
          );

        _history.sort((a, b) => b.sortDate.compareTo(a.sortDate));
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }

      final data = await CachedApiService.instance.getMap(
        key: 'milk_list_$_farmerId',
        uri: Uri.parse('${Api.milkList}/$_farmerId'),
        onCached: apply,
      );
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (_history.isEmpty) {
        _history.clear();
      }
    } catch (_) {
      if (_history.isEmpty && mounted) {
        _history.clear();
        Get.snackbar('error'.tr, 'unable_load_milk_history'.tr);
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
    var sheetClosedAfterSuccess = false;

    Future<void> pickDate() async {
      DateTime initialDate = DateTime.now();
      try {
        initialDate = DateFormat(
          'dd/MM/yyyy',
        ).parse(dateController.text.trim());
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
                      Text(
                        'edit_milk_entry'.tr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedShift.value,
                        decoration: _inputDecoration('shift'.tr),
                        items: [
                          DropdownMenuItem(
                            value: 'Morning',
                            child: Text('morning'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'Afternoon',
                            child: Text('afternoon'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'Evening',
                            child: Text('evening'.tr),
                          ),
                        ],
                        onChanged: (value) {
                          selectedShift.value = value ?? 'Morning';
                          quantityController.text = item.quantityForShift(
                            selectedShift.value,
                          );
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration('quantity'.tr),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: _inputDecoration('date'.tr).copyWith(
                          suffixIcon: const Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fatController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _inputDecoration('fat_upper'.tr),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: snfController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _inputDecoration('snf_upper'.tr),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration('rate'.tr),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving.value
                              ? null
                              : () async {
                                  final qty = quantityController.text.trim();
                                  if (qty.isEmpty ||
                                      (double.tryParse(qty) ?? -1) < 0) {
                                    Get.snackbar(
                                      'error'.tr,
                                      'please_enter_valid_quantity'.tr,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }

                                  try {
                                    isSaving.value = true;
                                    final payload = {
                                      'farmer_id': _farmerId.toString(),
                                      'dairy_id': item.dairyId > 0
                                          ? item.dairyId.toString()
                                          : '',
                                      'date': _formatDateForApi(
                                        dateController.text.trim(),
                                      ),
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

                                    if (response.statusCode == 200 &&
                                        data['status'] == true) {
                                      sheetClosedAfterSuccess = true;
                                      Get.back();
                                      Get.snackbar(
                                        'success'.tr,
                                        data['message']?.toString() ??
                                            'milk_entry_updated_success'.tr,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      await _loadHistory();
                                    } else {
                                      Get.snackbar(
                                        'error'.tr,
                                        data['message']?.toString() ??
                                            'failed_update_milk_entry'.tr,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    }
                                  } catch (e) {
                                    Get.snackbar(
                                      'error'.tr,
                                      e.toString(),
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } finally {
                                    if (!sheetClosedAfterSuccess) {
                                      isSaving.value = false;
                                    }
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
                              : Text('update_entry'.tr),
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
  }

  String _formatDateForApi(String value) {
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(value);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return value;
    }
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _pickFilterDate({required bool isFrom}) async {
    final currentValue = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null &&
            _dateOnly(_toDate!).isBefore(_dateOnly(picked))) {
          _toDate = picked;
        }
      } else {
        _toDate = picked;
        if (_fromDate != null &&
            _dateOnly(_fromDate!).isAfter(_dateOnly(picked))) {
          _fromDate = picked;
        }
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _fromDate = null;
      _toDate = null;
    });
  }

  String _formatFilterDate(DateTime? value, String fallback) {
    if (value == null) return fallback;
    return DateFormat('dd MMM yyyy').format(value);
  }

  String _formatQuantity(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return value.trim().isEmpty ? '-' : value;
    }
    if (parsed == parsed.toInt()) {
      return parsed.toInt().toString();
    }
    return parsed.toStringAsFixed(1);
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDateButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBF8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFilterDate(value, label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shiftTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatQuantity(value)} L',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.4,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleHistory = _visibleHistory;
    final visibleGroups = _MilkHistoryGroup.build(visibleHistory);
    final totalMilk = visibleHistory.fold<double>(
      0,
      (sum, item) => sum + item.totalMilkValue,
    );
    final rangeStart = visibleHistory.isEmpty
        ? null
        : visibleHistory.last.sortDate;
    final rangeEnd = visibleHistory.isEmpty
        ? null
        : visibleHistory.first.sortDate;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF4EA857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          widget.initialAnimalName.trim().isEmpty
              ? 'milk_record'.tr
              : '${widget.initialAnimalName.trim()} ${'milk_record'.tr}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF6BB56E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.local_drink_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'milk_record'.tr,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rangeStart != null && rangeEnd != null
                                        ? 'range_from_to'.trParams({
                                            'from': DateFormat(
                                              'dd MMM',
                                            ).format(rangeStart),
                                            'to': DateFormat(
                                              'dd MMM',
                                            ).format(rangeEnd),
                                          })
                                        : 'no_milk_history_found'.tr,
                                    style: TextStyle(
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _summaryTile(
                              icon: Icons.receipt_long_rounded,
                              label: 'milk_record'.tr,
                              value: visibleHistory.length.toString(),
                            ),
                            const SizedBox(width: 10),
                            _summaryTile(
                              icon: Icons.water_drop_rounded,
                              label: 'total_milk'.tr,
                              value: '${totalMilk.toStringAsFixed(1)} L',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'search_by_animal_name_or_tag'.tr,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () => _searchController.clear(),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                    ),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF8FBF8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _filterDateButton(
                              label: 'from_date'.tr,
                              value: _fromDate,
                              onTap: () => _pickFilterDate(isFrom: true),
                            ),
                            const SizedBox(width: 10),
                            _filterDateButton(
                              label: 'to_date'.tr,
                              value: _toDate,
                              onTap: () => _pickFilterDate(isFrom: false),
                            ),
                          ],
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text('clear'.tr),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visibleGroups.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'no_milk_history_found'.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${'from_date'.tr}: ${_formatFilterDate(_fromDate, '-')}   ${'to_date'.tr}: ${_formatFilterDate(_toDate, '-')}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...visibleGroups.map((group) {
                      final item = group.first;
                      final isPanGroup = group.isPanGroup;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.045),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isPanGroup
                                        ? Icons.grid_view_rounded
                                        : Icons.pets_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPanGroup
                                            ? '${item.panName.trim().isEmpty ? '-' : item.panName} (${group.entries.length} ${'animals'.tr})'
                                            : (item.animalName.trim().isEmpty
                                                  ? '-'
                                                  : item.animalName),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      if (!isPanGroup) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _infoChip(
                                              Icons
                                                  .confirmation_number_outlined,
                                              '${'tag'.tr}: ${item.tagNumber.trim().isEmpty ? '-' : item.tagNumber}',
                                            ),
                                            if (item.panId > 0)
                                              _infoChip(
                                                Icons.grid_view_rounded,
                                                '${'pan'.tr}: ${item.panName.trim().isEmpty ? '-' : item.panName}',
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '${_formatQuantity(group.totalMilkValue.toString())} L',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    if (!isPanGroup)
                                      IconButton(
                                        onPressed: () => _onEditTap(item),
                                        icon: const Icon(Icons.edit_rounded),
                                        color: AppColors.primary,
                                        tooltip: 'edit_animal'.tr,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAF7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.date,
                                      style: const TextStyle(
                                        fontSize: 13.2,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${'rate'.tr}: Rs. ${item.rate}/ltr',
                                    style: TextStyle(
                                      fontSize: 12.6,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _shiftTile(
                                  label: 'morning'.tr,
                                  value: isPanGroup
                                      ? group.morningTotal.toString()
                                      : item.morningMilk,
                                  icon: Icons.wb_sunny_outlined,
                                ),
                                const SizedBox(width: 10),
                                _shiftTile(
                                  label: 'afternoon'.tr,
                                  value: isPanGroup
                                      ? group.afternoonTotal.toString()
                                      : item.afternoonMilk,
                                  icon: Icons.light_mode_outlined,
                                ),
                                const SizedBox(width: 10),
                                _shiftTile(
                                  label: 'evening'.tr,
                                  value: isPanGroup
                                      ? group.eveningTotal.toString()
                                      : item.eveningMilk,
                                  icon: Icons.nights_stay_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _infoChip(
                                  Icons.opacity_rounded,
                                  '${'fat_upper'.tr}: ${item.fat}',
                                ),
                                _infoChip(
                                  Icons.science_outlined,
                                  '${'snf_upper'.tr}: ${item.snf}',
                                ),
                                _infoChip(
                                  Icons.calculate_outlined,
                                  '${'total'.tr}: ${_formatQuantity(group.totalMilkValue.toString())} L',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }
}

class _MilkHistoryItem {
  _MilkHistoryItem({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.tagNumber,
    required this.dairyId,
    required this.date,
    required this.sortDate,
    required this.dairyName,
    required this.panId,
    required this.panName,
    required this.morningMilk,
    required this.afternoonMilk,
    required this.eveningMilk,
    required this.totalMilk,
    required this.fat,
    required this.snf,
    required this.rate,
  });

  final int id;
  final int animalId;
  final String animalName;
  final String tagNumber;
  final int dairyId;
  final String date;
  final DateTime sortDate;
  final String dairyName;
  final int panId;
  final String panName;
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

  double get totalMilkValue => double.tryParse(totalMilk) ?? 0;

  bool matchesAnimal({
    required int animalId,
    required String animalName,
    required String tagNumber,
  }) {
    if (animalId > 0 && this.animalId > 0) {
      return this.animalId == animalId;
    }
    final normalizedName = animalName.trim().toLowerCase();
    final normalizedTag = tagNumber.trim().toLowerCase();
    final currentName = this.animalName.trim().toLowerCase();
    final currentTag = this.tagNumber.trim().toLowerCase();
    if (normalizedTag.isNotEmpty && currentTag.isNotEmpty) {
      return currentTag == normalizedTag;
    }
    return normalizedName.isNotEmpty && currentName == normalizedName;
  }

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final haystack = <String>[
      animalName,
      tagNumber,
      dairyName,
      date,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }

  bool get hasPan => panId > 0 || panName.trim().isNotEmpty;

  String get groupKey {
    if (panId > 0) return 'pan_id_${panId}_$date';
    final normalizedPan = panName.trim().toLowerCase();
    if (normalizedPan.isNotEmpty) return 'pan_name_${normalizedPan}_$date';
    return 'item_$id';
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
      animalId: int.tryParse((json['animal_id'] ?? '0').toString()) ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      dairyId: int.tryParse((json['dairy_id'] ?? '0').toString()) ?? 0,
      date: dateText,
      sortDate: parsedDate,
      dairyName: (json['dairy_name'] ?? '-').toString(),
      panId: int.tryParse((json['pan_id'] ?? '0').toString()) ?? 0,
      panName: (json['pan_name'] ?? '').toString(),
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

class _MilkHistoryGroup {
  _MilkHistoryGroup({
    required this.key,
    required this.isPanGroup,
    required this.entries,
  });

  final String key;
  final bool isPanGroup;
  final List<_MilkHistoryItem> entries;

  _MilkHistoryItem get first => entries.first;

  double get morningTotal => entries.fold<double>(
    0,
    (sum, e) => sum + (double.tryParse(e.morningMilk) ?? 0),
  );
  double get afternoonTotal => entries.fold<double>(
    0,
    (sum, e) => sum + (double.tryParse(e.afternoonMilk) ?? 0),
  );
  double get eveningTotal => entries.fold<double>(
    0,
    (sum, e) => sum + (double.tryParse(e.eveningMilk) ?? 0),
  );
  double get totalMilkValue =>
      entries.fold<double>(0, (sum, e) => sum + e.totalMilkValue);

  static List<_MilkHistoryGroup> build(List<_MilkHistoryItem> items) {
    final grouped = <String, List<_MilkHistoryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.groupKey, () => <_MilkHistoryItem>[]).add(item);
    }

    final groups =
        grouped.entries
            .map(
              (entry) => _MilkHistoryGroup(
                key: entry.key,
                isPanGroup: entry.value.first.hasPan,
                entries: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.first.sortDate.compareTo(a.first.sortDate));
    return groups;
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
