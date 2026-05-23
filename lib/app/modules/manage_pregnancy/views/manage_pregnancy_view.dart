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
        label: const Text('Add Record'),
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
                  'Search cow, tag, doctor, status...',
                  icon: Icons.search_rounded,
                ),
              ),
            ),
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
                                children: const [
                                  SizedBox(height: 120),
                                  Icon(
                                    Icons.health_and_safety_rounded,
                                    size: 50,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'No pregnancy records found',
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
          const Expanded(
            child: Text(
              'Manage Pregnancy',
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
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pregnant_woman_rounded,
                  color: AppColors.primary,
                ),
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
                    const SizedBox(height: 5),
                    Text(
                      'Pregnancy ${record.pregnancyNo}  |  Service ${record.serviceNo}',
                      style: TextStyle(
                        fontSize: 12,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailTile('AI Date', _dash(record.aiDate), Icons.event_rounded),
              _detailTile(
                'Check Due',
                _dash(record.pregnancyCheckDueDate),
                Icons.fact_check_rounded,
              ),
              _detailTile(
                'Expected Calving',
                _dash(record.expectedCalvingDate),
                Icons.child_care_rounded,
              ),
              _detailTile(
                'Remaining',
                record.remainingDays == null
                    ? '-'
                    : '${record.remainingDays} days',
                Icons.timelapse_rounded,
              ),
              _detailTile(
                'Result',
                controller.statusLabel(record.pregnancyResult),
                Icons.verified_rounded,
              ),
              _detailTile(
                'Current',
                record.isCurrent ? 'Yes' : 'No',
                Icons.radio_button_checked_rounded,
              ),
            ],
          ),
          if (record.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              record.notes,
              style: TextStyle(fontSize: 12, color: AppColors.grey.shade700),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Edit',
                  Icons.edit_rounded,
                  AppColors.primary,
                  () => _openForm(context, record: record),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  'Status',
                  Icons.sync_rounded,
                  const Color(0xFF1976D2),
                  () => _openStatusSheet(record),
                ),
              ),
              const SizedBox(width: 8),
              _iconAction(
                Icons.delete_outline_rounded,
                Colors.red.shade600,
                () => _confirmDelete(record),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _detailTile(String label, String value, IconData icon) {
    return Container(
      width: 150,
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 40,
        width: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: color, size: 18),
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

  void _openStatusSheet(PregnancyRecordModel record) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Wrap(
            runSpacing: 10,
            children: ManagePregnancyController.statuses
                .where((status) => status != 'all')
                .map(
                  (status) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: status == record.status
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : const Color(0xFFF7FAF7),
                    leading: Icon(
                      Icons.radio_button_checked_rounded,
                      color: _statusColor(status),
                    ),
                    title: Text(
                      controller.statusLabel(status),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onTap: () async {
                      Get.back();
                      await controller.updateStatus(record, status: status);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
      isScrollControlled: true,
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
              const Text(
                'Delete Pregnancy Record',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete ${record.cowLabel} pregnancy record?',
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
                      child: const Text('Cancel'),
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
                            : const Text('Delete'),
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
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
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
  String pregnancyResult = 'pending';
  String status = 'served';
  bool isCurrent = true;

  final heatDate = TextEditingController();
  final aiDate = TextEditingController();
  final bullName = TextEditingController();
  final semenNo = TextEditingController();
  final doctorName = TextEditingController();
  final checkDueDate = TextEditingController();
  final checkDate = TextEditingController();
  final expectedCalvingDate = TextEditingController();
  final dryOffDate = TextEditingController();
  final calvingDate = TextEditingController();
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
      pregnancyResult = record.pregnancyResult;
      status = record.status;
      isCurrent = record.isCurrent;
      heatDate.text = record.heatDate;
      aiDate.text = record.aiDate;
      bullName.text = record.bullName;
      semenNo.text = record.semenNo;
      doctorName.text = record.doctorName;
      checkDueDate.text = record.pregnancyCheckDueDate;
      checkDate.text = record.pregnancyCheckDate;
      expectedCalvingDate.text = record.expectedCalvingDate;
      dryOffDate.text = record.dryOffDate;
      calvingDate.text = record.calvingDate;
      notes.text = record.notes;
    }
  }

  @override
  void dispose() {
    heatDate.dispose();
    aiDate.dispose();
    bullName.dispose();
    semenNo.dispose();
    doctorName.dispose();
    checkDueDate.dispose();
    checkDate.dispose();
    expectedCalvingDate.dispose();
    dryOffDate.dispose();
    calvingDate.dispose();
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
                          ? 'Add Pregnancy Record'
                          : 'Edit Pregnancy Record',
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
                        decoration: _decor('Select Cow *'),
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
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select cow' : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _numberBox(
                            'Pregnancy No',
                            pregnancyNo,
                            (value) => pregnancyNo = value,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _numberBox(
                            'Service No',
                            serviceNo,
                            (value) => serviceNo = value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _dateBox('Heat Date', heatDate),
                    const SizedBox(height: 10),
                    _dateBox('AI Date *', aiDate, requiredField: true, onPicked: _autoDates),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: serviceType,
                      decoration: _decor('Service Type *'),
                      dropdownColor: const Color(0xFFF4FAF4),
                      items: const [
                        DropdownMenuItem(value: 'ai', child: Text('AI')),
                        DropdownMenuItem(value: 'natural', child: Text('Natural')),
                      ],
                      onChanged: (value) =>
                          setState(() => serviceType = value ?? 'ai'),
                    ),
                    const SizedBox(height: 10),
                    _textBox('Bull Name', bullName),
                    const SizedBox(height: 10),
                    _textBox('Semen No', semenNo),
                    const SizedBox(height: 10),
                    _textBox('Doctor Name', doctorName),
                    const SizedBox(height: 10),
                    _dateBox('Pregnancy Check Due Date', checkDueDate),
                    const SizedBox(height: 10),
                    _dateBox('Pregnancy Check Date', checkDate),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: pregnancyResult,
                      decoration: _decor('Pregnancy Result'),
                      dropdownColor: const Color(0xFFF4FAF4),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'pregnant', child: Text('Pregnant')),
                        DropdownMenuItem(value: 'not_pregnant', child: Text('Not Pregnant')),
                      ],
                      onChanged: (value) => setState(
                        () => pregnancyResult = value ?? 'pending',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _dateBox('Expected Calving Date', expectedCalvingDate),
                    const SizedBox(height: 10),
                    _dateBox('Dry Off Date', dryOffDate),
                    const SizedBox(height: 10),
                    _dateBox('Calving Date', calvingDate),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: _decor('Status'),
                      dropdownColor: const Color(0xFFF4FAF4),
                      items: ManagePregnancyController.statuses
                          .where((item) => item != 'all')
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(controller.statusLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        status = value ?? 'served';
                        pregnancyResult =
                            controller.resultForStatus(status, pregnancyResult);
                        isCurrent = ['served', 'pregnancy_check_due', 'pregnant']
                            .contains(status);
                      }),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => DropdownButtonFormField<int>(
                        initialValue: calfAnimalId == 0 ? null : calfAnimalId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFF4FAF4),
                        decoration: _decor('Calf Animal'),
                        items: controller.animals
                            .map(
                              (animal) => DropdownMenuItem(
                                value: animal.id,
                                child: Text(animal.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => calfAnimalId = value ?? 0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notes,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _decor('Notes'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isCurrent,
                      onChanged: (value) => setState(() => isCurrent = value),
                      title: const Text(
                        'Current pregnancy/service',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
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
                                      ? 'Save Record'
                                      : 'Update Record',
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

  Widget _numberBox(String label, int value, ValueChanged<int> onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: _decor(label),
      onChanged: (raw) => onChanged(int.tryParse(raw) ?? 1),
    );
  }

  Widget _textBox(String label, TextEditingController textController) {
    return TextFormField(
      controller: textController,
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
          ? (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null
          : null,
      onTap: () async {
        final initial = DateTime.tryParse(textController.text) ?? DateTime.now();
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
      expectedCalvingDate.text = controller.addDays(ai, 283);
      dryOffDate.text = controller.addDays(ai, 223);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await controller.saveRecord(
      record: widget.record,
      animalId: animalId,
      pregnancyNo: pregnancyNo,
      serviceNo: serviceNo,
      heatDate: heatDate.text.trim(),
      aiDate: aiDate.text.trim(),
      serviceType: serviceType,
      bullName: bullName.text.trim(),
      semenNo: semenNo.text.trim(),
      doctorName: doctorName.text.trim(),
      pregnancyCheckDueDate: checkDueDate.text.trim(),
      pregnancyCheckDate: checkDate.text.trim(),
      pregnancyResult: pregnancyResult,
      expectedCalvingDate: expectedCalvingDate.text.trim(),
      dryOffDate: dryOffDate.text.trim(),
      calvingDate: calvingDate.text.trim(),
      status: status,
      calfAnimalId: calfAnimalId,
      notes: notes.text.trim(),
      isCurrent: isCurrent,
    );
    if (ok) Get.back();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
