import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/shop_controller.dart';
import 'shop_order_success_view.dart';

class ShopCheckoutView extends StatefulWidget {
  const ShopCheckoutView({
    super.key,
    required this.items,
  });

  final List<CartItemModel> items;

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
    final subtotal = widget.items.fold<double>(0, (sum, item) => sum + (item.product.price * item.quantity));
    final total = subtotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _block(
            title: 'Delivery Address',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller.addressController,
                  minLines: 2,
                  maxLines: 3,
                  enabled: useDifferentAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter delivery address',
                    filled: true,
                    fillColor: useDifferentAddress ? Colors.white : const Color(0xFFF1F5F1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => useDifferentAddress = !useDifferentAddress),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: Text(useDifferentAddress ? 'Use default address' : 'Add different address'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _block(
            title: 'Payment Method',
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cash on Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('Pay when your order is delivered', style: TextStyle(fontSize: 12, color: AppColors.grey)),
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
            title: 'Order Items',
            child: Column(
              children: widget.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} x ${item.quantity}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('Rs ${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _block(
            title: 'Price Details',
            child: Column(
              children: [
                _priceRow('Subtotal', subtotal),
                _priceRow('Delivery', 0),
                const Divider(),
                _priceRow('Total', total, isBold: true),
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
                        Get.off(() => const ShopOrderSuccessView());
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: controller.isPlacingOrder.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Complete Order'),
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
