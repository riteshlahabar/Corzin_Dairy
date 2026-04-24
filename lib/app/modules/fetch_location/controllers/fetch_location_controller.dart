import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/session_service.dart';
import '../../../core/utils/api.dart';

class FetchLocationController extends GetxController {
  final RxBool isFetching = false.obs;
  final RxString latitude = ''.obs;
  final RxString longitude = ''.obs;
  final RxString currentAddress = ''.obs;

  int farmerId = 0;
  String mobile = '';

  @override
  void onInit() {
    super.onInit();
    _loadFromSession();
  }

  Future<void> _loadFromSession() async {
    farmerId = await SessionService.getFarmerId();
    mobile = await SessionService.getMobile();
    final profile = await SessionService.getFarmerProfile();
    latitude.value = (profile['latitude'] ?? '').trim();
    longitude.value = (profile['longitude'] ?? '').trim();
    currentAddress.value = (profile['current_location_address'] ?? '').trim();

    if (farmerId <= 0 && mobile.trim().isNotEmpty) {
      await _resolveFarmerIdByMobile();
    }
    if (currentAddress.value.isEmpty && mobile.trim().isNotEmpty) {
      await refreshFromBackend();
    }
  }

  Future<void> refreshFromBackend() async {
    if (mobile.trim().isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: const {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || data['status'] != true || data['data'] == null) {
        return;
      }

      final payload = Map<String, dynamic>.from(data['data'] as Map);
      final idRaw = payload['id'];
      final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
      if (id > 0) {
        farmerId = id;
        await SessionService.saveFarmerId(id);
      }

      latitude.value = payload['latitude']?.toString().trim() ?? latitude.value;
      longitude.value = payload['longitude']?.toString().trim() ?? longitude.value;
      currentAddress.value =
          payload['current_location_address']?.toString().trim().isNotEmpty == true
              ? payload['current_location_address'].toString().trim()
              : currentAddress.value;

      await SessionService.saveFarmerLocation(
        latitude: latitude.value,
        longitude: longitude.value,
        currentLocationAddress: currentAddress.value,
      );
    } catch (_) {}
  }

  Future<void> fetchCurrentLocation() async {
    if (isFetching.value) return;
    try {
      isFetching.value = true;

      if (farmerId <= 0) {
        await _resolveFarmerIdByMobile();
      }
      if (farmerId <= 0) {
        Get.snackbar('Error', 'Farmer profile not found. Please login again.');
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Off', 'Please enable location service and try again.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        Get.snackbar('Permission Required', 'Please allow location permission to continue.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await _saveLocationToBackend(
        latitudeValue: position.latitude,
        longitudeValue: position.longitude,
      );
    } catch (error) {
      Get.snackbar('Error', error.toString());
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> _saveLocationToBackend({
    required double latitudeValue,
    required double longitudeValue,
  }) async {
    final response = await http.post(
      Uri.parse('${Api.farmerLocation}/$farmerId'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': latitudeValue,
        'longitude': longitudeValue,
      }),
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode != 200 || data['status'] != true || data['data'] == null) {
      final msg = data is Map ? (data['message']?.toString() ?? 'Failed to save location.') : 'Failed to save location.';
      Get.snackbar('Error', msg);
      return;
    }

    final payload = Map<String, dynamic>.from(data['data'] as Map);
    final latText = (payload['latitude']?.toString() ?? latitudeValue.toStringAsFixed(7)).trim();
    final lngText = (payload['longitude']?.toString() ?? longitudeValue.toStringAsFixed(7)).trim();
    final addressText =
        payload['current_location_address']?.toString().trim().isNotEmpty == true
            ? payload['current_location_address'].toString().trim()
            : 'Lat: $latText, Lng: $lngText';

    latitude.value = latText;
    longitude.value = lngText;
    currentAddress.value = addressText;

    await SessionService.saveFarmerLocation(
      latitude: latText,
      longitude: lngText,
      currentLocationAddress: addressText,
    );

    Get.snackbar('Success', data['message']?.toString() ?? 'Current location fetched successfully.');
  }

  Future<void> _resolveFarmerIdByMobile() async {
    if (mobile.trim().isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('${Api.farmerProfileByMobile}/$mobile'),
        headers: const {'Accept': 'application/json'},
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode != 200 || data['status'] != true || data['data'] == null) {
        return;
      }
      final payload = Map<String, dynamic>.from(data['data'] as Map);
      final idRaw = payload['id'];
      final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '0') ?? 0;
      if (id > 0) {
        farmerId = id;
        await SessionService.saveFarmerId(id);
      }
    } catch (_) {}
  }
}

