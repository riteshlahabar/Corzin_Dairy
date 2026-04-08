import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/manage_pregnancy_controller.dart';

class ManagePregnancyView extends GetView<ManagePregnancyController> {
  const ManagePregnancyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'add_record'.tr,
          style: const TextStyle(color: Colors.white),
        ),
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
                      'manage_pregnancy'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.fetchRecords,
                        child: controller.records.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  SizedBox(height: 120),
                                  const Icon(
                                    Icons.pregnant_woman_outlined,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'no_pregnancy_records_found'.tr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                                  90,
                                ),
                                itemCount: controller.records.length,
                                itemBuilder: (context, index) {
                                  final item = controller.records[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.animalName.isEmpty
                                                    ? '-'
                                                    : item.animalName,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    item.pregnancyConfirmation
                                                    ? AppColors.primary
                                                          .withValues(
                                                            alpha: 0.12,
                                                          )
                                                    : Colors.orange.withValues(
                                                        alpha: 0.14,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                item.pregnancyConfirmation
                                                    ? 'pregnant'.tr
                                                    : 'not_confirmed'.tr,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      item.pregnancyConfirmation
                                                      ? AppColors.primary
                                                      : Colors.orange.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${'tag'.tr}: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _info(
                                          'lactation'.tr,
                                          item.lactationNumber.isEmpty
                                              ? 'na'.tr
                                              : item.lactationNumber,
                                        ),
                                        _info(
                                          'ai_date'.tr,
                                          item.aiDate.isEmpty
                                              ? '-'
                                              : item.aiDate,
                                        ),
                                        _info(
                                          'breed'.tr,
                                          item.breedName.isEmpty
                                              ? '-'
                                              : item.breedName,
                                        ),
                                        _info(
                                          'calving_date'.tr,
                                          item.calvingDate.isEmpty
                                              ? '-'
                                              : item.calvingDate,
                                        ),
                                        if (item.notes.isNotEmpty)
                                          _info('notes'.tr, item.notes),
                                      ],
                                    ),
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

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
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

  void _openAddSheet() {
    final selectedAnimal = Rxn<PregnancyAnimalItem>();
    final lactationController = TextEditingController();
    final breedController = TextEditingController();
    final notesController = TextEditingController();
    final pregnant = false.obs;
    final aiDate = Rxn<DateTime>();
    final calvingDate = Rxn<DateTime>();

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
                'manage_pregnancy_record'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<PregnancyAnimalItem>(
                  initialValue: selectedAnimal.value,
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
                  onChanged: (value) => selectedAnimal.value = value,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lactationController,
                keyboardType: TextInputType.number,
                decoration: _decoration('lactation_number'.tr),
              ),
              const SizedBox(height: 12),
              _dateField('ai_date'.tr, aiDate),
              const SizedBox(height: 12),
              TextField(
                controller: breedController,
                decoration: _decoration('breed_name'.tr),
              ),
              const SizedBox(height: 12),
              Obx(
                () => SwitchListTile(
                  value: pregnant.value,
                  activeThumbColor: AppColors.primary,
                  title: Text('pregnancy_confirmed'.tr),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => pregnant.value = value,
                ),
              ),
              const SizedBox(height: 8),
              _dateField('calving_new_born_birth_date'.tr, calvingDate),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 3,
                decoration: _decoration('notes'.tr),
              ),
              const SizedBox(height: 18),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () async {
                            if (selectedAnimal.value == null) {
                              Get.snackbar(
                                'error'.tr,
                                'please_select_an_animal'.tr,
                              );
                              return;
                            }
                            final ok = await controller.saveRecord(
                              animalId: selectedAnimal.value!.id,
                              lactationNumber: int.tryParse(
                                lactationController.text.trim(),
                              ),
                              aiDate: aiDate.value,
                              breedName: breedController.text.trim(),
                              pregnancyConfirmation: pregnant.value,
                              calvingDate: calvingDate.value,
                              notes: notesController.text.trim(),
                            );
                            if (ok) Get.back();
                          },
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

  Widget _dateField(String label, Rxn<DateTime> value) {
    return Obx(
      () => TextField(
        readOnly: true,
        controller: TextEditingController(
          text: value.value == null
              ? ''
              : '${value.value!.day.toString().padLeft(2, '0')}/${value.value!.month.toString().padLeft(2, '0')}/${value.value!.year}',
        ),
        decoration: _decoration(label).copyWith(
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: Get.context!,
            initialDate: value.value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) value.value = picked;
        },
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
}
