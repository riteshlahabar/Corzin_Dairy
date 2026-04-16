import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.black,
        title: const Text('Dairy Payment'),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: controller.loadPayments,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _openAddEntrySheet(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (controller.payments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No dairy payment history yet',
                          style: TextStyle(color: AppColors.grey.shade700),
                        ),
                      ),
                    ...controller.payments.map((payment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.dairyName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  payment.amount,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(payment.date),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Payment Pending: ${payment.pendingAmount}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${'status'.tr}: ${payment.status}',
                              style: TextStyle(color: AppColors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  void _openAddEntrySheet(BuildContext context) {
    final dairyController = TextEditingController();
    final amountController = TextEditingController();
    final pendingController = TextEditingController();
    final status = 'Pending'.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Dairy Payment Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dairyController,
                decoration: _input('Dairy Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _input('Amount (Rs)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pendingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _input('Pending Amount (Rs)'),
              ),
              const SizedBox(height: 10),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: status.value,
                  decoration: _input('Status'),
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  ],
                  onChanged: (value) => status.value = value ?? 'Pending',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (dairyController.text.trim().isEmpty ||
                        amountController.text.trim().isEmpty ||
                        pendingController.text.trim().isEmpty) {
                      Get.snackbar('Error', 'Please fill all fields');
                      return;
                    }
                    await controller.addPaymentEntry(
                      dairyName: dairyController.text,
                      amount: 'Rs ${amountController.text.trim()}',
                      pendingAmount: 'Rs ${pendingController.text.trim()}',
                      status: status.value,
                    );
                    Get.back();
                    Get.snackbar(
                      'Success',
                      'Dairy payment entry added',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(() {
      dairyController.dispose();
      amountController.dispose();
      pendingController.dispose();
    });
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }
}
