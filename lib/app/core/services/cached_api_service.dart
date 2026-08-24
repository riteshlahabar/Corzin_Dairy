import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_api_cache_service.dart';

class CachedApiService {
  CachedApiService._();

  static final CachedApiService instance = CachedApiService._();
  final LocalApiCacheService _cache = LocalApiCacheService.instance;

  Future<Map<String, dynamic>?> getMap({
    required String key,
    required Uri uri,
    Map<String, String> headers = const {'Accept': 'application/json'},
    void Function(Map<String, dynamic> cached)? onCached,
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    final cached = await _cache.readMap(key);
    if (!forceRefresh && cached != null) {
      onCached?.call(cached);
      if (maxAge != null && await _cache.isFresh(key, maxAge)) {
        return cached;
      }
    }

    try {
      final response = await http.get(uri, headers: headers);
      final decoded = _decodeMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _cache.writeJson(key, decoded);
      }
      return decoded;
    } catch (_) {
      return cached;
    }
  }

  Future<List<dynamic>?> getList({
    required String key,
    required Uri uri,
    Map<String, String> headers = const {'Accept': 'application/json'},
    void Function(List<dynamic> cached)? onCached,
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    final cached = await _cache.readList(key);
    if (!forceRefresh && cached != null) {
      onCached?.call(cached);
      if (maxAge != null && await _cache.isFresh(key, maxAge)) {
        return cached;
      }
    }

    try {
      final response = await http.get(uri, headers: headers);
      final decoded = _decodeList(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _cache.writeJson(key, decoded);
      }
      return decoded;
    } catch (_) {
      return cached;
    }
  }

  Future<Map<String, dynamic>?> getMapPreferCache({
    required String key,
    required Uri uri,
    Map<String, String> headers = const {'Accept': 'application/json'},
  }) async {
    final cached = await _cache.readMap(key);
    if (cached != null) {
      unawaited(getMap(key: key, uri: uri, headers: headers));
      return cached;
    }
    return getMap(key: key, uri: uri, headers: headers);
  }

  Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
  }

  List<dynamic> _decodeList(String body) {
    if (body.trim().isEmpty) return <dynamic>[];
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    return <dynamic>[];
  }
}
