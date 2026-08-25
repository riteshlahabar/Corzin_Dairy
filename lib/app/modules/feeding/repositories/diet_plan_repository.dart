import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cached_api_service.dart';
import '../../../core/utils/api.dart';

class DietPlanApiResult {
  const DietPlanApiResult({required this.statusCode, required this.data});

  final int statusCode;
  final dynamic data;

  bool get isSuccess => statusCode == 200 || statusCode == 201;
}

class DietPlanRepository {
  const DietPlanRepository();

  Future<int> loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('farmer_id') ?? 0;
  }

  Future<DietPlanApiResult> fetchAnimals(
    int farmerId, {
    void Function(Map<String, dynamic> data)? onCached,
    bool forceRefresh = false,
  }) async {
    final data = await CachedApiService.instance.getMap(
      key: 'animal_list_$farmerId',
      uri: Uri.parse('${Api.animalList}/$farmerId'),
      onCached: onCached,
      forceRefresh: forceRefresh,
    );
    return DietPlanApiResult(statusCode: data == null ? 0 : 200, data: data ?? {});
  }

  Future<DietPlanApiResult> fetchFeedTypes(
    int farmerId, {
    void Function(Map<String, dynamic> data)? onCached,
    bool forceRefresh = false,
  }) async {
    final data = await CachedApiService.instance.getMap(
      key: 'feeding_types_$farmerId',
      uri: Uri.parse('${Api.feedingTypes}?farmer_id=$farmerId'),
      onCached: onCached,
      forceRefresh: forceRefresh,
    );
    return DietPlanApiResult(statusCode: data == null ? 0 : 200, data: data ?? {});
  }

  Future<DietPlanApiResult> fetchPlans(
    int farmerId, {
    void Function(Map<String, dynamic> data)? onCached,
    bool forceRefresh = false,
  }) async {
    final data = await CachedApiService.instance.getMap(
      key: 'diet_plan_list_${farmerId}_include_metrics_1',
      uri: Uri.parse(
        '${Api.feedingDietPlans}/$farmerId',
      ).replace(queryParameters: {'include_metrics': '1'}),
      onCached: onCached,
      forceRefresh: forceRefresh,
    );
    return DietPlanApiResult(statusCode: data == null ? 0 : 200, data: data ?? {});
  }

  Future<DietPlanApiResult> fetchMetrics(
    Map<String, String> params, {
    void Function(Map<String, dynamic> data)? onCached,
    bool forceRefresh = false,
  }) async {
    final queryKey = params.entries
        .map((entry) => '${entry.key}_${entry.value}')
        .join('_');
    final data = await CachedApiService.instance.getMap(
      key: 'diet_plan_metrics_$queryKey',
      uri: Uri.parse(Api.feedingDietMetrics).replace(queryParameters: params),
      onCached: onCached,
      forceRefresh: forceRefresh,
    );
    return DietPlanApiResult(statusCode: data == null ? 0 : 200, data: data ?? {});
  }

  Future<DietPlanApiResult> savePlan(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(Api.feedingDietPlans),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    return _resultFromResponse(response);
  }

  Future<DietPlanApiResult> updatePlan({
    required int planId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.post(
      Uri.parse('${Api.feedingDietPlanUpdate}/$planId/update'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    return _resultFromResponse(response);
  }

  Future<DietPlanApiResult> deletePlan({
    required int planId,
    required int farmerId,
  }) async {
    final response = await http.post(
      Uri.parse('${Api.feedingDietPlanDelete}/$planId/delete'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'farmer_id': farmerId.toString()}),
    );
    return _resultFromResponse(response);
  }

  DietPlanApiResult _resultFromResponse(http.Response response) {
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    return DietPlanApiResult(statusCode: response.statusCode, data: data);
  }
}
