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

  Future<bool> saveFeedSubtypes({
    required int feedTypeId,
    required List<String> subtypes,
  }) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return false;
    }
    if (feedTypeId <= 0) {
      Get.snackbar('error'.tr, 'select_feed_type_error'.tr);
      return false;
    }
    try {
      isSaving.value = true;
      final payload = {
        'farmer_id': farmerId.toString(),
        'feed_type_id': feedTypeId.toString(),
        'subtypes': subtypes.map((subtype) => {'name': subtype}).toList(),
      };
      final uri = Uri.parse('${Api.feedingTypeSubtypeCreate}/$feedTypeId/subtypes');
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
      Get.snackbar('error'.tr, _extractApiMessage(data) ?? 'unable_save_feed_subtypes'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateFeedSubtype({
    required int feedTypeId,
    required int subtypeId,
    required String name,
  }) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return false;
    }
    final cleanName = name.trim();
    if (feedTypeId <= 0 || subtypeId <= 0 || cleanName.isEmpty) {
      Get.snackbar('error'.tr, 'invalid_subtype_update_payload'.tr);
      return false;
    }
    try {
      isSaving.value = true;
      final payload = {
        'farmer_id': farmerId.toString(),
        'feed_type_id': feedTypeId.toString(),
        'name': cleanName,
      };
      final uri = Uri.parse(
        '${Api.feedingTypeSubtypeUpdate}/$feedTypeId/subtypes/$subtypeId/update',
      );
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
      Get.snackbar('error'.tr, _extractApiMessage(data) ?? 'unable_update_feed_subtype'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteFeedSubtype({
    required int feedTypeId,
    required int subtypeId,
  }) async {
    if (farmerId == 0) {
      Get.snackbar('error'.tr, 'farmer_not_found_login_again'.tr);
      return false;
    }
    if (feedTypeId <= 0 || subtypeId <= 0) {
      Get.snackbar('error'.tr, 'invalid_subtype_delete_payload'.tr);
      return false;
    }
    try {
      isSaving.value = true;
      final payload = {
        'farmer_id': farmerId.toString(),
        'feed_type_id': feedTypeId.toString(),
      };
      final uri = Uri.parse(
        '${Api.feedingTypeSubtypeDelete}/$feedTypeId/subtypes/$subtypeId/delete',
      );
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
      Get.snackbar('error'.tr, _extractApiMessage(data) ?? 'unable_delete_feed_subtype'.tr);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  String? _extractApiMessage(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    if (message is Map) {
      final values = message.values.toList();
      if (values.isNotEmpty) {
        final first = values.first;
        if (first is List && first.isNotEmpty) {
          return first.first?.toString();
        }
        return first?.toString();
      }
    }
    return null;
  }
}

class FeedTypeSettingModel {
  final int id;
  final String name;
  final String defaultUnit;
  final bool canAddFarmerSubtype;
  final List<FeedSubtypeSettingModel> subtypes;

  FeedTypeSettingModel({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.canAddFarmerSubtype,
    required this.subtypes,
  });

  factory FeedTypeSettingModel.fromJson(Map<String, dynamic> json) {
    final List rawSubtypes = json['subtypes'] is List ? (json['subtypes'] as List) : const [];
    return FeedTypeSettingModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      defaultUnit: json['default_unit']?.toString() ?? 'Kg',
      canAddFarmerSubtype: json['can_add_farmer_subtype'] == true,
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
