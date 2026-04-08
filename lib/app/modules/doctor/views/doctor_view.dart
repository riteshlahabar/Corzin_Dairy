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
                        onRefresh: controller.initData,
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
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                children: [
                                  ...controller.filteredDoctors.map(
                                    (doctor) => _doctorCard(doctor),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'My Vet Requests',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 10),
                                  if (controller.isLoadingRequests.value)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                  if (!controller.isLoadingRequests.value &&
                                      controller.sortedRequests.isEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'No vet requests created yet.',
                                        style: TextStyle(fontSize: 12.5),
                                      ),
                                    ),
                                  ...controller.sortedRequests.map(
                                    (request) => _requestCard(request),
                                  ),
                                ],
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorCard(DoctorModel doctor) {
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
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _openRequestDialog(doctor),
              icon: const Icon(Icons.medical_information_outlined, size: 18),
              label: const Text('Request Visit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(VetRequestModel request) {
    final status = request.status.toLowerCase();
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.doctorName,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.capitalizeFirst ?? status,
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Animal: ${request.animalName}', style: const TextStyle(fontSize: 12.2)),
          const SizedBox(height: 4),
          Text('Concern: ${request.concern}', style: const TextStyle(fontSize: 12.2)),
          if (request.charges != '-') ...[
            const SizedBox(height: 4),
            Text('Charges: ${request.charges}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (request.scheduledAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Schedule: ${request.scheduledAt}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (status == 'proposed' || status == 'rescheduled') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.isUpdatingRequestStatus.value
                        ? null
                        : () => controller.updateFarmerApproval(request: request, approved: false),
                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.isUpdatingRequestStatus.value
                        ? null
                        : () => controller.updateFarmerApproval(request: request, approved: true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Approve', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'declined':
      case 'cancelled':
        return const Color(0xFFC62828);
      case 'rescheduled':
      case 'proposed':
        return const Color(0xFFEF6C00);
      default:
        return AppColors.primary;
    }
  }

  Future<void> _openRequestDialog(DoctorModel doctor) async {
    controller.selectedAnimal.value = null;
    controller.concernController.clear();
    controller.notesController.clear();

    await Get.dialog(
      AlertDialog(
        title: Text('Request ${doctor.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Animal', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Obx(
                () => DropdownButtonFormField<VetAnimalModel>(
                  initialValue: controller.selectedAnimal.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Choose animal',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: controller.animals
                      .map(
                        (animal) => DropdownMenuItem(
                          value: animal,
                          child: Text(animal.displayName, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => controller.selectedAnimal.value = value,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Concern', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.concernController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter concern',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Notes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.notesController,
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Optional notes',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSubmittingRequest.value
                  ? null
                  : () => controller.requestDoctorVisit(doctor),
              child: controller.isSubmittingRequest.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit'),
            ),
          ),
        ],
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
