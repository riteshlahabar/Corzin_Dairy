import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/doctor_controller.dart';

class DoctorAppointmentsView extends GetView<DoctorController> {
  const DoctorAppointmentsView({super.key});

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
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.initData,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          children: [
                            _sectionTitle('Animals'),
                            const SizedBox(height: 10),
                            if (controller.animals.isEmpty)
                              _emptyCard('No animals added yet.'),
                            ...controller.animals.map(_animalCard),
                            const SizedBox(height: 12),
                            _sectionTitle('My Appointments'),
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
                              _emptyCard('No appointments created yet.'),
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
                      ? 'Tag not available'
                      : 'Tag: ${animal.tagNumber}',
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
              child: const Text(
                'Create Appointment',
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
              style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w600),
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
          if (request.diseaseNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Disease: ${request.diseaseNames.join(', ')}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (request.diseaseDetails.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Details: ${request.diseaseDetails}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (request.visitOtp.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Visit OTP: ${request.visitOtp}', style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700)),
          ],
          if (request.treatmentDetails.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Treatment: ${request.treatmentDetails}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (request.charges != '-') ...[
            const SizedBox(height: 4),
            Text('Charges: ${request.charges}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (request.scheduledAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Schedule: ${request.scheduledAt}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (status == 'proposed') ...[
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
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
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
        title: Text('Create Appointment • ${animal.animalName.isEmpty ? 'Animal' : animal.animalName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Doctor', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Obx(
                () => DropdownButtonFormField<DoctorModel>(
                  initialValue: controller.selectedDoctor.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Choose doctor',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: controller.doctors
                      .map(
                        (doctor) => DropdownMenuItem(
                          value: doctor,
                          child: Text(doctor.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => controller.selectedDoctor.value = value,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Disease (checkbox)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Obx(
                () {
                  if (controller.diseases.isEmpty) {
                    return const Text(
                      'No diseases available. Please ask admin to add disease from panel.',
                      style: TextStyle(fontSize: 12),
                    );
                  }

                  return Column(
                    children: controller.diseases.map((disease) {
                      final selected = controller.selectedDiseaseIds.contains(disease.id);
                      return CheckboxListTile(
                        dense: true,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        contentPadding: EdgeInsets.zero,
                        value: selected,
                        onChanged: (checked) {
                          if (checked == true) {
                            if (!controller.selectedDiseaseIds.contains(disease.id)) {
                              controller.selectedDiseaseIds.add(disease.id);
                            }
                          } else {
                            controller.selectedDiseaseIds.remove(disease.id);
                          }
                          controller.selectedDiseaseIds.refresh();
                        },
                        title: Text(disease.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        subtitle: disease.description.isNotEmpty
                            ? Text(disease.description, style: const TextStyle(fontSize: 11.5))
                            : null,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 10),
              const Text('Disease Details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.diseaseDetailsController,
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Small details of disease',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSubmittingRequest.value
                  ? null
                  : () {
                      final selectedDoctor = controller.selectedDoctor.value;
                      if (selectedDoctor == null) {
                        Get.snackbar('Error', 'Please select doctor.');
                        return;
                      }
                      controller.requestDoctorVisit(doctor: selectedDoctor, animal: animal);
                    },
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
}
