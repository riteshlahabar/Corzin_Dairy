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
    final subtotal = widget.items.fold<double>(
      0,
      (sum, item) => sum + controller.lineTotalForItem(item),
    );
    final total = subtotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'shop_checkout'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _block(
            title: 'shop_delivery_address'.tr,
            icon: Icons.location_on_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller.addressController,
                  minLines: 2,
                  maxLines: 3,
                  enabled: useDifferentAddress,
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                  decoration: InputDecoration(
                    hintText: 'shop_enter_delivery_address'.tr,
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey),
                    filled: true,
                    fillColor: useDifferentAddress
                        ? Colors.white
                        : const Color(0xFFF4F7F4),
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDCE3DC)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8EDE8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(
                      () => useDifferentAddress = !useDifferentAddress,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            useDifferentAddress
                                ? Icons.undo_rounded
                                : Icons.edit_location_alt_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            useDifferentAddress
                                ? 'shop_use_default_address'.tr
                                : 'shop_add_different_address'.tr,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _block(
            title: 'shop_payment_method'.tr,
            icon: Icons.account_balance_wallet_rounded,
            child: Obx(
              () => Column(
                children: [
                  _paymentMethodTile(
                    value: ShopPaymentMethod.cod,
                    icon: Icons.payments_rounded,
                    title: 'shop_cash_on_delivery'.tr,
                    subtitle: 'shop_pay_on_delivery'.tr,
                  ),
                  const SizedBox(height: 10),
                  _paymentMethodTile(
                    value: ShopPaymentMethod.razorpay,
                    icon: Icons.credit_card_rounded,
                    title: 'shop_razorpay'.tr,
                    subtitle: 'shop_pay_online'.tr,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _block(
            title: 'shop_order_items'.tr,
            icon: Icons.inventory_2_rounded,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.items.length}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            child: Column(
              children: widget.items.map(_checkoutItemRow).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _block(
            title: 'shop_price_details'.tr,
            icon: Icons.receipt_long_rounded,
            child: Column(
              children: [
                _priceRow('shop_subtotal'.tr, subtotal),
                const Divider(height: 20, thickness: 1, color: Color(0xFFF0F3F0)),
                _priceRow('shop_total_amount'.tr, total, isBold: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
            // Full-width action button, as it was before — the total is already
            // shown in the Price Details card just above.
            child: Obx(
              () => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isPlacingOrder.value
                      ? null
                      : () async {
                          final ok = await controller.checkoutOrder(
                            directItems: widget.items,
                          );
                          if (!mounted || !ok) return;
                          if (widget.clearCartOnSuccess) {
                            controller.cartItems.clear();
                          }
                          Get.off(() => const ShopOrderSuccessView());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: controller.isPlacingOrder.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          controller.selectedPaymentMethod.value ==
                                  ShopPaymentMethod.razorpay
                              ? 'shop_pay_now'.tr
                              : 'shop_complete_order'.tr,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Matches the item rows on Order Details — thumbnail, name, then a quiet
  /// line with the rate and quantity.
  Widget _checkoutItemRow(CartItemModel item) {
    final image = item.product.imageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: image.trim().isEmpty
                  ? const _CheckoutImageFallback()
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _CheckoutImageFallback(),
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
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${controller.itemRateLabel(item)}  ·  ${controller.itemQuantityLabel(item)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'amount_rs'.trParams({
              'value': controller.lineTotalForItem(item).toStringAsFixed(2),
            }),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  /// Shared panel for every checkout section, matching the Order Details cards.
  Widget _block({
    required String title,
    required Widget child,
    IconData? icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF0F3F0)),
          child,
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? AppColors.black : AppColors.grey,
              ),
            ),
          ),
          Text(
            'amount_rs'.trParams({'value': value.toStringAsFixed(2)}),
            style: TextStyle(
              fontSize: isBold ? 17 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isBold ? AppColors.primary : AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = controller.selectedPaymentMethod.value == value;

    return InkWell(
      onTap: () => controller.selectedPaymentMethod.value = value,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFDCE3DC),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: selected ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : const Color(0xFFC5D0C5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutImageFallback extends StatelessWidget {
  const _CheckoutImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3EF),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.grey),
    );
  }
}
