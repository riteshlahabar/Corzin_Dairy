import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/feeding_controller.dart';

class FeedingView extends GetView<FeedingController> {
  const FeedingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Obx(
        () => controller.isPageLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  children: [
                    _header(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Form(
                          key: controller.formKey,
                          child: Column(
                            children: [
                              _hero(),
                              const SizedBox(height: 16),
                              _formCard(),
                              const SizedBox(height: 20),
                              _button(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
    child: Row(
      children: [
        IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'add_feeding'.tr,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.grass_rounded, color: Colors.white, size: 30),
        const SizedBox(height: 10),
        Text(
          'feeding_entry'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'feeding_desc'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      ],
    ),
  );

  Widget _formCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: controller.animals.isEmpty ? null : () => _openBulkEntryDialog(),
            icon: const Icon(Icons.playlist_add_rounded, size: 18),
            label: const Text('Bulk Entry'),
          ),
        ),
        _label('select_animal'.tr),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<FeedingAnimalModel>(
            initialValue: controller.selectedAnimal.value,
            isExpanded: true,
            decoration: _decoration('choose_animal'.tr),
            items: controller.animals
                .map(
                  (animal) => DropdownMenuItem(
                    value: animal,
                    child: Text(animal.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) => controller.selectedAnimal.value = value,
            validator: (value) =>
                value == null ? 'select_animal_error'.tr : null,
          ),
        ),
        const SizedBox(height: 16),
        _label('feed_type'.tr),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<FeedTypeModel>(
            initialValue: controller.selectedFeedType.value,
            isExpanded: true,
            decoration: _decoration('select_feed_type'.tr),
            items: controller.feedTypes
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.name.tr)),
                )
                .toList(),
            onChanged: controller.onFeedTypeChanged,
            validator: (value) => value == null ? 'select_feed_type'.tr : null,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final useVerticalLayout = constraints.maxWidth < 360;

            final quantityField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('quantity'.tr),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration('enter_quantity'.tr),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'enter_quantity_error'.tr;
                    }
                    return double.tryParse(value.trim()) == null
                        ? 'valid_quantity'.tr
                        : null;
                  },
                ),
              ],
            );

            final unitField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('unit'.tr),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: controller.selectedUnit.value,
                    isExpanded: true,
                    decoration: _decoration('unit'.tr),
                    items: controller.units
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.tr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        controller.selectedUnit.value = value ?? 'Kg',
                  ),
                ),
              ],
            );

            if (useVerticalLayout) {
              return Column(
                children: [
                  quantityField,
                  const SizedBox(height: 16),
                  unitField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: quantityField),
                const SizedBox(width: 12),
                Expanded(child: unitField),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _label('Feeding Time'),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedFeedingTime.value,
            isExpanded: true,
            decoration: _decoration('Select feeding time'),
            items: controller.feedingTimes
                .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                .toList(),
            onChanged: (value) =>
                controller.selectedFeedingTime.value = value ?? 'Morning',
          ),
        ),
        const SizedBox(height: 16),
        _label('date'.tr),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.dateController,
          readOnly: true,
          onTap: controller.pickDate,
          decoration: _decoration('select_date'.tr).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'select_date_error'.tr : null,
        ),
        const SizedBox(height: 16),
        _label('notes'.tr),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.notesController,
          maxLines: 4,
          decoration: _decoration('optional_notes'.tr),
        ),
      ],
    ),
  );

  Future<void> _openBulkEntryDialog() async {
    final qtyControllers = <int, TextEditingController>{};
    for (final animal in controller.animals) {
      qtyControllers[animal.id] = TextEditingController();
    }

    await Get.dialog(
      AlertDialog(
        title: const Text('Bulk Feeding Entry'),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controller.animals.map((animal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          animal.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: qtyControllers[animal.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _decoration('Qty'),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payload = <int, String>{};
              for (final animal in controller.animals) {
                payload[animal.id] = qtyControllers[animal.id]?.text.trim() ?? '';
              }
              Get.back();
              final result = await controller.submitBulkFeeding(payload);
              if (result['success'] == 0 && result['failed'] == 0) {
                return;
              }
              Get.snackbar(
                'Bulk Upload',
                'Success: ${result['success']}  Failed: ${result['failed']}',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Save All'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    for (final c in qtyControllers.values) {
      c.dispose();
    }
  }

  Widget _button() => Obx(
    () => SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            controller.isSubmitting.value ||
                controller.animals.isEmpty ||
                controller.feedTypes.isEmpty
            ? null
            : controller.submitFeeding,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: controller.isSubmitting.value
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'save_feeding_entry'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    ),
  );

  Widget _label(String value) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      value,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.grey.shade800,
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 12.5),
    filled: true,
    fillColor: const Color(0xFFF8FBF8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}
