import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/colors.dart';
import '../controllers/doctor_controller.dart';

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earth * c;
}

double _toRad(double deg) => deg * math.pi / 180.0;

class TrackDoctorVisitView extends StatefulWidget {
  const TrackDoctorVisitView({super.key});

  @override
  State<TrackDoctorVisitView> createState() => _TrackDoctorVisitViewState();
}

class _TrackDoctorVisitViewState extends State<TrackDoctorVisitView> {
  Timer? _poll;
  final MapController _mapController = MapController();
  int? _appointmentId;

  @override
  void initState() {
    super.initState();
    final raw = Get.arguments;
    _appointmentId = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final c = Get.find<DoctorController>();
    await c.fetchFarmerRequests();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _poll?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DoctorController>();
    final id = _appointmentId ?? 0;
    final req = controller.requests.cast<VetRequestModel?>().firstWhere(
          (r) => r?.id == id,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text(
          'Live tracking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: req == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE3ECE3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.doctorName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${req.animalName} · ${req.status}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                        ),
                        if (req.doctorLiveLatitude != null &&
                            req.doctorLiveLongitude != null &&
                            req.destLatitude != null &&
                            req.destLongitude != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Doctor is ~${_haversineKm(
                              req.doctorLiveLatitude!,
                              req.doctorLiveLongitude!,
                              req.destLatitude!,
                              req.destLongitude!,
                            ).toStringAsFixed(1)} km from your pin',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ] else if (req.doctorLiveUpdatedAt.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Waiting for doctor GPS…',
                            style: TextStyle(fontSize: 12.5, color: AppColors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildMap(req)),
              ],
            ),
    );
  }

  Widget _buildMap(VetRequestModel req) {
    final dest = req.destLatitude != null && req.destLongitude != null
        ? LatLng(req.destLatitude!, req.destLongitude!)
        : null;
    final doc = req.doctorLiveLatitude != null && req.doctorLiveLongitude != null
        ? LatLng(req.doctorLiveLatitude!, req.doctorLiveLongitude!)
        : null;

    LatLng center;
    double zoom = 13;
    if (dest != null && doc != null) {
      center = LatLng(
        (dest.latitude + doc.latitude) / 2,
        (dest.longitude + doc.longitude) / 2,
      );
      zoom = 12;
    } else if (dest != null) {
      center = dest;
    } else if (doc != null) {
      center = doc;
    } else {
      center = const LatLng(20.5937, 78.9629);
      zoom = 5;
    }

    final markers = <Marker>[];
    if (dest != null) {
      markers.add(
        Marker(
          width: 48,
          height: 48,
          point: dest,
          child: const Icon(Icons.home_rounded, color: Color(0xFF2E7D32), size: 40),
        ),
      );
    }
    if (doc != null) {
      markers.add(
        Marker(
          width: 48,
          height: 48,
          point: doc,
          child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFC62828), size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 3,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dairy.corzin',
          ),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
