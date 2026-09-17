import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../controllers/shop_controller.dart';

class ShopOrderDetailsView extends StatefulWidget {
  const ShopOrderDetailsView({
    super.key,
    required this.order,
  });

  final ShopOrderModel order;

  @override
  State<ShopOrderDetailsView> createState() => _ShopOrderDetailsViewState();
}

class _ShopOrderDetailsViewState extends State<ShopOrderDetailsView> {
  late ShopOrderModel order;
  Timer? _pollTimer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    order = widget.order;
    _maybeStartPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Polls while the order is still moving. It used to require the order to be
  /// assigned already, so an order opened before assignment never started
  /// polling; now any open order polls until it is delivered or cancelled.
  void _maybeStartPolling() {
    _pollTimer?.cancel();
    final status = order.status.toLowerCase();
    final finished = order.delivery.isDelivered ||
        status == 'completed' ||
        status == 'cancelled';
    if (finished) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshOrder());
  }

  Future<void> _refreshOrder() async {
    final controller = Get.find<ShopController>();
    final refreshed = await controller.fetchOrderById(order.id);
    if (refreshed == null || !mounted) return;
    setState(() => order = refreshed);
    final status = refreshed.status.toLowerCase();
    if (refreshed.delivery.isDelivered || status == 'completed' || status == 'cancelled') {
      _pollTimer?.cancel();
    }
  }

  // Step and label both come from ShopOrderModel so My Orders and this screen
  // always agree on what an order's status is called.
  int _currentStep() => order.timelineStep;

  String _statusText() => order.statusLabel;

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('shop_cancel_order'.tr),
        content: Text('shop_cancel_order_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('no'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('shop_cancel_order'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final controller = Get.find<ShopController>();
    final error = await controller.cancelOrder(order.id);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Pull the cancelled order back so the badge, timeline and button all
    // reflect the new state without leaving the screen.
    await _refreshOrder();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('shop_order_cancelled'.tr)));
  }

  Future<void> _callSupport() async {
    final launched = await launchUrl(
      Uri.parse('tel:${order.support.phone}'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Unable to open dialer');
    }
  }

  Future<void> _emailSupport() async {
    final launched = await launchUrl(
      Uri(
        scheme: 'mailto',
        path: order.support.email,
        query: 'subject=Order Support - Order : ${order.id}',
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Unable to open email app');
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(order.createdAt);
    final currentStep = _currentStep();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF7),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            '${'shop_order_prefix'.tr} : ${order.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: 'shop_order_details'.tr),
              Tab(text: 'shop_delivery_status'.tr),
              Tab(text: 'shop_contact_us'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _TopStatusCard(
                  statusText: _statusText(),
                  statusColor: order.statusColor,
                  paymentStatus: order.paymentStatus,
                  paymentMethod: order.paymentMethod,
                  total: order.total,
                  dateLabel: date == null ? '-' : DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'shop_delivery_address'.tr,
                  icon: Icons.location_on_rounded,
                  child: Text(
                    order.shippingAddress.trim().isEmpty ? 'shop_address_not_available'.tr : order.shippingAddress,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.black),
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'shop_ordered_items'.tr,
                  icon: Icons.inventory_2_rounded,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${order.items.length}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      ...order.items.map((item) => _OrderItemRow(item: item)),
                      const Divider(height: 20, thickness: 1, color: Color(0xFFF0F3F0)),
                      Row(
                        children: [
                          Text(
                            'shop_total_amount'.tr,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            'Rs ${order.total.toStringAsFixed(2)}',
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
                ),
                // Cancel sits at the very bottom, below the items, so it is a
                // deliberate action rather than something tapped on arrival.
                if (order.canFarmerCancel) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isCancelling ? null : _confirmCancel,
                      icon: _isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        'shop_cancel_order'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'shop_cancel_order_hint'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                  ),
                ],
              ],
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _SectionCard(
                  title: 'shop_delivery_timeline'.tr,
                  icon: Icons.local_shipping_rounded,
                  child: Column(
                    children: [
                      _stepTile('shop_timeline_order_placed'.tr, 1, currentStep,
                          order.delivery.placedAt, Icons.receipt_long_rounded),
                      _stepTile('shop_timeline_preparing'.tr, 2, currentStep,
                          order.delivery.assignedAt, Icons.inventory_rounded),
                      _stepTile('shop_timeline_out_for_delivery'.tr, 3, currentStep,
                          order.delivery.departedAt, Icons.local_shipping_rounded),
                      _stepTile('shop_timeline_delivered'.tr, 4, currentStep,
                          order.delivery.deliveredAt, Icons.home_rounded,
                          isLast: true),
                    ],
                  ),
                ),
                if (order.delivery.isAssigned) ...[
                  const SizedBox(height: 14),
                  _DeliveryCard(delivery: order.delivery),
                ],
              ],
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                // Hero panel: a support agent avatar over a soft green wash, so
                // the tab reads as "someone will help you" rather than a form.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.16),
                        AppColors.primary.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          size: 34,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'shop_need_help'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'shop_support_text'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.grey),
                      ),
                      if (order.support.name != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                order.support.name!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ContactTile(
                  icon: Icons.call_rounded,
                  color: AppColors.primary,
                  title: 'shop_call_support'.tr,
                  subtitle: order.support.phone,
                  onTap: () async {
                    try {
                      await _callSupport();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('shop_unable_dialer'.tr)),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                _ContactTile(
                  icon: Icons.mail_rounded,
                  color: const Color(0xFF1565C0),
                  title: 'shop_email_support'.tr,
                  subtitle: order.support.email,
                  onTap: () async {
                    try {
                      await _emailSupport();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('shop_unable_email'.tr)),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// One timeline step. [step] is this row's position and [currentStep] how far
  /// the order has got, so the row the order is *on* can be highlighted rather
  /// than looking identical to the ones already behind it. The connector line
  /// is drawn by the row above the last one.
  /// One timeline step. [step] is this row's position and [currentStep] how far
  /// the order has got, so the row the order is *on* can be highlighted rather
  /// than looking identical to the ones already behind it. The connector line
  /// is drawn by every row except the last.
  Widget _stepTile(
    String title,
    int step,
    int currentStep,
    DateTime? at,
    IconData icon, {
    bool isLast = false,
  }) {
    final done = currentStep >= step;
    final isCurrent = currentStep == step;
    final reached = currentStep > step;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : const Color(0xFFF1F4F1),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.30),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  reached ? Icons.check_rounded : icon,
                  color: done ? Colors.white : AppColors.grey,
                  size: 18,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: reached ? AppColors.primary : const Color(0xFFE6EBE6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: done ? AppColors.black : AppColors.grey,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'shop_timeline_current'.tr,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    at != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(at)
                        : 'shop_timeline_pending'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: at != null ? AppColors.grey : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero card at the top of the Order Details tab: a status-tinted gradient
/// panel carrying the state, the amount and how it was paid, so the three
/// things a farmer checks first are readable without scrolling.
class _TopStatusCard extends StatelessWidget {
  const _TopStatusCard({
    required this.statusText,
    required this.statusColor,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.total,
    required this.dateLabel,
  });

  final String statusText;
  final Color statusColor;
  final String paymentStatus;
  final String paymentMethod;
  final double total;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final paid = paymentStatus.toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.14),
            statusColor.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: paid ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      paid ? 'paid'.tr : 'pending'.tr,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: paid ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'shop_total_amount'.tr,
            style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            'Rs ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${'shop_ordered_on'.tr} $dateLabel',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                paymentMethod.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One ordered line: thumbnail, product name, then a quiet detail line with
/// pack size, quantity and unit price. The old single-row layout put all of
/// that on one line and squeezed badly on small phones.
class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

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
        'quantity_with_unit'.trParams({
          'qty': '${item.quantity}',
          'unit': item.unit.trim().isEmpty ? '' : ' ${item.unit}',
        }),
      if (item.price > 0)
        'amount_rs'.trParams({'value': item.price.toStringAsFixed(2)}),
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 50,
              height: 50,
              child: item.image == null
                  ? const _ItemImageFallback()
                  : Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ItemImageFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'amount_rs'.trParams({'value': item.lineTotal.toStringAsFixed(2)}),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ItemImageFallback extends StatelessWidget {
  const _ItemImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3EF),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.grey),
    );
  }
}

/// A tappable support channel: coloured icon tile, what it is, and the actual
/// number or address underneath so the farmer can see it before tapping.
class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 15, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The panel every block on this screen sits in: soft border, gentle shadow,
/// and a titled header with an optional leading icon so sections are easy to
/// tell apart while scrolling.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final ShopOrderDeliveryModel delivery;

  Future<void> _callDeliveryMan() async {
    final phone = deliveryManPhone;
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication);
  }

  String? get deliveryManPhone => delivery.deliveryManPhone;

  /// A delivered order must never read as "waiting for the delivery man".
  String _waitingText() {
    if (delivery.isDelivered) {
      final at = delivery.deliveredAt;
      if (at == null) return 'shop_delivered_done'.tr;
      return 'shop_delivered_on'.trParams({
        'date': DateFormat('dd MMM yyyy, hh:mm a').format(at),
      });
    }
    if (delivery.isOutForDelivery) return 'shop_on_the_way'.tr;
    return 'shop_waiting_for_delivery_man'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'shop_delivery_partner'.tr,
      icon: Icons.person_pin_circle_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.deliveryManName?.isNotEmpty == true
                            ? delivery.deliveryManName!
                            : 'shop_delivery_partner'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        delivery.deliveryManPhone ?? '',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                // Filled button rather than a bare icon — calling the delivery
                // man is the one action on this card.
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _callDeliveryMan,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.call_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // The handover code itself now lives on the My Orders card, not
          // here — this card only shows who is delivering and a status line.
          const SizedBox(height: 10),
          Text(
            _waitingText(),
            style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
