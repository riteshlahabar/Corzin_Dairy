import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/shop_controller.dart';
import 'shop_checkout_view.dart';

class ShopCartView extends StatelessWidget {
  const ShopCartView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShopController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return const Center(
            child: Text('Your cart is empty', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          children: [
            ...controller.cartItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(item.product.priceLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => controller.decreaseQty(item),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          onPressed: () => controller.increaseQty(item),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      }),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Obx(() => controller.cartItems.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => ShopCheckoutView(items: controller.cartItems.toList())),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: Text('Proceed to Checkout • Rs ${controller.grandTotal.toStringAsFixed(2)}'),
                  ),
                ),
              )),
      ),
    );
  }
}
