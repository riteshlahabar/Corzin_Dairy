import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
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
                top: false,
                bottom: false,
                child: Column(
                  children: [
                    _header(context),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).viewInsets.bottom + 24),
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

  Widget _header(BuildContext context) => Container(
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
        Text(
          'add_feeding'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ],
    ),
  );

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

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
            dropdownColor: const Color(0xFFF4FAF4),
            decoration: _decoration('choose_animal'.tr),
            items: controller.animals
                .map(
                  (animal) => DropdownMenuItem(
                    value: animal,
                    child: Text(animal.displayName, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: controller.selectAnimal,
            validator: (value) {
              if (value == null && controller.selectedPan.value == null) {
                return 'select_animal_error'.tr;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
        _label('select_pan'.tr, requiredField: true),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<FeedingPanModel>(
            initialValue: controller.selectedPan.value,
            isExpanded: true,
            dropdownColor: const Color(0xFFF4FAF4),
            decoration: _decoration('select_pan'.tr),
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
                : controller.selectPan,
          ),
        ),
        const SizedBox(height: 12),
        _label('diet_plan'.tr, requiredField: true),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<int>(
            initialValue: controller.selectedDietPlanId.value,
            isExpanded: true,
            dropdownColor: const Color(0xFFF4FAF4),
            decoration: _decoration('select_diet_plan'.tr),
            items: controller.dietPlans
                .map(
                  (plan) => DropdownMenuItem<int>(
                    value: plan.id,
                    child: Text(plan.displayLabel, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: controller.dietPlans.isEmpty
                ? null
                : controller.selectDietPlanById,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('package_quantity'.tr, requiredField: true),
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
                  _label('feeding_quantity'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller.quantityController,
                    focusNode: controller.quantityFocus,
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
              '${'balance'.tr}: ${controller.balanceQuantity.value.toStringAsFixed(2)} ${controller.selectedUnit.value}',
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
                    onTap: controller.pickDate,
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
                  _label('feeding_time'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.availableFeedingTimes.contains(controller.selectedFeedingTime.value)
                          ? controller.selectedFeedingTime.value
                          : null,
                      isExpanded: true,
                      dropdownColor: const Color(0xFFF4FAF4),
                      decoration: _decoration(
                        controller.availableFeedingTimes.isEmpty
                            ? 'no_time_left'.tr
                            : 'select_feeding_time'.tr,
                      ),
                      items: controller.availableFeedingTimes
                          .map(
                            (time) => DropdownMenuItem<String>(
                              value: time,
                              child: Text(time, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: controller.availableFeedingTimes.isEmpty
                          ? null
                          : (value) => controller.selectedFeedingTime.value = value ?? '',
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'No feeding time available for this date'
                          : null,
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
                controller.availableFeedingTimes.isEmpty ||
                controller.feedTypes.isEmpty
            ? null
            : _onSubmitTap,
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

  void _onSubmitTap() {
    final currentForm = controller.formKey.currentState;
    if (currentForm == null) return;

    final isValid = currentForm.validate();
    if (!isValid) {
      _focusFirstInvalidField();
      return;
    }

    if (controller.selectedAnimal.value == null && controller.selectedPan.value == null) {
      Get.snackbar('Error', 'Please select an animal or PAN', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.dietPlans.isNotEmpty && controller.selectedDietPlan.value == null) {
      Get.snackbar('Error', 'Please select diet plan for selected animal/PAN.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.selectedFeedingTime.value.trim().isEmpty || !controller.availableFeedingTimes.contains(controller.selectedFeedingTime.value)) {
      Get.snackbar('Info', 'No feeding time is available for selected date.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    controller.submitFeeding();
  }

  void _focusFirstInvalidField() {
    final qty = double.tryParse(controller.quantityController.text.trim());
    if (qty == null || qty <= 0) {
      controller.quantityFocus.requestFocus();
    }
  }
}
