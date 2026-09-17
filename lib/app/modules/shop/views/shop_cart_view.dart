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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'shop_cart'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() {
            final count = controller.cartItems.length;
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'shop_cart_item_count'.trParams({'count': '$count'}),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) return const _EmptyCart();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: [
            ...controller.cartItems.map(
              (item) => _CartItemCard(controller: controller, item: item),
            ),
            const SizedBox(height: 4),
            _BillSummary(controller: controller),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => controller.cartItems.isEmpty
            ? const SizedBox.shrink()
            : _CheckoutBar(controller: controller),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'shop_cart_empty'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 190,
              height: 46,
              child: ElevatedButton(
                onPressed: Get.back,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'shop_continue_shopping'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One line in the cart: product thumbnail, name and rate, the unit/strip
/// toggle where it applies, and a pill stepper with the line total beside it.
class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.controller, required this.item});

  final ShopController controller;
  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final image = item.product.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDE8)),
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
                  width: 58,
                  height: 58,
                  child: image.trim().isEmpty
                      ? const _CartImageFallback()
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _CartImageFallback(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      controller.itemPriceLabel(item),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                    if (controller.itemPackLabel(item).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        controller.itemPackLabel(item),
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              // Remove sits away from the stepper so it is hard to hit by
              // accident while changing quantity.
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => controller.removeFromCart(item),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.grey),
                ),
              ),
            ],
          ),
          if (controller.supportsQuantityMode(item)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ModeChip(
                  label: item.product.medicineUnitName.capitalizeFirst ?? 'Unit',
                  selected: item.quantityMode == CartQuantityMode.unit,
                  onTap: controller.canUseUnitMode(item)
                      ? () => controller.updateQuantityMode(item, CartQuantityMode.unit)
                      : null,
                ),
                _ModeChip(
                  label: 'shop_stripe'.tr,
                  selected: item.quantityMode == CartQuantityMode.pack,
                  onTap: () => controller.updateQuantityMode(item, CartQuantityMode.pack),
                ),
              ],
            ),
          ],
          const Divider(height: 22, thickness: 1, color: Color(0xFFF0F3F0)),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onTap: () => controller.decreaseQty(item),
                    ),
                    ConstrainedBox(
                      // Number only — the unit is already on the details line
                      // above, so repeating it here just crowded the stepper.
                      constraints: const BoxConstraints(minWidth: 40),
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onTap: () => controller.increaseQty(item),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'amount_rs'.trParams({
                  'value': controller.lineTotalForItem(item).toStringAsFixed(2),
                }),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFDCE3DC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : (disabled ? Colors.grey.shade400 : AppColors.black),
          ),
        ),
      ),
    );
  }
}

class _CartImageFallback extends StatelessWidget {
  const _CartImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3EF),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, size: 24, color: AppColors.grey),
    );
  }
}

/// Subtotal / delivery / total, so the farmer sees the arithmetic before
/// reaching checkout rather than only a single figure on the button.
class _BillSummary extends StatelessWidget {
  const _BillSummary({required this.controller});

  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDE8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'shop_bill_details'.tr,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF0F3F0)),
          _row('shop_subtotal'.tr, controller.subtotal),
          // Delivery charge is always 0 today, so the row is only rendered if
          // a real charge ever starts coming through.
          if (controller.deliveryCharge > 0) ...[
            const SizedBox(height: 8),
            _row('shop_delivery_charge'.tr, controller.deliveryCharge),
          ],
          const Divider(height: 20, thickness: 1, color: Color(0xFFF0F3F0)),
          Row(
            children: [
              Text(
                'shop_total_amount'.tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                'amount_rs'.trParams({
                  'value': controller.grandTotal.toStringAsFixed(2),
                }),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
        const Spacer(),
        Text(
          'amount_rs'.trParams({'value': value.toStringAsFixed(2)}),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.controller});

  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Equal halves so the total never gets squeezed by a long
              // button label, and vice versa.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'shop_total_amount'.tr,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'amount_rs'.trParams({
                        'value': controller.grandTotal.toStringAsFixed(2),
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.to(
                      () => ShopCheckoutView(
                        items: controller.cartItems.toList(),
                        clearCartOnSuccess: true,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'shop_checkout'.tr,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
