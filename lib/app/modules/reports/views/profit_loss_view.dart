import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/profit_loss_controller.dart';

class ProfitLossView extends StatelessWidget {
  const ProfitLossView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfitLossController());
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Get.isRegistered<BottomNavController>() &&
                          Get.find<BottomNavController>().closeDrawerPage()) {
                        return;
                      }
                      Get.back();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'profit_loss'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () {
                  final data = controller.summary.value;
                  return RefreshIndicator(
                    onRefresh: controller.fetchSummary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                      children: [
                        _filterCard(context, controller),
                        const SizedBox(height: 10),
                        if (controller.isLoading.value)
                          const Padding(
                            padding: EdgeInsets.only(top: 28),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          _metricCard(
                            title: 'milk_earning'.tr,
                            value: 'Rs ${data.milkEarning.toStringAsFixed(2)}',
                            color: const Color(0xFF1976D2),
                            icon: Icons.currency_rupee_rounded,
                          ),
                          _metricCard(
                            title: 'feeding_cost'.tr,
                            value: 'Rs ${data.feedingCost.toStringAsFixed(2)}',
                            color: const Color(0xFF2E7D32),
                            icon: Icons.grass_rounded,
                          ),
                          _metricCard(
                            title: 'doctor_cost'.tr,
                            value: 'Rs ${data.doctorCost.toStringAsFixed(2)}',
                            color: const Color(0xFFEF6C00),
                            icon: Icons.medical_services_outlined,
                          ),
                          _metricCard(
                            title: 'medicine_cost'.tr,
                            value: 'Rs ${data.medicineCost.toStringAsFixed(2)}',
                            color: const Color(0xFF8E24AA),
                            icon: Icons.medication_outlined,
                          ),
                          _metricCard(
                            title: 'total_expenses'.tr,
                            value: 'Rs ${data.totalExpenses.toStringAsFixed(2)}',
                            color: const Color(0xFFD84315),
                            icon: Icons.summarize_outlined,
                          ),
                          _netCard(data),
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
    );
  }

  Widget _filterCard(BuildContext context, ProfitLossController controller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDEBDE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'report_filters'.tr,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.fromDateController,
                  readOnly: true,
                  onTap: () => controller.pickFromDate(context),
                  decoration: _decoration('from_date'.tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller.toDateController,
                  readOnly: true,
                  onTap: () => controller.pickToDate(context),
                  decoration: _decoration('to_date'.tr),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.fetchSummary,
              icon: const Icon(Icons.analytics_outlined),
              label: Text('load_report'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEBDE)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _netCard(ProfitLossSummary summary) {
    final isProfit = summary.isProfit;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF1F7A33), const Color(0xFF3A9B49)]
              : [const Color(0xFFB71C1C), const Color(0xFFD84315)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isProfit ? 'net_profit'.tr : 'net_loss'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            'Rs ${summary.netProfit.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.98), fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF6FBF6),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD6E7D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD6E7D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}
