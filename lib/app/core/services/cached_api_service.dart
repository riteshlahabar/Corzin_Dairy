import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'local_api_cache_service.dart';

class CachedApiService {
  CachedApiService._();

  static final CachedApiService instance = CachedApiService._();
  final LocalApiCacheService _cache = LocalApiCacheService.instance;

  // Prevent identical GET requests from hitting Laravel simultaneously.
  final Map<String, Future<http.Response>> _inFlightGets =
      <String, Future<http.Response>>{};

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
      final response = await _deduplicatedGet(uri, headers);
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
      final response = await _deduplicatedGet(uri, headers);
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

  Future<http.Response> _deduplicatedGet(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final headerEntries = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final requestKey =
        '${uri.toString()}|${headerEntries.map((e) => '${e.key}:${e.value}').join('|')}';

    final existingRequest = _inFlightGets[requestKey];
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = http.get(uri, headers: headers);
    _inFlightGets[requestKey] = request;

    try {
      return await request;
    } finally {
      if (identical(_inFlightGets[requestKey], request)) {
        _inFlightGets.remove(requestKey);
      }
    }
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
