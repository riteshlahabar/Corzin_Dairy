import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/manage_animal_controller.dart';

class ManageAnimalView extends GetView<ManageAnimalController> {
  const ManageAnimalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'manage_animal'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'search_animal_tag_status'.tr,
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
            SizedBox(
              height: 42,
              child: Obx(
                () => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('all', 'all'.tr),
                    _filterChip('active', 'active'.tr),
                    _filterChip('sold', 'sold'.tr),
                    _filterChip('death', 'death'.tr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.fetchAnimals,
                        child: controller.filteredAnimals.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  SizedBox(height: 120),
                                  const Icon(
                                    Icons.manage_accounts_rounded,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'no_animals_found'.tr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                itemCount: controller.filteredAnimals.length,
                                itemBuilder: (context, index) {
                                  final animal =
                                      controller.filteredAnimals[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _animalImage(animal.image),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    animal.animalName.isEmpty
                                                        ? '-'
                                                        : animal.animalName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${'tag'.tr}: ${animal.tagNumber.isEmpty ? '-' : animal.tagNumber}',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: AppColors
                                                          .grey
                                                          .shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${'pan'.tr}: ${animal.animalTypeName.isEmpty ? '-' : animal.animalTypeName}',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: AppColors
                                                          .grey
                                                          .shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _statusBadge(
                                              animal.lifecycleStatus,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _detailRow(
                                          'unique_id'.tr,
                                          animal.uniqueId.isEmpty
                                              ? '-'
                                              : animal.uniqueId,
                                        ),
                                        _detailRow(
                                          'age'.tr,
                                          animal.age.isEmpty ? '-' : animal.age,
                                        ),
                                        _detailRow(
                                          'birth_date'.tr,
                                          animal.birthDate.isEmpty
                                              ? '-'
                                              : animal.birthDate,
                                        ),
                                        _detailRow(
                                          'gender'.tr,
                                          animal.gender.isEmpty
                                              ? '-'
                                              : animal.gender,
                                        ),
                                        _detailRow(
                                          'weight'.tr,
                                          animal.weight.isEmpty
                                              ? '-'
                                              : '${animal.weight} Kg',
                                        ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _openManageSheet(animal),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.settings_rounded,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              'manage_animal'.tr,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = controller.selectedFilter.value == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => controller.selectedFilter.value = value,
        selectedColor: AppColors.primary.withValues(alpha: 0.14),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _animalImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 74,
        width: 74,
        child: imageUrl.isEmpty
            ? _imageFallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imageFallback(),
              ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.pets_rounded, color: AppColors.primary, size: 30),
    );
  }

  Widget _statusBadge(String value) {
    Color color = AppColors.primary;
    if (value == 'sold') {
      color = const Color(0xFF1976D2);
    } else if (value == 'death') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value.isEmpty ? 'active'.tr : value.toLowerCase().tr,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }

  void _openManageSheet(ManageAnimalItem animal) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 54,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                'animal_lifecycle'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'manage_selected_animal'.trParams({
                  'name': animal.animalName.isEmpty
                      ? 'animal'.tr
                      : animal.animalName,
                }),
                style: TextStyle(fontSize: 13, color: AppColors.grey.shade700),
              ),
              const SizedBox(height: 18),
              _sheetButton('mark_active'.tr, AppColors.primary, () async {
                final ok = await controller.updateAnimalLifecycle(
                  animalId: animal.id,
                  action: 'active',
                );
                if (ok) Get.back();
              }),
              const SizedBox(height: 10),
              _sheetButton('mark_sold'.tr, const Color(0xFF1976D2), () async {
                final ok = await controller.updateAnimalLifecycle(
                  animalId: animal.id,
                  action: 'sold',
                );
                if (ok) Get.back();
              }),
              const SizedBox(height: 10),
              _sheetButton('record_death'.tr, Colors.red.shade600, () async {
                final ok = await controller.updateAnimalLifecycle(
                  animalId: animal.id,
                  action: 'death',
                );
                if (ok) Get.back();
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _sheetButton(String label, Color color, VoidCallback onTap) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: controller.isSubmitting.value ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: controller.isSubmitting.value
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

}
