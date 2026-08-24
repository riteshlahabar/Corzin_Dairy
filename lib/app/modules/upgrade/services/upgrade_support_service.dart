import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home/controllers/home_controller.dart';
import '../repositories/upgrade_repository.dart';
import 'upgrade_action_result.dart';

class UpgradeSupportService {
  const UpgradeSupportService({
    UpgradeRepository repository = const UpgradeRepository(),
  }) : _repository = repository;

  final UpgradeRepository _repository;

  Future<Map<String, String>> loadAdminContact() async {
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.adminContactNumber.value.trim().isNotEmpty) {
        return {
          'name': home.adminContactName.value,
          'number': home.adminContactNumber.value,
        };
      }
    }

    return _repository.fetchAdminContact();
  }

  Future<UpgradeActionResult> contactAdmin({
    required String adminContactNumber,
    required Future<void> Function() refreshContact,
    required String Function() latestContactNumber,
  }) async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().callAdminSupport();
      return const UpgradeActionResult(success: true, showMessage: false);
    }

    if (adminContactNumber.trim().isEmpty) {
      await refreshContact();
    }

    final number = latestContactNumber().replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) {
      return const UpgradeActionResult(
        success: false,
        titleKey: 'error',
        message: 'admin_contact_number_not_available',
      );
    }

    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      return const UpgradeActionResult(
        success: false,
        titleKey: 'error',
        message: 'unable_open_dialer',
      );
    }

    return const UpgradeActionResult(success: true, showMessage: false);
  }
}
