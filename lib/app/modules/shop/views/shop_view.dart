import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/shop_controller.dart';

class ShopView extends GetView<ShopController> {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF7),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'shop'.tr,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search product, category, description',
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
                    : Row(
                        children: [
                          Container(
                            width: 82,
                            margin: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListView.builder(
                              itemCount: controller.categories.length,
                              itemBuilder: (context, index) {
                                final category = controller.categories[index];
                                final selected = category == controller.selectedCategory.value;
                                return InkWell(
                                  onTap: () => controller.selectedCategory.value = category,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    margin: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 36,
                                          width: 36,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.primary
                                                : AppColors.grey.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _categoryIcon(category),
                                            size: 18,
                                            color: selected ? Colors.white : AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _categoryLabel(category),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: selected
                                                ? AppColors.primary
                                                : AppColors.grey.shade800,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: controller.filteredProducts.isEmpty
                                ? ListView(
                                    padding: const EdgeInsets.only(right: 16, bottom: 16),
                                    children: const [
                                      SizedBox(height: 140),
                                      Icon(Icons.storefront_outlined, size: 48, color: AppColors.primary),
                                      SizedBox(height: 12),
                                      Center(
                                        child: Text(
                                          'No shop products found',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.only(right: 16, bottom: 16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 0.56,
                                    ),
                                    itemCount: controller.filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final item = controller.filteredProducts[index];
                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 96,
                                              decoration: BoxDecoration(
                                                color: AppColors.grey.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.shopping_bag_outlined,
                                                  size: 30,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    item.category.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item.price,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.black,
                                              ),
                                            ),
                                            if (item.unit.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.unit,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.grey.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              item.subtitle.isEmpty ? item.description : item.subtitle,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.grey.shade700,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'all':
        return Icons.apps_rounded;
      case 'feed':
        return Icons.shopping_basket_outlined;
      case 'supplements':
        return Icons.spa_outlined;
      case 'medicine':
        return Icons.medication_outlined;
      case 'equipment':
        return Icons.agriculture_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'all':
        return 'All';
      case 'feed':
        return 'Feed';
      case 'supplements':
        return 'Supp';
      case 'medicine':
        return 'Meds';
      case 'equipment':
        return 'Tools';
      default:
        return category.length > 6 ? category.substring(0, 6) : category;
    }
  }
}
