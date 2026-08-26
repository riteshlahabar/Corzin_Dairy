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
  final List<_DietPlanQuantityLookup> _dietPlanLookups =
      <_DietPlanQuantityLookup>[];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  List<_FeedingHistoryItem> get _visibleHistory {
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

      final itemDate = _parseItemDate(item);
      if (_fromDate != null &&
          itemDate != null &&
          itemDate.isBefore(_dateOnly(_fromDate!))) {
        return false;
      }
      if (_toDate != null &&
          itemDate != null &&
          itemDate.isAfter(_dateOnly(_toDate!))) {
        return false;
      }
      if ((_fromDate != null || _toDate != null) && itemDate == null) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }
      return item.matchesSearch(query);
    }).toList();
  }

  bool get _hasActiveHistoryFilters =>
      _searchController.text.trim().isNotEmpty ||
      _fromDate != null ||
      _toDate != null;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 1).toInt();
    _searchController.addListener(_onHistoryFilterChanged);
    _initialize();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onHistoryFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadFarmerId();
    await Future.wait([_loadHistory(), _loadFeedTypes(), _loadDietPlans()]);
  }

  Future<void> _loadFarmerId() async {
    if (_farmerId > 0) return;
    final prefs = await SharedPreferences.getInstance();
    _farmerId = prefs.getInt('farmer_id') ?? 0;
    if (_farmerId == 0 && mounted) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
    }
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _loadFarmerId();
      if (_farmerId == 0) {
        _history.clear();
        return;
      }

      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List items = (data['data'] as List?) ?? [];
        _history
          ..clear()
          ..addAll(items.map((e) => _FeedingHistoryItem.fromJson(e)).toList());
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }

      final data = await CachedApiService.instance.getMap(
        key: 'feeding_list_$_farmerId',
        uri: Uri.parse('${Api.feedingList}/$_farmerId'),
        onCached: apply,
        forceRefresh: forceRefresh,
      );
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (_history.isEmpty) {
        _history.clear();
      }
    } catch (_) {
      if (_history.isEmpty && mounted) {
        _history.clear();
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

      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List items = (data['data'] as List?) ?? [];
        _feedTypes
          ..clear()
          ..addAll(items.map((e) => _FeedTypeEditorItem.fromJson(e)).toList());
        if (mounted) {
          setState(() => _isFeedTypeLoading = false);
        }
      }

      final data = await CachedApiService.instance.getMap(
        key: 'feeding_types_$_farmerId',
        uri: Uri.parse('${Api.feedingTypes}?farmer_id=$_farmerId'),
        onCached: apply,
      );
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (_feedTypes.isEmpty) {
        _feedTypes.clear();
      }
    } catch (_) {
      if (_feedTypes.isEmpty && mounted) {
        _feedTypes.clear();
        Get.snackbar('error'.tr, 'unable_load_feed_type_content'.tr);
      }
    } finally {
      if (mounted) {
        setState(() => _isFeedTypeLoading = false);
      }
    }
  }

  Future<void> _loadDietPlans() async {
    try {
      await _loadFarmerId();
      if (_farmerId == 0) {
        _dietPlanLookups.clear();
        return;
      }

      void apply(Map<String, dynamic> data) {
        if (data['status'] != true) return;
        final List items = (data['data'] as List?) ?? [];
        _dietPlanLookups
          ..clear()
          ..addAll(
            items
                .map(
                  (e) => _DietPlanQuantityLookup.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .where((item) => item.planQuantity > 0)
                .toList(),
          );
      }

      final data = await CachedApiService.instance.getMap(
        key: 'feeding_diet_plans_${_farmerId}_',
        uri: Uri.parse('${Api.feedingDietPlans}/$_farmerId'),
        onCached: apply,
      );
      if (data != null && data['status'] == true) {
        apply(data);
      } else if (_dietPlanLookups.isEmpty) {
        _dietPlanLookups.clear();
      }
    } catch (_) {
      if (_dietPlanLookups.isEmpty) {
        _dietPlanLookups.clear();
      }
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (_selectedTab == 0) {
      await Future.wait([_loadHistory(), _loadDietPlans()]);
    } else {
      await Future.wait([_loadFeedTypes(), _loadHistory()]);
    }
  }

  double _packageQuantityForItem(_FeedingHistoryItem item) {
    final matchedPlan = _matchedDietPlanForItem(item);
    if (matchedPlan != null) {
      return matchedPlan.planQuantity;
    }

    final totalPlanQuantity = item.planQuantity ?? 0;
    if (totalPlanQuantity > 0) return totalPlanQuantity;
    if (item.packageQuantity > 0) return item.packageQuantity;
    final subtypeTotal = item.feedSubtypeDetails.fold<double>(
      0,
      (sum, detail) => sum + detail.quantity,
    );
    return subtypeTotal > 0 ? subtypeTotal : 0;
  }

  String _packageQuantityTextForItem(_FeedingHistoryItem item) {
    return _formatDoubleToText(_packageQuantityForItem(item));
  }

  _DietPlanQuantityLookup? _matchedDietPlanForItem(_FeedingHistoryItem item) {
    final normalizedPlanName = item.dietPlanName.trim().toLowerCase();
    if (normalizedPlanName.isEmpty) return null;
    for (final plan in _dietPlanLookups) {
      if (plan.matches(item)) {
        return plan;
      }
    }
    return null;
  }

  Future<void> _onDeleteTap(
    _FeedingHistoryItem item, {
    bool closeViewAllPageOnSuccess = false,
  }) async {
    if (item.id <= 0) {
      Get.snackbar('error'.tr, 'unable_to_delete'.tr);
      return;
    }

    if (!mounted) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text('confirmation'.tr),
            content: Text(
              'confirm_action'.trParams({'action': 'delete'.tr.toLowerCase()}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'delete'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      debugPrint(
        '[FeedingDelete] confirmed itemId=${item.id}, mounted=$mounted',
      );
      final response = await http.post(
        Uri.parse('${Api.addFeeding}/delete/${item.id}'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'farmer_id': _farmerId.toString()}),
      );
      debugPrint(
        '[FeedingDelete] status=${response.statusCode}, body=${response.body}',
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 && data['status'] == true) {
        if (closeViewAllPageOnSuccess && mounted) {
          _closeViewAllPage();
        }
        Get.snackbar(
          'success'.tr,
          data['message']?.toString() ?? 'Feeding record deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        if (mounted) {
          await _loadHistory(forceRefresh: true);
        }
      } else {
        Get.snackbar(
          'error'.tr,
          data['message']?.toString() ?? 'unable_to_delete'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _onFeedContentEditTap(_FeedingHistoryItem item) async {
    final linkedType = _findLinkedFeedType(item);
    final subtypeNames = <String>{
      ...?linkedType?.subtypes.map((e) => e.trim()).where((e) => e.isNotEmpty),
      ...item.feedSubtypeDetails
          .map((e) => e.name.trim())
          .where((e) => e.isNotEmpty),
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
        final feeding =
            double.tryParse(feedQuantityController.text.trim()) ?? 0;
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
      _TextEditingControllerScope(
        controllers: [
          feedQuantityController,
          notesController,
          ...subtypeControllers.values,
        ],
        beforeDispose: () {
          feedQuantityController.removeListener(recalculateTotals);
        },
        child: StatefulBuilder(
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
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.feedType} • ${_displayHistoryDate(item.date)} • ${item.feedingTime}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black54,
                          ),
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
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
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
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                                        double.tryParse(
                                          feedQuantityController.text.trim(),
                                        ) ??
                                        0;
                                    if (feedingQty <= 0) {
                                      Get.snackbar(
                                        'error'.tr,
                                        'please_enter_valid_feeding_quantity'
                                            .tr,
                                      );
                                      return;
                                    }

                                    final subtypePayload =
                                        <Map<String, dynamic>>[];
                                    for (final name in subtypeNames) {
                                      if (!(subtypeSelected[name] ?? false)) {
                                        continue;
                                      }
                                      final qty =
                                          double.tryParse(
                                            subtypeControllers[name]?.text
                                                    .trim() ??
                                                '',
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
                                        if (item.animalId > 0)
                                          'animal_id': item.animalId.toString(),
                                        if (item.feedTypeId > 0)
                                          'feed_type_id': item.feedTypeId
                                              .toString(),
                                        'feed_type': item.feedType,
                                        'quantity': feedQuantityController.text
                                            .trim(),
                                        'feeding_quantity':
                                            feedQuantityController.text.trim(),
                                        'package_quantity':
                                            _packageQuantityForItem(
                                              item,
                                            ).toStringAsFixed(2),
                                        'balance_quantity': balanceQuantity
                                            .value
                                            .toStringAsFixed(2),
                                        'rate_per_unit': item.ratePerUnit
                                            .toStringAsFixed(2),
                                        'feeding_cost':
                                            (feedingQty * item.ratePerUnit)
                                                .toStringAsFixed(2),
                                        'feed_subtype_details': subtypePayload,
                                        'unit': item.unit,
                                        'feeding_time': item.feedingTime,
                                        'date': item.date,
                                        'notes': notesController.text.trim(),
                                      };

                                      final response = await http.post(
                                        Uri.parse(
                                          '${Api.feedingUpdate}/${item.id}',
                                        ),
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
                                        if (mounted) {
                                          await Future.wait([
                                            _loadHistory(),
                                            _loadDietPlans(),
                                          ]);
                                        }
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
      ),
      isScrollControlled: true,
    );
  }

  _FeedTypeEditorItem? _findLinkedFeedType(_FeedingHistoryItem item) {
    for (final type in _feedTypes) {
      if (type.id == item.feedTypeId) {
        return type;
      }
      if (type.name.trim().toLowerCase() ==
          item.feedType.trim().toLowerCase()) {
        return type;
      }
    }
    return null;
  }

  String _formatQuantity(double value) {
    return _formatDoubleToText(value);
  }

  void _onHistoryFilterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime? _parseItemDate(_FeedingHistoryItem item) {
    final parsed = _parseHistoryDateTime(item.date, item.feedingTime);
    if (parsed == null) return null;
    return _dateOnly(parsed);
  }

  Future<void> _pickHistoryDate({required bool isFrom}) async {
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

  void _clearHistoryFilters() {
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

  String _displayHistoryDate(String rawDate) {
    final normalized = rawDate.trim();
    if (normalized.isEmpty) return rawDate;

    DateTime? parsed;
    try {
      parsed = DateFormat('yyyy-MM-dd').parseStrict(normalized);
    } catch (_) {
      try {
        parsed = DateFormat('dd/MM/yyyy').parseStrict(normalized);
      } catch (_) {
        try {
          parsed = DateFormat('dd/MM/yy').parseStrict(normalized);
        } catch (_) {
          parsed = null;
        }
      }
    }

    if (parsed == null) return rawDate;
    return DateFormat('dd/MM/yy').format(parsed);
  }

  Widget _historySummaryTile({
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

  Widget _historyFilterDateButton({
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

  Widget _historyMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: textColor),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.6,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedingCompositionCard(_FeedingHistoryItem item) {
    final groups = _compositionGroupsForItem(item);
    return _contentGridSection(groups, sectionSpacing: 8);
  }

  Map<String, List<String>> _compositionGroupsForItem(
    _FeedingHistoryItem item,
  ) {
    final matchedPlan = _matchedDietPlanForItem(item);
    final groups = <String, List<String>>{};

    if (matchedPlan != null && matchedPlan.subtypeDetails.isNotEmpty) {
      for (final detail in matchedPlan.subtypeDetails) {
        final feedTypeName = detail.feedTypeName.trim().isEmpty
            ? (matchedPlan.feedType.trim().isEmpty
                  ? item.feedType.trim()
                  : matchedPlan.feedType.trim())
            : detail.feedTypeName.trim();
        final subtypeName = detail.name.trim();
        if (feedTypeName.isEmpty) continue;
        groups.putIfAbsent(feedTypeName, () => <String>[]);
        if (subtypeName.isNotEmpty) {
          groups[feedTypeName]!.add(subtypeName);
        }
      }
    }

    if (groups.isEmpty) {
      final visibleSubtypes = item.feedSubtypeDetails
          .where((detail) => detail.quantity > 0)
          .toList();
      final feedTypeLabel = item.feedType.trim().isEmpty
          ? '-'
          : item.feedType.trim();
      if (feedTypeLabel.isNotEmpty) {
        groups.putIfAbsent(feedTypeLabel, () => <String>[]);
        for (final detail in visibleSubtypes) {
          final subtypeName = detail.name.trim();
          if (subtypeName.isNotEmpty) {
            groups[feedTypeLabel]!.add(subtypeName);
          }
        }
      }
    }

    return groups;
  }

  Widget _compactHistoryValueTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 26,
            width: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.2,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewAllContentsSection(_FeedingHistoryItem item) {
    final groups = _compositionGroupsForItem(item);
    return _contentGridSection(groups);
  }

  Widget _contentGridSection(
    Map<String, List<String>> groups, {
    double sectionSpacing = 8,
  }) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final itemWidth = (maxWidth - sectionSpacing) / 2;

        return Wrap(
          spacing: sectionSpacing,
          runSpacing: sectionSpacing,
          children: groups.entries.map((entry) {
            final subtypeNames = entry.value.toSet().toList();
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBF8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDEEDC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    if (subtypeNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: subtypeNames
                            .map(
                              (name) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: const Color(0xFFD8EAD9),
                                  ),
                                ),
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
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
            );
          }).toList(),
        );
      },
    );
  }

  Widget _viewAllMetricRow(_FeedingHistoryItem row) {
    return Row(
      children: [
        Expanded(
          child: _compactHistoryValueTile(
            label: 'feeding_quantity'.tr,
            value: '${row.feedingQuantityText} ${row.unit}',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF0D47A1),
            backgroundColor: const Color(0xFFE3F2FD),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactHistoryValueTile(
            label: 'rate_per_unit'.tr,
            value: _formatQuantity(row.ratePerUnit),
            icon: Icons.sell_rounded,
            color: const Color(0xFF6A1B9A),
            backgroundColor: const Color(0xFFF3E5F5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactHistoryValueTile(
            label: 'feeding_cost'.tr,
            value: _formatQuantity(row.feedingCost),
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFEF6C00),
            backgroundColor: const Color(0xFFFFF3E0),
          ),
        ),
      ],
    );
  }

  Widget _viewAllEntryCard(
    _FeedingHistoryItem row, {
    required Future<void> Function() onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EEE3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${_displayHistoryDate(row.date)}  |  ${row.feedingTime}',
                  style: const TextStyle(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _viewAllMetricRow(row),
          const SizedBox(height: 10),
          _viewAllContentsSection(row),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  List<_FeedingHistoryGroup> _buildHistoryGroups() {
    final grouped = <String, List<_FeedingHistoryItem>>{};
    for (final item in _visibleHistory) {
      grouped
          .putIfAbsent(item.groupKey, () => <_FeedingHistoryItem>[])
          .add(item);
    }

    final groups =
        grouped.entries.map((entry) {
          final rows = List<_FeedingHistoryItem>.from(entry.value)
            ..sort((a, b) => _historySortKey(b).compareTo(_historySortKey(a)));
          final latest = rows.first;
          return _FeedingHistoryGroup(
            key: entry.key,
            latest: latest,
            entries: rows,
            isPanGroup: latest.hasPan,
          );
        }).toList()..sort(
          (a, b) =>
              _historySortKey(b.latest).compareTo(_historySortKey(a.latest)),
        );
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
    final totalCost = visibleHistory.fold<double>(
      0,
      (sum, item) => sum + item.feedingCost,
    );
    final historyDates =
        visibleHistory.map(_parseItemDate).whereType<DateTime>().toList()
          ..sort();
    final rangeStart = historyDates.isEmpty ? null : historyDates.first;
    final rangeEnd = historyDates.isEmpty ? null : historyDates.last;
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
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                              Icons.restaurant_rounded,
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
                                  'feeding_record'.tr,
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
                                      : 'no_feeding_history_found'.tr,
                                  style: TextStyle(
                                    fontSize: 12.8,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
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
                          _historySummaryTile(
                            icon: Icons.receipt_long_rounded,
                            label: 'feeding_record'.tr,
                            value: visibleHistory.length.toString(),
                          ),
                          const SizedBox(width: 10),
                          _historySummaryTile(
                            icon: Icons.currency_rupee_rounded,
                            label: 'feeding_cost'.tr,
                            value: _formatQuantity(totalCost),
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
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade200),
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
                          _historyFilterDateButton(
                            label: 'from_date'.tr,
                            value: _fromDate,
                            onTap: () => _pickHistoryDate(isFrom: true),
                          ),
                          const SizedBox(width: 10),
                          _historyFilterDateButton(
                            label: 'to_date'.tr,
                            value: _toDate,
                            onTap: () => _pickHistoryDate(isFrom: false),
                          ),
                        ],
                      ),
                      if (_hasActiveHistoryFilters) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearHistoryFilters,
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
                if (visibleHistory.isEmpty)
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
                          'no_feeding_history_found'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...groups.map((group) {
                    final item = group.latest;
                    final planTitle = item.dietPlanName.trim().isNotEmpty
                        ? item.dietPlanName.trim()
                        : item.feedType;
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
                                child: const Icon(
                                  Icons.food_bank_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.isPanGroup
                                          ? '${item.panName} (${group.entries.length} ${'animals'.tr})'
                                          : item.animalDisplay,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16.2,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _infoChip(
                                              icon: Icons.event_note_rounded,
                                              label: planTitle,
                                              color: const Color(0xFFE3F2FD),
                                              textColor: const Color(
                                                0xFF0D47A1,
                                              ),
                                              maxWidth: constraints.maxWidth,
                                            ),
                                            _infoChip(
                                              icon:
                                                  Icons.currency_rupee_rounded,
                                              label:
                                                  '${'feeding_cost'.tr}: ${_formatQuantity(item.feedingCost)}',
                                              color: const Color(0xFFFFF3E0),
                                              textColor: const Color(
                                                0xFFEF6C00,
                                              ),
                                              maxWidth: constraints.maxWidth,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _onDeleteTap(item),
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: Colors.red,
                                tooltip: 'delete'.tr,
                                visualDensity: VisualDensity.compact,
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
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_displayHistoryDate(item.date)}  •  ${item.feedingTime}',
                                    style: const TextStyle(
                                      fontSize: 13.2,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _historyMetricCard(
                                label: 'package_quantity'.tr,
                                value:
                                    '${_packageQuantityTextForItem(item)} ${item.unit}',
                                icon: Icons.scale_rounded,
                                backgroundColor: const Color(0xFFE8F5E9),
                                textColor: const Color(0xFF256029),
                              ),
                              const SizedBox(width: 10),
                              _historyMetricCard(
                                label: 'feeding_quantity'.tr,
                                value:
                                    '${item.feedingQuantityText} ${item.unit}',
                                icon: Icons.inventory_2_rounded,
                                backgroundColor: const Color(0xFFE3F2FD),
                                textColor: const Color(0xFF0D47A1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _feedingCompositionCard(item),
                          if (item.notes.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBF9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${'notes'.tr}: ${item.notes}',
                                style: TextStyle(
                                  fontSize: 12.8,
                                  color: Colors.black.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (group.entries.length > 1) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _openViewAllEntries(group),
                                icon: const Icon(
                                  Icons.visibility_rounded,
                                  size: 16,
                                ),
                                label: Text('view_all'.tr),
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
                    );
                  }),
              ],
            ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    double? maxWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewAllSummaryCard(_FeedingHistoryGroup group) {
    final totalQuantity = group.entries.fold<double>(
      0,
      (sum, item) => sum + item.feedingQuantity,
    );
    final totalCost = group.entries.fold<double>(
      0,
      (sum, item) => sum + item.feedingCost,
    );
    final planNames = group.entries
        .map(
          (item) => item.dietPlanName.trim().isNotEmpty
              ? item.dietPlanName.trim()
              : item.feedType.trim(),
        )
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4EA857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.isPanGroup
                ? group.latest.panName
                : group.latest.animalDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            planNames.isEmpty ? 'feeding_record'.tr : planNames.join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _viewAllHeaderMetric(
                  label: 'entries'.tr,
                  value: '${group.entries.length}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _viewAllHeaderMetric(
                  label: 'feeding_quantity'.tr,
                  value:
                      '${_formatQuantity(totalQuantity)} ${group.latest.unit}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _viewAllHeaderMetric(
                  label: 'feeding_cost'.tr,
                  value: _formatQuantity(totalCost),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewAllHeaderMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _closeViewAllPage() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Future<void> _openViewAllEntries(_FeedingHistoryGroup group) async {
    final page = Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _closeViewAllPage,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'feeding_record'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _viewAllSummaryCard(group),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: group.entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final row = group.entries[index];
                  return _viewAllEntryCard(
                    row,
                    onDelete: () =>
                        _onDeleteTap(row, closeViewAllPageOnSuccess: true),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    // Open View All as a real route so FeedingHistoryView stays mounted.
    // The View All callbacks (_onDeleteTap, etc.) belong to this State.
    await Get.to<void>(() => page);
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
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'edit_wrong_subtype_qty_here'.tr,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${'time'.tr}: ${item.feedingTime} | ${'date'.tr}: ${_displayHistoryDate(item.date)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black54,
                          ),
                        ),
                        if (item.feedSubtypeDetails.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.feedSubtypeDetails
                                .map(
                                  (detail) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
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

class _TextEditingControllerScope extends StatefulWidget {
  const _TextEditingControllerScope({
    required this.controllers,
    required this.child,
    this.beforeDispose,
  });

  final List<TextEditingController> controllers;
  final Widget child;
  final VoidCallback? beforeDispose;

  @override
  State<_TextEditingControllerScope> createState() =>
      _TextEditingControllerScopeState();
}

class _TextEditingControllerScopeState
    extends State<_TextEditingControllerScope> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    widget.beforeDispose?.call();
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
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
    required this.planQuantity,
    required this.packageQuantity,
    required this.balanceQuantity,
    required this.ratePerUnit,
    required this.feedingCost,
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
  final double? planQuantity;
  final double packageQuantity;
  final double balanceQuantity;
  final double ratePerUnit;
  final double feedingCost;
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

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final haystack = <String>[
      animalName,
      tagNumber,
      panName,
      feedType,
      dietPlanName,
      date,
      feedingTime,
      notes,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
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

  double get resolvedPackageQuantity {
    final totalPlanQuantity = planQuantity ?? 0;
    if (totalPlanQuantity > 0) return totalPlanQuantity;
    if (packageQuantity > 0) return packageQuantity;
    final subtypeTotal = feedSubtypeDetails.fold<double>(
      0,
      (sum, detail) => sum + detail.quantity,
    );
    if (subtypeTotal > 0) return subtypeTotal;
    return 0;
  }

  String get packageQuantityText =>
      _formatDoubleToText(resolvedPackageQuantity);

  factory _FeedingHistoryItem.fromJson(Map<String, dynamic> json) {
    return _FeedingHistoryItem(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      animalId: int.tryParse((json['animal_id'] ?? '0').toString()) ?? 0,
      animalName: (json['animal_name'] ?? '').toString(),
      tagNumber: (json['tag_number'] ?? '').toString(),
      panId:
          int.tryParse(
            (json['pan_id'] ??
                    (json['pan'] is Map ? (json['pan']['id'] ?? 0) : 0))
                .toString(),
          ) ??
          0,
      panName:
          (json['pan_name'] ??
                  (json['pan'] is Map ? (json['pan']['name'] ?? '') : ''))
              .toString(),
      dietPlanName: (json['diet_plan_name'] ?? json['diet_plan'] ?? '')
          .toString(),
      feedType: (json['feed_type'] ?? '').toString(),
      feedTypeId: int.tryParse((json['feed_type_id'] ?? '0').toString()) ?? 0,
      quantity: (json['quantity'] ?? '').toString(),
      feedingQuantity:
          double.tryParse((json['feeding_quantity'] ?? '0').toString()) ?? 0,
      planQuantity:
          double.tryParse((json['plan_quantity'] ?? '0').toString()) ?? 0,
      packageQuantity:
          double.tryParse((json['package_quantity'] ?? '0').toString()) ?? 0,
      balanceQuantity:
          double.tryParse((json['balance_quantity'] ?? '0').toString()) ?? 0,
      ratePerUnit:
          double.tryParse((json['rate_per_unit'] ?? '0').toString()) ?? 0,
      feedingCost:
          double.tryParse((json['feeding_cost'] ?? '0').toString()) ?? 0,
      unit: (json['unit'] ?? '').toString(),
      feedingTime: (json['feeding_time'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      feedSubtypeDetails: _FeedSubtypeDetail.parse(
        json['feed_subtype_details'],
      ),
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

class _DietPlanQuantityLookup {
  _DietPlanQuantityLookup({
    required this.id,
    required this.animalId,
    required this.panId,
    required this.dietPlanName,
    required this.feedType,
    required this.planQuantity,
    required this.subtypeDetails,
  });

  final int id;
  final int animalId;
  final int panId;
  final String dietPlanName;
  final String feedType;
  final double planQuantity;
  final List<_DietPlanSubtypeLookup> subtypeDetails;

  bool matches(_FeedingHistoryItem item) {
    final targetPlanName = item.dietPlanName.trim().toLowerCase();
    if (targetPlanName.isNotEmpty &&
        dietPlanName.trim().toLowerCase() != targetPlanName) {
      return false;
    }

    if (item.animalId > 0 && animalId > 0 && item.animalId != animalId) {
      return false;
    }

    if (item.panId > 0 && panId > 0 && item.panId != panId) {
      return false;
    }

    final targetFeedType = item.feedType.trim().toLowerCase();
    if (targetFeedType.isNotEmpty &&
        feedType.trim().isNotEmpty &&
        targetFeedType != feedType.trim().toLowerCase()) {
      return false;
    }

    return true;
  }

  factory _DietPlanQuantityLookup.fromJson(Map<String, dynamic> json) {
    return _DietPlanQuantityLookup(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      animalId: int.tryParse((json['animal_id'] ?? '0').toString()) ?? 0,
      panId: int.tryParse((json['pan_id'] ?? '0').toString()) ?? 0,
      dietPlanName: (json['diet_plan_name'] ?? json['plan_name'] ?? '')
          .toString(),
      feedType: (json['feed_type'] ?? '').toString(),
      planQuantity:
          double.tryParse((json['plan_quantity'] ?? '0').toString()) ?? 0,
      subtypeDetails: _DietPlanSubtypeLookup.parse(json['subtype_details']),
    );
  }
}

class _DietPlanSubtypeLookup {
  _DietPlanSubtypeLookup({required this.feedTypeName, required this.name});

  final String feedTypeName;
  final String name;

  factory _DietPlanSubtypeLookup.fromJson(Map<String, dynamic> json) {
    return _DietPlanSubtypeLookup(
      feedTypeName: (json['feed_type_name'] ?? json['feed_type'] ?? '')
          .toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  static List<_DietPlanSubtypeLookup> parse(dynamic raw) {
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
        .map(
          (item) =>
              _DietPlanSubtypeLookup.fromJson(item.cast<String, dynamic>()),
        )
        .where(
          (item) =>
              item.feedTypeName.trim().isNotEmpty ||
              item.name.trim().isNotEmpty,
        )
        .toList();
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
        .map(
          (item) => _FeedSubtypeDetail.fromJson(item.cast<String, dynamic>()),
        )
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
    final List rawSubtypes = json['subtypes'] is List
        ? (json['subtypes'] as List)
        : const [];
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
