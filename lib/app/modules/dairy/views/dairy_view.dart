import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/dairy_controller.dart';

class DairyView extends GetView<DairyController> {
  const DairyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(
          () => Column(
            children: [
              _buildHeader(),
              Expanded(
                child: controller.isPageLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.fetchDairies,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            _buildHeroCard(),
                            const SizedBox(height: 16),
                            _buildSearchRow(),
                            const SizedBox(height: 16),
                            if (controller.filteredDairies.isEmpty)
                              _buildEmptyState()
                            else
                              ...controller.filteredDairies.map(_dairyCard),
                          ],
                        ),
                      ),
              ),
            ],
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
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'add_dairy'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
        ],
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dairy Directory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage milk centers with GST, contact, and full address details from the app.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.35,
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Search dairy, city, GST, contact',
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
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _openAddDairySheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
      child: const Column(
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 46, color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'No dairy records found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Tap Add to create a dairy entry for this farmer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.black54),
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
                  dairy.dairyName.isEmpty ? 'Unnamed Dairy' : dairy.dairyName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: dairy.isActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.grey.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dairy.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dairy.isActive ? AppColors.primary : AppColors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline_rounded, dairy.farmerName.isEmpty ? 'Farmer not available' : dairy.farmerName),
          const SizedBox(height: 8),
          _infoRow(Icons.receipt_long_outlined, dairy.gstNo.isEmpty ? 'GST not added' : dairy.gstNo),
          const SizedBox(height: 8),
          _infoRow(Icons.call_outlined, dairy.contactNumber.isEmpty ? 'No contact added' : dairy.contactNumber),
          const SizedBox(height: 8),
          _infoRow(Icons.home_outlined, dairy.address.isEmpty ? 'No address added' : dairy.address),
          const SizedBox(height: 8),
          _infoRow(Icons.location_city_outlined, [dairy.city, dairy.taluka, dairy.district, dairy.state].where((item) => item.isNotEmpty).join(', ').isEmpty ? 'No location added' : [dairy.city, dairy.taluka, dairy.district, dairy.state].where((item) => item.isNotEmpty).join(', ')),
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

  void _openAddDairySheet() {
    controller.clearForm();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 54,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Add Dairy',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _field(controller.dairyNameController, 'Dairy name', requiredField: true),
                  const SizedBox(height: 12),
                  _field(controller.gstNoController, 'GST no.'),
                  const SizedBox(height: 12),
                  _field(controller.contactController, 'Contact number'),
                  const SizedBox(height: 12),
                  _field(controller.addressController, 'Address', maxLines: 3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(controller.cityController, 'City')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(controller.talukaController, 'Taluka')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(controller.districtController, 'District')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(controller.stateController, 'State')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(controller.pincodeController, 'Pincode'),
                  const SizedBox(height: 18),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: controller.isSubmitting.value ? null : controller.submitDairy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Dairy',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _field(TextEditingController fieldController, String hint, {int maxLines = 1, bool requiredField = false}) {
    return TextFormField(
      controller: fieldController,
      maxLines: maxLines,
      validator: (value) {
        if (requiredField && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
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
}
