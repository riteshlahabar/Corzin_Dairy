import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../controllers/doctor_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../shop/controllers/shop_controller.dart';
import '../../shop/views/shop_cart_view.dart';

class DoctorAppointmentsNearbyView extends StatefulWidget {
  const DoctorAppointmentsNearbyView({super.key});

  @override
  State<DoctorAppointmentsNearbyView> createState() => _DoctorAppointmentsNearbyViewState();
}

class _DoctorAppointmentsNearbyViewState extends State<DoctorAppointmentsNearbyView> {
  late final DoctorController controller;
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DoctorController>();
    homeController = Get.find<HomeController>();
  }

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
                    Obx(
                      () {
                        final count = homeController.notificationHistory.length;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: _openNotificationSheet,
                              icon: const Icon(Icons.notifications_none_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.black,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 5,
                                top: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18),
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
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
              child: DefaultTabController(
                length: 3,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final currentRequests = controller.sortedRequests
                      .where((request) {
                        final status = request.status.trim().toLowerCase();
                        return status == 'pending' ||
                            status == 'accept' ||
                            status == 'accepted' ||
                            status == 'approved' ||
                            status == 'farmer_approved' ||
                            status == 'in_progress' ||
                            status == 'followup' ||
                            status == 'follow_up';
                      })
                      .toList();
                  final currentCards = List<VetRequestModel>.from(currentRequests)
                    ..sort((a, b) => b.sortDate.compareTo(a.sortDate));
                  final historyRequests = controller.sortedRequests
                      .where((request) => request.status.trim().toLowerCase() == 'completed')
                      .toList();
                  final historyByAnimal = <String, List<VetRequestModel>>{};
                  for (final request in historyRequests) {
                    final key = request.animalId > 0
                        ? 'id_${request.animalId}'
                        : 'name_${request.animalName.trim().toLowerCase()}';
                    historyByAnimal.putIfAbsent(key, () => <VetRequestModel>[]).add(request);
                  }
                  final historyGroups = historyByAnimal.values.map((group) {
                    final copied = List<VetRequestModel>.from(group)
                      ..sort((a, b) => _historySortDate(b).compareTo(_historySortDate(a)));
                    return copied;
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Appointment'),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5EA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const SizedBox(
                                height: 40,
                                child: TabBar(
                                isScrollable: false,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                dividerColor: Colors.transparent,
                                labelColor: Colors.white,
                                unselectedLabelColor: AppColors.primary,
                                labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                labelPadding: EdgeInsets.zero,
                                tabs: [
                                  Tab(text: 'Create'),
                                  Tab(text: 'Current'),
                                  Tab(text: 'History'),
                                ],
                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            RefreshIndicator(
                              onRefresh: controller.initData,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                children: [
                                  if (controller.animals.isEmpty) _emptyCard('No animals added yet.'),
                                  ...controller.animals.map(_animalCreateCard),
                                ],
                              ),
                            ),
                            RefreshIndicator(
                              onRefresh: controller.fetchFarmerRequests,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                children: [
                                  if (controller.isLoadingRequests.value)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                  if (!controller.isLoadingRequests.value && currentCards.isEmpty)
                                    _emptyCard('No current appointments.'),
                                  ...currentCards.map(_currentRequestCard),
                                ],
                              ),
                            ),
                            RefreshIndicator(
                              onRefresh: controller.fetchFarmerRequests,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                                children: [
                                  if (controller.isLoadingRequests.value)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                  if (!controller.isLoadingRequests.value && historyGroups.isEmpty)
                                    _emptyCard('No treatment history yet.'),
                                  ...historyGroups.map(_historyAnimalCard),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotificationSheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await homeController.clearNotificationHistory();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Obx(() {
                if (homeController.notificationHistory.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No notifications yet.'),
                  );
                }

                return SizedBox(
                  height: Get.height * 0.5,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: homeController.notificationHistory.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = homeController.notificationHistory[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE3ECE3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt.toLocal()),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
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

  Widget _animalCreateCard(VetAnimalModel animal) {
    final latestRequest = controller.latestRequestForAnimal(animal.id);
    final normalized = latestRequest?.status.toLowerCase() ?? '';
    final isApprovedState = {
      'accept',
      'accepted',
      'approved',
      'farmer_approved',
      'scheduled',
      'in_progress',
    }.contains(normalized);
    final isPendingState = {
      'pending',
      'new',
      'requested',
      'proposed',
      'awaiting_farmer_approval',
      'awaiting_approval',
    }.contains(normalized);
    final hasStatusFlow = latestRequest != null && normalized != 'completed' && (isApprovedState || isPendingState);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3ECE3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.animalName.isEmpty ? 'Animal' : animal.animalName,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      animal.tagNumber.isEmpty
                          ? 'Tag not available'
                          : 'Tag: ${animal.tagNumber}',
                      style: const TextStyle(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E5A4E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreateAppointmentDialog(animal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text(
                      'Create Appointment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              if (hasStatusFlow && isApprovedState) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _openTrackingView(latestRequest),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _currentRequestCard(VetRequestModel request) {
    final animal = controller.animals.firstWhereOrNull((item) => item.id == request.animalId);
    final normalizedStatus = request.status.toLowerCase();
    final isApprovedState = {
      'accept',
      'accepted',
      'approved',
      'farmer_approved',
      'scheduled',
      'in_progress',
    }.contains(normalizedStatus);
    final isFollowup = {'followup', 'follow_up'}.contains(normalizedStatus);
    final statusColor = isFollowup
        ? const Color(0xFF0D47A1)
        : (isApprovedState ? const Color(0xFF2E7D32) : const Color(0xFFE07A00));
    final statusLabel = isFollowup ? 'Follow-up' : (isApprovedState ? 'Accept' : 'Pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3ECE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.animalName,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11.5, color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Appointment ID: ${request.displayAppointmentCode}',
            style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            animal == null || animal.tagNumber.trim().isEmpty
                ? 'Tag: -'
                : 'Tag: ${animal.tagNumber}',
            style: const TextStyle(fontSize: 12.2, color: AppColors.grey),
          ),
          const SizedBox(height: 4),
          Text('Concern: ${request.concern}', style: const TextStyle(fontSize: 12.2)),
          if (request.scheduledAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Schedule: ${_formatDateLabel(request.scheduledAt)}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (request.charges != '-') ...[
            const SizedBox(height: 4),
            Text('Charges: ${request.charges}', style: const TextStyle(fontSize: 12.2)),
          ],
          if (isFollowup) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: controller.isUpdatingRequestStatus.value
                          ? null
                          : () => controller.cancelFollowup(request: request),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFFC0392B).withValues(alpha: 0.45)),
                        foregroundColor: const Color(0xFFC0392B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Cancel Follow Up',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {
                        final targetAnimal = animal ??
                            VetAnimalModel(
                              id: request.animalId,
                              animalName: request.animalName,
                              tagNumber: '',
                              imageUrl: '',
                            );
                        if (targetAnimal.id <= 0) {
                          Get.snackbar('Error', 'Animal not found for follow-up appointment.');
                          return;
                        }
                        _openCreateAppointmentDialog(targetAnimal);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Create Appointment',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isApprovedState && request.canTrackVisit) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: OutlinedButton.icon(
                onPressed: () => _openTrackingView(request),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text('Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyAnimalCard(List<VetRequestModel> requests) {
    final latest = requests.first;
    final animal = controller.animals.firstWhereOrNull((item) => item.id == latest.animalId);
    final historyCount = requests.length;
    final animalImage = animal?.imageUrl.trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEADC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A16).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: animalImage.isNotEmpty
                          ? Image.network(
                              animalImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.pets_rounded, color: AppColors.primary, size: 22),
                            )
                          : const Icon(Icons.pets_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest.animalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            animal == null || animal.tagNumber.trim().isEmpty
                                ? 'Tag: -'
                                : 'Tag: ${animal.tagNumber}',
                            style: const TextStyle(
                              fontSize: 12.2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4E5A4E),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Latest: ${_formatCardDateTimeLabel(latest.completedAt)}',
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4E5A4E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF7EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Total treatments: $historyCount',
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: () => _openAnimalHistorySheet(requests),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'View History',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openAnimalHistorySheet(List<VetRequestModel> requests) async {
    final sorted = List<VetRequestModel>.from(requests)
      ..sort((a, b) => _historySortDate(b).compareTo(_historySortDate(a)));

    await showModalBottomSheet<void>(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F8F1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F8F1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'History',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final request = sorted[index];
                      final doctorName = request.doctorName.trim();
                      final prefixedName = doctorName.toLowerCase().startsWith('dr.')
                          ? doctorName
                          : 'Dr. ${doctorName.isEmpty ? 'Doctor' : doctorName}';
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openTreatmentDetailsSheet(request);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
                            foregroundColor: AppColors.primary,
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(
                            '$prefixedName • ${_formatDateTimeLabel(request.completedAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTrackingView(VetRequestModel request) async {
    await Get.to(
      () => AppointmentTrackingView(
        appointmentId: request.id,
        doctorName: request.doctorName,
        initialRequest: request,
      ),
    );
  }

  Future<void> _openCreateAppointmentDialog(VetAnimalModel animal) async {
    controller.selectedDiseaseIds.clear();
    controller.diseaseDetailsController.clear();

    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFEAF5EA),
        title: Text('Create Appointment - ${animal.animalName.isEmpty ? 'Animal' : animal.animalName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  : () => controller.requestDoctorVisit(animal: animal),
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

  Future<void> _openTreatmentDetailsSheet(VetRequestModel request) async {
    await showModalBottomSheet<void>(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F8F1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final treatmentText = request.treatmentDetails.trim().isEmpty
            ? 'No treatment details added yet.'
            : request.treatmentDetails.trim();
        final onsiteTreatment = request.onsiteTreatment.trim();
        final notes = request.notes.trim();
        final prescriptionItems = _parsePrescriptionItems(treatmentText);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F8F1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Treatment Details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Appointment ID: ${request.displayAppointmentCode}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text('Doctor: ${request.doctorName}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                'Treatment Date: ${_formatDateTimeLabel(request.completedAt)}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text('Animal: ${request.animalName}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                'Next Follow-up Date: ${_formatDateLabel(request.nextFollowupDate)}',
                style: const TextStyle(fontSize: 13),
              ),
              if (request.fees.trim() != '-' || request.charges.trim() != '-') ...[
                const SizedBox(height: 6),
                Text(
                  'Fees: ${request.fees.trim() != '-' ? request.fees : request.charges}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              if (request.onSiteMedicineCharges.trim() != '-') ...[
                const SizedBox(height: 6),
                Text(
                  'On Site Medicine Charges: ${request.onSiteMedicineCharges}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              if (request.totalCharges.trim() != '-' || request.charges.trim() != '-') ...[
                const SizedBox(height: 6),
                Text(
                  'Total: ${request.totalCharges.trim() != '-' ? request.totalCharges : request.charges}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              if (onsiteTreatment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'On-Site Treatment: $onsiteTreatment',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Notes: $notes',
                  style: const TextStyle(fontSize: 12.8),
                ),
              ],
              const SizedBox(height: 12),
              if (prescriptionItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3ECE3)),
                  ),
                  child: Text(
                    treatmentText,
                    style: const TextStyle(fontSize: 13),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3ECE3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Prescription',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _addPrescriptionToCart(prescriptionItems),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.shopping_cart_outlined, size: 15),
                            label: Text(
                              'shop_add_to_cart'.tr,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...prescriptionItems.map((item) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3ECE3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _doseChip('M', item.times.contains('M')),
                                  _doseChip('A', item.times.contains('A')),
                                  _doseChip('E', item.times.contains('E')),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF5EA),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Total: ${item.totalTabs}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateLabel(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  DateTime _historySortDate(VetRequestModel request) {
    final completed = DateTime.tryParse(request.completedAt.trim());
    if (completed != null) return completed;
    return request.sortDate;
  }

  String _formatDateTimeLabel(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  String _formatCardDateTimeLabel(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM, hh:mm a').format(parsed.toLocal());
  }

  List<_PrescriptionItem> _parsePrescriptionItems(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final parsed = <_PrescriptionItem>[];
    for (final line in lines) {
      // Expected format:
      // 1. Paracetamol | Time: M/A/E | Total Tabs: 5
      final parts = line.split('|').map((part) => part.trim()).toList();
      if (parts.length < 3) continue;

      var medicine = parts[0];
      medicine = medicine.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
      if (medicine.isEmpty) continue;

      final timePart = parts[1].replaceFirst(RegExp(r'^Time:\s*', caseSensitive: false), '').trim();
      final totalPart = parts[2].replaceFirst(RegExp(r'^Total\s*Tabs:\s*', caseSensitive: false), '').trim();

      final times = timePart
          .split('/')
          .map((slot) => slot.trim().toUpperCase())
          .where((slot) => slot == 'M' || slot == 'A' || slot == 'E')
          .toList();

      parsed.add(
        _PrescriptionItem(
          name: medicine,
          times: times,
          totalTabs: totalPart.isEmpty ? '-' : totalPart,
        ),
      );
    }

    return parsed;
  }

  Future<void> _addPrescriptionToCart(List<_PrescriptionItem> items) async {
    if (items.isEmpty) {
      Get.snackbar('Unavailable', 'No prescription medicine found.');
      return;
    }

    final shopController = Get.isRegistered<ShopController>()
        ? Get.find<ShopController>()
        : Get.put(ShopController());

    final requests = items
        .where((item) => item.name.trim().isNotEmpty)
        .map(
          (item) => PrescriptionCartRequest(
            name: item.name.trim(),
            quantity: _parsePrescriptionQuantity(item.totalTabs),
          ),
        )
        .toList();

    if (requests.isEmpty) {
      Get.snackbar('Unavailable', 'No prescription medicine found.');
      return;
    }

    final result = await shopController.addPrescriptionToCart(requests);
    if (!result.hasAdded) return;

    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    Get.to(() => const ShopCartView());
  }

  int _parsePrescriptionQuantity(String totalTabs) {
    final value = totalTabs.trim();
    if (value.isEmpty || value == '-') {
      return 1;
    }
    final match = RegExp(r'\d+').firstMatch(value);
    final qty = int.tryParse(match?.group(0) ?? '1') ?? 1;
    if (qty <= 0) return 1;
    if (qty > 50) return 50;
    return qty;
  }

  Widget _doseChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          color: active ? AppColors.primary : AppColors.grey,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrescriptionItem {
  const _PrescriptionItem({
    required this.name,
    required this.times,
    required this.totalTabs,
  });

  final String name;
  final List<String> times;
  final String totalTabs;
}

class AppointmentTrackingView extends StatefulWidget {
  const AppointmentTrackingView({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.initialRequest,
  });

  final int appointmentId;
  final String doctorName;
  final VetRequestModel initialRequest;

  @override
  State<AppointmentTrackingView> createState() => _AppointmentTrackingViewState();
}

class _AppointmentTrackingViewState extends State<AppointmentTrackingView> {
  late final DoctorController controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DoctorController>();
    // Refresh in background while showing passed appointment instantly.
    controller.fetchFarmerRequests();
  }

  Future<void> _refreshTrackingData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await controller.fetchFarmerRequests();
      await controller.loadDoctors();
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Dr. ${widget.doctorName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final appointment =
            controller.findRequestById(widget.appointmentId) ?? widget.initialRequest;
        final doctor = controller.findDoctorById(appointment.doctorId);
        final doctorName = (doctor?.name.trim().isNotEmpty == true)
            ? doctor!.name.trim()
            : (appointment.doctorName.trim().isNotEmpty ? appointment.doctorName.trim() : 'Doctor');
        final doctorDegree = doctor?.speciality.trim() ?? '';
        final doctorPhone = doctor?.phone.trim() ?? '';

        final hasFarmerPoint = appointment.destLatitude != null && appointment.destLongitude != null;
        final hasDoctorPoint =
            appointment.doctorLiveLatitude != null && appointment.doctorLiveLongitude != null;

        final center = hasDoctorPoint
            ? LatLng(appointment.doctorLiveLatitude!, appointment.doctorLiveLongitude!)
            : hasFarmerPoint
                ? LatLng(appointment.destLatitude!, appointment.destLongitude!)
                : const LatLng(18.5204, 73.8567);

        double? distanceKm;
        int? etaMinutes;
        if (hasFarmerPoint && hasDoctorPoint) {
          final distanceMeters = Geolocator.distanceBetween(
            appointment.destLatitude!,
            appointment.destLongitude!,
            appointment.doctorLiveLatitude!,
            appointment.doctorLiveLongitude!,
          );
          distanceKm = distanceMeters / 1000;
          etaMinutes = ((distanceKm / 30) * 60).ceil();
        }

        return Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.dairycorzin',
                  ),
                  if (hasFarmerPoint || hasDoctorPoint)
                    MarkerLayer(
                      markers: [
                        if (hasFarmerPoint)
                          Marker(
                            point: LatLng(appointment.destLatitude!, appointment.destLongitude!),
                            width: 52,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 1.2),
                              ),
                              child: const Icon(Icons.home_rounded, color: Colors.blue, size: 30),
                            ),
                          ),
                        if (hasDoctorPoint)
                          Marker(
                            point: LatLng(appointment.doctorLiveLatitude!, appointment.doctorLiveLongitude!),
                            width: 52,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 1.2),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 30),
                            ),
                          ),
                        if (hasFarmerPoint && hasDoctorPoint && etaMinutes != null)
                          Marker(
                            point: LatLng(
                              (appointment.destLatitude! + appointment.doctorLiveLatitude!) / 2,
                              (appointment.destLongitude! + appointment.doctorLiveLongitude!) / 2,
                            ),
                            width: 86,
                            height: 32,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$etaMinutes min',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (hasFarmerPoint && hasDoctorPoint)
                    PolylineLayer(
                      polylines: _buildDottedLine(
                        LatLng(appointment.destLatitude!, appointment.destLongitude!),
                        LatLng(appointment.doctorLiveLatitude!, appointment.doctorLiveLongitude!),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: Color(0xFFE3ECE3))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (appointment.canTrackVisit) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. $doctorName',
                                style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w700),
                              ),
                              if (doctorDegree.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  doctorDegree,
                                  style: const TextStyle(fontSize: 12.3, color: AppColors.grey),
                                ),
                              ],
                              if (appointment.charges != '-') ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Fees: ${appointment.charges}',
                                  style: const TextStyle(fontSize: 12.3, color: AppColors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (doctorPhone.isNotEmpty)
                          IconButton(
                            onPressed: () => _openDialPad(doctorPhone),
                            icon: const Icon(Icons.call_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              foregroundColor: AppColors.primary,
                            ),
                            tooltip: 'Call doctor',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Status: ${appointment.status.toUpperCase()}',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (distanceKm != null && etaMinutes != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.social_distance_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Doctor is ${distanceKm.toStringAsFixed(2)} km away',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Estimated arrival: $etaMinutes minutes',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (appointment.address.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.home_rounded, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Farmer address: ${appointment.address}',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else
                    Row(
                      children: const [
                        Icon(Icons.location_searching_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Waiting for doctor live location update...',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : _refreshTrackingData,
                      icon: _isRefreshing
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openDialPad(String rawPhone) async {
    final cleaned = rawPhone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) {
      Get.snackbar('Error', 'Doctor phone number is not available.');
      return;
    }

    final uri = Uri.parse('tel:$cleaned');
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      Get.snackbar('Error', 'Unable to open dial pad on this device.');
    }
  }

  List<Polyline> _buildDottedLine(LatLng start, LatLng end) {
    const segments = 24;
    final polylines = <Polyline>[];
    for (int i = 0; i < segments; i += 2) {
      final t1 = i / segments;
      final t2 = (i + 1) / segments;
      final p1 = LatLng(
        start.latitude + (end.latitude - start.latitude) * t1,
        start.longitude + (end.longitude - start.longitude) * t1,
      );
      final p2 = LatLng(
        start.latitude + (end.latitude - start.latitude) * t2,
        start.longitude + (end.longitude - start.longitude) * t2,
      );
      polylines.add(
        Polyline(
          points: [p1, p2],
          color: const Color(0xFF2E7D32),
          strokeWidth: 4,
        ),
      );
    }
    return polylines;
  }
}
