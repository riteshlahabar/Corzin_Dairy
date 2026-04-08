import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
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
                  top: true,
                  bottom: false,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.black, elevation: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('add_milk'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.black))),
        ],
      ),
    );
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
              TextButton.icon(
                onPressed: controller.animals.isEmpty ? null : () => _openBulkEntryDialog(),
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: const Text('Bulk Entry'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel('select_animal'.tr),
          const SizedBox(height: 8),
          Obx(() => _dropdownCard(child: DropdownButtonFormField<MilkAnimalModel>(initialValue: controller.selectedAnimal.value, isExpanded: true, dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary), decoration: _dropdownDecoration('choose_animal'.tr), items: controller.animals.map((animal) => DropdownMenuItem<MilkAnimalModel>(value: animal, child: Text(animal.displayName, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => controller.selectedAnimal.value = value, validator: (value) => value == null ? 'select_animal_error'.tr : null))),
          const SizedBox(height: 16),
          _fieldLabel('Select Dairy'),
          const SizedBox(height: 8),
          Obx(() => _dropdownCard(child: DropdownButtonFormField<MilkDairyModel>(initialValue: controller.selectedDairy.value, isExpanded: true, dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary), decoration: _dropdownDecoration('Select dairy'), items: controller.dairies.map((dairy) => DropdownMenuItem<MilkDairyModel>(value: dairy, child: Text(dairy.displayName, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => controller.selectedDairy.value = value, validator: (value) => value == null ? 'Please select a dairy' : null))),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('milk_date'.tr), const SizedBox(height: 8), TextFormField(controller: controller.milkDateController, readOnly: true, onTap: controller.pickMilkDate, decoration: _inputDecoration('dd/MM/yyyy').copyWith(suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary)), validator: (value) => value == null || value.trim().isEmpty ? 'select_date_error'.tr : null)])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('shift'.tr), const SizedBox(height: 8), Obx(() => _dropdownCard(child: DropdownButtonFormField<String>(initialValue: controller.selectedShift.value, isExpanded: true, dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary), decoration: _dropdownDecoration('select_shift'.tr), items: controller.shifts.map((shift) => DropdownMenuItem<String>(value: shift, child: Text(shift))).toList(), onChanged: (value) => controller.selectedShift.value = value ?? 'Morning')))]))]),
          const SizedBox(height: 16),
          _fieldLabel('quantity_liters'.tr),
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

  Future<void> _openBulkEntryDialog() async {
    final qtyControllers = <int, TextEditingController>{};
    for (final animal in controller.animals) {
      qtyControllers[animal.id] = TextEditingController();
    }

    await Get.dialog(
      AlertDialog(
        title: const Text('Bulk Milk Entry'),
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
                          decoration: _inputDecoration('Liters'),
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
              final result = await controller.submitBulkMilk(payload);
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

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: controller.isSubmitting.value || controller.animals.isEmpty || controller.dairies.isEmpty ? null : controller.submitMilk, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: controller.isSubmitting.value ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline_rounded, color: Colors.white), const SizedBox(width: 8), Text('save_milk_entry'.tr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]))));
  }

  Widget _sectionTitle(String title) => Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)));
  Widget _fieldLabel(String title) => Align(alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.grey.shade800)));

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
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 12.5),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.red)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 12.5),
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}
