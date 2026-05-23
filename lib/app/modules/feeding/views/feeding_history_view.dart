import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../core/utils/api.dart';

class FeedingHistoryView extends StatefulWidget {
  const FeedingHistoryView({
    super.key,
    this.initialTab = 0,
    this.showTabs = true,
    this.initialAnimalId,
    this.initialAnimalName = '',
    this.initialTagNumber = '',
  });

  final int initialTab;
  final bool showTabs;
  final int? initialAnimalId;
  final String initialAnimalName;
  final String initialTagNumber;

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

  List<_FeedingHistoryItem> get _visibleHistory {
    final selectedAnimalId = widget.initialAnimalId ?? 0;
    final selectedName = widget.initialAnimalName.trim();
    final selectedTag = widget.initialTagNumber.trim();
    if (selectedAnimalId <= 0 && selectedName.isEmpty && selectedTag.isEmpty) {
      return _history;
    }
    return _history
        .where(
          (item) => item.matchesAnimal(
            animalId: selectedAnimalId,
            animalName: selectedName,
            tagNumber: selectedTag,
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 1).toInt();
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
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
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
        Get.snackbar('error'.tr, 'unable_load_feeding_history'.tr);
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
        Get.snackbar('error'.tr, 'unable_load_feed_type_content'.tr);
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
                      Text(
                        'edit_feeding_entry'.tr,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('quantity'.tr),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: unitController,
                        decoration: _inputDecoration('unit'.tr),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFeedingTime.value,
                        decoration: _inputDecoration('feeding_time'.tr),
                        items: [
                          DropdownMenuItem(value: 'Morning', child: Text('morning'.tr)),
                          DropdownMenuItem(value: 'Afternoon', child: Text('afternoon'.tr)),
                          DropdownMenuItem(value: 'Evening', child: Text('evening'.tr)),
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
                        decoration: _inputDecoration('date'.tr).copyWith(
                          suffixIcon: const Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: _inputDecoration('notes'.tr),
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
                                    Get.snackbar('error'.tr, 'quantity_unit_date_required'.tr);
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
                                        'success'.tr,
                                        data['message']?.toString() ??
                                            'feeding_entry_updated_success'.tr,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      await _loadHistory();
                                    } else {
                                      Get.snackbar(
                                        'error'.tr,
                                        data['message']?.toString() ??
                                            'failed_update_feeding_entry'.tr,
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
      Get.snackbar('error'.tr, 'no_subtype_data_found'.tr);
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
                      Text(
                        'diet_plan'.tr,
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
                                  decoration: _inputDecoration('qty'.tr),
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
                          '${'total'.tr} ${item.unit}: ${totalSubtypeQuantity.value.toStringAsFixed(2)}',
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
                        decoration: _inputDecoration('feeding_quantity'.tr),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${'balance'.tr}: ${balanceQuantity.value.toStringAsFixed(2)} ${item.unit}',
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
                        decoration: _inputDecoration('notes'.tr),
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
                                    Get.snackbar('error'.tr, 'please_enter_valid_feeding_quantity'.tr);
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
                                        'success'.tr,
                                        data['message']?.toString() ??
                                            'feed_content_updated_success'.tr,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      await _loadHistory();
                                    } else {
                                      Get.snackbar(
                                        'error'.tr,
                                        data['message']?.toString() ??
                                            'failed_update_feed_content'.tr,
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
                              : Text('update_content'.tr),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          widget.initialAnimalName.trim().isNotEmpty
              ? '${widget.initialAnimalName.trim()} ${'feeding_record'.tr}'
              : ((widget.showTabs ? _selectedTab : widget.initialTab) == 0)
              ? 'feeding_record'.tr
              : 'diet_plan'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          if (widget.showTabs) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _segmentButton(
                      title: 'feeding_record'.tr,
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _segmentButton(
                      title: 'diet_plan'.tr,
                      selected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: (widget.showTabs ? _selectedTab : widget.initialTab) == 0
                ? _buildHistoryTab()
                : _buildFeedTypeTab(),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  List<_FeedingHistoryGroup> _buildHistoryGroups() {
    final grouped = <String, List<_FeedingHistoryItem>>{};
    for (final item in _visibleHistory) {
      grouped.putIfAbsent(item.groupKey, () => <_FeedingHistoryItem>[]).add(item);
    }

    final groups = grouped.entries
        .map((entry) {
          final rows = List<_FeedingHistoryItem>.from(entry.value)
            ..sort((a, b) => _historySortKey(b).compareTo(_historySortKey(a)));
          final latest = rows.first;
          return _FeedingHistoryGroup(
            key: entry.key,
            latest: latest,
            entries: rows,
            isPanGroup: latest.hasPan,
          );
        })
        .toList()
      ..sort((a, b) => _historySortKey(b.latest).compareTo(_historySortKey(a.latest)));
    return groups;
  }

  int _historySortKey(_FeedingHistoryItem item) {
    final dt = _parseHistoryDateTime(item.date, item.feedingTime);
    if (dt != null) return dt.millisecondsSinceEpoch;
    return item.id;
  }

  DateTime? _parseHistoryDateTime(String rawDate, String feedingTime) {
    DateTime? date;
    final normalized = rawDate.trim();
    if (normalized.isEmpty) return null;
    try {
      date = DateFormat('yyyy-MM-dd').parseStrict(normalized);
    } catch (_) {
      try {
        date = DateFormat('dd/MM/yyyy').parseStrict(normalized);
      } catch (_) {
        date = null;
      }
    }
    if (date == null) return null;

    final time = feedingTime.trim().toLowerCase();
    var hour = 8;
    if (time == 'afternoon') hour = 14;
    if (time == 'evening') hour = 19;
    return DateTime(date.year, date.month, date.day, hour);
  }

  Widget _buildHistoryTab() {
    final groups = _buildHistoryGroups();
    final visibleHistory = _visibleHistory;
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
          : visibleHistory.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 220),
                    Center(
                      child: Text(
                        'no_feeding_history_found'.tr,
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final group = groups[index];
                    final item = group.latest;
                    final planTitle = item.dietPlanName.trim().isNotEmpty
                        ? item.dietPlanName.trim()
                        : item.feedType;
                    return Container(
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.isPanGroup
                                        ? '${item.panName} (${group.entries.length} ${'animals'.tr})'
                                        : item.animalDisplay,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    onPressed: () => _onEditTap(item),
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    color: AppColors.primary,
                                    tooltip: 'edit'.tr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.feedType} - ${item.quantity} ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4FAF4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${'diet_plan'.tr}: $planTitle',
                                    style: const TextStyle(
                                      fontSize: 12.4,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _infoChip(
                                      icon: Icons.scale_rounded,
                                      label:
                                          '${'package_quantity'.tr}: ${_formatQuantity(item.packageQuantity)} ${item.unit}',
                                      color: const Color(0xFFE3F2FD),
                                      textColor: const Color(0xFF0D47A1),
                                    ),
                                    _infoChip(
                                      icon: Icons.inventory_2_rounded,
                                      label:
                                          '${'balance'.tr}: ${_formatQuantity(item.balanceQuantity)} ${item.unit}',
                                      color: const Color(0xFFE8F5E9),
                                      textColor: const Color(0xFF256029),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${'time'.tr}: ${item.feedingTime}',
                                  style: const TextStyle(fontSize: 12.8),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${'date'.tr}: ${item.date}',
                                  style: const TextStyle(fontSize: 12.8),
                                ),
                                if (item.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${'notes'.tr}: ${item.notes}',
                                    style: const TextStyle(fontSize: 12.8),
                                  ),
                                ],
                                if (group.entries.length > 1) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _openViewAllEntries(group),
                                      icon: const Icon(Icons.visibility_rounded, size: 16),
                                      label: const Text('View All'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        textStyle: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openViewAllEntries(_FeedingHistoryGroup group) async {
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.isPanGroup
                    ? group.latest.panName
                    : group.latest.animalDisplay,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${group.entries.length} records',
                style: TextStyle(
                  fontSize: 12.2,
                  color: Colors.black.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final row = group.entries[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FBF7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EEE3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${row.feedType} - ${row.quantity} ${row.unit}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${'date'.tr}: ${row.date}  |  ${'time'.tr}: ${row.feedingTime}',
                                  style: const TextStyle(fontSize: 12.2, color: Colors.black54),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${'package_quantity'.tr}: ${_formatQuantity(row.packageQuantity)} ${row.unit}  |  ${'balance'.tr}: ${_formatQuantity(row.balanceQuantity)} ${row.unit}',
                                  style: const TextStyle(fontSize: 12.2, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              Get.back();
                              await _onEditTap(row);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            tooltip: 'edit'.tr,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildFeedTypeTab() {
    final visibleHistory = _visibleHistory;
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
                  child: Text(
                    'edit_wrong_subtype_qty_here'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (visibleHistory.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'no_feed_entries_found'.tr,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ...visibleHistory.map(
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
                              tooltip: 'edit_feed_content'.tr,
                            ),
                          ],
                        ),
                        Text(
                          '${item.feedType} • ${item.quantity} ${item.unit}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${'time'.tr}: ${item.feedingTime} | ${'date'.tr}: ${item.date}',
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
    required this.panId,
    required this.panName,
    required this.dietPlanName,
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
  final int panId;
  final String panName;
  final String dietPlanName;
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

  bool get hasPan => panName.trim().isNotEmpty;

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

  String get groupKey {
    if (panId > 0) return 'pan_id_$panId';
    final normalizedPan = panName.trim().toLowerCase();
    if (normalizedPan.isNotEmpty) return 'pan_name_$normalizedPan';
    if (animalId > 0) return 'animal_id_$animalId';
    return 'animal_name_${animalName.trim().toLowerCase()}';
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
      panId: int.tryParse(
            (json['pan_id'] ?? (json['pan'] is Map ? (json['pan']['id'] ?? 0) : 0)).toString(),
          ) ??
          0,
      panName: (json['pan_name'] ??
              (json['pan'] is Map ? (json['pan']['name'] ?? '') : ''))
          .toString(),
      dietPlanName: (json['diet_plan_name'] ?? json['diet_plan'] ?? '').toString(),
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

class _FeedingHistoryGroup {
  _FeedingHistoryGroup({
    required this.key,
    required this.latest,
    required this.entries,
    required this.isPanGroup,
  });

  final String key;
  final _FeedingHistoryItem latest;
  final List<_FeedingHistoryItem> entries;
  final bool isPanGroup;
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
