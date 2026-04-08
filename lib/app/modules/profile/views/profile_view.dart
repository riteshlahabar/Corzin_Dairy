import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    Text(
                      'profile'.tr,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHeaderCard(),
                    const SizedBox(height: 18),
                    _editableInfoCard(
                      title: 'farmer_information'.tr,
                      isEditing: controller.isEditingFarmerInfo.value,
                      onEditTap: controller.toggleFarmerInfoEdit,
                      children: [
                        _buildEditableField(
                          label: 'first_name'.tr,
                          controller: controller.firstNameController,
                          enabled: controller.isEditingFarmerInfo.value,
                        ),
                        _buildEditableField(
                          label: 'middle_name'.tr,
                          controller: controller.middleNameController,
                          enabled: controller.isEditingFarmerInfo.value,
                        ),
                        _buildEditableField(
                          label: 'last_name'.tr,
                          controller: controller.lastNameController,
                          enabled: controller.isEditingFarmerInfo.value,
                        ),
                        _buildReadOnlyRow(
                          label: 'mobile_number'.tr,
                          value: controller.profile['mobile'] ?? '-',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _editableInfoCard(
                      title: 'location'.tr,
                      isEditing: controller.isEditingLocation.value,
                      onEditTap: controller.toggleLocationEdit,
                      children: [
                        _buildEditableField(
                          label: 'village'.tr,
                          controller: controller.villageController,
                          enabled: controller.isEditingLocation.value,
                        ),
                        _buildEditableField(
                          label: 'city'.tr,
                          controller: controller.cityController,
                          enabled: controller.isEditingLocation.value,
                        ),
                        _buildEditableField(
                          label: 'taluka'.tr,
                          controller: controller.talukaController,
                          enabled: controller.isEditingLocation.value,
                        ),
                        _buildEditableField(
                          label: 'district'.tr,
                          controller: controller.districtController,
                          enabled: controller.isEditingLocation.value,
                        ),
                        _buildEditableField(
                          label: 'state'.tr,
                          controller: controller.stateController,
                          enabled: controller.isEditingLocation.value,
                        ),
                        _buildEditableField(
                          label: 'pincode'.tr,
                          controller: controller.pincodeController,
                          enabled: controller.isEditingLocation.value,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (controller.isEditingAny || controller.selectedPhoto.value != null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : controller.saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: controller.isSaving.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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

  Widget _buildHeaderCard() {
    final photoUrl = controller.profile['farmer_photo'] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F3E7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 82,
                width: 82,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: controller.selectedPhoto.value != null
                      ? Image.file(
                          File(controller.selectedPhoto.value!.path),
                          fit: BoxFit.cover,
                        )
                      : photoUrl.trim().isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primary,
                                  size: 40,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 40,
                            ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: controller.pickProfilePhoto,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            controller.fullName().isEmpty ? 'guest'.tr : controller.fullName(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.profile['mobile'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey.shade700,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableInfoCard({
    required String title,
    required bool isEditing,
    required VoidCallback onEditTap,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: onEditTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing ? Icons.close_rounded : Icons.edit_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    if (!enabled) {
      return _buildReadOnlyRow(label: label, value: controller.text);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF7FBF7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
