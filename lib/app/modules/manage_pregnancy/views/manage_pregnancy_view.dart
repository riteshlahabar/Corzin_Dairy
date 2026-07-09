import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/manage_pregnancy_controller.dart';
import '../models/pregnancy_record_model.dart';

class ManagePregnancyView extends GetView<ManagePregnancyController> {
  const ManagePregnancyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('add_record'.tr),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _appBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: controller.searchController,
                decoration: _inputDecoration(
                  'search_cow_tag_doctor_status'.tr,
                  icon: Icons.search_rounded,
                ),
              ),
            ),
            _animalFilterDropdown(),
            _statusFilters(),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.fetchRecords,
                        child: controller.filteredRecords.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  SizedBox(height: 120),
                                  Icon(
                                    Icons.health_and_safety_rounded,
                                    size: 50,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'no_pregnancy_records_found'.tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  92,
                                ),
                                itemCount: controller.filteredRecords.length,
                                itemBuilder: (context, index) {
                                  return _recordCard(
                                    context,
                                    controller.filteredRecords[index],
                                  );
                                },
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        8,
        6,
      ),
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
              'manage_pregnancy'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
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

  Widget _statusFilters() {
    return SizedBox(
      height: 40,
      child: Obx(
        () => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: ManagePregnancyController.statuses
              .map((status) => _statusChip(status))
              .toList(),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final isSelected = controller.selectedStatus.value == status;
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: ChoiceChip(
        label: Text(controller.statusLabel(status)),
        selected: isSelected,
        onSelected: (_) => controller.selectedStatus.value = status,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.black,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.primary.withValues(alpha: 0.12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _recordCard(BuildContext context, PregnancyRecordModel record) {
    final statusColor = _statusColor(record.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
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
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _animalAvatar(record),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.cowLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dash(record.uniqueId)}  |  ${'tag'.tr}: ${_dash(record.tagNumber)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _badge(controller.statusLabel(record.status), statusColor),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _detailTile(
                    'ai_date'.tr,
                    _displayDate(record.aiDate),
                    Icons.event_rounded,
                    width: tileWidth,
                  ),
                  _detailTile(
                    _isPregnancyChecked(record)
                        ? 'pregnancy_check_date'.tr
                        : 'pregnancy_check_due'.tr,
                    _isPregnancyChecked(record)
                        ? _displayDate(record.pregnancyCheckDate)
                        : _displayDate(record.pregnancyCheckDueDate),
                    Icons.fact_check_rounded,
                    width: tileWidth,
                  ),
                  if (record.status == 'pregnant') ...[
                    _detailTile(
                      'expected_calving'.tr,
                      _displayDate(record.expectedCalvingDate),
                      Icons.child_care_rounded,
                      width: tileWidth,
                    ),
                    _detailTile(
                      'remaining'.tr,
                      record.remainingDays == null
                          ? '-'
                          : '${record.remainingDays} ${'days'.tr}',
                      Icons.timelapse_rounded,
                      width: tileWidth,
                    ),
                  ],
                  if (record.status == 'calved') ...[
                    _detailTile(
                      'delivery_date'.tr,
                      _displayDate(record.calvingDate),
                      Icons.child_care_rounded,
                      width: tileWidth,
                    ),
                    _detailTile(
                      'breed_name'.tr,
                      _dash(record.breedName),
                      Icons.pets_rounded,
                      width: tileWidth,
                    ),
                  ],
                  if (record.status == 'aborted') ...[
                    _detailTile(
                      'abort_date'.tr,
                      _displayDate(record.abortDate),
                      Icons.event_busy_rounded,
                      width: tileWidth,
                    ),
                    _detailTile(
                      'abort_reason'.tr,
                      _dash(record.abortReason),
                      Icons.notes_rounded,
                      width: tileWidth,
                    ),
                  ],
                ],
              );
            },
          ),
          if (record.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              record.notes,
              style: TextStyle(fontSize: 12, color: AppColors.grey.shade700),
            ),
          ],
          if (record.status != 'calved' && record.status != 'aborted') ...[
            const SizedBox(height: 12),
            if (record.status == 'pregnant')
              Row(
                children: [
                  Expanded(
                    child: _statusActionButton(
                      label: 'delivery'.tr,
                      color: AppColors.primary,
                      isSelected: false,
                      onTap: () => _openDeliverySheet(record),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statusActionButton(
                      label: 'abort'.tr,
                      color: Colors.red.shade600,
                      isSelected: false,
                      onTap: () => _openAbortSheet(record),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _statusActionButton(
                      label: 'pregnant'.tr,
                      color: AppColors.primary,
                      isSelected: record.status == 'pregnant',
                      onTap: () => _openPregnancyCheckSheet(
                        record,
                        nextStatus: 'pregnant',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statusActionButton(
                      label: 'non_pregnant'.tr,
                      color: const Color(0xFFE67E22),
                      isSelected: record.status == 'not_pregnant',
                      onTap: () => _openPregnancyCheckSheet(
                        record,
                        nextStatus: 'not_pregnant',
                      ),
                    ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'edit'.tr,
                  Icons.edit_rounded,
                  AppColors.primary,
                  () => _openForm(context, record: record),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  'delete'.tr,
                  Icons.delete_outline_rounded,
                  Colors.red.shade600,
                  () => _confirmDelete(record),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _detailTile(
    String label,
    String value,
    IconData icon, {
    double? width,
  }) {
    return Container(
      width: width ?? 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {PregnancyRecordModel? record}) {
    Get.bottomSheet(
      _PregnancyFormSheet(record: record),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _openPregnancyCheckSheet(
    PregnancyRecordModel record, {
    required String nextStatus,
  }) {
    final checkDateController = TextEditingController(
      text: record.pregnancyCheckDate.trim().isNotEmpty
          ? _displayDate(record.pregnancyCheckDate)
          : _formatDate(DateTime.now()),
    );
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Wrap(
                runSpacing: 12,
                children: [
                  Text(
                    nextStatus == 'pregnant'
                        ? 'mark_as_pregnant'.tr
                        : 'mark_as_non_pregnant'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextFormField(
                    controller: checkDateController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      'pregnancy_check_date'.tr,
                      icon: Icons.calendar_month_rounded,
                    ),
                    onTap: () async {
                      final initial =
                          _parseDate(checkDateController.text.trim()) ??
                          DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                surface: Color(0xFFF4FAF4),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setSheetState(
                          () => checkDateController.text = _formatDate(picked),
                        );
                      }
                    },
                  ),
                  Obx(
                    () => SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                final checkDate = checkDateController.text
                                    .trim();
                                if (checkDate.isEmpty) {
                                  Get.snackbar(
                                    'validation'.tr,
                                    'please_select_pregnancy_check_date'.tr,
                                  );
                                  return;
                                }
                                final navigator = Navigator.of(context);
                                final ok = await controller.updateStatus(
                                  record,
                                  status: nextStatus,
                                  pregnancyCheckDate: checkDate,
                                );
                                if (ok && navigator.canPop()) {
                                  navigator.pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _statusColor(nextStatus),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                nextStatus == 'pregnant'
                                    ? 'confirm_pregnant'.tr
                                    : 'confirm_non_pregnant'.tr,
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openDeliverySheet(PregnancyRecordModel record) {
    final deliveryDateController = TextEditingController(
      text: record.calvingDate.trim().isNotEmpty
    ? _displayDate(record.calvingDate)
    : _formatDate(DateTime.now()),
    );

    final breedNameController = TextEditingController(
      text: _initialBreedName(record),
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Wrap(
                runSpacing: 12,
                children: [
                  Text(
                    'confirm_delivery'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextFormField(
                    controller: deliveryDateController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      'delivery_date'.tr,
                      icon: Icons.calendar_month_rounded,
                    ),
                    onTap: () async {
                      final value = await _pickDate(
                        context,
                        deliveryDateController.text.trim(),
                      );
                      if (value != null) {
                        setSheetState(
                          () => deliveryDateController.text = value,
                        );
                      }
                    },
                  ),
                  TextFormField(
                    controller: breedNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      'breed_name'.tr,
                      icon: Icons.pets_rounded,
                    ),
                  ),
                  Obx(
                    () => SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                final deliveryDate = deliveryDateController.text
                                    .trim();

                                if (deliveryDate.isEmpty) {
                                  Get.snackbar(
                                    'validation'.tr,
                                    'please_select_delivery_date'.tr,
                                  );
                                  return;
                                }

                                final navigator = Navigator.of(context);

                                final ok = await controller.updateStatus(
                                  record,
                                  status: 'calved',
                                  pregnancyCheckDate: record.pregnancyCheckDate,
                                  calvingDate: deliveryDate,
                                  breedName: breedNameController.text.trim(),
                                );

                                if (ok && navigator.canPop()) {
                                  navigator.pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('save_delivery'.tr),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openAbortSheet(PregnancyRecordModel record) {
    final abortDateController = TextEditingController(
      text: record.abortDate.trim().isNotEmpty
    ? _displayDate(record.abortDate)
    : _formatDate(DateTime.now()),
    );

    final abortReasonController = TextEditingController(
      text: record.abortReason.trim().isNotEmpty
          ? record.abortReason.trim()
          : record.notes.trim(),
    );

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Wrap(
                runSpacing: 12,
                children: [
                  Text(
                    'confirm_abort'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextFormField(
                    controller: abortDateController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      'abort_date'.tr,
                      icon: Icons.calendar_month_rounded,
                    ),
                    onTap: () async {
                      final value = await _pickDate(
                        context,
                        abortDateController.text.trim(),
                      );
                      if (value != null) {
                        setSheetState(() => abortDateController.text = value);
                      }
                    },
                  ),
                  TextFormField(
                    controller: abortReasonController,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      'abort_reason'.tr,
                      icon: Icons.notes_rounded,
                    ),
                  ),
                  Obx(
                    () => SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                final abortDate = abortDateController.text
                                    .trim();

                                if (abortDate.isEmpty) {
                                  Get.snackbar(
                                    'validation'.tr,
                                    'please_select_abort_date'.tr,
                                  );
                                  return;
                                }

                                final navigator = Navigator.of(context);

                                final ok = await controller.updateStatus(
                                  record,
                                  status: 'aborted',
                                  pregnancyCheckDate: record.pregnancyCheckDate,
                                  abortDate: abortDate,
                                  abortReason: abortReasonController.text
                                      .trim(),
                                );

                                if (ok && navigator.canPop()) {
                                  navigator.pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('save_abort'.tr),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _initialBreedName(PregnancyRecordModel record) {
    if (record.breedName.trim().isNotEmpty) {
      return record.breedName.trim();
    }

    final animal = controller.allAnimals.firstWhereOrNull(
      (item) => item.id == record.animalId,
    );

    return animal?.breedName.trim() ?? '';
  }

  Future<String?> _pickDate(BuildContext context, String initialValue) async {
   final initial = _parseDate(initialValue) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: Color(0xFFF4FAF4),
            ),
          ),
          child: child!,
        );
      },
    );

    return picked == null ? null : _formatDate(picked);
  }

  Widget _statusActionButton({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? color.withValues(alpha: 0.12)
              : Colors.white,
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _animalFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Obx(() {
        final selectedId = controller.selectedAnimalId.value;
        final availableIds = controller.animals.map((item) => item.id).toSet();
        final value = selectedId != null && availableIds.contains(selectedId)
            ? selectedId
            : null;
        return DropdownButtonFormField<int?>(
          initialValue: value,
          isExpanded: true,
          iconEnabledColor: AppColors.primary,
          iconDisabledColor: AppColors.primary,
          dropdownColor: const Color(0xFFF4FAF4),
          decoration: _inputDecoration(
            'select_animal'.tr,
            icon: Icons.pets_rounded,
          ),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text('all'.tr)),
            ...controller.animals.map(
              (animal) => DropdownMenuItem<int?>(
                value: animal.id,
                child: Text(animal.label, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (value) => controller.selectedAnimalId.value = value,
        );
      }),
    );
  }

  Widget _animalAvatar(PregnancyRecordModel record) {
    final imageUrl = record.image.trim();
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackAnimalAvatar(),
      );
    }
    return _fallbackAnimalAvatar();
  }

  Widget _fallbackAnimalAvatar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.10),
      child: const Icon(Icons.pets_rounded, color: AppColors.primary),
    );
  }

  void _confirmDelete(PregnancyRecordModel record) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'delete_pregnancy_record'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'delete_pregnancy_record_confirm'.trParams({
                  'name': record.cowLabel,
                }),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: AppColors.grey.shade700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                Get.back();
                                await controller.deleteRecord(record);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('delete'.tr),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: AppColors.primary),
      prefixIconConstraints: const BoxConstraints(minWidth: 38),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pregnant' => AppColors.primary,
      'calved' => const Color(0xFF1976D2),
      'not_pregnant' || 'repeat_heat' => const Color(0xFFE67E22),
      'aborted' => Colors.red.shade600,
      'pregnancy_check_due' => const Color(0xFF7B1FA2),
      _ => const Color(0xFF546E7A),
    };
  }

  bool _isPregnancyChecked(PregnancyRecordModel record) {
    return record.status == 'pregnant' ||
        record.status == 'not_pregnant' ||
        record.status == 'calved' ||
        record.status == 'aborted';
  }

  String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    try {
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(text)) {
        final parts = text.split('-');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
        final parts = text.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
        return DateTime.tryParse(text);
      }
    } catch (_) {}

    return DateTime.tryParse(text);
  }

  String _displayDate(String value) {
    final parsed = _parseDate(value);
    if (parsed == null) return '-';
    return _formatDate(parsed);
  }

  String _dash(String value) => value.trim().isEmpty ? '-' : value;
}

class _PregnancyFormSheet extends StatefulWidget {
  const _PregnancyFormSheet({this.record});

  final PregnancyRecordModel? record;

  @override
  State<_PregnancyFormSheet> createState() => _PregnancyFormSheetState();
}

class _PregnancyFormSheetState extends State<_PregnancyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final ManagePregnancyController controller;

  int animalId = 0;
  int pregnancyNo = 1;
  int serviceNo = 1;
  int calfAnimalId = 0;
  String serviceType = 'ai';

  final lactationNumberController = TextEditingController();
  final heatDate = TextEditingController();
  final aiDate = TextEditingController();
  final bullName = TextEditingController();
  final semenNo = TextEditingController();
  final doctorName = TextEditingController();
  final checkDueDate = TextEditingController();
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<ManagePregnancyController>();
    final record = widget.record;
    if (record != null) {
      animalId = record.animalId;
      pregnancyNo = record.pregnancyNo;
      serviceNo = record.serviceNo;
      calfAnimalId = record.calfAnimalId;
      serviceType = record.serviceType;
      heatDate.text = _displayDate(record.heatDate);
      aiDate.text = _displayDate(record.aiDate);
      bullName.text = record.bullName;
      semenNo.text = record.semenNo;
      doctorName.text = record.doctorName;
      checkDueDate.text = _displayDate(record.pregnancyCheckDueDate);
      notes.text = record.notes;
    }
    _syncLactationNumber();
  }

  @override
  void dispose() {
    lactationNumberController.dispose();
    heatDate.dispose();
    aiDate.dispose();
    bullName.dispose();
    semenNo.dispose();
    doctorName.dispose();
    checkDueDate.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.record == null
                          ? 'add_pregnancy_record'.tr
                          : 'edit_pregnancy_record'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                  children: [
                    Obx(
                      () => DropdownButtonFormField<int>(
                        initialValue: animalId == 0 ? null : animalId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFF4FAF4),
                        decoration: _decor('${'select_cow'.tr} *'),
                        items: controller.animals
                            .map(
                              (animal) => DropdownMenuItem(
                                value: animal.id,
                                child: Text(animal.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            animalId = value ?? 0;
                            if (widget.record == null && animalId > 0) {
                              final next = controller.nextNumbers(animalId);
                              pregnancyNo = next.pregnancyNo;
                              serviceNo = next.serviceNo;
                            }
                            _syncLactationNumber();
                          });
                        },
                        validator: (value) =>
                            value == null ? 'please_select_cow'.tr : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _textBox(
                      'lactation_number'.tr,
                      lactationNumberController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _dateBox('heat_date'.tr, heatDate),
                    const SizedBox(height: 10),
                    _dateBox(
                      '${'ai_date'.tr} *',
                      aiDate,
                      requiredField: true,
                      onPicked: _autoDates,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: serviceType,
                      decoration: _decor('${'service_type'.tr} *'),
                      dropdownColor: const Color(0xFFF4FAF4),
                      items: [
                        const DropdownMenuItem(value: 'ai', child: Text('AI')),
                        DropdownMenuItem(
                          value: 'natural',
                          child: Text('natural'.tr),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => serviceType = value ?? 'ai'),
                    ),
                    const SizedBox(height: 10),
                    _textBox('bull_name'.tr, bullName),
                    const SizedBox(height: 10),
                    _textBox('semen_no'.tr, semenNo),
                    const SizedBox(height: 10),
                    _textBox('doctor_name'.tr, doctorName),
                    const SizedBox(height: 10),
                    _dateBox(
                      '${'pregnancy_check_due_date'.tr} *',
                      checkDueDate,
                      requiredField: true,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notes,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _decor('notes'.tr),
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.record == null
                                      ? 'save_record'.tr
                                      : 'update_record'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textBox(
    String label,
    TextEditingController textController, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: textController,
      keyboardType: keyboardType,
      decoration: _decor(label),
    );
  }

  Widget _dateBox(
    String label,
    TextEditingController textController, {
    bool requiredField = false,
    VoidCallback? onPicked,
  }) {
    return TextFormField(
      controller: textController,
      readOnly: true,
      decoration: _decor(label).copyWith(
        suffixIcon: textController.text.isEmpty
            ? const Icon(Icons.calendar_month_rounded)
            : IconButton(
                onPressed: () {
                  setState(() => textController.clear());
                  onPicked?.call();
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
      validator: requiredField
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
      onTap: () async {
        final initial = _parseDate(textController.text) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  surface: Color(0xFFF4FAF4),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final value = _formatDate(picked);
          setState(() => textController.text = value);
          onPicked?.call();
        }
      },
    );
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  void _autoDates() {
    final ai = aiDate.text.trim();
    setState(() {
      checkDueDate.text = controller.addDays(ai, 30);
    });
  }

  void _syncLactationNumber() {
    final selectedAnimal = controller.allAnimals.firstWhereOrNull(
      (animal) => animal.id == animalId,
    );
    final value = selectedAnimal?.lactationNumber ?? 0;
    lactationNumberController.text = value > 0 ? value.toString() : '';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final existing = widget.record;
    final isEdit = existing != null;
    final numbers = isEdit
        ? (pregnancyNo: pregnancyNo, serviceNo: serviceNo)
        : controller.nextNumbers(animalId);

    final normalizedResult = isEdit ? existing.pregnancyResult : 'pending';
    final normalizedStatus = isEdit ? existing.status : 'pregnancy_check_due';
    final normalizedIsCurrent = isEdit ? existing.isCurrent : true;
    final lactationNumber =
        int.tryParse(lactationNumberController.text.trim()) ?? 0;

    final ok = await controller.saveRecord(
      record: existing,
      animalId: animalId,
      lactationNumber: lactationNumber,
      pregnancyNo: numbers.pregnancyNo,
      serviceNo: numbers.serviceNo,
      heatDate: heatDate.text.trim(),
      aiDate: aiDate.text.trim(),
      serviceType: serviceType,
      bullName: bullName.text.trim(),
      semenNo: semenNo.text.trim(),
      doctorName: doctorName.text.trim(),
      pregnancyCheckDueDate: checkDueDate.text.trim(),
      pregnancyCheckDate: isEdit ? existing.pregnancyCheckDate : '',
      pregnancyResult: normalizedResult,
      expectedCalvingDate: isEdit ? existing.expectedCalvingDate : '',
      dryOffDate: isEdit ? existing.dryOffDate : '',
      calvingDate: isEdit ? existing.calvingDate : '',
      status: normalizedStatus,
      calfAnimalId: calfAnimalId,
      notes: notes.text.trim(),
      isCurrent: normalizedIsCurrent,
    );
    if (!ok) return;

    _stayOnManagePregnancyAfterSave();
  }

  void _stayOnManagePregnancyAfterSave() {
    if (Get.isBottomSheetOpen == true) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    controller.selectedStatus.value = 'pregnancy_check_due';
    controller.searchController.clear();

    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().runSilentSyncNow();
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    try {
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(text)) {
        final parts = text.split('-');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(text)) {
        final parts = text.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
        return DateTime.tryParse(text);
      }
    } catch (_) {}

    return DateTime.tryParse(text);
  }

  String _displayDate(String value) {
    final parsed = _parseDate(value);
    if (parsed == null) return '';
    return _formatDate(parsed);
  }
}
