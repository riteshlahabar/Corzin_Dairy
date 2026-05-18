import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/health_controller.dart';

class HealthView extends GetView<HealthController> {
  const HealthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      floatingActionButton: Builder(
        builder: (context) => _addButton(context),
      ),
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
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'health'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'dmi'.tr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2B21),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : _dmiList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

  Widget _addButton(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _dmiList() {
    final latestRows = _latestDmiByAnimal();
    return RefreshIndicator(
      onRefresh: controller.fetchDmiRecords,
      child: latestRows.isEmpty
          ? _emptyState('no_dmi_records_found'.tr)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: latestRows.length,
              itemBuilder: (context, index) {
                final item = latestRows[index];
                return _card(
                  title: '${item.animalName} - Tag ${item.tagNumber}',
                  subtitle: item.dmiType.isEmpty ? '-' : item.dmiType,
                  dateText: item.date,
                  status: _cardStatusLabel(item.alertStatus),
                  rows: [
                    _info('required_dmi'.tr, '${item.requiredDmi} Kg'),
                    _info('body_weight'.tr, '${item.bodyWeight} Kg'),
                    _info('total_milk'.tr, '${item.totalMilk} L'),
                    _info('actual_dmi'.tr, '${item.actualDmi} Kg'),
                    if (item.notes.isNotEmpty) _info('notes'.tr, item.notes),
                  ],
                );
              },
            ),
    );
  }

  List<DmiRecordItem> _latestDmiByAnimal() {
    final Map<int, DmiRecordItem> byAnimal = <int, DmiRecordItem>{};
    for (final row in controller.dmiRecords) {
      if (row.animalId == 0) continue;
      byAnimal.putIfAbsent(row.animalId, () => row);
    }
    return byAnimal.values.toList();
  }

  Widget _card({
    required String title,
    required String subtitle,
    String dateText = '-',
    String status = '',
    required List<Widget> rows,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EFE3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (status.isNotEmpty) _statusPill(status),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaPill(Icons.pets_outlined, subtitle),
              _metaPill(Icons.calendar_month_rounded, '${'date'.tr}: $dateText'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FCF8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7EF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final statusLower = status.toLowerCase();
    final bool isGood = statusLower.contains('balanced') || statusLower.contains('auto');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFFEAF8EE) : const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isGood ? const Color(0xFF167B33) : const Color(0xFFB66A00),
        ),
      ),
    );
  }

  String _cardStatusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'auto calculated') {
      return '';
    }
    return status;
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.health_and_safety_outlined,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

