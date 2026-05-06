import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.black,
        title: const Text(
          'Dairy Payment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = controller.payments;
          final totalBalance = items.fold<double>(
            0,
            (sum, item) => sum + (item.latest?.balanceAmount ?? item.currentBalance),
          );

          return RefreshIndicator(
            onRefresh: controller.loadPayments,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _overviewCard(
                  dairyCount: items.length,
                  totalBalance: totalBalance,
                ),
                const SizedBox(height: 12),
                _addEntryCard(context),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _emptyCard()
                else
                  ...items.map((payment) => _paymentCard(context, payment)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _overviewCard({
    required int dairyCount,
    required double totalBalance,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2E7D32),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _overviewMetric(
                  label: 'Total Dairies',
                  value: dairyCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewMetric(
                  label: 'Outstanding',
                  value: _inr(totalBalance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addEntryCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openAddEntrySheet(context),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E8E2)),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0x142E7D32),
              child: Icon(Icons.add_rounded, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add New Payment Entry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE7)),
      ),
      child: Text(
        'No dairy payment history yet.',
        style: TextStyle(
          color: AppColors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _paymentCard(BuildContext context, PaymentDairySummary summary) {
    final latest = summary.latest;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAE4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0x142E7D32),
                child: Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  summary.dairyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusBadge(latest?.balanceAmount ?? summary.currentBalance),
            ],
          ),
          const SizedBox(height: 10),
          if (latest == null)
            Text(
              'No payment entry yet.',
              style: TextStyle(color: AppColors.grey.shade700, fontWeight: FontWeight.w600),
            )
          else ...[
            Row(
              children: [
                Icon(Icons.event_rounded, size: 15, color: AppColors.grey.shade700),
                const SizedBox(width: 5),
                Text(
                  latest.date,
                  style: TextStyle(
                    color: AppColors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'Total',
                    value: _inr(latest.totalAmount),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard(
                    title: 'Paid',
                    value: _inr(latest.paidAmount),
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard(
                    title: 'Balance',
                    value: _inr(latest.balanceAmount),
                    color: latest.balanceAmount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '(${_inr(latest.previousBalance)} previous + ${_inr(latest.dayTotalAmount)} day total)',
              style: TextStyle(
                color: AppColors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openAddEntrySheet(context, preselectedDairyId: summary.id),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Entry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0x802E7D32)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openHistorySheet(summary),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View More'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3EAE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(double balance) {
    final isPending = balance > 0;
    final bg = isPending ? const Color(0xFFFFF2E8) : const Color(0xFFEAF8ED);
    final fg = isPending ? const Color(0xFFB45309) : const Color(0xFF166534);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPending ? 'Pending' : 'Settled',
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _openAddEntrySheet(BuildContext context, {int? preselectedDairyId}) {
    if (controller.dairyOptions.isEmpty) {
      Get.snackbar('Error', 'No dairy found. Please add dairy first.');
      return;
    }

    final paidController = TextEditingController();
    final notesController = TextEditingController();
    final initialDairy = controller.dairyOptionById(preselectedDairyId ?? 0) ?? controller.dairyOptions.first;
    final selectedDairyId = initialDairy.id.obs;
    final previousBalance = controller.previousBalanceForDairy(initialDairy.id).obs;
    final totalAmount = previousBalance.value.obs;
    final balancePreview = previousBalance.value.obs;

    void recalc() {
      final paid = _toDouble(paidController.text);
      final dairyId = selectedDairyId.value;
      if (dairyId <= 0) {
        totalAmount.value = 0;
        balancePreview.value = 0;
        return;
      }
      previousBalance.value = controller.previousBalanceForDairy(dairyId);
      totalAmount.value = previousBalance.value;
      balancePreview.value = totalAmount.value - paid;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
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
                Container(
                  height: 4,
                  width: 52,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E0D9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Text(
                  'Add Dairy Payment Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<int>(
                    initialValue: selectedDairyId.value,
                    decoration: _input('Dairy Name'),
                    items: controller.dairyOptions
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.dairyName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      selectedDairyId.value = value ?? 0;
                      recalc();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => TextFormField(
                    enabled: false,
                    initialValue: _inr(totalAmount.value),
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _input('Total Amount (Rs)'),
                  ),
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
                              final dairyId = selectedDairyId.value;
                              if (dairyId <= 0 || controller.dairyOptionById(dairyId) == null) {
                                Get.snackbar('Error', 'Please select dairy name');
                                return;
                              }
                              final total = totalAmount.value;
                              final paid = _toDouble(paidController.text);
                              if (total <= 0) {
                                Get.snackbar('Error', 'No total amount available for payment');
                                return;
                              }
                              if (paid < 0) {
                                Get.snackbar('Error', 'Please enter valid paid amount');
                                return;
                              }
                              if (paid > total) {
                                Get.snackbar('Error', 'Paid amount cannot be greater than total amount');
                                return;
                              }

                              try {
                                await controller.addPaymentEntry(
                                  dairyId: dairyId,
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
    );
  }

  void _openHistorySheet(PaymentDairySummary summary) {
    final latest = summary.latest;
    Get.bottomSheet(
      Container(
        height: Get.height * 0.78,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F9F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 52,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E0D9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.dairyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _historyKpi(
                            title: 'Entries',
                            value: summary.history.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _historyKpi(
                            title: 'Current Balance',
                            value: _inr(latest?.balanceAmount ?? summary.currentBalance),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: summary.history.isEmpty
                    ? Center(
                        child: Text(
                          'No payment entries available.',
                          style: TextStyle(color: AppColors.grey.shade700),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: summary.history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = summary.history[index];
                          return Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE4ECE6)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A101828),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.date,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _historyAmountRow(
                                  label: 'Total Amount',
                                  value: _inr(item.totalAmount),
                                  valueColor: AppColors.primary,
                                ),
                                _historyAmountRow(
                                  label: 'Paid Amount',
                                  value: _inr(item.paidAmount),
                                  valueColor: Colors.blueGrey.shade700,
                                ),
                                _historyAmountRow(
                                  label: 'Balance',
                                  value: _inr(item.balanceAmount),
                                  valueColor:
                                      item.balanceAmount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(${_inr(item.previousBalance)} previous balance + ${_inr(item.dayTotalAmount)} day total)',
                                  style: TextStyle(
                                    color: AppColors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.notes.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7FAF8),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE6EEE8)),
                                    ),
                                    child: Text(
                                      'Notes: ${item.notes}',
                                      style: TextStyle(
                                        color: AppColors.grey.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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

  Widget _historyKpi({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyAmountRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      labelText: hint,
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
