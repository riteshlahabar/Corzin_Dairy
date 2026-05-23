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
                      _priceText(item.sellingPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_textOrDash(item.animalName)} (${_textOrDash(item.uniqueId)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
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
              _chip('age'.tr, _textOrDash(item.age)),
              _chip('milk_production'.tr, _milkText(item.dailyMilkProduction)),
            ],
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

  String _textOrDash(String value) {
    final v = value.trim();
    return v.isEmpty ? '-' : v;
  }

  String _milkText(String value) {
    final v = value.trim();
    if (v.isEmpty || v == 'null') return '-';
    return '$v L/day';
  }

  String _priceText(String value) {
    final v = value.trim();
    if (v.isEmpty || v == 'null') return '-';
    return 'Rs $v';
  }
}
