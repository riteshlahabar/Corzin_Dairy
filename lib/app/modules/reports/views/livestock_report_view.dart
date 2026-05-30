import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/livestock_report_controller.dart';

class LivestockReportView extends StatelessWidget {
  const LivestockReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LivestockReportController());
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
                    onPressed: _handleBackPress,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'livestock_report'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () {
                  final visibleSections = controller.visibleSections;
                  final summaryCards = controller.summaryCards;
                  final hasNoData = visibleSections.isEmpty ||
                      visibleSections.every((section) => section.rows.isEmpty);
                  return RefreshIndicator(
                    onRefresh: controller.fetchReport,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                      children: [
                        _filterCard(context, controller),
                        const SizedBox(height: 10),
                        if (summaryCards.isNotEmpty) ...[
                          _summarySection(summaryCards),
                          const SizedBox(height: 10),
                        ],
                        if (controller.isLoading.value)
                          const Padding(
                            padding: EdgeInsets.only(top: 28),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (hasNoData)
                          _emptyCard()
                        else
                          ...visibleSections.map(_sectionCard),
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

  Widget _filterCard(BuildContext context, LivestockReportController controller) {
    final selectedScope = controller.scope.value;
    final selectedReportType = controller.reportType.value;
    final targetIds = controller.targets.map((item) => item.id).toSet();
    final selectedTargetId = controller.selectedTargetId.value;
    final dropdownValue = selectedTargetId != null && targetIds.contains(selectedTargetId)
        ? selectedTargetId
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDEBDE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'report_filters'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedScope,
            decoration: _decoration('report_scope'.tr),
            dropdownColor: const Color(0xFFF2FAF2),
            items: [
              DropdownMenuItem(value: 'animal', child: Text('animal_wise'.tr)),
              DropdownMenuItem(value: 'pan', child: Text('pan_wise'.tr)),
            ],
            onChanged: (value) {
              unawaited(controller.changeScope(value));
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedReportType,
            decoration: _decoration('report_type'.tr),
            dropdownColor: const Color(0xFFF2FAF2),
            items: [
              DropdownMenuItem(
                value: LivestockReportController.reportTypeAll,
                child: Text('all_reports'.tr),
              ),
              DropdownMenuItem(
                value: LivestockReportController.reportTypeMilk,
                child: Text('milk_report'.tr),
              ),
              DropdownMenuItem(
                value: LivestockReportController.reportTypeFeeding,
                child: Text('feeding_report'.tr),
              ),
              DropdownMenuItem(
                value: LivestockReportController.reportTypeMedical,
                child: Text('medical_history'.tr),
              ),
              DropdownMenuItem(
                value: LivestockReportController.reportTypeLifecycle,
                child: Text('life_cycle_history'.tr),
              ),
              DropdownMenuItem(
                value: LivestockReportController.reportTypeMastitis,
                child: Text('${'mastitis'.tr} Report'),
              ),
              DropdownMenuItem(
                value: LivestockReportController.reportTypeProfitLoss,
                child: Text('profit_loss_report'.tr),
              ),
            ],
            onChanged: controller.changeReportType,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: dropdownValue,
            decoration: _decoration(
              selectedScope == 'pan' ? 'select_pan'.tr : 'select_animal'.tr,
            ),
            dropdownColor: const Color(0xFFF2FAF2),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text(selectedScope == 'pan' ? 'all_pans'.tr : 'all_animals'.tr),
              ),
              ...controller.targets.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              controller.selectedTargetId.value = value;
              unawaited(controller.fetchReport());
            },
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.isExporting.value
                      ? null
                      : () {
                          unawaited(controller.exportExcel());
                        },
                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                  label: Text('export_excel'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.isExporting.value
                      ? null
                      : () {
                          unawaited(controller.exportPdf());
                        },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text('export_pdf'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleBackPress() {
    if (Get.isRegistered<BottomNavController>()) {
      final nav = Get.find<BottomNavController>();
      if (nav.closeDrawerPage()) return;
      if (nav.currentIndex.value != 0) {
        nav.changeTab(0);
        return;
      }
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  Widget _sectionCard(ReportSectionData section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEBDE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          if (section.rows.isEmpty)
            Text(
              'no_report_data'.tr,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF5C6A60)),
            )
          else
            _sectionTable(section),
        ],
      ),
    );
  }

  Widget _sectionTable(ReportSectionData section) {
    return Column(
      children: section.rows
          .asMap()
          .entries
          .map((entry) => _rowCard(section, entry.value, entry.key))
          .toList(),
    );
  }

  Widget _rowCard(ReportSectionData section, List<String> row, int index) {
    final keyedValues = <String, String>{};
    for (var i = 0; i < section.headers.length; i++) {
      if (i >= row.length) continue;
      keyedValues[section.headers[i]] = row[i];
    }

    final idHeader = section.headers.firstWhereOrNull(
      (header) => header.trim().toLowerCase() == 'id',
    );
    final orderedPairs = <MapEntry<String, String>>[];
    if (idHeader != null && keyedValues.containsKey(idHeader)) {
      orderedPairs.add(
        MapEntry(idHeader, keyedValues[idHeader] ?? '-'),
      );
      keyedValues.remove(idHeader);
    }
    orderedPairs.addAll(
      section.headers
          .where((header) => keyedValues.containsKey(header))
          .map((header) => MapEntry(header, keyedValues[header] ?? '-')),
    );

    return Container(
      margin: EdgeInsets.only(bottom: index == section.rows.length - 1 ? 0 : 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEADC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < orderedPairs.length; i++)
              _kvRow(
                orderedPairs[i].key,
                orderedPairs[i].value,
                isLast: i == orderedPairs.length - 1,
              ),
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value, {required bool isLast}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C4A31),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF35523A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySection(List<ReportSummaryCardData> summaryCards) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: summaryCards
          .map(
            (item) => Container(
              width: (Get.width - 36) / 2,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDEBDE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5D4F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _emptyCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEBDE)),
      ),
      child: Center(
        child: Text(
          'no_report_data'.tr,
          style: const TextStyle(fontSize: 13, color: Color(0xFF5C6A60)),
        ),
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
