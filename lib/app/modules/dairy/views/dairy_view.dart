import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../routes/app_pages.dart';
import '../controllers/dairy_controller.dart';

enum DairyViewMode { add, list }

class DairyView extends GetView<DairyController> {
  const DairyView({super.key, this.initialMode = DairyViewMode.add});

  final DairyViewMode initialMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      resizeToAvoidBottomInset: true,
      floatingActionButton: initialMode == DairyViewMode.list
          ? FloatingActionButton(
              onPressed: _openAddDairyScreen,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'add_dairy'.tr,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(
          () => Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: controller.isPageLoading.value && initialMode == DairyViewMode.list
                    ? const Center(child: CircularProgressIndicator())
                    : initialMode == DairyViewMode.list
                        ? _buildListMode()
                        : _buildAddMode(),
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
              initialMode == DairyViewMode.list
                  ? 'dairy_list'.tr
                  : (controller.isEditMode.value ? 'edit_dairy'.tr : 'add_dairy'.tr),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListMode() {
    return RefreshIndicator(
      onRefresh: controller.fetchDairies,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 12),
          _buildSearchRow(),
          const SizedBox(height: 12),
          if (controller.filteredDairies.isEmpty) _buildEmptyState() else ...controller.filteredDairies.map(_dairyCard),
        ],
      ),
    );
  }

  Widget _buildAddMode() {
    final bottomInset = MediaQuery.of(Get.context!).viewInsets.bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset > 0 ? 12 : 24),
      child: Form(
        key: controller.formKey,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
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
              _sectionTitle('dairy_details'.tr),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  controller.isEditMode.value
                      ? 'update_dairy_information'.tr
                      : 'manage_dairy_profile_details'.tr,
                  style: TextStyle(
                    fontSize: 12.8,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _label('dairy_name'.tr, requiredField: true),
              const SizedBox(height: 6),
              _field(
                controller.dairyNameController,
                'enter_dairy_name'.tr,
                requiredField: true,
                focusNode: controller.dairyNameFocus,
              ),
              const SizedBox(height: 12),
              _label('gst_no'.tr, requiredField: false),
              const SizedBox(height: 6),
              _field(controller.gstNoController, 'enter_gst_optional'.tr),
              const SizedBox(height: 12),
              _label('mobile_number'.tr, requiredField: true),
              const SizedBox(height: 6),
              _field(
                controller.contactController,
                'enter_mobile_10'.tr,
                requiredField: true,
                focusNode: controller.contactFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'mobile_required'.tr;
                  if (!RegExp(r'^\d{10}$').hasMatch(text)) {
                    return 'mobile_10_digits'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _label('address'.tr, requiredField: true),
              const SizedBox(height: 6),
              _field(
                controller.addressController,
                'enter_address'.tr,
                requiredField: true,
                maxLines: 2,
                focusNode: controller.addressFocus,
              ),
              const SizedBox(height: 12),
              _label('state'.tr, requiredField: true),
              const SizedBox(height: 6),
              Obx(
                () => _dropdownField(
                  label: 'state'.tr,
                  requiredField: true,
                  value: controller.stateController.text.trim().isEmpty ? null : controller.stateController.text.trim(),
                  items: controller.states,
                  enabled: !controller.isLocationLoading.value,
                  onChanged: (value) {
                    if (value == null) return;
                    controller.onStateChanged(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _label('district'.tr, requiredField: true),
              const SizedBox(height: 6),
              Obx(
                () => _dropdownField(
                  label: 'district'.tr,
                  requiredField: true,
                  value: controller.districtController.text.trim().isEmpty ? null : controller.districtController.text.trim(),
                  items: controller.districts,
                  enabled: controller.districts.isNotEmpty,
                  onChanged: (value) {
                    if (value == null) return;
                    controller.onDistrictChanged(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _label('subdistrict'.tr, requiredField: true),
              const SizedBox(height: 6),
              Obx(
                () => _dropdownField(
                  label: 'subdistrict'.tr,
                  requiredField: true,
                  value: controller.talukaController.text.trim().isEmpty ? null : controller.talukaController.text.trim(),
                  items: controller.talukas,
                  enabled: controller.talukas.isNotEmpty,
                  onChanged: (value) {
                    if (value == null) return;
                    controller.onTalukaChanged(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _label('city_village'.tr, requiredField: true),
              const SizedBox(height: 6),
              _field(
                controller.cityController,
                'enter_city_village'.tr,
                requiredField: true,
                focusNode: controller.cityFocus,
              ),
              const SizedBox(height: 12),
              _label('pincode'.tr, requiredField: true),
              const SizedBox(height: 6),
              _field(
                controller.pincodeController,
                'enter_pincode_6'.tr,
                requiredField: true,
                focusNode: controller.pincodeFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'pincode_required'.tr;
                  if (!RegExp(r'^\d{6}$').hasMatch(text)) {
                    return 'pincode_6_digits'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value ? null : _onSaveDairyTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            controller.isEditMode.value ? 'update_dairy'.tr : 'save_dairy'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4EA857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dairy_list'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'dairy_list_subtitle'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                Text(
                  '${controller.filteredDairies.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'total'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller.searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'search_dairy_city_gst_contact'.tr,
          hintStyle: TextStyle(fontSize: 12.2, color: Colors.grey.shade600),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.store_mall_directory_outlined, size: 46, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'no_dairy_records_found'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _dairyCard(DairyModel dairy) {
    final locationText = [
      dairy.city,
      dairy.taluka,
      dairy.district,
      dairy.state,
    ].where((item) => item.isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dairy.dairyName.isEmpty ? 'unnamed_dairy'.tr : dairy.dairyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _miniBadge(
                          icon: Icons.call_outlined,
                          text: dairy.contactNumber.isEmpty ? '-' : dairy.contactNumber,
                        ),
                        _miniBadge(
                          icon: Icons.location_on_outlined,
                          text: locationText.isEmpty ? '-' : locationText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openEditDairyScreen(dairy),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 36,
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'gst_no'.tr,
                  value: dairy.gstNo.isEmpty ? '-' : dairy.gstNo,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  label: 'pincode'.tr,
                  value: dairy.pincode.isEmpty ? '-' : dairy.pincode,
                  icon: Icons.pin_drop_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: _infoRow(
              Icons.home_outlined,
              dairy.address.isEmpty ? '-' : dairy.address,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge({required IconData icon, required String text}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.8),
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController fieldController,
    String hint, {
    int maxLines = 1,
    bool requiredField = false,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: fieldController,
      focusNode: focusNode,
      scrollPadding: const EdgeInsets.only(bottom: 12),
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.text
          ? (maxLines > 1
                ? TextCapitalization.sentences
                : TextCapitalization.words)
          : TextCapitalization.none,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13.5),
      validator: validator ??
          (value) {
            if (requiredField && (value == null || value.trim().isEmpty)) {
              return 'required_field'.tr;
            }
            return null;
          },
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 12 : 10,
        ),
        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFF8FBF8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required bool requiredField,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = LinkedHashSet<String>.from(
      items.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ).toList(growable: false);
    final selectedValue = (value != null && uniqueItems.contains(value.trim())) ? value.trim() : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('$label|${uniqueItems.length}|${selectedValue ?? ''}'),
      initialValue: selectedValue,
      isExpanded: true,
      dropdownColor: const Color(0xFFF7FCF7),
      decoration: InputDecoration(
        hintText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FBF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      items: uniqueItems
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (val) {
        if (requiredField && (val == null || val.trim().isEmpty)) {
          return 'required_field'.tr;
        }
        return null;
      },
    );
  }

  void _onSaveDairyTap() {
    final currentForm = controller.formKey.currentState;
    if (currentForm == null) return;

    final isValid = currentForm.validate();
    if (!isValid) {
      _focusFirstInvalidField();
      return;
    }

    if (controller.stateController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'please_select_state'.tr);
      return;
    }
    if (controller.districtController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'please_select_district'.tr);
      return;
    }
    if (controller.talukaController.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'please_select_subdistrict'.tr);
      return;
    }

    controller.submitDairy();
  }

  void _focusFirstInvalidField() {
    if (controller.dairyNameController.text.trim().isEmpty) {
      controller.dairyNameFocus.requestFocus();
      return;
    }
    final mobile = controller.contactController.text.trim();
    if (mobile.isEmpty || !RegExp(r'^\d{10}$').hasMatch(mobile)) {
      controller.contactFocus.requestFocus();
      return;
    }
    if (controller.addressController.text.trim().isEmpty) {
      controller.addressFocus.requestFocus();
      return;
    }
    if (controller.cityController.text.trim().isEmpty) {
      controller.cityFocus.requestFocus();
      return;
    }
    final pin = controller.pincodeController.text.trim();
    if (pin.isEmpty || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      controller.pincodeFocus.requestFocus();
    }
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _label(String text, {required bool requiredField}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12.8,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          children: [
            TextSpan(text: text),
            if (requiredField)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  void _openAddDairyScreen() {
    controller.startCreateMode();
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().openDrawerPage(
        const DairyView(initialMode: DairyViewMode.add),
      );
      return;
    }
    Get.toNamed(Routes.DAIRY);
  }

  void _openEditDairyScreen(DairyModel dairy) {
    controller.startEditMode(dairy);
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().openDrawerPage(
        const DairyView(initialMode: DairyViewMode.add),
      );
      return;
    }
    Get.toNamed(
      Routes.DAIRY,
      arguments: {'edit_dairy': dairy.toJson()},
    );
  }

  void _goBack() {
    if (initialMode == DairyViewMode.add) {
      controller.startCreateMode();
    }
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }
}
