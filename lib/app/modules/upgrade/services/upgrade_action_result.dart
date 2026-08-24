class UpgradeActionResult {
  const UpgradeActionResult({
    required this.success,
    this.titleKey = '',
    this.message = '',
    this.navigateHome = false,
    this.reloadPlans = false,
    this.showMessage = true,
  });

  final bool success;
  final String titleKey;
  final String message;
  final bool navigateHome;
  final bool reloadPlans;
  final bool showMessage;
}
