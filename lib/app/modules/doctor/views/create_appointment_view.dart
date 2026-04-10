import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/colors.dart';
import '../controllers/doctor_controller.dart';

class CreateAppointmentView extends GetView<DoctorController> {
  const CreateAppointmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final animal = Get.arguments as VetAnimalModel?;
    if (animal == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text(
          'Book vet visit',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE3ECE3))),
              ),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: animal.imageUrl.trim().isNotEmpty
                        ? Image.network(
                            animal.imageUrl.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.pets_rounded, color: AppColors.primary),
                          )
                        : const Icon(Icons.pets_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.animalName.isEmpty ? 'Animal' : animal.animalName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          animal.tagNumber.isEmpty ? 'Tag not set' : 'Tag ${animal.tagNumber}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select symptoms / disease',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.diseases.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE3ECE3)),
                          ),
                          child: const Text(
                            'No diseases listed yet. Admin can add them under Settings → Add Disease.',
                            style: TextStyle(fontSize: 12.5, height: 1.35),
                          ),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE3ECE3)),
                        ),
                        child: Column(
                          children: controller.diseases.map((disease) {
                            return Obx(() {
                              final selected = controller.selectedDiseaseIds.contains(disease.id);
                              return CheckboxListTile(
                                dense: true,
                                value: selected,
                                activeColor: AppColors.primary,
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
                                title: Text(
                                  disease.name,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                                subtitle: disease.description.isNotEmpty
                                    ? Text(
                                        disease.description,
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            });
                          }).toList(),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller.concernDescriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe the problem, behaviour, duration…',
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE3ECE3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE3ECE3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Disease details (short)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller.diseaseDetailsController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Small note on visible symptoms',
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE3ECE3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE3ECE3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Extra notes (optional)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller.notesController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Anything else the vet should know',
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE3ECE3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE3ECE3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Location is shared when you allow GPS — similar to cab or food delivery tracking.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isSubmittingRequest.value
                        ? null
                        : () => controller.requestDoctorVisit(animal: animal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: controller.isSubmittingRequest.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Text(
                            'Submit request',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
