import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/shop_controller.dart';
import 'shop_order_success_view.dart';

class ShopCheckoutView extends StatefulWidget {
  const ShopCheckoutView({
    super.key,
    required this.items,
    this.clearCartOnSuccess = false,
  });

  final List<CartItemModel> items;
  final bool clearCartOnSuccess;

  @override
  State<ShopCheckoutView> createState() => _ShopCheckoutViewState();
}

class _ShopCheckoutViewState extends State<ShopCheckoutView> {
  late final ShopController controller;
  bool useDifferentAddress = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ShopController>();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<double>(0, (sum, item) => sum + controller.lineTotalForItem(item));
    final total = subtotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: Text('shop_checkout'.tr),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _block(
            title: 'shop_delivery_address'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller.addressController,
                  minLines: 2,
                  maxLines: 3,
                  enabled: useDifferentAddress,
                  decoration: InputDecoration(
                    hintText: 'shop_enter_delivery_address'.tr,
                    filled: true,
                    fillColor: useDifferentAddress ? Colors.white : const Color(0xFFF1F5F1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => useDifferentAddress = !useDifferentAddress),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: Text(useDifferentAddress ? 'shop_use_default_address'.tr : 'shop_add_different_address'.tr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _block(
            title: 'shop_payment_method'.tr,
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.selectedPaymentMethod.value == 'cod'
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('shop_cash_on_delivery'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('shop_pay_on_delivery'.tr, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _block(
            title: 'shop_order_items'.tr,
            child: Column(
              children: widget.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.product.name} x ${controller.itemQuantityLabel(item)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                if (item.product.hasPackPricing)
                                  Text(
                                    controller.itemRateLabel(item),
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Text('Rs ${controller.lineTotalForItem(item).toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _block(
            title: 'shop_price_details'.tr,
            child: Column(
              children: [
                _priceRow('shop_subtotal'.tr, subtotal),
                _priceRow('shop_delivery'.tr, 0),
                const Divider(),
                _priceRow('shop_total_amount'.tr, total, isBold: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Obx(
            () => SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isPlacingOrder.value
                    ? null
                    : () async {
                        final ok = await controller.placeOrder(directItems: widget.items);
                        if (!mounted || !ok) return;
                        if (widget.clearCartOnSuccess) {
                          controller.cartItems.clear();
                        }
                        Get.off(() => const ShopOrderSuccessView());
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: controller.isPlacingOrder.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text('shop_complete_order'.tr),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _block({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool isBold = false}) {
    final style = TextStyle(
      fontSize: 13.5,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('Rs ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
