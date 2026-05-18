import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        surfaceTintColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'dairy_payment'.tr,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() && Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
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
          Text(
            'payment_overview'.tr,
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
                  label: 'total_dairies'.tr,
                  value: dairyCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewMetric(
                  label: 'outstanding'.tr,
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
        color: Colors.white.withValues(alpha: 0.18),
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
      child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0x142E7D32),
              child: Icon(Icons.add_rounded, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'add_new_payment_entry'.tr,
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
        'no_dairy_payment_history'.tr,
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
              'no_payment_entry_yet'.tr,
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
                    title: 'total'.tr,
                    value: _inr(latest.totalAmount),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard(
                    title: 'paid'.tr,
                    value: _inr(latest.paidAmount),
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricCard(
                    title: 'balance'.tr,
                    value: _inr(latest.balanceAmount),
                    color: latest.balanceAmount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${'previous_balance'.tr} + ${'today_balance'.tr} = ${'total_balance'.tr}\n'
              '${_inr(_remainingPreviousBalance(latest))} + ${_inr(_remainingTodayBalance(latest))} = ${_inr(latest.balanceAmount)}',
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
                  label: Text('add_entry'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0x802E7D32)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openHistorySheet(summary),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text('view_more'.tr),
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
        isPending ? 'pending'.tr : 'settled'.tr,
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
      Get.snackbar('error'.tr, 'no_dairy_found_add_first'.tr);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final paidController = TextEditingController();
    final paidFocus = FocusNode();
    final notesController = TextEditingController();
    final initialDairy = controller.dairyOptionById(preselectedDairyId ?? 0) ?? controller.dairyOptions.first;
    final selectedDairyId = initialDairy.id.obs;
    final previousBalance = controller.previousBalanceForDairy(initialDairy.id).obs;
    final todayBalance = controller.todayBalanceForDairy(initialDairy.id).obs;
    final totalAmount = controller.totalBalanceForDairy(initialDairy.id).obs;
    final balancePreview = totalAmount.value.obs;
    final totalBalanceController = TextEditingController();
    totalBalanceController.text = _inr(totalAmount.value);

    void recalc() {
      final paid = _toDouble(paidController.text);
      final dairyId = selectedDairyId.value;
      if (dairyId <= 0) {
        previousBalance.value = 0;
        todayBalance.value = 0;
        totalAmount.value = 0;
        balancePreview.value = 0;
        totalBalanceController.text = _inr(totalAmount.value);
        return;
      }
      previousBalance.value = controller.previousBalanceForDairy(dairyId);
      todayBalance.value = controller.todayBalanceForDairy(dairyId);
      totalAmount.value = controller.totalBalanceForDairy(dairyId);
      balancePreview.value = totalAmount.value - paid;
      totalBalanceController.text = _inr(totalAmount.value);
    }

    Get.bottomSheet(
      AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: formKey,
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
                Text(
                  'add_dairy_payment_entry'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<int>(
                    initialValue: selectedDairyId.value,
                    decoration: _input('dairy_name'.tr),
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
                    validator: (value) => value == null || value <= 0
                        ? 'please_select_dairy_name'.tr
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  enabled: false,
                  controller: totalBalanceController,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _input('total_balance'.tr),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: paidController,
                  focusNode: paidFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => recalc(),
                  decoration: _input('paid_amount_rs'.tr),
                  validator: (value) {
                    final paid = _toDouble(value ?? '');
                    final total = totalAmount.value;
                    if ((value ?? '').trim().isEmpty) return 'please_enter_valid_paid_amount'.tr;
                    if (paid < 0) return 'please_enter_valid_paid_amount'.tr;
                    if (paid > total) return 'paid_amount_gt_total'.tr;
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: _input('notes'.tr),
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
                          '${'previous_balance'.tr}: ${_inr(previousBalance.value)}',
                          style: TextStyle(
                            color: AppColors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'today_balance'.tr}: ${_inr(todayBalance.value)}',
                          style: TextStyle(
                            color: AppColors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'total_balance'.tr}: ${_inr(totalAmount.value)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'balance_amount'.tr}: ${_inr(balancePreview.value)}',
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
                              final formState = formKey.currentState;
                              if (formState == null) return;
                              final valid = formState.validate();
                              if (!valid) {
                                paidFocus.requestFocus();
                                return;
                              }
                              final dairyId = selectedDairyId.value;
                              if (dairyId <= 0 || controller.dairyOptionById(dairyId) == null) {
                                Get.snackbar('error'.tr, 'please_select_dairy_name'.tr);
                                return;
                              }
                              final total = totalAmount.value;
                              final paid = _toDouble(paidController.text);
                              if (total <= 0) {
                                Get.snackbar('error'.tr, 'no_total_amount_for_payment'.tr);
                                return;
                              }
                              if (paid < 0) {
                                Get.snackbar('error'.tr, 'please_enter_valid_paid_amount'.tr);
                                return;
                              }
                              if (paid > total) {
                                Get.snackbar('error'.tr, 'paid_amount_gt_total'.tr);
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
                                  'success'.tr,
                                  'dairy_payment_entry_added'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'error'.tr,
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
                          : Text('save_entry'.tr),
                    ),
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(() {
      paidController.dispose();
      notesController.dispose();
      paidFocus.dispose();
      totalBalanceController.dispose();
    });
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
                    Text(
                      'payment_history'.tr,
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
                            title: 'entries'.tr,
                            value: summary.history.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _historyKpi(
                            title: 'current_balance'.tr,
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
                          'no_payment_entries_available'.tr,
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
                                  label: 'total_amount'.tr,
                                  value: _inr(item.totalAmount),
                                  valueColor: AppColors.primary,
                                ),
                                _historyAmountRow(
                                  label: 'paid_amount'.tr,
                                  value: _inr(item.paidAmount),
                                  valueColor: Colors.blueGrey.shade700,
                                ),
                                _historyAmountRow(
                                  label: 'balance'.tr,
                                  value: _inr(item.balanceAmount),
                                  valueColor:
                                      item.balanceAmount > 0 ? Colors.orange.shade800 : Colors.green.shade700,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${'previous_balance'.tr} + ${'today_balance'.tr} = ${'total_balance'.tr}\n'
                                  '${_inr(_remainingPreviousBalance(item))} + ${_inr(_remainingTodayBalance(item))} = ${_inr(item.balanceAmount)}',
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
                                      '${'notes'.tr}: ${item.notes}',
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
        color: Colors.white.withValues(alpha: 0.20),
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

  static double _remainingPreviousBalance(PaymentDayEntry item) {
    final remaining = item.previousBalance - item.paidAmount;
    return remaining > 0 ? remaining : 0;
  }

  static double _remainingTodayBalance(PaymentDayEntry item) {
    final paidAfterPrevious = item.paidAmount - item.previousBalance;
    final remaining = item.dayTotalAmount - (paidAfterPrevious > 0 ? paidAfterPrevious : 0);
    return remaining > 0 ? remaining : 0;
  }

  static double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  static String _inr(double value) {
    return 'Rs ${value.toStringAsFixed(2)}';
  }
}
