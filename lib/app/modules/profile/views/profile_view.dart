import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    Text(
                      'profile'.tr,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.fullName().isEmpty
                                ? 'guest'.tr
                                : controller.fullName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.profile['mobile'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _infoCard(
                      title: 'farmer_information'.tr,
                      values: [
                        MapEntry('first_name'.tr, controller.profile['first_name'] ?? '-'),
                        MapEntry('middle_name'.tr, controller.profile['middle_name'] ?? '-'),
                        MapEntry('last_name'.tr, controller.profile['last_name'] ?? '-'),
                        MapEntry('mobile_number'.tr, controller.profile['mobile'] ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _infoCard(
                      title: 'location'.tr,
                      values: [
                        MapEntry('village'.tr, controller.profile['village'] ?? '-'),
                        MapEntry('city'.tr, controller.profile['city'] ?? '-'),
                        MapEntry('taluka'.tr, controller.profile['taluka'] ?? '-'),
                        MapEntry('district'.tr, controller.profile['district'] ?? '-'),
                        MapEntry('state'.tr, controller.profile['state'] ?? '-'),
                        MapEntry('pincode'.tr, controller.profile['pincode'] ?? '-'),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<MapEntry<String, String>> values,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...values.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.trim().isEmpty ? '-' : entry.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
