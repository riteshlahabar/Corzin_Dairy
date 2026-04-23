import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/farmer_details_controller.dart';

class FarmerDetailsView extends GetView<FarmerDetailsController> {
  const FarmerDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            width: double.infinity,
            child: Text(
              "farmer_details".tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Obx(() => _photoUploadCard()),
                    _sectionTitle("personal_info".tr),
                    _field("first_name".tr, controller.firstName, icon: Icons.person_outline),
                    _field("middle_name".tr, controller.middleName, icon: Icons.person_outline),
                    _field("last_name".tr, controller.lastName, icon: Icons.person_outline),
                    _sectionTitle("location".tr),
                    Obx(
                      () => _dropdownField(
                        label: "state".tr,
                        value: controller.state.text.trim().isEmpty ? null : controller.state.text.trim(),
                        items: controller.states,
                        enabled: !controller.isLocationLoading.value,
                        onChanged: (value) {
                          if (value == null) return;
                          controller.onStateChanged(value);
                        },
                      ),
                    ),
                    Obx(
                      () => _dropdownField(
                        label: "district".tr,
                        value: controller.district.text.trim().isEmpty ? null : controller.district.text.trim(),
                        items: controller.districts,
                        enabled: controller.districts.isNotEmpty,
                        onChanged: (value) {
                          if (value == null) return;
                          controller.onDistrictChanged(value);
                        },
                      ),
                    ),
                    Obx(
                      () => _dropdownField(
                        label: "Taluka/Subdistrict/City",
                        value: controller.taluka.text.trim().isEmpty ? null : controller.taluka.text.trim(),
                        items: controller.talukas,
                        enabled: controller.talukas.isNotEmpty,
                        onChanged: (value) {
                          if (value == null) return;
                          controller.onTalukaChanged(value);
                        },
                      ),
                    ),
                    _field("Address/Village", controller.village, icon: Icons.home_outlined),
                    _field(
                      "pincode".tr,
                      controller.pincode,
                      icon: Icons.pin_drop_outlined,
                      isNumber: true,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "submit".tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = LinkedHashSet<String>.from(
      items.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ).toList(growable: false);
    final selectedValue = (value != null && uniqueItems.contains(value.trim()))
        ? value.trim()
        : null;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label|${uniqueItems.length}|${selectedValue ?? ''}'),
        initialValue: selectedValue,
        isExpanded: true,
        dropdownColor: const Color(0xFFF7FCF7),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: const Icon(Icons.map_outlined, color: AppColors.primary),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        items: uniqueItems
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _photoUploadCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: controller.pickFarmerPhoto,
        child: Ink(
          width: double.infinity,
          height: 170,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: controller.selectedPhoto.value == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload farmer photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to select from gallery',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(controller.selectedPhoto.value!.path),
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
