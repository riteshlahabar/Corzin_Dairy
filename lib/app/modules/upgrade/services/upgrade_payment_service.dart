import 'package:get/get.dart';

import '../../../core/services/razorpay_service.dart';
import '../models/plan_model.dart';
import '../repositories/upgrade_repository.dart';
import 'upgrade_action_result.dart';
import 'upgrade_home_subscription_service.dart';

class UpgradePaymentService {
  const UpgradePaymentService({
    UpgradeRepository repository = const UpgradeRepository(),
    UpgradeHomeSubscriptionService homeSubscriptionService =
        const UpgradeHomeSubscriptionService(),
  }) : _repository = repository,
       _homeSubscriptionService = homeSubscriptionService;

  final UpgradeRepository _repository;
  final UpgradeHomeSubscriptionService _homeSubscriptionService;

  Future<UpgradeActionResult> purchasePlan({
    required int farmerId,
    required String farmerName,
    required String mobileNumber,
    required PlanModel plan,
  }) async {
    if (plan.amount <= 0) {
      return const UpgradeActionResult(
        success: false,
        titleKey: 'info',
        message: 'free_plan_no_payment',
      );
    }
    if (farmerId <= 0) {
      return const UpgradeActionResult(
        success: false,
        titleKey: 'error',
        message: 'please_login_again',
      );
    }

    final orderResult = await _repository.createSubscriptionOrder(
      farmerId: farmerId,
      planId: plan.id,
    );
    final order = orderResult.data;
    if (!orderResult.success || order == null || !order.isValid) {
      return UpgradeActionResult(
        success: false,
        titleKey: 'payment',
        message: orderResult.message.isNotEmpty
            ? orderResult.message
            : 'Unable to create payment order.',
      );
    }

    final paymentResult = await RazorpayService.instance.openCheckout(
      amount: order.amount,
      keyId: order.keyId,
      orderId: order.orderId,
      customerName: farmerName,
      contact: mobileNumber,
      description: 'Subscription - ${plan.name.tr}',
      notes: {
        'flow': 'subscription',
        'farmer_id': '$farmerId',
        'plan_id': '${plan.id}',
      },
    );

    if (!paymentResult.success) {
      final message = paymentResult.message.trim();
      return UpgradeActionResult(
        success: false,
        titleKey: 'payment',
        message: message,
        showMessage: message.isNotEmpty && message != 'payment_cancelled'.tr,
      );
    }

    final paymentMeta = paymentResult.toApiPayload();
    if ((paymentMeta['razorpay_order_id'] ?? '').toString().trim().isEmpty) {
      paymentMeta['razorpay_order_id'] = order.orderId;
    }

    final saved = await _repository.saveSubscriptionPurchase(
      farmerId: farmerId,
      plan: plan,
      paymentMeta: paymentMeta,
    );

    if (!saved) {
      return const UpgradeActionResult(
        success: false,
        titleKey: 'info',
        message: 'subscription_activation_pending',
      );
    }

    await _homeSubscriptionService.refreshHomeSubscription();
    return const UpgradeActionResult(
      success: true,
      titleKey: 'success',
      message: 'subscription_payment_success',
      navigateHome: true,
    );
  }
}
