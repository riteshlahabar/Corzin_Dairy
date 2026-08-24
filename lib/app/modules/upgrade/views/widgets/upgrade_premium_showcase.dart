import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/plan_model.dart';
import '../../services/upgrade_plan_display_service.dart';

class UpgradePremiumShowcase extends StatelessWidget {
  const UpgradePremiumShowcase({
    super.key,
    required this.plans,
    this.displayService = const UpgradePlanDisplayService(),
  });

  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _brightGreen = Color(0xFF80EA73);

  final List<PlanModel> plans;
  final UpgradePlanDisplayService displayService;

  @override
  Widget build(BuildContext context) {
    final spotlightPlan = displayService.spotlightPlan(plans);
    final features = spotlightPlan.features.take(4).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF07140E), Color(0xFF0D2619), Color(0xFF12351F)],
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
                const _PremiumIconCluster(),
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
                _PremiumBenefitBox(features: features),
              ],
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PremiumIconCluster extends StatelessWidget {
  const _PremiumIconCluster();

  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _brightGreen = Color(0xFF80EA73);

  @override
  Widget build(BuildContext context) {
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
}

class _PremiumBenefitBox extends StatelessWidget {
  const _PremiumBenefitBox({required this.features});

  static const Color _brightGreen = Color(0xFF80EA73);

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _brightGreen.withValues(alpha: 0.38)),
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
            ...features.map((feature) => _PremiumBenefit(feature.tr))
          else ...[
            _PremiumBenefit('access_advanced_features'.tr),
            _PremiumBenefit('get_priority_support'.tr),
            _PremiumBenefit('unlock_all_premium_tools'.tr),
          ],
        ],
      ),
    );
  }
}

class _PremiumBenefit extends StatelessWidget {
  const _PremiumBenefit(this.text);

  static const Color _brightGreen = Color(0xFF80EA73);

  final String text;

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: _brightGreen.withValues(alpha: 0.45)),
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
}
