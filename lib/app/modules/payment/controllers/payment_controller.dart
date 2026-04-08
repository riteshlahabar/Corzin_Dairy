import 'package:get/get.dart';

class PaymentController extends GetxController {
  final RxList<PaymentModel> payments = <PaymentModel>[
    const PaymentModel(
      dairyName: 'Green Valley Dairy',
      amount: '₹12,480',
      date: '01 Apr 2026',
      status: 'Paid',
    ),
    const PaymentModel(
      dairyName: 'Shree Milk Center',
      amount: '₹9,250',
      date: '28 Mar 2026',
      status: 'Paid',
    ),
    const PaymentModel(
      dairyName: 'Sai Dairy Point',
      amount: '₹7,980',
      date: '24 Mar 2026',
      status: 'Pending',
    ),
  ].obs;
}

class PaymentModel {
  final String dairyName;
  final String amount;
  final String date;
  final String status;

  const PaymentModel({
    required this.dairyName,
    required this.amount,
    required this.date,
    required this.status,
  });
}
