import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  RazorpayService._() {
    _attachListeners();
  }

  static final RazorpayService instance = RazorpayService._();
  static const String _merchantName = 'Dairy Corzin';
  static const String _defaultKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
  );

  final Razorpay _razorpay = Razorpay();
  Completer<RazorpayPaymentResult>? _activePayment;
  bool _listenersAttached = false;

  void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<RazorpayPaymentResult> openCheckout({
    required double amount,
    required String description,
    String? keyId,
    String? orderId,
    String? customerName,
    String? contact,
    String? email,
    Map<String, String>? notes,
  }) async {
    final resolvedKey = (keyId ?? _defaultKeyId).trim();
    if (resolvedKey.isEmpty) {
      Get.snackbar('error'.tr, 'razorpay_not_configured'.tr);
      return const RazorpayPaymentResult.failure(
        message: 'Razorpay key is not configured.',
      );
    }

    if (amount <= 0) {
      Get.snackbar('error'.tr, 'valid_amount_required'.tr);
      return const RazorpayPaymentResult.failure(
        message: 'Amount must be greater than zero.',
      );
    }

    if (_activePayment != null && !_activePayment!.isCompleted) {
      Get.snackbar('payment'.tr, 'payment_in_progress'.tr);
      return const RazorpayPaymentResult.failure(
        message: 'Another payment is already in progress.',
      );
    }

    final completer = Completer<RazorpayPaymentResult>();
    _activePayment = completer;

    final normalizedContact =
        contact == null ? '' : contact.replaceAll(RegExp(r'[^0-9]'), '');

    final options = <String, dynamic>{
      'key': resolvedKey,
      'amount': (amount * 100).round(),
      'name': customerName?.trim().isNotEmpty == true
          ? customerName!.trim()
          : _merchantName,
      'description': description.trim(),
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'theme': {'color': '#5FAE2E'},
      'prefill': {
        'contact': normalizedContact,
        'email': email?.trim() ?? '',
      },
      'notes': notes ?? <String, String>{},
    };

    if (orderId?.trim().isNotEmpty == true) {
      options['order_id'] = orderId!.trim();
    }

    try {
      _razorpay.open(options);
    } catch (e, st) {
      debugPrint('Razorpay open error: $e\n$st');
      _complete(
        RazorpayPaymentResult.failure(message: e.toString()),
      );
    }

    return completer.future;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _complete(
      RazorpayPaymentResult.success(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      ),
    );
  }

  void _handleError(PaymentFailureResponse response) {
    final message = response.message?.trim().isNotEmpty == true
        ? response.message!.trim()
        : 'payment_failed_retry'.tr;
    _complete(
      RazorpayPaymentResult.failure(
        code: '${response.code}',
        message: message,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _complete(
      RazorpayPaymentResult.failure(
        message: response.walletName?.trim().isNotEmpty == true
            ? 'External wallet selected: ${response.walletName}'
            : 'payment_cancelled'.tr,
      ),
    );
  }

  void _complete(RazorpayPaymentResult result) {
    final completer = _activePayment;
    if (completer == null || completer.isCompleted) return;
    completer.complete(result);
    _activePayment = null;
  }

  void dispose() {
    _razorpay.clear();
    _listenersAttached = false;
    _activePayment = null;
  }
}

class RazorpayPaymentResult {
  const RazorpayPaymentResult._({
    required this.success,
    required this.paymentId,
    required this.orderId,
    required this.signature,
    required this.message,
    required this.code,
  });

  const RazorpayPaymentResult.success({
    required String paymentId,
    String orderId = '',
    String signature = '',
  }) : this._(
          success: true,
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
          message: '',
          code: '',
        );

  const RazorpayPaymentResult.failure({
    String code = '',
    required String message,
  }) : this._(
          success: false,
          paymentId: '',
          orderId: '',
          signature: '',
          message: message,
          code: code,
        );

  final bool success;
  final String paymentId;
  final String orderId;
  final String signature;
  final String message;
  final String code;

  Map<String, dynamic> toApiPayload() {
    return {
      'payment_gateway': 'razorpay',
      'payment_reference': paymentId,
      'razorpay_payment_id': paymentId,
      'razorpay_order_id': orderId,
      'razorpay_signature': signature,
      'payment_status': success ? 'paid' : 'failed',
      if (code.trim().isNotEmpty) 'payment_error_code': code.trim(),
      if (message.trim().isNotEmpty) 'payment_error_message': message.trim(),
    };
  }
}
