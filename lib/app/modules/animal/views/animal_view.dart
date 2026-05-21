import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
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
                  top: false,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 8, 6),
      child: Row(
        children: [
          IconButton(onPressed: _goBack, icon: const Icon(Icons.arrow_back_ios_new_rounded), color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(controller.pageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
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
    final title = 'animal_add_new_title'.tr;
    final description = 'animal_add_new_desc'.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.82)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(height: 62, width: 62, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.pets_rounded, color: Colors.white, size: 32)),
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
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.045), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          _sectionTitle('basic_details'.tr),
          const SizedBox(height: 14),
          _fieldLabel('animal_type_label'.tr, requiredField: true), const SizedBox(height: 8), Obx(() => DropdownButtonFormField<AnimalTypeModel>(initialValue: controller.selectedAnimalType.value, hint: Text('select_animal_type'.tr), isExpanded: true, dropdownColor: const Color(0xFFF4FAF4), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7FAF7F)), decoration: _animalTypeDecoration('select_animal_type'.tr), items: controller.animalTypes.map((type) => DropdownMenuItem<AnimalTypeModel>(value: type, child: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(), onChanged: (value) => controller.selectedAnimalType.value = value, validator: (value) => value == null ? 'please_select_animal_type'.tr : null)), const SizedBox(height: 16),
          _fieldLabel('animal_name_label'.tr, requiredField: true), const SizedBox(height: 8), TextFormField(controller: controller.animalNameController, focusNode: controller.animalNameFocus, textInputAction: TextInputAction.next, decoration: _inputDecoration('enter_animal_name'.tr), validator: (value) => value == null || value.trim().isEmpty ? 'please_enter_animal_name'.tr : null),
          Obx(() => controller.showMotherAnimalDropdown ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const SizedBox(height: 16),
            _fieldLabel('mother_animal_name_tag'.tr, requiredField: true),
            const SizedBox(height: 8),
            DropdownButtonFormField<MotherAnimalModel>(
                initialValue: controller.selectedMotherAnimal.value,
                isExpanded: true,
                dropdownColor: const Color(0xFFF4FAF4),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7FAF7F)),
                decoration: _animalTypeDecoration('select_mother_animal'.tr),
                items: controller.motherAnimals
                    .map(
                      (animal) => DropdownMenuItem<MotherAnimalModel>(
                        value: animal,
                        child: Text(animal.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => controller.selectedMotherAnimal.value = value,
                validator: (value) {
                  if (!controller.showMotherAnimalDropdown) return null;
                  return value == null ? 'please_select_mother_animal'.tr : null;
                },
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'mother_animal_helper_text'.tr,
                style: TextStyle(fontSize: 12.5, color: AppColors.grey.shade700),
              ),
            ),
          ],
          ) : const SizedBox.shrink()),
          const SizedBox(height: 16),
          _fieldLabel('tag_number_label'.tr, requiredField: true), const SizedBox(height: 8), TextFormField(controller: controller.tagNumberController, focusNode: controller.tagNumberFocus, textInputAction: TextInputAction.next, decoration: _inputDecoration('enter_tag_number'.tr), validator: (value) => value == null || value.trim().isEmpty ? 'please_enter_tag_number'.tr : null),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('lactation_number'.tr), const SizedBox(height: 8), TextFormField(controller: controller.lactationNumberController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], textInputAction: TextInputAction.next, decoration: _inputDecoration('enter_lactation_no'.tr))])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_fieldLabel('ai_date'.tr), const SizedBox(height: 8), ValueListenableBuilder<TextEditingValue>(valueListenable: controller.aiDateController, builder: (_, value, _) => TextFormField(controller: controller.aiDateController, readOnly: true, onTap: controller.pickAiDate, decoration: _inputDecoration('dd/MM/yyyy').copyWith(suffixIcon: value.text.trim().isEmpty ? const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary) : IconButton(onPressed: controller.clearAiDate, icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary), tooltip: 'Clear'))))]))]),
          const SizedBox(height: 16),
          _fieldLabel('breed_name'.tr), const SizedBox(height: 8), TextFormField(controller: controller.breedNameController, textInputAction: TextInputAction.next, decoration: _inputDecoration('enter_breed_name'.tr)),
          const SizedBox(height: 18),
          _sectionTitle('animal_info'.tr), const SizedBox(height: 14),
          _fieldLabel('birth_date'.tr, requiredField: true),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.birthDateController,
            builder: (_, value, _) => TextFormField(
              controller: controller.birthDateController,
              readOnly: true,
              onTap: controller.pickBirthDate,
              decoration: _inputDecoration('dd/MM/yyyy').copyWith(
                suffixIcon: value.text.trim().isEmpty
                    ? const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary)
                    : IconButton(
                        onPressed: controller.clearBirthDate,
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                        tooltip: 'Clear',
                      ),
              ),
              validator: (fieldValue) => (fieldValue ?? '').trim().isEmpty ? 'Please select birth date' : null,
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.ageController,
            builder: (context, value, _) {
              final ageText = value.text.trim();
              if (ageText.isEmpty) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8EF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCFE6CF)),
                  ),
                  child: Text(
                    '${'age'.tr}: $ageText',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _fieldLabel('purchase_date'.tr),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.purchaseDateController,
            builder: (_, value, _) => TextFormField(
              controller: controller.purchaseDateController,
              readOnly: true,
              onTap: controller.pickPurchaseDate,
              decoration: _inputDecoration('dd/MM/yyyy').copyWith(
                suffixIcon: value.text.trim().isEmpty
                    ? const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary)
                    : IconButton(
                        onPressed: controller.clearPurchaseDate,
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                        tooltip: 'Clear',
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('gender'.tr, requiredField: true),
                    const SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: controller.selectedGender.value.isEmpty ? null : controller.selectedGender.value,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFF4FAF4),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7FAF7F)),
                        decoration: _animalTypeDecoration('select_gender'.tr),
                        items: controller.genderList
                            .map((gender) => DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ))
                            .toList(),
                        onChanged: (value) => controller.selectedGender.value = value ?? '',
                        validator: (value) => value == null || value.isEmpty ? 'please_select_gender'.tr : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('weight'.tr, requiredField: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.weightController,
                      focusNode: controller.weightFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('enter_weight'.tr),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return 'Please enter weight';
                        final parsed = double.tryParse(text);
                        if (parsed == null || parsed <= 0) return 'Please enter valid weight';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _fieldLabel('animal_image'.tr, requiredField: true), const SizedBox(height: 12),
          Obx(() => InkWell(borderRadius: BorderRadius.circular(18), onTap: controller.pickImage, child: Ink(width: double.infinity, height: 170, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2)), child: controller.selectedImage.value == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(height: 56, width: 56, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 30)), const SizedBox(height: 12), Text('upload_animal_image'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black)), const SizedBox(height: 4), Text('tap_select_gallery'.tr, style: TextStyle(fontSize: 13, color: AppColors.grey.shade700))]) : Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(controller.selectedImage.value!.path), width: double.infinity, height: 170, fit: BoxFit.cover)), Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18))) ])))),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: controller.isSubmitting.value ? null : _onSubmitTap, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: controller.isSubmitting.value ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_outline_rounded, color: Colors.white), const SizedBox(width: 8), Text('save_animal'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]))));
  }

  void _onSubmitTap() {
    final currentForm = controller.formKey.currentState;
    if (currentForm == null) return;

    final isValid = currentForm.validate();
    if (!isValid) {
      _focusFirstInvalidField();
      return;
    }

    if (controller.selectedAnimalType.value == null) {
      Get.snackbar('Error', 'Please select animal type', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.showMotherAnimalDropdown && controller.selectedMotherAnimal.value == null) {
      Get.snackbar('Error', 'Please select mother animal', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.selectedGender.value.trim().isEmpty) {
      Get.snackbar('Error', 'Please select gender', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (controller.selectedImage.value == null) {
      Get.snackbar('Error', 'Please upload animal image', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    controller.submitAnimal();
  }

  void _focusFirstInvalidField() {
    if (controller.animalNameController.text.trim().isEmpty) {
      controller.animalNameFocus.requestFocus();
      return;
    }
    if (controller.tagNumberController.text.trim().isEmpty) {
      controller.tagNumberFocus.requestFocus();
      return;
    }
    if (controller.birthDateController.text.trim().isEmpty) {
      return;
    }
    final weightText = controller.weightController.text.trim();
    final weight = double.tryParse(weightText);
    if (weightText.isEmpty || weight == null || weight <= 0) {
      controller.weightFocus.requestFocus();
    }
  }

  Widget _sectionTitle(String title) => Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)));
  Widget _fieldLabel(String title, {bool requiredField = false}) => Align(
    alignment: Alignment.centerLeft,
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.grey.shade800),
        children: [
          TextSpan(text: title),
          if (requiredField) const TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    ),
  );


  InputDecoration _animalTypeDecoration(String hint) {
    return _inputDecoration(hint).copyWith(
      fillColor: const Color(0xFFF4FAF4),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4EFE4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(hintText: hint, hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 14), isDense: true, filled: true, fillColor: const Color(0xFFF8FBF8), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)));
  }
}


