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
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
          _fieldLabel('Select PAN', requiredField: true),
          const SizedBox(height: 8),
          Obx(
            () => _dropdownCard(
              child: DropdownButtonFormField<MilkPanModel>(
                initialValue: controller.selectedPan.value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                decoration: _dropdownDecoration('Select PAN'),
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
              Expanded(child: _fieldLabel('Select Dairy', requiredField: true)),
              SizedBox(
                height: 28,
                width: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add Dairy',
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
          Obx(() => _dropdownCard(child: DropdownButtonFormField<MilkDairyModel>(initialValue: controller.selectedDairy.value, isExpanded: true, dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary), decoration: _dropdownDecoration('Select dairy'), items: controller.dairies.map((dairy) => DropdownMenuItem<MilkDairyModel>(value: dairy, child: Text(dairy.displayName, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => controller.selectedDairy.value = value, validator: (value) => value == null ? 'Please select a dairy' : null))),
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
                            controller.availableShifts.isEmpty ? 'No shift left' : 'Select shift',
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
                              ? 'No shift available for this date'
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
          TextFormField(controller: controller.quantityController, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, decoration: _inputDecoration('enter_milk_quantity'.tr), validator: (value) { if (value == null || value.trim().isEmpty) return 'enter_quantity_error'.tr; final parsed = double.tryParse(value.trim()); if (parsed == null || parsed <= 0) return 'valid_quantity'.tr; return null; }),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('FAT'), const SizedBox(height: 8), TextFormField(controller: controller.fatController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration('Enter FAT'))])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('SNF'), const SizedBox(height: 8), TextFormField(controller: controller.snfController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration('Enter SNF'))]))]),
          const SizedBox(height: 16),
          _fieldLabel('Rate / Liter'),
          const SizedBox(height: 8),
          TextFormField(controller: controller.rateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), textInputAction: TextInputAction.next, decoration: _inputDecoration('Enter rate per liter')),
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
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline_rounded, color: Color(0xFFB7791F)), const SizedBox(width: 10), Expanded(child: Text('Please make sure animal and dairy records are available before saving milk entry.', style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF7A5314))))]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: controller.isSubmitting.value || controller.isScheduleLoading.value || controller.animals.isEmpty || controller.dairies.isEmpty || controller.availableShifts.isEmpty ? null : controller.submitMilk, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: (controller.isSubmitting.value || controller.isScheduleLoading.value) ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline_rounded, color: Colors.white), const SizedBox(width: 8), Text('save_milk_entry'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]))));
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
