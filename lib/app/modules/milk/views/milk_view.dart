import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/milk_controller.dart';

class MilkView extends GetView<MilkController> {
  const MilkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF6),
      body: Obx(
        () => controller.isPageLoading.value
            ? const Center(child: CircularProgressIndicator())
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).viewInsets.bottom + 24),
                          child: Form(
                            key: controller.formKey,
                            child: Column(
                              children: [
                                _buildHeroCard(),
                                const SizedBox(height: 16),
                                _buildFormCard(),
                                const SizedBox(height: 20),
                                _buildSubmitButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
          Expanded(child: Text('add_milk'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
        ],
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4EA857)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(height: 62, width: 62, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.local_drink_rounded, color: Colors.white, size: 32)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('milk_entry'.tr, style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('milk_entry_desc'.tr, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w400))])),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.045), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('milk_entry'.tr)),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel('select_animal'.tr, requiredField: true),
          const SizedBox(height: 8),
          Obx(
            () => _dropdownCard(
              child: DropdownButtonFormField<MilkAnimalModel>(
                initialValue: controller.selectedAnimal.value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                decoration: _dropdownDecoration('choose_animal'.tr),
                items: controller.animals
                    .map(
                      (animal) => DropdownMenuItem<MilkAnimalModel>(
                        value: animal,
                        child: Text(animal.displayName, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: controller.selectAnimal,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel('select_pan'.tr, requiredField: true),
          const SizedBox(height: 8),
          Obx(
            () => _dropdownCard(
              child: DropdownButtonFormField<MilkPanModel>(
                initialValue: controller.selectedPan.value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                decoration: _dropdownDecoration('select_pan'.tr),
                items: controller.pans
                    .map(
                      (pan) => DropdownMenuItem<MilkPanModel>(
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
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _fieldLabel('select_dairy'.tr, requiredField: true)),
              SizedBox(
                height: 28,
                width: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'add_dairy'.tr,
                  onPressed: controller.openAddDairyFromMilk,
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => _dropdownCard(child: DropdownButtonFormField<MilkDairyModel>(initialValue: controller.selectedDairy.value, isExpanded: true, dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary), decoration: _dropdownDecoration('select_dairy'.tr), items: controller.dairies.map((dairy) => DropdownMenuItem<MilkDairyModel>(value: dairy, child: Text(dairy.displayName, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => controller.selectedDairy.value = value, validator: (value) => value == null ? 'please_select_dairy_name'.tr : null))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('milk_date'.tr, requiredField: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.milkDateController,
                      readOnly: true,
                      onTap: controller.pickMilkDate,
                      decoration: _inputDecoration('dd/MM/yyyy'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'select_date_error'.tr
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('shift'.tr, requiredField: true),
                    const SizedBox(height: 8),
                    Obx(
                      () => _dropdownCard(
                        child: DropdownButtonFormField<String>(
                          initialValue: controller.availableShifts.contains(controller.selectedShift.value)
                              ? controller.selectedShift.value
                              : null,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                          ),
                          decoration: _dropdownDecoration(
                            controller.availableShifts.isEmpty ? 'no_time_left'.tr : 'select_shift'.tr,
                          ),
                          items: controller.availableShifts
                              .map(
                                (shift) => DropdownMenuItem<String>(
                                  value: shift,
                                  child: Text(shift, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: controller.availableShifts.isEmpty
                              ? null
                              : (value) => controller.selectedShift.value = value ?? '',
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'no_shift_available_for_date'.tr
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('quantity_liters'.tr, requiredField: true),
          const SizedBox(height: 8),
          TextFormField(controller: controller.quantityController, focusNode: controller.quantityFocus, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, decoration: _inputDecoration('enter_milk_quantity'.tr), validator: (value) { if (value == null || value.trim().isEmpty) return 'enter_quantity_error'.tr; final parsed = double.tryParse(value.trim()); if (parsed == null || parsed <= 0) return 'valid_quantity'.tr; return null; }),
          _buildPanCowMilkSection(),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('fat_upper'.tr, requiredField: true), const SizedBox(height: 8), TextFormField(controller: controller.fatController, focusNode: controller.fatFocus, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration('enter_fat'.tr), validator: (value) { if (value == null || value.trim().isEmpty) return 'fat_required'.tr; final parsed = double.tryParse(value.trim()); if (parsed == null || parsed <= 0) return 'enter_valid_fat'.tr; return null; })])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('snf_upper'.tr, requiredField: true), const SizedBox(height: 8), TextFormField(controller: controller.snfController, focusNode: controller.snfFocus, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration('enter_snf'.tr), validator: (value) { if (value == null || value.trim().isEmpty) return 'snf_required'.tr; final parsed = double.tryParse(value.trim()); if (parsed == null || parsed <= 0) return 'enter_valid_snf'.tr; return null; })]))]),
          const SizedBox(height: 16),
          _fieldLabel('rate_per_liter'.tr, requiredField: true),
          const SizedBox(height: 8),
          TextFormField(controller: controller.rateController, focusNode: controller.rateFocus, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, decoration: _inputDecoration('enter_rate_per_liter'.tr), validator: (value) { if (value == null || value.trim().isEmpty) return 'rate_required'.tr; final parsed = double.tryParse(value.trim()); if (parsed == null || parsed <= 0) return 'enter_valid_rate'.tr; return null; }),
          const SizedBox(height: 16),
          _fieldLabel('notes'.tr),
          const SizedBox(height: 8),
          TextFormField(controller: controller.notesController, minLines: 3, maxLines: 4, textInputAction: TextInputAction.done, decoration: _inputDecoration('optional_notes'.tr)),
          if (controller.animals.isEmpty || controller.dairies.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF7E7), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFD98A))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline_rounded, color: Color(0xFFB7791F)), const SizedBox(width: 10), Expanded(child: Text('milk_entry_info_hint'.tr, style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF7A5314))))]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanCowMilkSection() {
    return Obx(() {
      if (controller.selectedPan.value == null) return const SizedBox.shrink();

      final matched = controller.isCowMilkMatched;
      final statusColor = matched ? AppColors.primary : Colors.red.shade600;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withValues(alpha: matched ? 0.16 : 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.pets_rounded, color: AppColors.primary, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('cow_wise_milk_distribution'.tr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.black)),
                      const SizedBox(height: 2),
                      Text('edit_cow_milk_before_save'.tr, style: TextStyle(fontSize: 11.5, color: AppColors.grey.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.panCowMilkEntries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD98A)),
                ),
                child: Text('no_cows_found_in_selected_pan'.tr, style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A5314), fontWeight: FontWeight.w600)),
              )
            else
              ...controller.panCowMilkEntries.map(_cowMilkRow),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: matched ? AppColors.primary.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryLine('total_cow_milk'.tr, '${controller.cowMilkTotal.value.toStringAsFixed(2)} L', statusColor),
                  const SizedBox(height: 5),
                  _summaryLine('difference'.tr, controller.cowMilkDifferenceLabel, statusColor),
                  const SizedBox(height: 5),
                  _summaryLine('status'.tr, controller.cowMilkStatusLabel, statusColor),
                  if (!matched) ...[
                    const SizedBox(height: 8),
                    Text(
                      'cow_total_mismatch_warning'.tr,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cowMilkRow(PanCowMilkEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.animal.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.black)),
                const SizedBox(height: 3),
                Text(
                  '${'default_milk_per_milking'.tr}: ${entry.animal.defaultMilkPerSession.toStringAsFixed(2)} L',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: TextFormField(
              controller: entry.quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: _inputDecoration('0.00').copyWith(
                suffixText: 'L',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              validator: (_) {
                if (controller.selectedPan.value == null) return null;
                final value = double.tryParse(entry.quantityController.text.trim());
                if (value == null || value < 0) return 'Invalid';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.grey.shade800, fontWeight: FontWeight.w700))),
        Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final panMismatch = controller.selectedPan.value != null && !controller.isCowMilkMatched;
      return SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: controller.isSubmitting.value || controller.isScheduleLoading.value || controller.animals.isEmpty || controller.dairies.isEmpty || controller.availableShifts.isEmpty || panMismatch ? null : _onSubmitTap, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: (controller.isSubmitting.value || controller.isScheduleLoading.value) ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline_rounded, color: Colors.white), const SizedBox(width: 8), Text('save_milk_entry'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))])));
    });
  }

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
    if (controller.selectedDairy.value == null) {
      Get.snackbar('error'.tr, 'please_select_dairy_name'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.selectedShift.value.trim().isEmpty || !controller.availableShifts.contains(controller.selectedShift.value)) {
      Get.snackbar('info'.tr, 'no_milk_shift_available_for_date'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.selectedPan.value != null && !controller.isCowMilkMatched) {
      Get.snackbar('validation'.tr, 'cow_total_mismatch_warning'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    controller.submitMilk();
  }

  void _focusFirstInvalidField() {
    final quantity = double.tryParse(controller.quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      controller.quantityFocus.requestFocus();
      return;
    }
    final fat = double.tryParse(controller.fatController.text.trim());
    if (fat == null || fat <= 0) {
      controller.fatFocus.requestFocus();
      return;
    }
    final snf = double.tryParse(controller.snfController.text.trim());
    if (snf == null || snf <= 0) {
      controller.snfFocus.requestFocus();
      return;
    }
    final rate = double.tryParse(controller.rateController.text.trim());
    if (rate == null || rate <= 0) {
      controller.rateFocus.requestFocus();
    }
  }

  Widget _sectionTitle(String title) => Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)));
  Widget _fieldLabel(String title, {bool requiredField = false}) => Align(
    alignment: Alignment.centerLeft,
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.grey.shade800),
        children: [
          TextSpan(text: title),
          if (requiredField) const TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    ),
  );

  Widget _dropdownCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EADF)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 12.5),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.red)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 12.5),
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}
