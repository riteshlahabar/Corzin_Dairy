import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widget/bottom_navigation_bar.dart';
import '../controllers/doctor_controller.dart';

class DoctorAppointmentsView extends GetView<DoctorController> {
  const DoctorAppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAF7),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Builder(
              builder: (context) => Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: EdgeInsets.fromLTRB(
                  4,
                  MediaQuery.of(context).padding.top + 4,
                  8,
                  6,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _goHome,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        'doctor'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.initData,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          children: [
                            _sectionTitle('animals'.tr),
                            const SizedBox(height: 10),
                            if (controller.animals.isEmpty)
                              _emptyCard('no_animals_added_yet'.tr),
                            ...controller.animals.map(_animalCard),
                            const SizedBox(height: 12),
                            _sectionTitle('my_appointments'.tr),
                            const SizedBox(height: 10),
                            if (controller.isLoadingRequests.value)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            if (!controller.isLoadingRequests.value &&
                                controller.sortedRequests.isEmpty)
                              _emptyCard('no_appointments_created_yet'.tr),
                            ...controller.sortedRequests.map(_requestCard),
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

  void _goHome() {
    if (Get.isRegistered<BottomNavController>()) {
      final bottomNav = Get.find<BottomNavController>();
      if (bottomNav.popRouteOrCloseDrawerPage()) return;
      bottomNav.changeTab(0);
      return;
    }
    Get.back();
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(fontSize: 12.5)),
    );
  }

  Widget _animalCard(VetAnimalModel animal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3ECE3)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.animalName.isEmpty ? 'Animal' : animal.animalName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  animal.tagNumber.isEmpty
                      ? 'tag_not_available'.tr
                      : 'tag_value'.trParams({'value': animal.tagNumber}),
                  style: const TextStyle(fontSize: 12.2, color: AppColors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () => _openCreateAppointmentDialog(animal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'create_appointment'.tr,
                style: TextStyle(fontSize: 11.8, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorInfoCard(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_services_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${doctor.name} • ${doctor.speciality.isEmpty ? 'Doctor' : doctor.speciality}',
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
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
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.capitalizeFirst ?? status,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'animal_value'.trParams({'value': request.animalName}),
            style: const TextStyle(fontSize: 12.2),
          ),
          const SizedBox(height: 4),
          Text(
            'concern_value'.trParams({'value': request.concern}),
            style: const TextStyle(fontSize: 12.2),
          ),
          if (request.diseaseNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'disease_value'.trParams({'value': request.diseaseNames.join(', ')}),
              style: const TextStyle(fontSize: 12.2),
            ),
          ],
          if (request.diseaseDetails.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'details_value'.trParams({'value': request.diseaseDetails}),
              style: const TextStyle(fontSize: 12.2),
            ),
          ],
          if (request.visitOtp.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'visit_otp_value'.trParams({'value': request.visitOtp}),
              style: const TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (request.treatmentDetails.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'treatment_value'.trParams({'value': request.treatmentDetails}),
              style: const TextStyle(fontSize: 12.2),
            ),
          ],
          if (request.charges != '-') ...[
            const SizedBox(height: 4),
            Text(
              'charges_value'.trParams({'value': request.charges}),
              style: const TextStyle(fontSize: 12.2),
            ),
          ],
          if (request.scheduledAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'schedule_value'.trParams({'value': request.scheduledAt}),
              style: const TextStyle(fontSize: 12.2),
            ),
          ],
          if (status == 'proposed') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.isUpdatingRequestStatus.value
                        ? null
                        : () => controller.updateFarmerApproval(
                            request: request,
                            approved: false,
                          ),
                    child: Text(
                      'decline'.tr,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.isUpdatingRequestStatus.value
                        ? null
                        : () => controller.updateFarmerApproval(
                            request: request,
                            approved: true,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text('accept'.tr, style: const TextStyle(fontSize: 12)),
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
      case 'proposed':
        return const Color(0xFFEF6C00);
      default:
        return AppColors.primary;
    }
  }

  Future<void> _openCreateAppointmentDialog(VetAnimalModel animal) async {
    controller.selectedDoctor.value = null;
    controller.selectedDiseaseIds.clear();
    controller.diseaseDetailsController.clear();

    await Get.dialog(
      AlertDialog(
        title: Text(
          '${'create_appointment'.tr} - ${animal.animalName.isEmpty ? 'animal'.tr : animal.animalName}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_doctor'.tr,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Obx(
                () => DropdownButtonFormField<DoctorModel>(
                  initialValue: controller.selectedDoctor.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'choose_doctor'.tr,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: controller.doctors
                      .map(
                        (doctor) => DropdownMenuItem(
                          value: doctor,
                          child: Text(
                            doctor.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => controller.selectedDoctor.value = value,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'disease_checkbox'.tr,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Obx(() {
                if (controller.diseases.isEmpty) {
                  return Text(
                    'no_diseases_available_admin'.tr,
                    style: TextStyle(fontSize: 12),
                  );
                }

                return Column(
                  children: controller.diseases.map((disease) {
                    final selected = controller.selectedDiseaseIds.contains(
                      disease.id,
                    );
                    return CheckboxListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      contentPadding: EdgeInsets.zero,
                      value: selected,
                      onChanged: (checked) {
                        if (checked == true) {
                          if (!controller.selectedDiseaseIds.contains(
                            disease.id,
                          )) {
                            controller.selectedDiseaseIds.add(disease.id);
                          }
                        } else {
                          controller.selectedDiseaseIds.remove(disease.id);
                        }
                        controller.selectedDiseaseIds.refresh();
                      },
                      title: Text(
                        disease.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: disease.description.isNotEmpty
                          ? Text(
                              disease.description,
                              style: const TextStyle(fontSize: 11.5),
                            )
                          : null,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 10),
              Text(
                'disease_details'.tr,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.diseaseDetailsController,
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'small_details_disease'.tr,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSubmittingRequest.value
                  ? null
                  : () {
                      final selectedDoctor = controller.selectedDoctor.value;
                      if (selectedDoctor == null) {
                        Get.snackbar('error'.tr, 'please_select_doctor'.tr);
                        return;
                      }
                      controller.requestDoctorVisit(
                        doctor: selectedDoctor,
                        animal: animal,
                      );
                    },
              child: controller.isSubmittingRequest.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('submit'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
