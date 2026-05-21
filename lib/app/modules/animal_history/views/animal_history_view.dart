import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../../routes/app_pages.dart';
import '../../feeding/views/feeding_history_view.dart';
import '../../milk/views/milk_history_view.dart';
import '../controllers/animal_history_controller.dart';

class AnimalHistoryView extends GetView<AnimalHistoryController> {
  const AnimalHistoryView({super.key, this.onlyForSale = false});

  final bool onlyForSale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
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
                      onlyForSale ? 'animal_for_sale'.tr : 'animal_list'.tr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'search_animal_tag_action'.tr,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
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
            Expanded(
              child: Obx(
                () {
                  final items = onlyForSale
                      ? controller.filteredHistory.where((item) => item.isForSale).toList()
                      : controller.filteredHistory;
                  return controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.fetchHistory,
                        child: items.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  SizedBox(height: 120),
                                  Icon(Icons.pets_rounded, size: 48, color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'no_animals_found'.tr,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _animalCard(item);
                                },
                              ),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _animalCard(AnimalHistoryItem item) {
    final statusText = item.isForSale
        ? 'status_selling'.tr
        : (item.isActive ? item.lifecycleStatus.capitalizeFirst ?? 'active'.tr : 'status_inactive'.tr);
    final statusColor = item.isForSale
        ? const Color(0xFFB25E00)
        : (item.isActive ? AppColors.primary : Colors.redAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animalImage(item.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.animalName.isEmpty ? '-' : item.animalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusPill(statusText, statusColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _miniChip(Icons.confirmation_number_outlined, item.uniqueId.isEmpty ? '-' : item.uniqueId),
                        _miniChip(Icons.sell_outlined, '${'tag'.tr}: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}'),
                        _miniChip(Icons.category_outlined, item.animalTypeName.isEmpty ? '-' : item.animalTypeName),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailTile('pan'.tr.toUpperCase(), item.panName.isEmpty ? '-' : item.panName, Icons.grid_view_rounded),
              _detailTile('gender'.tr, item.gender.isEmpty ? '-' : item.gender, Icons.female_rounded),
              _detailTile('birth_date'.tr, item.birthDate.isEmpty ? '-' : item.birthDate, Icons.cake_rounded),
              _detailTile('purchase_date'.tr, item.purchaseDate.isEmpty ? '-' : item.purchaseDate, Icons.shopping_bag_outlined),
              _detailTile('age'.tr, item.age.isEmpty ? '-' : item.age, Icons.timelapse_rounded),
              _detailTile('weight'.tr, item.weight.isEmpty ? '-' : '${item.weight} Kg', Icons.monitor_weight_outlined),
              _detailTile('breed'.tr, item.breedName.isEmpty ? '-' : item.breedName, Icons.pets_rounded),
              _detailTile('lactation'.tr, item.lactationNumber.isEmpty ? '-' : item.lactationNumber, Icons.local_drink_rounded),
              _detailTile('ai_date'.tr, item.aiDate.isEmpty ? '-' : item.aiDate, Icons.calendar_month_rounded),
              _detailTile('mother'.tr, item.motherLabel.isEmpty ? '-' : item.motherLabel, Icons.family_restroom_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: 'view_all'.tr,
                  icon: Icons.visibility_rounded,
                  onTap: () => _openViewAllHistorySheet(item),
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              _squareActionButton(
                icon: Icons.edit_rounded,
                color: AppColors.primary,
                onTap: () => _openEditSheet(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.black),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _detailTile(String label, String value, IconData icon) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: AppColors.grey.shade700, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool filled = false,
    Color color = AppColors.primary,
  }) {
    return SizedBox(
      height: 40,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 16, color: Colors.white),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 16),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.35)),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
    );
  }

  Widget _squareActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 40,
        width: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _animalImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 72,
        width: 72,
        child: imageUrl.isEmpty
            ? _imageFallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _imageFallback(),
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

  void _openViewAllHistorySheet(AnimalHistoryItem item) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.animalName.isEmpty ? 'animal_history'.tr : '${item.animalName} ${'history'.tr}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _historyActionTile(
                icon: Icons.pets_rounded,
                title: 'animal_history'.tr,
                subtitle: 'current_animal_lifecycle_details'.tr,
                onTap: Get.back,
              ),
              _historyActionTile(
                icon: Icons.local_drink_rounded,
                title: 'milk_record'.tr,
                subtitle: 'open_milk_records_page'.tr,
                onTap: () {
                  Get.back();
                  Get.to(() => const MilkHistoryView());
                },
              ),
              _historyActionTile(
                icon: Icons.grass_rounded,
                title: 'feeding_record'.tr,
                subtitle: 'open_feeding_records_page'.tr,
                onTap: () {
                  Get.back();
                  Get.to(() => const FeedingHistoryView());
                },
              ),
              _historyActionTile(
                icon: Icons.local_hospital_rounded,
                title: 'treatment_history'.tr,
                subtitle: 'open_doctor_history_tab'.tr,
                onTap: () {
                  Get.back();
                  Get.toNamed(
                    Routes.DOCTOR,
                    arguments: {'initial_tab': 2},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.grey.shade700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  void _openEditSheet(AnimalHistoryItem item) {
    final nameController = TextEditingController(text: item.animalName);
    final tagController = TextEditingController(text: item.tagNumber);
    final birthDateController = TextEditingController(text: item.birthDate);
    final weightController = TextEditingController(text: item.weight);
    final selectedGender = (item.gender.isEmpty ? 'Female' : item.gender).obs;
    final selectedTypeId = item.animalTypeId.obs;
    final selectedImage = Rxn<XFile>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'edit_animal'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: () async {
                        final file = await controller.pickAnimalPhoto();
                        if (file != null) selectedImage.value = file;
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(42),
                        child: SizedBox(
                          height: 84,
                          width: 84,
                          child: selectedImage.value != null
                              ? Image.file(File(selectedImage.value!.path), fit: BoxFit.cover)
                              : (item.image.isNotEmpty
                                  ? Image.network(
                                      item.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _imageFallback(),
                                    )
                                  : _imageFallback()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _input(nameController, 'animal_name_label'.tr),
                  const SizedBox(height: 10),
                  _input(tagController, 'tag_number_label'.tr),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedTypeId.value == 0 ? null : selectedTypeId.value,
                    decoration: _decoration('animal_type_label'.tr),
                    items: controller.animalTypes
                        .map((type) => DropdownMenuItem<int>(value: type.id, child: Text(type.name)))
                        .toList(),
                    onChanged: (value) => selectedTypeId.value = value ?? 0,
                  ),
                  const SizedBox(height: 10),
                  _input(birthDateController, 'birth_date_ddmmyyyy'.tr),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender.value,
                    decoration: _decoration('gender'.tr),
                    items: [
                      DropdownMenuItem(value: 'Male', child: Text('male'.tr)),
                      DropdownMenuItem(value: 'Female', child: Text('female'.tr)),
                    ],
                    onChanged: (value) => selectedGender.value = value ?? 'Female',
                  ),
                  const SizedBox(height: 10),
                  _input(weightController, 'weight'.tr, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () async {
                              if (selectedTypeId.value == 0) {
                                Get.snackbar('error'.tr, 'please_select_animal_type'.tr);
                                return;
                              }
                              final ok = await controller.updateAnimal(
                                item: item,
                                animalName: nameController.text,
                                tagNumber: tagController.text,
                                animalTypeId: selectedTypeId.value,
                                birthDate: birthDateController.text,
                                gender: selectedGender.value,
                                weight: weightController.text,
                                imageFile: selectedImage.value,
                              );
                              if (ok) Get.back();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(
                              'update_animal'.tr,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
    ).whenComplete(() {
      nameController.dispose();
      tagController.dispose();
      birthDateController.dispose();
      weightController.dispose();
    });
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decoration(hint),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
