import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/health_controller.dart';

class HealthView extends StatefulWidget {
  const HealthView({super.key, this.initialSection = HealthSection.dmi});

  final HealthSection initialSection;

  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
  late final HealthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<HealthController>()
        ? Get.find<HealthController>()
        : Get.put(HealthController());
    controller.selectedSection.value = widget.initialSection;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setSection(widget.initialSection);
      if (widget.initialSection == HealthSection.mastitis &&
          controller.mastitisRecords.isEmpty) {
        controller.fetchMastitisRecords();
      } else if (widget.initialSection == HealthSection.dmi &&
          controller.dmiRecords.isEmpty) {
        controller.fetchDmiRecords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      floatingActionButton: widget.initialSection == HealthSection.mastitis
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _openMastitisSheet(context),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _screenTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : (widget.initialSection == HealthSection.dmi
                        ? _dmiList()
                        : _mastitisList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _screenTitle =>
      widget.initialSection == HealthSection.dmi ? 'dmi'.tr : 'mastitis'.tr;

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _dmiList() {
    final latestRows = _latestDmiByAnimal();
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchDmiRecords();
      },
      child: latestRows.isEmpty
          ? _emptyState('no_dmi_records_found'.tr)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: latestRows.length,
              itemBuilder: (context, index) {
                final item = latestRows[index];
                return _card(
                  title: '${item.animalName} - Tag ${item.tagNumber}',
                  subtitle: item.dmiType.isEmpty ? '-' : item.dmiType,
                  dateText: item.date,
                  status: _cardStatusLabel(item.alertStatus),
                  rows: [
                    _info('required_dmi'.tr, '${item.requiredDmi} Kg'),
                    _info('body_weight'.tr, '${item.bodyWeight} Kg'),
                    _info('total_milk'.tr, '${item.totalMilk} L'),
                    _info('actual_dmi'.tr, '${item.actualDmi} Kg'),
                    if (item.notes.isNotEmpty) _info('notes'.tr, item.notes),
                  ],
                );
              },
            ),
    );
  }

  Widget _mastitisList() {
    final records = controller.filteredMastitisRecords;
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchMastitisRecords();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _mastitisSearchBar(),
          const SizedBox(height: 10),
          _mastitisResultFilters(),
          const SizedBox(height: 12),
          if (records.isEmpty)
            _inlineEmptyState('no_mastitis_records_found'.tr)
          else
            ...records.map(
              (item) => _card(
                title: '${item.animalName} - Tag ${item.tagNumber}',
                subtitle: item.testResult,
                dateText: item.date,
                status: item.recoveryStatus,
                action: IconButton(
                  onPressed: () => _openMastitisSheet(context, record: item),
                  icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(minHeight: 34, minWidth: 34),
                  padding: EdgeInsets.zero,
                ),
                rows: [
                  _info('test_result'.tr, item.testResult),
                  _info('treatment'.tr, item.treatment),
                  _info('recovery_status'.tr, item.recoveryStatus),
                  if (item.notes.isNotEmpty) _info('notes'.tr, item.notes),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _mastitisSearchBar() {
    return TextField(
      onChanged: (value) => controller.mastitisSearchQuery.value = value,
      decoration: InputDecoration(
        hintText: 'Search mastitis records',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _mastitisResultFilters() {
    final filters = <String, String>{
      'all': 'All',
      'positive': 'positive'.tr,
      'suspected': 'suspected'.tr,
      'negative': 'negative'.tr,
    };

    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final selected = controller.mastitisResultFilter.value == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => controller.mastitisResultFilter.value = entry.key,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? AppColors.primary : const Color(0xFFDDEBDE),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<DmiRecordItem> _latestDmiByAnimal() {
    final Map<int, DmiRecordItem> byAnimal = <int, DmiRecordItem>{};
    for (final row in controller.dmiRecords) {
      if (row.animalId == 0) continue;
      byAnimal.putIfAbsent(row.animalId, () => row);
    }
    return byAnimal.values.toList();
  }

  Widget _card({
    required String title,
    required String subtitle,
    String dateText = '-',
    String status = '',
    Widget? action,
    required List<Widget> rows,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EFE3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (status.isNotEmpty) _statusPill(status),
              if (action != null) ...[
                const SizedBox(width: 6),
                action,
              ],
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaPill(Icons.pets_outlined, subtitle),
              _metaPill(Icons.calendar_month_rounded, '${'date'.tr}: $dateText'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FCF8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7EF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final statusLower = status.toLowerCase();
    final bool isGood = statusLower.contains('balanced') ||
        statusLower.contains('auto') ||
        statusLower.contains('recovered') ||
        statusLower.contains('negative');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFFEAF8EE) : const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isGood ? const Color(0xFF167B33) : const Color(0xFFB66A00),
        ),
      ),
    );
  }

  String _cardStatusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'auto calculated') {
      return '';
    }
    return status;
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.health_and_safety_outlined,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _inlineEmptyState(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EFE3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            size: 42,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _openMastitisSheet(
    BuildContext context, {
    MastitisRecordItem? record,
  }) async {
    final selectedAnimal = Rxn<HealthAnimalItem>(_animalForRecord(record));
    final testResult = (record?.testResult.trim().isNotEmpty == true
            ? record!.testResult.trim().toLowerCase()
            : 'suspected')
        .obs;
    final recoveryStatus = (record?.recoveryStatus.trim().isNotEmpty == true
            ? record!.recoveryStatus.trim().toLowerCase()
            : 'under_treatment')
        .obs;
    final treatmentController = TextEditingController(text: record?.treatment ?? '');
    final notesController = TextEditingController(text: record?.notes ?? '');
    final selectedDate = _parseDisplayDate(record?.date).obs;
    final localSaving = false.obs;
    final isEdit = record != null;

    await Get.bottomSheet(
      Obx(
        () => Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 54,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text(
                    isEdit ? 'Edit Mastitis Record' : 'add_mastitis_record'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<HealthAnimalItem>(
                    initialValue: selectedAnimal.value,
                    isExpanded: true,
                    decoration: _sheetDecoration('select_animal'.tr),
                    items: controller.animals
                        .map(
                          (animal) => DropdownMenuItem<HealthAnimalItem>(
                            value: animal,
                            child: Text(animal.displayName, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedAnimal.value = value,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: testResult.value,
                    decoration: _sheetDecoration('test_result'.tr),
                    items: [
                      DropdownMenuItem(value: 'negative', child: Text('negative'.tr)),
                      DropdownMenuItem(value: 'suspected', child: Text('suspected'.tr)),
                      DropdownMenuItem(value: 'positive', child: Text('positive'.tr)),
                    ],
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        testResult.value = value;
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: treatmentController,
                    decoration: _sheetDecoration('treatment'.tr),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: recoveryStatus.value,
                    decoration: _sheetDecoration('recovery_status'.tr),
                    items: [
                      DropdownMenuItem(value: 'under_treatment', child: Text('under_treatment'.tr)),
                      DropdownMenuItem(value: 'recovered', child: Text('recovered'.tr)),
                      DropdownMenuItem(value: 'not_recovered', child: Text('not_recovered'.tr)),
                    ],
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        recoveryStatus.value = value;
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.value,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        selectedDate.value = picked;
                      }
                    },
                    child: InputDecorator(
                      decoration: _sheetDecoration('date'.tr),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate.value),
                        style: const TextStyle(fontSize: 13.5, color: AppColors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: _sheetDecoration('notes'.tr),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (localSaving.value || controller.isSubmitting.value)
                          ? null
                          : () async {
                              final animal = selectedAnimal.value;
                              final treatment = treatmentController.text.trim();
                              if (animal == null || treatment.isEmpty) {
                                Get.snackbar('validation'.tr, 'please_fill_required_fields'.tr);
                                return;
                              }

                              localSaving.value = true;
                              final ok = isEdit
                                  ? await controller.updateMastitis(
                                      recordId: record.id,
                                      animalId: animal.id,
                                      testResult: testResult.value,
                                      treatment: treatment,
                                      recoveryStatus: recoveryStatus.value,
                                      date: selectedDate.value,
                                      notes: notesController.text.trim(),
                                    )
                                  : await controller.saveMastitis(
                                      animalId: animal.id,
                                      testResult: testResult.value,
                                      treatment: treatment,
                                      recoveryStatus: recoveryStatus.value,
                                      date: selectedDate.value,
                                      notes: notesController.text.trim(),
                                    );
                              localSaving.value = false;
                              if (ok) {
                                final message = controller.lastSubmitMessage.trim().isEmpty
                                    ? 'Mastitis record saved successfully'
                                    : controller.lastSubmitMessage.trim();
                                if (Get.isBottomSheetOpen == true) {
                                  Get.back();
                                }
                                Future.delayed(const Duration(milliseconds: 250), () {
                                  Get.snackbar(
                                    'Success',
                                    message,
                                    duration: const Duration(seconds: 4),
                                  );
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: (localSaving.value || controller.isSubmitting.value)
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Record' : 'save_record'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      isScrollControlled: true,
    );
  }

  HealthAnimalItem? _animalForRecord(MastitisRecordItem? record) {
    if (record == null || record.animalId <= 0) {
      return null;
    }
    for (final animal in controller.animals) {
      if (animal.id == record.animalId) {
        return animal;
      }
    }
    return null;
  }

  DateTime _parseDisplayDate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      return DateTime.now();
    }
  }

  InputDecoration _sheetDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FCF8),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }
}
