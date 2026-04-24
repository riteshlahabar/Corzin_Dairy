import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
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
        title: Text('shop_my_orders'.tr),
        backgroundColor: Colors.white,
      ),
      body: Obx(() {
        final orders = controller.myOrders;
        if (orders.isEmpty) {
          return Center(
            child: Text('shop_no_orders'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchMyOrders,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            itemCount: orders.length,
            itemBuilder: (_, index) {
              final order = orders[index];
              final date = DateTime.tryParse(order.createdAt);
              final paid = order.paymentStatus.toLowerCase() == 'paid';
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Get.to(() => ShopOrderDetailsView(order: order)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${'shop_order_prefix'.tr} #${order.id}',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date == null ? '-' : DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()),
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                      const SizedBox(height: 6),
                      ...order.items.take(3).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '${item.productName} x ${item.quantity}${item.unit.trim().isEmpty ? '' : ' ${item.unit}'}',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                      if (order.items.length > 3)
                        Text('+${order.items.length - 3} ${'shop_more_items'.tr}', style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${'shop_payment_prefix'.tr}: ${order.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 12.5)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: paid ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              paid ? 'shop_paid_upper'.tr : 'shop_pending_upper'.tr,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: paid ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.grey),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${'shop_total_amount'.tr}: Rs ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
