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
              initialMode == DairyViewMode.list ? 'dairy_list'.tr : 'add_dairy'.tr,
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 16),
          _buildSearchRow(),
          const SizedBox(height: 16),
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
                            'save_dairy'.tr,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4EA857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.storefront_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'dairy_list'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'search_dairy_city_gst_contact'.tr,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openAddDairyScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'add_dairy'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dairy.dairyName.isEmpty ? 'unnamed_dairy'.tr : dairy.dairyName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.receipt_long_outlined, dairy.gstNo.isEmpty ? '-' : dairy.gstNo),
          const SizedBox(height: 8),
          _infoRow(Icons.call_outlined, dairy.contactNumber.isEmpty ? '-' : dairy.contactNumber),
          const SizedBox(height: 8),
          _infoRow(Icons.home_outlined, dairy.address.isEmpty ? '-' : dairy.address),
          const SizedBox(height: 8),
          _infoRow(
            Icons.location_city_outlined,
            [dairy.city, dairy.taluka, dairy.district, dairy.state].where((item) => item.isNotEmpty).join(', ').isEmpty
                ? '-'
                : [dairy.city, dairy.taluka, dairy.district, dairy.state].where((item) => item.isNotEmpty).join(', '),
          ),
          if (dairy.pincode.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.pin_drop_outlined, dairy.pincode),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
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
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().openDrawerPage(
        const DairyView(initialMode: DairyViewMode.add),
      );
      return;
    }
    Get.toNamed(Routes.DAIRY);
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }
}
