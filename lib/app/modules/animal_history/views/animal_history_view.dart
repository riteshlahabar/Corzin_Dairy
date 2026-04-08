import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                                children: [
                                  SizedBox(height: 120),
                                  const Icon(Icons.history_rounded, size: 48, color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'no_animal_history_found'.tr,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                                                item.animalName.isEmpty ? '-' : item.animalName,
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                item.prettyAction,
                                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('${'tag'.tr}: ${item.tagNumber.isEmpty ? '-' : item.tagNumber}', style: TextStyle(fontSize: 12, color: AppColors.grey.shade700)),
                                        const SizedBox(height: 12),
                                        _row('from_status'.tr, item.fromStatus.isEmpty ? '-' : item.fromStatus),
                                        _row('to_status'.tr, item.toStatus.isEmpty ? '-' : item.toStatus),
                                        _row('from_type'.tr, item.fromAnimalType.isEmpty ? '-' : item.fromAnimalType),
                                        _row('to_type'.tr, item.toAnimalType.isEmpty ? '-' : item.toAnimalType),
                                        if (item.notes.isNotEmpty) _row('notes'.tr, item.notes),
                                        _row('changed_at'.tr, item.changedAt.isEmpty ? '-' : item.changedAt),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: AppColors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
