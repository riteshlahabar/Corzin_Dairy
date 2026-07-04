import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/upgrade_controller.dart';

class UpgradeView extends GetView<UpgradeController> {
  const UpgradeView({super.key});

  static const Color _deepGreen = Color(0xFF07140E);
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _brightGreen = Color(0xFF80EA73);
  static const Color _softGreen = Color(0xFFEAF7E6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !controller.isPlanLocked,
        leading: controller.isPlanLocked
            ? null
            : IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(
          'upgrade_plan'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _premiumShowcaseSection(),
                  const SizedBox(height: 16),
                  _currentPlanCard(),
                  const SizedBox(height: 18),
                  _choosePlanPremiumBox(),
                  const SizedBox(height: 18),
                  _selectedPlanDetails(),
                  const SizedBox(height: 18),
                  _continueButton(),
                ],
              ),
      ),
    );
  }

  Widget _premiumShowcaseSection() {
    final spotlightPlan = _spotlightPlan();
    final features = spotlightPlan.features.take(4).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF07140E),
            Color(0xFF0D2619),
            Color(0xFF12351F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -55,
            right: -45,
            child: _glowCircle(150, _brightGreen.withValues(alpha: 0.20)),
          ),
          Positioned(
            bottom: -70,
            left: -55,
            child: _glowCircle(170, _primaryGreen.withValues(alpha: 0.20)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            child: Column(
              children: [
                _premiumIconCluster(),
                const SizedBox(height: 20),
                Text(
                  'premium_upgrade_heading'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'premium_upgrade_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _brightGreen.withValues(alpha: 0.38),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'premium_upgrade_heading'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.96),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _brightGreen.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _brightGreen.withValues(alpha: 0.42),
                              ),
                            ),
                            child: Text(
                              'pro_tag'.tr,
                              style: TextStyle(
                                color: _brightGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (features.isNotEmpty)
                        ...features.map((feature) => _premiumBenefit(feature.tr))
                      else ...[
                        _premiumBenefit('access_advanced_features'.tr),
                        _premiumBenefit('get_priority_support'.tr),
                        _premiumBenefit('unlock_all_premium_tools'.tr),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumIconCluster() {
    return SizedBox(
      width: 190,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                width: 78,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFF0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: _primaryGreen,
                  size: 34,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                width: 78,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFF0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: _primaryGreen,
                  size: 32,
                ),
              ),
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFFF6FFF4),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _brightGreen.withValues(alpha: 0.45),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _brightGreen.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: _primaryGreen,
              size: 56,
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _brightGreen.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: _brightGreen.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: _brightGreen,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _choosePlanPremiumBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'choose_plan'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  'premium_tag'.tr.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: controller.plans.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final plan = controller.plans[index];
                return _premiumPlanCard(plan);
              },
            ),
          ),
        ],
      ),
    );
  }

 Widget _premiumPlanCard(PlanModel plan) {
  return Obx(
    () {
      final selected = controller.selectedPlanId.value == plan.id;
      final yearly = _isTwelveMonthPlan(plan);
      final highlighted = yearly || plan.highlighted;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectPlanImmediately(plan),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 132,
          height: 210,
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: selected
                  ? const [
                      Color(0xFF0F7A34),
                      Color(0xFF25A84D),
                    ]
                  : const [
                      Color(0xFF1C8A3D),
                      Color(0xFF0F6D30),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: selected
                  ? _brightGreen
                  : highlighted
                      ? _brightGreen.withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.24),
              width: selected ? 2.2 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? _brightGreen.withValues(alpha: 0.26)
                    : _primaryGreen.withValues(alpha: 0.18),
                blurRadius: selected ? 22 : 14,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? _brightGreen
                          : Colors.white.withValues(alpha: 0.10),
                      border: Border.all(
                        color: selected
                            ? _brightGreen
                            : Colors.white.withValues(alpha: 0.42),
                        width: 1.2,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: _deepGreen,
                          )
                        : null,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _planTitle(plan),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              const Spacer(),

              if (yearly) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _brightGreen,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _brightGreen.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'discount_20_off'.tr,
                    style: TextStyle(
                      color: _deepGreen,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                plan.price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _planSubtext(plan),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _brightGreen.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? _brightGreen.withValues(alpha: 0.50)
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  selected ? 'selected'.tr : 'tap_to_choose'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? _brightGreen
                        : Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _selectPlanImmediately(PlanModel plan) {
    controller.selectedPlanId.value = plan.id;
    controller.selectPlan(plan);
  }

  Widget _currentPlanCard() {
    final currentPlan = controller.currentPlan;
    final isLocked = controller.isPlanLocked;
    final warning = controller.planLockMessage.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isLocked ? const Color(0xFFD9EAD3) : const Color(0xFFD8EAD3),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'current_plan'.tr,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      currentPlan.name.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'amount'.tr,
                      style: TextStyle(
                        color: AppColors.grey.shade700,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentPlan.amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _currentPlanMetric(
                  icon: Icons.calendar_today_rounded,
                  label: 'start_date'.tr,
                  value: currentPlan.startDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _currentPlanMetric(
                  icon: Icons.event_available_rounded,
                  label: 'renew_date'.tr,
                  value: currentPlan.renewDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _currentPlanMetric(
                  icon: Icons.timelapse_rounded,
                  label: 'expires_in'.tr,
                  value: '${controller.planDaysLeft} ${'days'.tr}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLocked ? Icons.lock_clock_rounded : Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLocked ? 'plan_expired_contact_admin'.tr : 'current_plan'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isLocked || warning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8EAD3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warning.isEmpty ? 'plan_expired_contact_admin'.tr : warning,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectedPlanDetails() {
    return Obx(
      () {
        final plan = controller.selectedPlan;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFD8EAD3)),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _softGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _planSubtext(plan),
                          style: TextStyle(
                            color: AppColors.grey.shade700,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    plan.price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (plan.features.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...plan.features.take(6).map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: _softGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature.tr,
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontSize: 12.8,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _continueButton() {
    return Obx(
      () {
        final plan = controller.selectedPlan;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF145423),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: controller.isPurchasingPlan.value
                ? null
                : controller.continueWithSelectedPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: controller.isPurchasingPlan.value
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open_rounded, size: 19),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'continue_with_plan'.trParams({'price': plan.price}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _currentPlanMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.grey.shade700,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PlanModel _spotlightPlan() {
    for (final plan in controller.plans) {
      if (plan.highlighted) return plan;
    }
    if (controller.plans.isNotEmpty) {
      return controller.plans.first;
    }
    return const PlanModel(
      name: 'paid_plan',
      price: 'Rs 0',
      amount: 0,
      features: <String>[],
      highlighted: false,
    );
  }

  bool _isTwelveMonthPlan(PlanModel plan) {
    final name = plan.name.toLowerCase();
    return name.contains('12 month') ||
        name.contains('12month') ||
        name.contains('year');
  }

  String _planTitle(PlanModel plan) {
    final name = plan.name.toLowerCase();

    if (name.contains('12 month') ||
        name.contains('12month') ||
        name.contains('year')) {
      return 'yearly'.tr;
    }
    if (name.contains('6 month') || name.contains('6month')) {
      return 'half_yearly'.tr;
    }
    if (name.contains('month')) {
      return 'monthly'.tr;
    }
    if (plan.amount <= 0) {
      return 'free_trial'.tr;
    }
    return plan.name.tr;
  }

  String _planSubtext(PlanModel plan) {
    final name = plan.name.toLowerCase();

    if (name.contains('12 month') ||
        name.contains('12month') ||
        name.contains('year')) {
      return 'billed_annually'.tr;
    }
    if (name.contains('6 month') || name.contains('6month')) {
      return 'billed_every_6_months'.tr;
    }
    if (name.contains('month')) {
      return 'billed_monthly'.tr;
    }
    if (plan.amount <= 0) {
      return 'play_after_trial'.tr;
    }
    return plan.highlighted ? 'best_value_plan'.tr : 'flexible_farm_plan'.tr;
  }

  void _goBack() {
    if (controller.isPlanLocked) {
      return;
    }
    if (Get.isRegistered<BottomNavController>() &&
        Get.find<BottomNavController>().closeDrawerPage()) {
      return;
    }
    Get.back();
  }
}
