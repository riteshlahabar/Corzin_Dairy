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

  void _maybeStartPolling() {
    _pollTimer?.cancel();
    final shouldPoll = order.delivery.isAssigned && !order.delivery.isDelivered;
    if (!shouldPoll) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshOrder());
  }

  Future<void> _refreshOrder() async {
    final controller = Get.find<ShopController>();
    final refreshed = await controller.fetchOrderById(order.id);
    if (refreshed == null || !mounted) return;
    setState(() => order = refreshed);
    if (refreshed.delivery.isDelivered || refreshed.status.toLowerCase() == 'completed') {
      _pollTimer?.cancel();
    }
  }

  int _currentStep() {
    final status = order.status.toLowerCase();
    if (status == 'completed') return 3;
    if (status == 'in_progress') return 2;
    return 1;
  }

  String _statusText() {
    final status = order.status.toLowerCase();
    switch (status) {
      case 'in_progress':
        return 'shop_status_in_progress'.tr;
      case 'completed':
        return 'shop_status_delivered'.tr;
      case 'cancelled':
        return 'shop_status_cancelled'.tr;
      default:
        return 'shop_status_order_placed'.tr;
    }
  }

  Future<void> _callSupport() async {
    const supportNumber = '18001234567';
    final launched = await launchUrl(
      Uri.parse('tel:$supportNumber'),
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
        path: 'support@corzin.com',
        query: 'subject=Order Support - #${order.id}',
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
            '${'shop_order_prefix'.tr} #${order.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
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
              padding: const EdgeInsets.all(14),
              children: [
                _TopStatusCard(
                  statusText: _statusText(),
                  paymentStatus: order.paymentStatus,
                  total: order.total,
                  dateLabel: date == null ? '-' : DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'shop_delivery_address'.tr,
                  child: Text(
                    order.shippingAddress.trim().isEmpty ? 'shop_address_not_available'.tr : order.shippingAddress,
                    style: const TextStyle(fontSize: 14, color: AppColors.black),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'shop_ordered_items'.tr,
                  child: Column(
                    children: order.items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  'quantity_with_unit'.trParams({
                                    'qty': '${item.quantity}',
                                    'unit': item.unit.trim().isEmpty ? '' : ' ${item.unit}',
                                  }),
                                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'amount_rs'.trParams({'value': item.lineTotal.toStringAsFixed(2)}),
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _SectionCard(
                  title: 'shop_delivery_timeline'.tr,
                  child: Column(
                    children: [
                      _stepTile('shop_timeline_order_placed'.tr, currentStep >= 1),
                      _stepTile('shop_timeline_in_progress'.tr, currentStep >= 2),
                      _stepTile('shop_timeline_delivered'.tr, currentStep >= 3),
                    ],
                  ),
                ),
                if (order.delivery.isAssigned) ...[
                  const SizedBox(height: 12),
                  _DeliveryCard(delivery: order.delivery),
                ],
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _SectionCard(
                  title: 'shop_need_help'.tr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'shop_support_text'.tr,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.grey),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.call_outlined),
                          label: Text('shop_call_support'.tr),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.email_outlined),
                          label: Text('shop_email_support'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTile(String title, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check : Icons.circle_outlined,
              color: done ? Colors.white : AppColors.grey,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: done ? AppColors.black : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStatusCard extends StatelessWidget {
  const _TopStatusCard({
    required this.statusText,
    required this.paymentStatus,
    required this.total,
    required this.dateLabel,
  });

  final String statusText;
  final String paymentStatus;
  final double total;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final paid = paymentStatus.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: paid ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  paid ? '${'shop_payment_prefix'.tr}: ${'paid'.tr}' : '${'shop_payment_prefix'.tr}: ${'pending'.tr}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: paid ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${'shop_ordered_on'.tr} $dateLabel', style: const TextStyle(fontSize: 12.5, color: AppColors.grey)),
          const SizedBox(height: 5),
          Text('${'shop_total_amount'.tr}: Rs ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
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
    final phone = delivery.deliveryManPhone;
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final showCode = delivery.isCodeRequested;

    return _SectionCard(
      title: 'shop_delivery_partner'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.two_wheeler_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.deliveryManName?.isNotEmpty == true ? delivery.deliveryManName! : 'shop_delivery_partner'.tr,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      delivery.deliveryManPhone ?? '',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _callDeliveryMan,
                icon: const Icon(Icons.call, color: AppColors.primary),
              ),
            ],
          ),
          if (showCode) ...[
            const SizedBox(height: 14),
            Container(
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
                  Text(
                    delivery.code!.splitMapJoin('', onNonMatch: (c) => '$c '),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'shop_waiting_for_delivery_man'.tr,
              style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
