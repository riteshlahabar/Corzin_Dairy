class RazorpayOrderModel {
  const RazorpayOrderModel({
    required this.keyId,
    required this.orderId,
    required this.amount,
  });

  final String keyId;
  final String orderId;
  final double amount;

  bool get isValid => keyId.isNotEmpty && orderId.isNotEmpty && amount > 0;

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderModel(
      keyId: json['key_id']?.toString().trim() ?? '',
      orderId: json['order_id']?.toString().trim() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    );
  }
}
