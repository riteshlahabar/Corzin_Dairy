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
                    ...controller.payments.map((payment) => _paymentCard(payment)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _paymentCard(PaymentDairySummary summary) {
    final latest = summary.latest;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 170),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.dairyName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (latest == null)
            Text(
              'No payment entry yet.',
              style: TextStyle(color: AppColors.grey.shade700),
            )
          else ...[
            Text(
              'Date: ${latest.date}',
              style: TextStyle(color: AppColors.grey.shade800, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Total Amount: ${_inr(latest.totalAmount)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Paid Amount: ${_inr(latest.paidAmount)}',
              style: TextStyle(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Balance: ${_inr(latest.balanceAmount)}',
              style: TextStyle(
                color: latest.balanceAmount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () => _openHistorySheet(summary),
              child: const Text('View More'),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddEntrySheet(BuildContext context) {
    if (controller.dairyOptions.isEmpty) {
      Get.snackbar('Error', 'No dairy found. Please add dairy first.');
      return;
    }

    final totalController = TextEditingController();
    final paidController = TextEditingController();
    final notesController = TextEditingController();
    final selectedDairy = Rxn<PaymentDairyOption>(controller.dairyOptions.first);
    final previousBalance = controller.previousBalanceForDairy(selectedDairy.value!.id).obs;
    final balancePreview = previousBalance.value.obs;

    void recalc() {
      final total = _toDouble(totalController.text);
      final paid = _toDouble(paidController.text);
      final dairy = selectedDairy.value;
      if (dairy == null) {
        balancePreview.value = 0;
        return;
      }
      previousBalance.value = controller.previousBalanceForDairy(dairy.id);
      balancePreview.value = controller.previewBalance(
        dairyId: dairy.id,
        totalAmount: total,
        paidAmount: paid,
      );
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Dairy Payment Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<PaymentDairyOption>(
                    initialValue: selectedDairy.value,
                    decoration: _input('Dairy Name'),
                    items: controller.dairyOptions
                        .map(
                          (item) => DropdownMenuItem<PaymentDairyOption>(
                            value: item,
                            child: Text(item.dairyName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      selectedDairy.value = value;
                      recalc();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => recalc(),
                  decoration: _input('Total Amount (Rs)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => recalc(),
                  decoration: _input('Paid Amount (Rs)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: _input('Notes'),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAF7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Previous Balance: ${_inr(previousBalance.value)}',
                          style: TextStyle(
                            color: AppColors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Balance Amount: ${_inr(balancePreview.value)}',
                          style: TextStyle(
                            color: balancePreview.value > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              final dairy = selectedDairy.value;
                              if (dairy == null) {
                                Get.snackbar('Error', 'Please select dairy name');
                                return;
                              }
                              final total = _toDouble(totalController.text);
                              final paid = _toDouble(paidController.text);
                              if (total <= 0) {
                                Get.snackbar('Error', 'Please enter valid total amount');
                                return;
                              }
                              if (paid < 0) {
                                Get.snackbar('Error', 'Please enter valid paid amount');
                                return;
                              }

                              try {
                                await controller.addPaymentEntry(
                                  dairyId: dairy.id,
                                  totalAmount: total,
                                  paidAmount: paid,
                                  notes: notesController.text,
                                );
                                Get.back();
                                Get.snackbar(
                                  'Success',
                                  'Dairy payment entry added',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  e.toString().replaceFirst('Exception: ', ''),
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Entry'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(() {
      totalController.dispose();
      paidController.dispose();
      notesController.dispose();
    });
  }

  void _openHistorySheet(PaymentDairySummary summary) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.72,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${summary.dairyName} - Payment History',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: summary.history.isEmpty
                    ? Center(
                        child: Text(
                          'No payment entries available.',
                          style: TextStyle(color: AppColors.grey.shade700),
                        ),
                      )
                    : ListView.separated(
                        itemCount: summary.history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = summary.history[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAF7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.date,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Total Amount: ${_inr(item.totalAmount)}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '(${_inr(item.previousBalance)} previous balance + ${_inr(item.dayTotalAmount)} day total)',
                                  style: TextStyle(
                                    color: AppColors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Paid Amount: ${_inr(item.paidAmount)}',
                                  style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Balance: ${_inr(item.balanceAmount)}',
                                  style: TextStyle(
                                    color: item.balanceAmount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (item.notes.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Notes: ${item.notes}',
                                    style: TextStyle(color: AppColors.grey.shade700),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  static double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  static String _inr(double value) {
    return 'Rs ${value.toStringAsFixed(2)}';
  }
}
