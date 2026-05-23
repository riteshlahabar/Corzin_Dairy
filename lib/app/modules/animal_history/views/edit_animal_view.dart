import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/animal_history_controller.dart';

class EditAnimalView extends StatefulWidget {
  const EditAnimalView({super.key, required this.item});

  final AnimalHistoryItem item;

  @override
  State<EditAnimalView> createState() => _EditAnimalViewState();
}

class _EditAnimalViewState extends State<EditAnimalView> {
  final _formKey = GlobalKey<FormState>();
  late final AnimalHistoryController controller;
  late final TextEditingController _animalNameController;
  late final TextEditingController _tagNumberController;
  late final TextEditingController _lactationNumberController;
  late final TextEditingController _aiDateController;
  late final TextEditingController _breedNameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _purchaseDateController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _defaultMilkPerSessionController;
  final FocusNode _animalNameFocus = FocusNode();
  final FocusNode _tagNumberFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _defaultMilkPerSessionFocus = FocusNode();

  int _selectedTypeId = 0;
  String _selectedGender = 'Female';
  AnimalHistoryItem? _selectedMotherAnimal;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AnimalHistoryController>();
    final item = widget.item;
    _animalNameController = TextEditingController(text: item.animalName);
    _tagNumberController = TextEditingController(text: item.tagNumber);
    _lactationNumberController = TextEditingController(text: item.lactationNumber);
    _aiDateController = TextEditingController(text: item.aiDate);
    _breedNameController = TextEditingController(text: item.breedName);
    _birthDateController = TextEditingController(text: item.birthDate);
    _purchaseDateController = TextEditingController(text: item.purchaseDate);
    _ageController = TextEditingController(text: item.age);
    _weightController = TextEditingController(text: item.weight);
    _defaultMilkPerSessionController = TextEditingController(text: item.defaultMilkPerSession);
    _selectedTypeId = item.animalTypeId;
    _selectedGender = item.gender.trim().isEmpty ? 'Female' : item.gender.trim();
    _selectedMotherAnimal = _findExistingMother();
    _syncAgeFromBirthDateText();
  }

  @override
  void dispose() {
    _animalNameController.dispose();
    _tagNumberController.dispose();
    _lactationNumberController.dispose();
    _aiDateController.dispose();
    _breedNameController.dispose();
    _birthDateController.dispose();
    _purchaseDateController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _defaultMilkPerSessionController.dispose();
    _animalNameFocus.dispose();
    _tagNumberFocus.dispose();
    _weightFocus.dispose();
    _defaultMilkPerSessionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF6),
      body: GestureDetector(
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
                    key: _formKey,
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
          Expanded(
            child: Text(
              'edit_animal'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.animalName.trim().isEmpty ? 'edit_animal'.tr : widget.item.animalName,
                  style: const TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'update_all_animal_details'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionTitle('basic_details'.tr),
          const SizedBox(height: 14),
          _fieldLabel('animal_type_label'.tr, requiredField: true),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<int>(
              initialValue: _selectedTypeId == 0 ? null : _selectedTypeId,
              isExpanded: true,
              dropdownColor: const Color(0xFFF4FAF4),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7FAF7F)),
              decoration: _dropdownDecoration('select_animal_type'.tr),
              items: controller.animalTypes
                  .map(
                    (type) => DropdownMenuItem<int>(
                      value: type.id,
                      child: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypeId = value ?? 0;
                  if (!_showMotherAnimalDropdown) {
                    _selectedMotherAnimal = null;
                  }
                });
              },
              validator: (value) => value == null ? 'please_select_animal_type'.tr : null,
            ),
          ),
          if (_showMotherAnimalDropdown) ...[
            const SizedBox(height: 16),
            _fieldLabel('mother_animal_name_tag'.tr, requiredField: true),
            const SizedBox(height: 8),
            DropdownButtonFormField<AnimalHistoryItem>(
              initialValue: _selectedMotherAnimal,
              isExpanded: true,
              dropdownColor: const Color(0xFFF4FAF4),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7FAF7F)),
              decoration: _dropdownDecoration('select_mother_animal'.tr),
              items: _motherAnimals
                  .map(
                    (animal) => DropdownMenuItem<AnimalHistoryItem>(
                      value: animal,
                      child: Text(_motherLabel(animal), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedMotherAnimal = value),
              validator: (value) {
                if (!_showMotherAnimalDropdown) return null;
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
          const SizedBox(height: 16),
          _fieldLabel('animal_name_label'.tr, requiredField: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _animalNameController,
            focusNode: _animalNameFocus,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('enter_animal_name'.tr),
            validator: (value) => value == null || value.trim().isEmpty ? 'please_enter_animal_name'.tr : null,
          ),
          const SizedBox(height: 16),
          _fieldLabel('tag_number_label'.tr, requiredField: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tagNumberController,
            focusNode: _tagNumberFocus,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('enter_tag_number'.tr),
            validator: (value) => value == null || value.trim().isEmpty ? 'please_enter_tag_number'.tr : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('lactation_number'.tr),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lactationNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('enter_lactation_no'.tr),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('ai_date'.tr),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _aiDateController,
                      builder: (_, value, _) => TextFormField(
                        controller: _aiDateController,
                        readOnly: true,
                        onTap: () => _pickDate(_aiDateController, optional: true),
                        decoration: _inputDecoration('dd/MM/yyyy').copyWith(
                          suffixIcon: value.text.trim().isEmpty
                              ? const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary)
                              : IconButton(
                                  onPressed: () => setState(_aiDateController.clear),
                                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                                  tooltip: 'Clear',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('breed_name'.tr),
          const SizedBox(height: 8),
          TextFormField(
            controller: _breedNameController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('enter_breed_name'.tr),
          ),
          const SizedBox(height: 18),
          _sectionTitle('animal_info'.tr),
          const SizedBox(height: 14),
          _fieldLabel('birth_date'.tr, requiredField: true),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _birthDateController,
            builder: (_, value, _) => TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: () => _pickDate(_birthDateController, syncAge: true),
              decoration: _inputDecoration('dd/MM/yyyy').copyWith(
                suffixIcon: value.text.trim().isEmpty
                    ? const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary)
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _birthDateController.clear();
                            _ageController.clear();
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                        tooltip: 'Clear',
                      ),
              ),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Please select birth date' : null,
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ageController,
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
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _fieldLabel('purchase_date'.tr),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _purchaseDateController,
            builder: (_, value, _) => TextFormField(
              controller: _purchaseDateController,
              readOnly: true,
              onTap: () => _pickDate(_purchaseDateController, optional: true),
              decoration: _inputDecoration('dd/MM/yyyy').copyWith(
                suffixIcon: value.text.trim().isEmpty
                    ? const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary)
                    : IconButton(
                        onPressed: () => setState(_purchaseDateController.clear),
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
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender.isEmpty ? null : _selectedGender,
                      isExpanded: true,
                      dropdownColor: const Color(0xFFF4FAF4),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7FAF7F)),
                      decoration: _dropdownDecoration('select_gender'.tr),
                      items: [
                        DropdownMenuItem(value: 'Male', child: Text('male'.tr)),
                        DropdownMenuItem(value: 'Female', child: Text('female'.tr)),
                      ],
                      onChanged: (value) => setState(() => _selectedGender = value ?? ''),
                      validator: (value) => value == null || value.isEmpty ? 'please_select_gender'.tr : null,
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
                      controller: _weightController,
                      focusNode: _weightFocus,
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
          _fieldLabel('default_milk_per_milking'.tr),
          const SizedBox(height: 8),
          TextFormField(
            controller: _defaultMilkPerSessionController,
            focusNode: _defaultMilkPerSessionFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('enter_default_milk_per_milking'.tr),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return null;
              final parsed = double.tryParse(text);
              if (parsed == null || parsed < 0) return 'enter_valid_milk_qty'.tr;
              return null;
            },
          ),
          const SizedBox(height: 18),
          _fieldLabel('animal_image'.tr, requiredField: true),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _pickImage,
            child: Ink(
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
              ),
              child: _buildImagePreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: controller.isSubmitting.value ? null : _onSubmitTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: controller.isSubmitting.value
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'update_animal'.tr,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              File(_selectedImage!.path),
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
          _imageEditBadge(),
        ],
      );
    }

    if (widget.item.image.trim().isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              widget.item.image,
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imagePlaceholder(),
            ),
          ),
          _imageEditBadge(),
        ],
      );
    }

    return _imagePlaceholder();
  }

  Widget _imageEditBadge() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 12),
        Text('upload_animal_image'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('tap_select_gallery'.tr, style: TextStyle(fontSize: 13, color: AppColors.grey.shade700)),
      ],
    );
  }

  Future<void> _pickImage() async {
    final image = await controller.pickAnimalPhoto();
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _pickDate(
    TextEditingController target, {
    bool syncAge = false,
    bool optional = false,
  }) async {
    DateTime initialDate = DateTime.now();
    if (target.text.trim().isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parseStrict(target.text.trim());
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        const softGreen = Color(0xFFF4FAF4);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF95BE95),
              onPrimary: AppColors.black,
              surface: softGreen,
              onSurface: AppColors.black,
            ),
            dialogTheme: theme.dialogTheme.copyWith(backgroundColor: softGreen),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: softGreen,
              headerBackgroundColor: const Color(0xFFDDEEDC),
              headerForegroundColor: AppColors.black,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        target.text = DateFormat('dd/MM/yyyy').format(picked);
        if (syncAge) _syncAgeFromBirthDateText();
      });
    } else if (!optional && syncAge) {
      _syncAgeFromBirthDateText();
    }
  }

  void _onSubmitTap() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      _focusFirstInvalidField();
      return;
    }
    if (_selectedTypeId == 0) {
      Get.snackbar('Error', 'please_select_animal_type'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_showMotherAnimalDropdown && _selectedMotherAnimal == null) {
      Get.snackbar('Error', 'please_select_mother_animal'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ageInfo = _calculateAgeInfoFromText(_birthDateController.text);
    if (ageInfo == null) {
      Get.snackbar('Error', 'Please select valid birth date', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (widget.item.image.trim().isEmpty && _selectedImage == null) {
      Get.snackbar('Error', 'Please upload animal image', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final ok = await controller.updateAnimal(
      item: widget.item,
      animalName: _animalNameController.text,
      tagNumber: _tagNumberController.text,
      animalTypeId: _selectedTypeId,
      lactationNumber: _lactationNumberController.text,
      aiDate: _aiDateController.text,
      breedName: _breedNameController.text,
      motherAnimalId: _showMotherAnimalDropdown ? _selectedMotherAnimal?.id : null,
      birthDate: _birthDateController.text,
      purchaseDate: _purchaseDateController.text,
      age: ageInfo.years.toString(),
      gender: _selectedGender,
      weight: _weightController.text,
      defaultMilkPerSession: _defaultMilkPerSessionController.text,
      imageFile: _selectedImage,
    );

    if (ok) {
      Get.back();
    }
  }

  void _focusFirstInvalidField() {
    if (_animalNameController.text.trim().isEmpty) {
      _animalNameFocus.requestFocus();
      return;
    }
    if (_tagNumberController.text.trim().isEmpty) {
      _tagNumberFocus.requestFocus();
      return;
    }
    final weightText = _weightController.text.trim();
    final weight = double.tryParse(weightText);
    if (weightText.isEmpty || weight == null || weight <= 0) {
      _weightFocus.requestFocus();
    }
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().popRouteOrCloseDrawerPage()) {
      return;
    }
    Get.back();
  }

  AnimalHistoryItem? _findExistingMother() {
    final motherName = widget.item.motherAnimalName.trim().toLowerCase();
    final motherTag = widget.item.motherTagNumber.trim().toLowerCase();
    if (motherName.isEmpty && motherTag.isEmpty) return null;
    return _motherAnimals.firstWhereOrNull((animal) {
      final nameMatches = motherName.isNotEmpty && animal.animalName.trim().toLowerCase() == motherName;
      final tagMatches = motherTag.isNotEmpty && animal.tagNumber.trim().toLowerCase() == motherTag;
      return nameMatches || tagMatches;
    });
  }

  List<AnimalHistoryItem> get _motherAnimals {
    return controller.history.where((animal) => animal.id != widget.item.id).toList();
  }

  String _motherLabel(AnimalHistoryItem animal) {
    final tag = animal.tagNumber.trim();
    if (tag.isEmpty) return animal.animalName;
    return '${animal.animalName} ($tag)';
  }

  bool get _showMotherAnimalDropdown {
    final selectedType = controller.animalTypes.firstWhereOrNull((type) => type.id == _selectedTypeId);
    final name = selectedType?.name.trim().toLowerCase() ?? '';
    if (name.isEmpty) return false;
    return name.contains('calf') ||
        name.contains('calves') ||
        name.contains('new born') ||
        name.contains('बछ') ||
        name.contains('वासर');
  }

  _AgeInfo? _calculateAgeInfoFromBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    if (birthDate.isAfter(now)) return null;
    var years = now.year - birthDate.year;
    var months = now.month - birthDate.month;
    var days = now.day - birthDate.day;

    if (days < 0) {
      final previousMonthLastDay = DateTime(now.year, now.month, 0).day;
      days += previousMonthLastDay;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    if (years < 0) {
      years = 0;
      months = 0;
      days = 0;
    }
    return _AgeInfo(years: years, display: '$years years $months month $days days');
  }

  _AgeInfo? _calculateAgeInfoFromText(String birthDateText) {
    final text = birthDateText.trim();
    if (text.isEmpty) return null;
    try {
      final parsed = DateFormat('dd/MM/yyyy').parseStrict(text);
      return _calculateAgeInfoFromBirthDate(parsed);
    } catch (_) {
      return null;
    }
  }

  void _syncAgeFromBirthDateText() {
    final ageInfo = _calculateAgeInfoFromText(_birthDateController.text);
    _ageController.text = ageInfo?.display ?? widget.item.age;
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
      ),
    );
  }

  Widget _fieldLabel(String title, {bool requiredField = false}) {
    return Align(
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
  }

  InputDecoration _dropdownDecoration(String hint) {
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
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey.shade500, fontSize: 14),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

class _AgeInfo {
  _AgeInfo({required this.years, required this.display});

  final int years;
  final String display;
}
