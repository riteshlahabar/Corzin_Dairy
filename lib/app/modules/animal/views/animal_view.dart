import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/animal_controller.dart';

class AnimalView extends GetView<AnimalController> {
  const AnimalView({super.key});

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
                              children: [_buildHeroCard(), const SizedBox(height: 16), _buildMainFormCard(), const SizedBox(height: 20), _buildSubmitButton()],
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
          IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back_ios_new_rounded), style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.black, elevation: 0.5)),
          const SizedBox(width: 8),
          Expanded(child: Text(controller.pageTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.black))),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final title = controller.isNewBornMode ? 'Register New Born Cow' : 'Register a new animal';
    final description = controller.isNewBornMode ? 'Add calf details quickly so the new born animal starts tracking in the system immediately.' : 'Add complete details to keep your dairy records clean and organized.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.82)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(height: 62, width: 62, decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(18)), child: Icon(controller.isNewBornMode ? Icons.child_care_rounded : Icons.pets_rounded, color: Colors.white, size: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(description, style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w400))]),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          _sectionTitle('Basic Details'),
          const SizedBox(height: 14),
          if (controller.isNewBornMode)
            Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.lock_outline_rounded, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text('Animal type locked to ${controller.lockedAnimalTypeName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))]))
          else ...[
            _fieldLabel('Animal Type'), const SizedBox(height: 8), Obx(() => DropdownButtonFormField<AnimalTypeModel>(initialValue: controller.selectedAnimalType.value, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded), decoration: _inputDecoration('Select animal type'), items: controller.animalTypes.map((type) => DropdownMenuItem<AnimalTypeModel>(value: type, child: Text(type.name))).toList(), onChanged: (value) => controller.selectedAnimalType.value = value, validator: (value) => value == null ? 'Please select animal type' : null)), const SizedBox(height: 16),
          ],
          _fieldLabel('Animal Name'), const SizedBox(height: 8), TextFormField(controller: controller.animalNameController, textInputAction: TextInputAction.next, decoration: _inputDecoration('Enter animal name'), validator: (value) => value == null || value.trim().isEmpty ? 'Please enter animal name' : null),
          const SizedBox(height: 16),
          _fieldLabel('Tag Number'), const SizedBox(height: 8), TextFormField(controller: controller.tagNumberController, textInputAction: TextInputAction.next, decoration: _inputDecoration('Enter tag number'), validator: (value) => value == null || value.trim().isEmpty ? 'Please enter tag number' : null),
          const SizedBox(height: 18),
          _sectionTitle('Animal Info'), const SizedBox(height: 14),
          _fieldLabel('Birth Date'), const SizedBox(height: 8), TextFormField(controller: controller.birthDateController, readOnly: true, onTap: controller.pickBirthDate, decoration: _inputDecoration('dd/MM/yyyy').copyWith(suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary)), validator: (value) => value == null || value.trim().isEmpty ? 'Please select birth date' : null),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('Gender'), const SizedBox(height: 8), Obx(() => DropdownButtonFormField<String>(initialValue: controller.selectedGender.value.isEmpty ? null : controller.selectedGender.value, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded), decoration: _inputDecoration('Select gender'), items: controller.genderList.map((gender) => DropdownMenuItem<String>(value: gender, child: Text(gender))).toList(), onChanged: (value) => controller.selectedGender.value = value ?? '', validator: (value) => value == null || value.isEmpty ? 'Select gender' : null))])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('Weight'), const SizedBox(height: 8), TextFormField(controller: controller.weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration('Enter weight'))]))]),
          const SizedBox(height: 18),
          _sectionTitle('Animal Image'), const SizedBox(height: 12),
          Obx(() => InkWell(borderRadius: BorderRadius.circular(18), onTap: controller.pickImage, child: Ink(width: double.infinity, height: 170, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.2)), child: controller.selectedImage.value == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(height: 56, width: 56, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 30)), const SizedBox(height: 12), const Text('Upload animal image', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black)), const SizedBox(height: 4), Text('Tap to select from gallery', style: TextStyle(fontSize: 13, color: AppColors.grey.shade700))]) : Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(controller.selectedImage.value!.path), width: double.infinity, height: 170, fit: BoxFit.cover)), Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18))) ]))))
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: controller.isSubmitting.value ? null : controller.submitAnimal, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withOpacity(0.55), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: controller.isSubmitting.value ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline_rounded, color: Colors.white), const SizedBox(width: 8), Text(controller.isNewBornMode ? 'Save New Born Cow' : 'Save Animal', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]))));
  }

  Widget _sectionTitle(String title) => Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)));
  Widget _fieldLabel(String title) => Align(alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.grey.shade800)));

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(hintText: hint, hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 14), filled: true, fillColor: const Color(0xFFF8FBF8), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)));
  }
}
