import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/shop_controller.dart';
import 'shop_order_details_view.dart';

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  late final ShopController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ShopController>();
    controller.fetchMyOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'shop_my_orders'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(() {
        final orders = controller.myOrders;

        // Don't flash "No orders" while the first fetch is still running.
        if (!controller.hasLoadedMyOrders.value && orders.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (orders.isEmpty) {
          // Kept scrollable so pull-to-refresh still works with no orders.
          return RefreshIndicator(
            onRefresh: controller.fetchMyOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Text(
                    'shop_no_orders'.tr,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchMyOrders,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            itemCount: orders.length,
            itemBuilder: (_, index) => _OrderCard(order: orders[index]),
          ),
        );
      }),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }
}

/// One order in the list. Laid out in three bands — a tinted header carrying
/// the order number, date and status; the item preview; and a footer with the
/// payment chip and total — so the eye can scan any one of them down the list.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ShopOrderModel order;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(order.createdAt);
    final paid = order.paymentStatus.toLowerCase() == 'paid';
    final extraItems = order.items.length - 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => ShopOrderDetailsView(order: order)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — status tint carries straight through to the badge so
              // the card's state is readable at a glance while scrolling.
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                color: order.statusColor.withValues(alpha: 0.06),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'shop_order_prefix'.tr} : ${order.id}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.grey),
                              const SizedBox(width: 5),
                              Text(
                                date == null
                                    ? '-'
                                    : DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()),
                                style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: order.statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: order.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: order.statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.take(3).map((item) => _OrderLine(item: item)),
                    if (extraItems > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 4),
                        child: Text(
                          '+$extraItems ${'shop_more_items'.tr}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 20, thickness: 1, color: Color(0xFFF0F3F0)),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.paymentMethod.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: paid
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.orange.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  paid ? 'shop_paid_upper'.tr : 'shop_pending_upper'.tr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: paid ? Colors.green.shade700 : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'shop_total_amount'.tr,
                            style: const TextStyle(fontSize: 11, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.grey),
                  ],
                ),
              ),
              _DeliveryCodeCard(delivery: order.delivery),
            ],
          ),
        ),
      ),
    );
  }
}

/// The handover code for this order, shown only while one is active —
/// relocated here (from the order details screen) so it sits at the bottom
/// of the order's card in the My Orders list instead of requiring a tap
/// into the order to see it.
class _DeliveryCodeCard extends StatefulWidget {
  const _DeliveryCodeCard({required this.delivery});

  final ShopOrderDeliveryModel delivery;

  @override
  State<_DeliveryCodeCard> createState() => _DeliveryCodeCardState();
}

class _DeliveryCodeCardState extends State<_DeliveryCodeCard> {
  Timer? _countdownTimer;

  ShopOrderDeliveryModel get delivery => widget.delivery;

  @override
  void initState() {
    super.initState();
    _syncCountdown();
  }

  @override
  void didUpdateWidget(covariant _DeliveryCodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Ticks once a second only while a code is on screen, so the "expires in"
  /// label counts down instead of the code silently vanishing.
  void _syncCountdown() {
    _countdownTimer?.cancel();
    if (!delivery.isCodeRequested || delivery.codeExpiry == null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Duration? get _remaining {
    final expiry = delivery.codeExpiry;
    if (expiry == null) return null;
    final left = expiry.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final showCode = delivery.isCodeRequested && (remaining == null || remaining > Duration.zero);
    final codeExpired = delivery.isCodeRequested && remaining == Duration.zero;

    if (!showCode && !codeExpired) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: showCode
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    'shop_delivery_code_hint'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Each digit in its own tile — easier to read out loud to
                  // the delivery man than one run of numbers.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: delivery.code!
                        .split('')
                        .map(
                          (digit) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 38,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              digit,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  if (remaining != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppColors.grey),
                        const SizedBox(width: 5),
                        Text(
                          'shop_code_expires_in'.trParams({
                            'time': '${remaining.inMinutes}:'
                                '${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                          }),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                'shop_code_expired'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
              ),
            ),
    );
  }
}

/// A compact preview line for one ordered item, matching the item rows on the
/// Order Details screen: small thumbnail, name, then pack size and quantity.
class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item});

  final ShopOrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final hasPack = item.packSize != null;
    final details = <String>[
      if (item.packLabel.isNotEmpty) item.packLabel,
      // With a pack size the unit already appears in the pack label, and the
      // quantity counts packs — "2 kg" there would read as two kilos.
      if (hasPack)
        '× ${item.quantity}'
      else
        'x ${item.quantity}${item.unit.trim().isEmpty ? '' : ' ${item.unit}'}',
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              width: 30,
              height: 30,
              child: item.image == null
                  ? const _LineImageFallback()
                  : Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _LineImageFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  details,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineImageFallback extends StatelessWidget {
  const _LineImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3EF),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.grey),
    );
  }
}
