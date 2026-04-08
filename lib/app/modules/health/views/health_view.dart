import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/health_controller.dart';

class HealthView extends GetView<HealthController> {
  const HealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF7),
        floatingActionButton: Builder(
          builder: (context) => _addButton(context),
        ),
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'health'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'medical'.tr),
                    Tab(text: 'mastitis'.tr),
                    Tab(text: 'dmi'.tr),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(
                  () => controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: [
                            _medicalList(),
                            _mastitisList(),
                            _dmiList(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        final tabController = DefaultTabController.of(context);
        final index = tabController.index;
        if (index == 0) {
          _openMedicalSheet();
        } else if (index == 1) {
          _openMastitisSheet();
        } else {
          _openDmiSheet();
        }
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text('add_record'.tr, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _medicalList() => RefreshIndicator(
    onRefresh: controller.fetchMedicalRecords,
    child: controller.medicalRecords.isEmpty
        ? _emptyState('no_medical_records_found'.tr)
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: controller.medicalRecords.length,
            itemBuilder: (context, index) {
              final item = controller.medicalRecords[index];
              return _card(
                title: item.medicineName,
                subtitle: '${item.animalName} - Tag ${item.tagNumber}',
                rows: [
                  _info('dose'.tr, item.dose),
                  _info('disease'.tr, item.disease),
                  _info('date'.tr, item.date),
                  if (item.notes.isNotEmpty) _info('notes'.tr, item.notes),
                ],
              );
            },
          ),
  );

  Widget _mastitisList() => RefreshIndicator(
    onRefresh: controller.fetchMastitisRecords,
    child: controller.mastitisRecords.isEmpty
        ? _emptyState('no_mastitis_records_found'.tr)
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: controller.mastitisRecords.length,
            itemBuilder: (context, index) {
              final item = controller.mastitisRecords[index];
              return _card(
                title: item.testResult,
                subtitle: '${item.animalName} - Tag ${item.tagNumber}',
                rows: [
                  _info('treatment'.tr, item.treatment),
                  _info('recovery'.tr, item.recoveryStatus),
                  _info('date'.tr, item.date),
                  if (item.notes.isNotEmpty) _info('notes'.tr, item.notes),
                ],
              );
            },
          ),
  );

  Widget _dmiList() => RefreshIndicator(
    onRefresh: controller.fetchDmiRecords,
    child: controller.dmiRecords.isEmpty
        ? _emptyState('no_dmi_records_found'.tr)
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: controller.dmiRecords.length,
            itemBuilder: (context, index) {
              final item = controller.dmiRecords[index];
              return _card(
                title: '${item.requiredDmi} Kg ${'required_dmi'.tr}',
                subtitle: '${item.animalName} - Tag ${item.tagNumber}',
                rows: [
                  _info('body_weight'.tr, '${item.bodyWeight} Kg'),
                  _info('total_milk'.tr, '${item.totalMilk} L'),
                  _info('actual_dmi'.tr, '${item.actualDmi} Kg'),
                  _info('alert'.tr, item.alertStatus),
                  _info('date'.tr, item.date),
                  if (item.notes.isNotEmpty) _info('notes'.tr, item.notes),
                ],
              );
            },
          ),
  );

  Widget _card({
    required String title,
    required String subtitle,
    required List<Widget> rows,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.5, color: AppColors.grey.shade700),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
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

  void _openMedicalSheet() {
    final animal = Rxn<HealthAnimalItem>();
    final medicineController = TextEditingController();
    final doseController = TextEditingController();
    final diseaseController = TextEditingController();
    final notesController = TextEditingController();
    final date = Rx<DateTime>(DateTime.now());
    _showFormSheet(
      title: 'add_medical_record'.tr,
      children: [
        _animalDropdown(animal),
        _textField(medicineController, 'medicine_name'.tr),
        _textField(doseController, 'dose'.tr),
        _textField(diseaseController, 'disease'.tr),
        _dateField(date),
        _textField(notesController, 'notes'.tr, maxLines: 3),
      ],
      onSave: () async {
        if (animal.value == null ||
            medicineController.text.trim().isEmpty ||
            doseController.text.trim().isEmpty ||
            diseaseController.text.trim().isEmpty) {
          Get.snackbar('error'.tr, 'please_fill_required_fields'.tr);
          return;
        }
        final ok = await controller.saveMedical(
          animalId: animal.value!.id,
          medicineName: medicineController.text.trim(),
          dose: doseController.text.trim(),
          date: date.value,
          disease: diseaseController.text.trim(),
          notes: notesController.text.trim(),
        );
        if (ok) Get.back();
      },
    );
  }

  void _openMastitisSheet() {
    final animal = Rxn<HealthAnimalItem>();
    final testResult = 'Positive'.obs;
    final treatmentController = TextEditingController();
    final recoveryStatus = 'Under Treatment'.obs;
    final notesController = TextEditingController();
    final date = Rx<DateTime>(DateTime.now());
    _showFormSheet(
      title: 'add_mastitis_record'.tr,
      children: [
        _animalDropdown(animal),
        _stringDropdown(testResult, const [
          'Positive',
          'Negative',
          'Suspected',
        ], 'test_result'.tr),
        _textField(treatmentController, 'treatment'.tr),
        _stringDropdown(recoveryStatus, const [
          'Under Treatment',
          'Recovered',
          'Not Recovered',
        ], 'recovery_status'.tr),
        _dateField(date),
        _textField(notesController, 'notes'.tr, maxLines: 3),
      ],
      onSave: () async {
        if (animal.value == null || treatmentController.text.trim().isEmpty) {
          Get.snackbar('error'.tr, 'please_fill_required_fields'.tr);
          return;
        }
        final ok = await controller.saveMastitis(
          animalId: animal.value!.id,
          testResult: testResult.value,
          treatment: treatmentController.text.trim(),
          recoveryStatus: recoveryStatus.value,
          date: date.value,
          notes: notesController.text.trim(),
        );
        if (ok) Get.back();
      },
    );
  }

  void _openDmiSheet() {
    final animal = Rxn<HealthAnimalItem>();
    final weightController = TextEditingController();
    final milkController = TextEditingController();
    final actualController = TextEditingController();
    final notesController = TextEditingController();
    final date = Rx<DateTime>(DateTime.now());
    final requiredDmi = ''.obs;

    void recalc() {
      final weight = double.tryParse(weightController.text.trim()) ?? 0;
      final milk = double.tryParse(milkController.text.trim()) ?? 0;
      if (weight > 0 || milk > 0) {
        requiredDmi.value = controller
            .calculateRequiredDmi(weight, milk)
            .toStringAsFixed(2);
      } else {
        requiredDmi.value = '';
      }
    }

    weightController.addListener(recalc);
    milkController.addListener(recalc);

    _showFormSheet(
      title: 'add_dmi_record'.tr,
      children: [
        _animalDropdown(animal),
        _textField(
          weightController,
          '${'body_weight'.tr} (Kg)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _textField(
          milkController,
          '${'total_milk'.tr} (L)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        Obx(
          () => _readonlyField(
            '${'required_dmi'.tr} (Kg)',
            requiredDmi.value.isEmpty ? '-' : requiredDmi.value,
          ),
        ),
        _textField(
          actualController,
          '${'actual_dmi'.tr} (Kg)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        _dateField(date),
        _textField(notesController, 'notes'.tr, maxLines: 3),
      ],
      onSave: () async {
        final bodyWeight = double.tryParse(weightController.text.trim());
        final totalMilk = double.tryParse(milkController.text.trim());
        final actualDmi = double.tryParse(actualController.text.trim());
        if (animal.value == null ||
            bodyWeight == null ||
            totalMilk == null ||
            actualDmi == null) {
          Get.snackbar('error'.tr, 'please_fill_required_fields'.tr);
          return;
        }
        final ok = await controller.saveDmi(
          animalId: animal.value!.id,
          bodyWeight: bodyWeight,
          totalMilk: totalMilk,
          actualDmi: actualDmi,
          date: date.value,
          notes: notesController.text.trim(),
        );
        if (ok) Get.back();
      },
    );
  }

  void _showFormSheet({
    required String title,
    required List<Widget> children,
    required Future<void> Function() onSave,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 54,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 18),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                            'save_record'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _animalDropdown(Rxn<HealthAnimalItem> animal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Obx(
        () => DropdownButtonFormField<HealthAnimalItem>(
          initialValue: animal.value,
          isExpanded: true,
          decoration: _decoration('select_animal'.tr),
          items: controller.animals
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.displayName),
                ),
              )
              .toList(),
          onChanged: (value) => animal.value = value,
        ),
      ),
    );
  }

  Widget _stringDropdown(RxString value, List<String> options, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Obx(
        () => DropdownButtonFormField<String>(
          initialValue: value.value,
          isExpanded: true,
          decoration: _decoration(label),
          items: options
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(_optionTranslation(item)),
                ),
              )
              .toList(),
          onChanged: (next) => value.value = next ?? value.value,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _decoration(hint),
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value),
        decoration: _decoration(label),
      ),
    );
  }

  Widget _dateField(Rx<DateTime> date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Obx(
        () => TextField(
          readOnly: true,
          controller: TextEditingController(
            text:
                '${date.value.day.toString().padLeft(2, '0')}/${date.value.month.toString().padLeft(2, '0')}/${date.value.year}',
          ),
          decoration: _decoration('select_date'.tr).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: Get.context!,
              initialDate: date.value,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) date.value = picked;
          },
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FBF8),
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

  String _optionTranslation(String value) {
    switch (value) {
      case 'Positive':
        return 'positive'.tr;
      case 'Negative':
        return 'negative'.tr;
      case 'Suspected':
        return 'suspected'.tr;
      case 'Under Treatment':
        return 'under_treatment'.tr;
      case 'Recovered':
        return 'recovered'.tr;
      case 'Not Recovered':
        return 'not_recovered'.tr;
      default:
        return value;
    }
  }
}
