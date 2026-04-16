import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/colors.dart';
import '../controllers/animal_history_controller.dart';

class AnimalHistoryView extends GetView<AnimalHistoryController> {
  const AnimalHistoryView({super.key});

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
                      'animal_history'.tr,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                  hintText: 'search_animal_tag_action'.tr,
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
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.fetchHistory,
                        child: controller.filteredHistory.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: const [
                                  SizedBox(height: 120),
                                  Icon(Icons.pets_rounded, size: 48, color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'No animals found',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemCount: controller.filteredHistory.length,
                                itemBuilder: (context, index) {
                                  final item = controller.filteredHistory[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(14),
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _animalImage(item.image),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.animalName.isEmpty ? '-' : item.animalName,
                                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${'tag'.tr}: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}',
                                                    style: TextStyle(fontSize: 12.5, color: AppColors.grey.shade700),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item.animalTypeName.isEmpty ? '-' : item.animalTypeName,
                                                    style: TextStyle(fontSize: 12.5, color: AppColors.grey.shade700),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  onPressed: () => _openEditSheet(item),
                                                  icon: const Icon(Icons.edit_rounded),
                                                  tooltip: 'Edit',
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(height: 2),
                                                item.isForSale
                                                    ? Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange.withValues(alpha: 0.14),
                                                          borderRadius: BorderRadius.circular(99),
                                                        ),
                                                        child: const Text(
                                                          'Selling',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            color: Color(0xFFB25E00),
                                                          ),
                                                        ),
                                                      )
                                                    : SizedBox(
                                                        height: 30,
                                                        child: ElevatedButton(
                                                          onPressed: controller.isSubmitting.value
                                                              ? null
                                                              : () => controller.sellAnimal(item),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: AppColors.primary,
                                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            elevation: 0,
                                                          ),
                                                          child: const Text(
                                                            'Sell',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 11.5,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _row('birth_date'.tr, item.birthDate.isEmpty ? '-' : item.birthDate),
                                        _row('gender'.tr, item.gender.isEmpty ? '-' : item.gender),
                                        _row('weight'.tr, item.weight.isEmpty ? '-' : '${item.weight} Kg'),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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
                  const Text(
                    'Edit Animal',
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
                  _input(nameController, 'Animal Name'),
                  const SizedBox(height: 10),
                  _input(tagController, 'Tag Number'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedTypeId.value == 0 ? null : selectedTypeId.value,
                    decoration: _decoration('Animal Type'),
                    items: controller.animalTypes
                        .map((type) => DropdownMenuItem<int>(value: type.id, child: Text(type.name)))
                        .toList(),
                    onChanged: (value) => selectedTypeId.value = value ?? 0,
                  ),
                  const SizedBox(height: 10),
                  _input(birthDateController, 'Birth Date (dd/MM/yyyy)'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender.value,
                    decoration: _decoration('Gender'),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) => selectedGender.value = value ?? 'Female',
                  ),
                  const SizedBox(height: 10),
                  _input(weightController, 'Weight', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () async {
                              if (selectedTypeId.value == 0) {
                                Get.snackbar('Error', 'Please select animal type');
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
                          : const Text(
                              'Update Animal',
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
