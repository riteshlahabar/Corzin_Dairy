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
                              const SizedBox(height: 14),
                              _formCard(),
                              const SizedBox(height: 18),
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
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.grass_rounded, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          'feeding_entry'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'feeding_desc'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    ),
  );

  Widget _formCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
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
        _label('select_animal'.tr, requiredField: true),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<FeedingAnimalModel>(
            initialValue: controller.selectedAnimal.value,
            isExpanded: true,
            decoration: _decoration('choose_animal'.tr),
            items: controller.animals
                .map(
                  (animal) => DropdownMenuItem(
                    value: animal,
                    child: Text(animal.displayName, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              controller.selectedAnimal.value = value;
              if (value != null) {
                controller.selectedPan.value = null;
              }
            },
            validator: (value) {
              if (value == null && controller.selectedPan.value == null) {
                return 'select_animal_error'.tr;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
        _label('Select PAN', requiredField: true),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<FeedingPanModel>(
            initialValue: controller.selectedPan.value,
            isExpanded: true,
            decoration: _decoration('Choose PAN'),
            items: controller.pans
                .map(
                  (pan) => DropdownMenuItem(
                    value: pan,
                    child: Text(pan.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: controller.pans.isEmpty
                ? null
                : (value) {
                    controller.selectedPan.value = value;
                    if (value != null) {
                      controller.selectedAnimal.value = null;
                    }
                  },
          ),
        ),
        const SizedBox(height: 12),
        _label('feed_type'.tr, requiredField: true),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<FeedTypeModel>(
            initialValue: controller.selectedFeedType.value,
            isExpanded: true,
            decoration: _decoration('select_feed_type'.tr),
            items: controller.feedTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: controller.onFeedTypeChanged,
            validator: (value) => value == null ? 'select_feed_type'.tr : null,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () {
            final selectedType = controller.selectedFeedType.value;
            if (selectedType == null || selectedType.subtypes.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Subtypes', requiredField: true),
                const SizedBox(height: 6),
                ...selectedType.subtypes.map(
                  (subtype) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Obx(
                          () => Checkbox(
                            value: controller.subtypeSelected[subtype.id] ?? false,
                            activeColor: AppColors.primary,
                            onChanged: (value) => controller.onSubtypeChecked(subtype.id, value ?? false),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            subtype.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 86,
                          child: TextField(
                            controller: controller.subtypeQuantityControllers[subtype.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            enabled: controller.subtypeSelected[subtype.id] ?? false,
                            decoration: _decoration('Qty'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total ${controller.selectedUnit.value}: ${controller.totalSubtypeQuantity.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Package Quantity', requiredField: true),
                  const SizedBox(height: 6),
                  Obx(
                    () => TextFormField(
                      key: ValueKey('pkg_${controller.totalSubtypeQuantity.value.toStringAsFixed(2)}'),
                      initialValue: controller.totalSubtypeQuantity.value.toStringAsFixed(2),
                      readOnly: true,
                      decoration: _decoration('0.00'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Feeding Quantity', requiredField: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller.quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoration('enter_quantity'.tr),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'enter_quantity_error'.tr;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'valid_quantity'.tr;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(
          () => Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Balance: ${controller.balanceQuantity.value.toStringAsFixed(2)} ${controller.selectedUnit.value}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('date'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller.dateController,
                    readOnly: true,
                    decoration: _decoration('select_date'.tr),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'select_date_error'.tr : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Feeding Time', requiredField: true),
                  const SizedBox(height: 6),
                  Obx(
                    () => TextFormField(
                      initialValue: controller.selectedFeedingTime.value,
                      readOnly: true,
                      decoration: _decoration('Select feeding time'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _label('notes'.tr),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.notesController,
          maxLines: 3,
          decoration: _decoration('optional_notes'.tr),
        ),
      ],
    ),
  );

  Widget _button() => Obx(
    () => SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed:
            controller.isSubmitting.value ||
                controller.isScheduleLoading.value ||
                controller.animals.isEmpty ||
                controller.feedTypes.isEmpty
            ? null
            : controller.submitFeeding,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: controller.isSubmitting.value || controller.isScheduleLoading.value
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

  Widget _label(String value, {bool requiredField = false}) => Align(
    alignment: Alignment.centerLeft,
    child: RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.grey.shade800,
        ),
        children: [
          TextSpan(text: value),
          if (requiredField) const TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 12.5),
    filled: true,
    fillColor: const Color(0xFFF8FBF8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
  );
}
