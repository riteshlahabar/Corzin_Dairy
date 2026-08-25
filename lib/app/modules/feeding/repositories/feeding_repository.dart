import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cached_api_service.dart';
import '../../../core/utils/api.dart';

class FeedingApiResult {
  const FeedingApiResult({required this.statusCode, required this.data});

  final int statusCode;
  final dynamic data;

  bool get isSuccess => statusCode == 200 || statusCode == 201;
}

class FeedingRepository {
  const FeedingRepository({
    this.referenceCacheMaxAge = const Duration(minutes: 10),
    this.dietPlanCacheMaxAge = const Duration(minutes: 2),
    this.scheduleCacheMaxAge = const Duration(minutes: 1),
  });

  final Duration referenceCacheMaxAge;
  final Duration dietPlanCacheMaxAge;
  final Duration scheduleCacheMaxAge;

  Future<int> loadFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('farmer_id') ?? 0;
  }

  Future<Map<String, dynamic>?> fetchAnimals({
    required int farmerId,
    required void Function(Map<String, dynamic> data) onCached,
  }) {
    return CachedApiService.instance.getMap(
      key: 'animal_list_$farmerId',
      uri: Uri.parse('${Api.animalList}/$farmerId'),
      onCached: onCached,
      maxAge: referenceCacheMaxAge,
    );
  }

  Future<Map<String, dynamic>?> fetchFeedTypes({
    required int farmerId,
    required void Function(Map<String, dynamic> data) onCached,
  }) {
    return CachedApiService.instance.getMap(
      key: 'feeding_types_$farmerId',
      uri: Uri.parse('${Api.feedingTypes}?farmer_id=$farmerId'),
      onCached: onCached,
      maxAge: referenceCacheMaxAge,
    );
  }

  Future<Map<String, dynamic>?> fetchDietPlans({
    required int farmerId,
    required Map<String, String> query,
    required void Function(Map<String, dynamic> data) onCached,
    bool forceRefresh = false,
  }) {
    final uri = Uri.parse(
      '${Api.feedingDietPlans}/$farmerId',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final queryKey = query.entries
        .map((entry) => '${entry.key}_${entry.value}')
        .join('_');

    return CachedApiService.instance.getMap(
      key: 'feeding_diet_plans_${farmerId}_$queryKey',
      uri: uri,
      onCached: onCached,
      maxAge: dietPlanCacheMaxAge,
      forceRefresh: forceRefresh,
    );
  }

  Future<Map<String, dynamic>?> fetchSchedule({
    required int farmerId,
    required void Function(Map<String, dynamic> data) onCached,
    bool forceRefresh = false,
  }) {
    return CachedApiService.instance.getMap(
      key: 'feeding_list_$farmerId',
      uri: Uri.parse('${Api.feedingList}/$farmerId'),
      headers: const {'Accept': 'application/json'},
      onCached: onCached,
      maxAge: scheduleCacheMaxAge,
      forceRefresh: forceRefresh,
    );
  }

  Future<FeedingApiResult> submitFeeding(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(Api.addFeeding),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    return FeedingApiResult(statusCode: response.statusCode, data: data);
  }
}
