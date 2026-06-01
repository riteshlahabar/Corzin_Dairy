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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSection(widget.initialSection);
    });
  }

  @override
  void didUpdateWidget(covariant HealthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadSection(widget.initialSection);
        }
      });
    }
  }

  void _loadSection(HealthSection section) {
    controller.selectedSection.value = section;
    if (section == HealthSection.mastitis) {
      controller.fetchMastitisRecords();
    } else {
      controller.fetchDmiRecords();
    }
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
    final records = controller.filteredDmiRecords;
    return RefreshIndicator(
      onRefresh: () async {
        await controller.fetchDmiRecords();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: [
          _dmiSearchAndDateFilters(),
          const SizedBox(height: 10),
          _dmiAnimalTypeFilters(),
          const SizedBox(height: 12),
          if (records.isEmpty)
            _inlineEmptyState('no_dmi_records_found'.tr)
          else
            ...records.map((item) {
              return _card(
                title: '${item.animalName} - Tag ${item.tagNumber}',
                subtitle: item.dmiType.isEmpty ? '-' : item.dmiType,
                dateText: item.date,
                status: _cardStatusLabel(item.alertStatus),
                rows: [
                  _info('required_dmi'.tr, '${item.requiredDmi} Kg'),
                  _info('body_weight'.tr, '${item.bodyWeight} Kg'),
                  if (!item.isNonMilking) _info('total_milk'.tr, '${item.totalMilk} L'),
                  _info('actual_dmi'.tr, '${item.actualDmi} Kg'),
                  if (item.notes.isNotEmpty) _info('notes'.tr, item.notes),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _mastitisList() {
    final records = controller.filteredMastitisGroups;
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
              (item) => _mastitisCard(item),
            ),
        ],
      ),
    );
  }

  Widget _mastitisCard(MastitisGroupItem item) {
    final treatments = item.treatments;
    final recoveredRows = item.recoveredRows;
    final isRecovered = item.recoveryStatus == 'recovered' || item.recoveryStatus == 'recoverd';
    return _card(
      title: '${item.animalName} - Tag ${item.tagNumber}',
      subtitle: _mastitisResultLabel(item.testResult),
      dateText: item.latestDate,
      status: _mastitisStatusLabel(item.recoveryStatus),
      rows: [
        if (treatments.isEmpty)
          _info('treatment'.tr, 'No treatment added')
        else
          ...treatments.map(
            (row) => _info(row.date, row.treatment),
          ),
        if (recoveredRows.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...recoveredRows.map(
            (row) => _info(row.date, 'recovered'.tr),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isRecovered ? null : () => _openMastitisTreatmentSheet(context, item),
                icon: const Icon(Icons.medical_services_outlined, size: 18),
                label: const Text('Add Treatment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isRecovered ? null : () => _confirmMastitisRecovered(item),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text('recovered'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dmiSearchAndDateFilters() {
    return Column(
      children: [
        TextField(
          onChanged: (value) => controller.dmiSearchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'Search by animal name or tag',
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
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dmiDateButton(
                label: 'From',
                date: controller.dmiFromDate.value,
                onTap: () => _pickDmiDate(isFrom: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dmiDateButton(
                label: 'To',
                date: controller.dmiToDate.value,
                onTap: () => _pickDmiDate(isFrom: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dmiDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDEBDE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "$label: ${DateFormat('dd/MM/yyyy').format(date)}",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDmiDate({required bool isFrom}) async {
    final initialDate = isFrom ? controller.dmiFromDate.value : controller.dmiToDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    if (isFrom) {
      await controller.setDmiDateRange(from: picked);
    } else {
      await controller.setDmiDateRange(to: picked);
    }
  }

  Widget _dmiAnimalTypeFilters() {
    final filters = <String, String>{'all': 'All'};
    for (final type in controller.dmiAnimalTypes) {
      filters[type.toLowerCase()] = type;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected = controller.dmiAnimalTypeFilter.value.toLowerCase() == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => controller.dmiAnimalTypeFilter.value = entry.key,
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
        statusLower.contains('negative') ||
        statusLower == 'recovered'.tr.toLowerCase();
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

  String _mastitisResultLabel(String result) {
    switch (result.trim().toLowerCase()) {
      case 'positive':
        return 'positive'.tr;
      case 'negative':
        return 'negative'.tr;
      default:
        return result.trim().isEmpty ? '-' : result;
    }
  }

  String _mastitisStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'under_treatment':
      case 'under_treatement':
      case 'under treatment':
      case 'under treatement':
        return 'under_treatment'.tr;
      case 'recovered':
      case 'recoverd':
        return 'recovered'.tr;
      default:
        return status.trim().isEmpty ? '-' : status;
    }
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

  Future<void> _openMastitisSheet(BuildContext context) async {
    final selectedAnimal = Rxn<HealthAnimalItem>();
    final testResult = 'positive'.obs;
    final localSaving = false.obs;

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
                _sheetHandle(),
                Text(
                  'add_mastitis_record'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<HealthAnimalItem>(
                  initialValue: selectedAnimal.value,
                  isExpanded: true,
                  decoration: _sheetDecoration('select_animal'.tr),
                  items: controller.milkingAnimals
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
                    DropdownMenuItem(value: 'positive', child: Text('positive'.tr)),
                    DropdownMenuItem(value: 'negative', child: Text('negative'.tr)),
                  ],
                  onChanged: (value) {
                    if (value != null && value.isNotEmpty) {
                      testResult.value = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (localSaving.value || controller.isSubmitting.value)
                        ? null
                        : () async {
                            final animal = selectedAnimal.value;
                            if (animal == null) {
                              Get.snackbar('validation'.tr, 'select_animal'.tr);
                              return;
                            }

                            localSaving.value = true;
                            final ok = await controller.saveMastitis(
                              animalId: animal.id,
                              testResult: testResult.value,
                            );
                            localSaving.value = false;
                            if (ok) {
                              _closeSheetAndShowSuccess(
                                controller.lastSubmitMessage.trim().isEmpty
                                    ? 'Mastitis record saved successfully'
                                    : controller.lastSubmitMessage.trim(),
                              );
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
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Text('save_record'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _openMastitisTreatmentSheet(BuildContext context, MastitisGroupItem item) async {
  final treatmentController = TextEditingController();
  final selectedDate = DateTime.now().obs;
  final localSaving = false.obs;

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
              _sheetHandle(),
              const Text(
                'Add Treatment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '${item.animalName} - Tag ${item.tagNumber}',
                style: TextStyle(
                  color: AppColors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: treatmentController,
                minLines: 2,
                maxLines: 3,
                decoration: _sheetDecoration('treatment'.tr),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (localSaving.value || controller.isSubmitting.value)
                      ? null
                      : () async {
                          final treatment = treatmentController.text.trim();

                          if (treatment.isEmpty) {
                            Get.snackbar('validation'.tr, 'Please enter treatment');
                            return;
                          }

                          localSaving.value = true;

                          final ok = await controller.addMastitisTreatment(
                            animalId: item.animalId,
                            treatment: treatment,
                            date: selectedDate.value,
                          );

                          localSaving.value = false;

                          if (ok) {
                            _closeSheetAndShowSuccess(
                              controller.lastSubmitMessage.trim().isEmpty
                                  ? 'Treatment added successfully'
                                  : controller.lastSubmitMessage.trim(),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : const Text(
                          'Save Treatment',
                          style: TextStyle(fontWeight: FontWeight.w700),
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

  Future<void> _confirmMastitisRecovered(MastitisGroupItem item) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Recovery'),
        content: Text('Are you sure your animal ${item.animalName} is recovered?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final saved = await controller.markMastitisRecovered(
      animalId: item.animalId,
      date: DateTime.now(),
    );
    if (saved) {
      Get.snackbar(
        'Success',
        controller.lastSubmitMessage.trim().isEmpty
            ? 'Animal marked as recovered'
            : controller.lastSubmitMessage.trim(),
        duration: const Duration(seconds: 4),
      );
    }
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        height: 4,
        width: 54,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  void _closeSheetAndShowSuccess(String message) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    Future.delayed(const Duration(milliseconds: 250), () {
      Get.snackbar('Success', message, duration: const Duration(seconds: 4));
    });
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
