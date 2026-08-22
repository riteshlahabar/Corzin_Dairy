import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/feeding_controller.dart';
import 'diet_plan_view.dart';

class FeedingView extends GetView<FeedingController> {
  const FeedingView({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomSafePadding = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom
        : mediaQuery.viewPadding.bottom;

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
                        padding: EdgeInsets.fromLTRB(16, 14, 16, bottomSafePadding + 24),
                        child: Form(
                          key: controller.formKey,
                          child: Column(
                            children: [
                              _entryCalendar(),
                              const SizedBox(height: 12),
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
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _entryCalendar() {
    final weekdays = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Obx(
      () {
        final month = controller.entryCalendarMonth.value;
        final firstDay = DateTime(month.year, month.month);
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        final leadingEmptyCells = firstDay.weekday % 7;
        final totalCells = leadingEmptyCells + daysInMonth;
        final trailingEmptyCells = (7 - (totalCells % 7)) % 7;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0EADF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _monthArrow(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => controller.moveEntryCalendarMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  _monthArrow(
                    icon: Icons.chevron_right_rounded,
                    onTap: controller.canMoveEntryCalendarForward
                        ? () => controller.moveEntryCalendarMonth(1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE8EFE8)),
                    bottom: BorderSide(color: Color(0xFFE8EFE8)),
                  ),
                ),
                child: Row(
                  children: weekdays
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 9.8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: 1.22,
                children: [
                  ...List.generate(leadingEmptyCells, (_) => _calendarBlankBlock()),
                  ...List.generate(daysInMonth, (index) {
                    final day = DateTime(month.year, month.month, index + 1);
                    return _calendarDayBlock(day, controller.entryCountForDay(day));
                  }),
                  ...List.generate(trailingEmptyCells, (_) => _calendarBlankBlock()),
                ],
              ),
              const SizedBox(height: 8),
              _calendarLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _monthArrow({required IconData icon, required VoidCallback? onTap}) {
    return SizedBox.square(
      dimension: 26,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 26, height: 26),
        visualDensity: VisualDensity.compact,
        color: AppColors.primary,
        disabledColor: AppColors.grey.shade400,
      ),
    );
  }

  Widget _calendarBlankBlock() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EFE8), width: 0.55),
      ),
    );
  }

  Widget _calendarDayBlock(DateTime date, int entryCount) {
    final now = DateTime.now();
    final color = entryCount >= 2
        ? const Color(0xFF2EAD4B)
        : entryCount == 1
            ? const Color(0xFFF2C94C)
            : const Color(0xFFE5484D);
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isToday ? AppColors.primary : const Color(0xFFE8EFE8),
          width: isToday ? 0.9 : 0.55,
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isToday ? AppColors.black : AppColors.grey.shade700,
                  fontSize: 9.6,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 5),
              height: 3,
              width: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        _legendItem(const Color(0xFF2EAD4B), 'both_shift_done'.tr),
        _legendItem(const Color(0xFFF2C94C), 'single_shift_done'.tr),
        _legendItem(const Color(0xFFE5484D), 'no_entry_done'.tr),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 7,
          width: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.4,
            color: AppColors.grey.shade800,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

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
        _dietPlanHeader(),
        const SizedBox(height: 6),
        Obx(
          () {
            final selectedId = controller.selectedDietPlanId.value;
            final resolvedSelectedId = (selectedId != null &&
                    controller.dietPlans.any((plan) => plan.id == selectedId))
                ? selectedId
                : null;

            return DropdownButtonFormField<int>(
              initialValue: resolvedSelectedId,
              isExpanded: true,
              dropdownColor: const Color(0xFFF4FAF4),
              decoration: _decoration('select_diet_plan'.tr),
                items: controller.dietPlans
                    .map(
                      (plan) => DropdownMenuItem<int>(
                        value: plan.id,
                        child: Text(
                          controller.dietPlanDisplayLabel(plan),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
              onChanged: controller.dietPlans.isEmpty
                  ? null
                  : controller.selectDietPlanById,
            );
          },
        ),
        const SizedBox(height: 12),
        Column(
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
                final selectedPlan = controller.selectedDietPlan.value;
                if (selectedPlan != null &&
                    parsed - controller.packageQuantity.value > 0.000001) {
                  return 'Feeding quantity cannot be greater than available diet quantity.';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            Obx(
              () => Text(
                controller.feedingQuantityHalfShiftNote(),
                style: TextStyle(
                  fontSize: 11.8,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('rate_per_unit'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller.ratePerUnitController,
                    focusNode: controller.ratePerUnitFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoration('enter_rate_per_unit'.tr),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'enter_rate_per_unit_error'.tr;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'valid_rate_per_unit'.tr;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('feeding_cost'.tr, requiredField: true),
                  const SizedBox(height: 6),
                  Obx(
                    () => TextFormField(
                      key: ValueKey(
                        'feeding_cost_${controller.feedingCost.value.toStringAsFixed(2)}',
                      ),
                      initialValue: controller.feedingCost.value.toStringAsFixed(2),
                      readOnly: true,
                      decoration: _decoration('0.00'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _label('notes'.tr),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.notesController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration('optional_notes'.tr),
        ),
      ],
    ),
  );

  Widget _dietPlanHeader() => Row(
    children: [
      Expanded(child: _label('diet_plan'.tr, requiredField: true)),
      Obx(() {
        final selectedPlan = controller.selectedDietPlan.value;
        final canEdit = selectedPlan != null;

        return TextButton.icon(
          onPressed: canEdit ? () => _openDietPlanEditor(selectedPlan) : null,
          icon: Icon(
            Icons.edit_rounded,
            size: 16,
            color: canEdit ? AppColors.primary : AppColors.grey.shade400,
          ),
          label: Text(
            'edit'.tr,
            style: TextStyle(
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
              color: canEdit ? AppColors.primary : AppColors.grey.shade400,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      }),
    ],
  );

  Future<void> _openDietPlanEditor(FeedDietPlanModel plan) async {
    final updated = await Get.to<bool>(
      () => DietPlanView(
        mode: DietPlanViewMode.edit,
        initialPlan: plan,
      ),
    );
    if (updated != true) return;

    await controller.fetchDietPlans();
    controller.selectDietPlanById(plan.id);
  }
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
      Get.snackbar('error'.tr, 'please_select_animal_or_pan'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.dietPlans.isNotEmpty && controller.selectedDietPlan.value == null) {
      Get.snackbar('error'.tr, 'please_select_diet_plan_for_selected_animal_pan'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.selectedFeedingTime.value.trim().isEmpty || !controller.availableFeedingTimes.contains(controller.selectedFeedingTime.value)) {
      Get.snackbar('info'.tr, 'no_feeding_time_available_selected_date'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    controller.submitFeeding();
  }

  void _focusFirstInvalidField() {
    final qty = double.tryParse(controller.quantityController.text.trim());
    if (qty == null || qty <= 0) {
      controller.quantityFocus.requestFocus();
      return;
    }
    final rate = double.tryParse(controller.ratePerUnitController.text.trim());
    if (rate == null || rate < 0) {
      controller.ratePerUnitFocus.requestFocus();
    }
  }
}
