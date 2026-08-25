import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/health_controller.dart';

part 'reagent_view.dart';

part 'dmi_view.dart';

part 'mastitis_view.dart';

part 'vaccination_view.dart';

class HealthView extends StatefulWidget {
  const HealthView({super.key, this.initialSection = HealthSection.dmi});

  final HealthSection initialSection;

  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
  late final HealthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<HealthController>()
        ? Get.find<HealthController>()
        : Get.put(HealthController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSection(widget.initialSection);
    });
  }

  @override
  void didUpdateWidget(covariant HealthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadSection(widget.initialSection);
        }
      });
    }
  }

  void _loadSection(HealthSection section) {
    controller.loadSection(section);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      floatingActionButton: widget.initialSection == HealthSection.reagent
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _openHealthReagentSheet(this, context),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : widget.initialSection == HealthSection.mastitis
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _openHealthMastitisSheet(this, context),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : widget.initialSection == HealthSection.vaccination
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () => _openHealthVaccinationSheet(this, context),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
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
                      _screenTitle,
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
            const SizedBox(height: 14),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : switch (widget.initialSection) {
                        HealthSection.reagent => _buildHealthReagentList(this),
                        HealthSection.dmi => _buildHealthDmiList(this),
                        HealthSection.mastitis => _buildHealthMastitisList(this),
                        HealthSection.vaccination => _buildHealthVaccinationList(this),
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _screenTitle =>
      switch (widget.initialSection) {
        HealthSection.reagent => 'reagent'.tr,
        HealthSection.dmi => 'dmi'.tr,
        HealthSection.mastitis => 'mastitis'.tr,
        HealthSection.vaccination => 'vaccination'.tr,
      };

  void _goBack() {
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }

String _translatedAnimalTypeFilterLabel(String rawName) {
    final normalized = rawName.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') {
      return rawName.trim().isEmpty ? rawName : 'all'.tr;
    }

    if (_containsAny(normalized, const ['milking cow', 'milking cows']) ||
        (normalized.contains('milking') && !normalized.contains('non'))) {
      return 'milking_cows'.tr;
    }

    if (_containsAny(normalized, const [
          'non milking cow',
          'non-milking cow',
          'non milking cows',
          'non-milking cows',
          'dry cow',
          'dry cows',
        ]) ||
        normalized.contains('dry')) {
      return 'dry_cows'.tr;
    }

    if (_containsAny(normalized, const ['heifer', 'heifers'])) {
      return 'heifers'.tr;
    }

    if (_containsAny(normalized, const ['calf', 'calves'])) {
      return 'calves'.tr;
    }

    if (_containsAny(normalized, const ['bull', 'bulls'])) {
      return 'bulls'.tr;
    }

    if (_containsAny(normalized, const ['mother', 'mothers'])) {
      return 'mother'.tr;
    }

    if (_containsAny(normalized, const ['cow', 'cows'])) {
      return 'cow'.tr;
    }

    if (normalized == 'mixed') {
      return 'mixed'.tr;
    }

    return rawName;
  }

  bool _containsAny(String value, List<String> checks) {
    for (final check in checks) {
      if (value.contains(check)) return true;
    }
    return false;
  }

  Widget _card({
    required String title,
    required String subtitle,
    String dateLabel = '',
    String dateText = '-',
    String status = '',
    Widget? action,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (status.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(child: Align(alignment: Alignment.centerRight, child: _statusPill(status))),
              ],
              if (action != null) ...[
                const SizedBox(width: 6),
                action,
              ],
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaPill(Icons.pets_outlined, subtitle),
              _metaPill(
                Icons.calendar_month_rounded,
                '${dateLabel.isEmpty ? 'date'.tr : dateLabel}: $dateText',
              ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
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
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final statusLower = status.trim().toLowerCase();
    final bool isGood = statusLower == 'balanced' ||
        statusLower == 'balanced'.tr.toLowerCase() ||
        statusLower.contains('auto') ||
        statusLower == 'recovered' ||
        statusLower == 'recovered'.tr.toLowerCase() ||
        statusLower == 'negative' ||
        statusLower == 'negative'.tr.toLowerCase();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isGood ? const Color(0xFFEAF8EE) : const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isGood ? const Color(0xFF167B33) : const Color(0xFFB66A00),
          ),
        ),
      ),
    );
  }

  String _cardStatusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'auto calculated') {
      return '';
    }
    if (normalized == 'balanced') {
      return 'balanced'.tr;
    }
    if (normalized == 'low') {
      return 'low'.tr;
    }
    if (normalized == 'high') {
      return 'high'.tr;
    }
    return status;
  }

  String _mastitisResultLabel(String result) {
    switch (result.trim().toLowerCase()) {
      case 'positive':
        return 'positive'.tr;
      case 'negative':
        return 'negative'.tr;
      default:
        return result.trim().isEmpty ? '-' : result;
    }
  }

  String _mastitisStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'under_treatment':
      case 'under_treatement':
      case 'under treatment':
      case 'under treatement':
        return 'under_treatment'.tr;
      case 'recovered':
      case 'recoverd':
        return 'recovered'.tr;
      default:
        return status.trim().isEmpty ? '-' : status;
    }
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
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

  Widget _reagentInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _inlineEmptyState(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EFE3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            size: 42,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

Widget _sheetHandle() {
    return Center(
      child: Container(
        height: 4,
        width: 54,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  void _closeSheetAndShowSuccess(String message) {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    Future.delayed(const Duration(milliseconds: 250), () {
      Get.snackbar('success'.tr, message, duration: const Duration(seconds: 4));
    });
  }

  InputDecoration _sheetDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FCF8),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }
}
