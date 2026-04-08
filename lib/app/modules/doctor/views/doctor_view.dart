import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/doctor_controller.dart';

class DoctorView extends GetView<DoctorController> {
  const DoctorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF7),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'doctor'.tr,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search doctor, speciality, location',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.loadDoctors,
                        child: controller.filteredDoctors.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: const [
                                  SizedBox(height: 120),
                                  Icon(Icons.medical_services_outlined, size: 48, color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'No doctors found',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                itemCount: controller.filteredDoctors.length,
                                itemBuilder: (context, index) {
                                  final doctor = controller.filteredDoctors[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              height: 52,
                                              width: 52,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Icon(
                                                Icons.medical_services_outlined,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    doctor.name,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    doctor.speciality,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: AppColors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: doctor.availableToday
                                                    ? AppColors.primary.withValues(alpha: 0.1)
                                                    : AppColors.grey.withValues(alpha: 0.16),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                doctor.availableToday ? 'available_today'.tr : 'offline'.tr,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: doctor.availableToday
                                                      ? AppColors.primary
                                                      : AppColors.grey.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _infoRow(Icons.work_outline_rounded, '${'experience'.tr}: ${doctor.experience.isEmpty ? '-' : doctor.experience}'),
                                        const SizedBox(height: 8),
                                        _infoRow(Icons.location_on_outlined, '${'location'.tr}: ${doctor.location.isEmpty ? '-' : doctor.location}'),
                                        const SizedBox(height: 8),
                                        _infoRow(Icons.call_outlined, '${'contact'.tr}: ${doctor.phone.isEmpty ? '-' : doctor.phone}'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      );
}
