import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/plan_model.dart';
import '../../services/upgrade_plan_display_service.dart';

class UpgradePlanCard extends StatelessWidget {
  const UpgradePlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.displayService = const UpgradePlanDisplayService(),
  });

  static const Color _deepGreen = Color(0xFF07140E);
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _brightGreen = Color(0xFF80EA73);

  final PlanModel plan;
  final bool selected;
  final VoidCallback? onTap;
  final UpgradePlanDisplayService displayService;

  @override
  Widget build(BuildContext context) {
    final yearly = displayService.isTwelveMonthPlan(plan);
    final highlighted = yearly || plan.highlighted;
    final selectable = plan.isSelectable;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 132,
        height: 210,
        padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: !selectable
                ? const [Color(0xFF8B9A8F), Color(0xFF6F7D73)]
                : selected
                ? const [Color(0xFF0F7A34), Color(0xFF25A84D)]
                : const [Color(0xFF1C8A3D), Color(0xFF0F6D30)],
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
                        : Colors.white.withValues(
                            alpha: selectable ? 0.10 : 0.06,
                          ),
                    border: Border.all(
                      color: selected
                          ? _brightGreen
                          : Colors.white.withValues(
                              alpha: selectable ? 0.42 : 0.24,
                            ),
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
                    displayService.planTitle(plan),
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
            if (!selectable) ...[
              _PlanPill(
                text: 'used'.tr,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                textColor: Colors.white,
              ),
              const SizedBox(height: 8),
            ] else if (yearly) ...[
              _PlanPill(
                text: 'discount_20_off'.tr,
                backgroundColor: _brightGreen,
                textColor: _deepGreen,
                shadowColor: _brightGreen.withValues(alpha: 0.25),
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
              displayService.planSubtext(plan),
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
                    : Colors.white.withValues(alpha: selectable ? 0.10 : 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? _brightGreen.withValues(alpha: 0.50)
                      : Colors.white.withValues(
                          alpha: selectable ? 0.18 : 0.10,
                        ),
                ),
              ),
              child: Text(
                !selectable
                    ? 'free_plan_used'.tr
                    : (selected ? 'selected'.tr : 'tap_to_choose'.tr),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? _brightGreen
                      : Colors.white.withValues(
                          alpha: selectable ? 0.82 : 0.62,
                        ),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.shadowColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: shadowColor == null
            ? null
            : [
                BoxShadow(
                  color: shadowColor!,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
