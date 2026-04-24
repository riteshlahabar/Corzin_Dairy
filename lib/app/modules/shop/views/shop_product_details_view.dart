import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/shop_controller.dart';
import 'shop_cart_view.dart';
import 'shop_checkout_view.dart';

class ShopProductDetailsView extends StatelessWidget {
  const ShopProductDetailsView({
    super.key,
    required this.product,
  });

  final ShopProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopController>();
    final images = product.galleryImageUrls.isNotEmpty
        ? product.galleryImageUrls
        : (product.imageUrl.isNotEmpty ? [product.imageUrl] : <String>[]);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const ShopCartView()),
            icon: Obx(
              () => Badge(
                isLabelVisible: controller.cartCount > 0,
                label: Text(controller.cartCount.toString()),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
            tooltip: 'shop_add_to_cart'.tr,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _ImageGallery(images: images),
          const SizedBox(height: 14),
          Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (product.subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(product.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
          ],
          const SizedBox(height: 8),
          Text(product.priceLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (product.unit.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(product.unit, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
          const SizedBox(height: 12),
          if (product.features.isNotEmpty) ...[
            Text('shop_features'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...product.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text('shop_description'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            product.description.trim().isEmpty ? 'shop_no_description'.tr : product.description,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.addToCart(product),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('shop_add_to_cart'.tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(
                      () => ShopCheckoutView(
                        items: [controller.initialCartItemForProduct(product)],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('buy_now'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.primary)),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, index) {
          final image = images[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.image_not_supported_outlined, color: AppColors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
