import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../../home/controllers/home_controller.dart';

class BuyAnimalView extends GetView<HomeController> {
  const BuyAnimalView({super.key});

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
              padding: EdgeInsets.fromLTRB(
                8,
                MediaQuery.of(context).padding.top + 4,
                8,
                6,
              ),
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
                      'buy_animal'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final items = controller.publicSaleAnimals;
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.fetchSaleAnimals,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(
                          Icons.pets_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'no_animals_available_for_buying'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.fetchSaleAnimals,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _animalCard(item);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _animalCard(HomeSaleAnimalModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 72,
                  width: 72,
                  child: item.image.trim().isEmpty
                      ? Container(
                          color: const Color(0xFFEAF5EC),
                          child: const Icon(
                            Icons.pets_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        )
                      : Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFEAF5EC),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _textOrDash(item.animalName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'tag'.tr}: ${_textOrDash(item.tagNumber)}',
                      style: TextStyle(
                        fontSize: 12.2,
                        color: AppColors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'type'.tr}: ${_textOrDash(item.animalTypeName)}',
                      style: TextStyle(
                        fontSize: 12.2,
                        color: AppColors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('unique_id'.tr, _textOrDash(item.uniqueId)),
              _chip('pan'.tr, _textOrDash(item.panName)),
              _chip('gender'.tr, _textOrDash(item.gender)),
              _chip('age'.tr, _textOrDash(item.age)),
              _chip('weight'.tr, item.weight.trim().isEmpty ? '-' : '${item.weight} Kg'),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => _openDetails(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  'view_more'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _openDetails(HomeSaleAnimalModel item) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 50,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  _textOrDash(item.animalName),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip('unique_id'.tr, _textOrDash(item.uniqueId)),
                    _chip('tag'.tr, _textOrDash(item.tagNumber)),
                    _chip('type'.tr, _textOrDash(item.animalTypeName)),
                    _chip('pan'.tr, _textOrDash(item.panName)),
                    _chip('gender'.tr, _textOrDash(item.gender)),
                    _chip('age'.tr, _textOrDash(item.age)),
                    _chip('birth_date'.tr, _textOrDash(item.birthDate)),
                    _chip('weight'.tr, item.weight.trim().isEmpty ? '-' : '${item.weight} Kg'),
                    _chip('breed_name'.tr, _textOrDash(item.breedName)),
                    _chip('lactation'.tr, _textOrDash(item.lactationNumber)),
                    _chip('ai_date'.tr, _textOrDash(item.aiDate)),
                    _chip('listed_at'.tr, _textOrDash(item.listedAt)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _textOrDash(String value) {
    final v = value.trim();
    return v.isEmpty ? '-' : v;
  }
}
