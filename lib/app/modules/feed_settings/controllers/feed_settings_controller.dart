import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/api.dart';

class FeedSettingsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxList<FeedTypeSettingModel> feedTypes = <FeedTypeSettingModel>[].obs;

  int farmerId = 0;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await _loadFarmerId();
    await fetchFeedTypes();
  }

  Future<void> _loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getInt('farmer_id') ?? 0;
  }

  Future<void> fetchFeedTypes() async {
    if (farmerId == 0) return;
    try {
      isLoading.value = true;
      final uri = Uri.parse('${Api.feedingTypes}?farmer_id=$farmerId');
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 && data['status'] == true) {
        final List list = data['data'] ?? [];
        feedTypes.assignAll(list.map((item) => FeedTypeSettingModel.fromJson(item)).toList());
      } else {
        feedTypes.clear();
      }
    } catch (_) {
      feedTypes.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveFeedType({
    int? feedTypeId,
    required String name,
    required String defaultUnit,
    required List<String> subtypes,
  }) async {
    if (farmerId == 0) {
      Get.snackbar('Error', 'Farmer not found. Please login again.');
      return false;
    }
    try {
      isSaving.value = true;
      final payload = {
        'farmer_id': farmerId.toString(),
        'name': name.trim(),
        'default_unit': defaultUnit.trim(),
        'subtypes': subtypes.map((subtype) => {'name': subtype}).toList(),
      };
      final uri = feedTypeId == null
          ? Uri.parse(Api.feedingTypeCreate)
          : Uri.parse('${Api.feedingTypeUpdate}/$feedTypeId/update');
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchFeedTypes();
        return true;
      }
      Get.snackbar('Error', data['message']?.toString() ?? 'Unable to save feed type');
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}

class FeedTypeSettingModel {
  final int id;
  final String name;
  final String defaultUnit;
  final List<FeedSubtypeSettingModel> subtypes;

  FeedTypeSettingModel({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.subtypes,
  });

  factory FeedTypeSettingModel.fromJson(Map<String, dynamic> json) {
    final List rawSubtypes = json['subtypes'] is List ? (json['subtypes'] as List) : const [];
    return FeedTypeSettingModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      defaultUnit: json['default_unit']?.toString() ?? 'Kg',
      subtypes: rawSubtypes
          .map((item) => FeedSubtypeSettingModel.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class FeedSubtypeSettingModel {
  final int id;
  final String name;

  FeedSubtypeSettingModel({required this.id, required this.name});

  factory FeedSubtypeSettingModel.fromJson(Map<String, dynamic> json) {
    return FeedSubtypeSettingModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
