import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../translations/translations.dart';
import '../utils/api.dart';

class DynamicTranslationService {
  static const String _cacheKey = 'dynamic_translations_cache_v2';

  static Map<String, Map<String, String>> _translations = {
    'en': <String, String>{},
    'hi': <String, String>{},
    'mr': <String, String>{},
  };

  static Map<String, Map<String, String>> get translationMaps => {
    for (final entry in _translations.entries)
      entry.key: Map<String, String>.from(entry.value),
  };

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Cached translation is available immediately.
    _applyFromCache(prefs.getString(_cacheKey));

    // Do not block app startup while waiting for the server.
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    try {
      final response = await http.get(
        Uri.parse(Api.appTranslations),
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body);
      final source = _extractPayload(decoded);
      if (source == null) {
        return;
      }

      final mapped = _parseLanguageMaps(source);
      _setTranslations(mapped);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_translations));

      if (Get.isRegistered<GetMaterialController>()) {
        Get.forceAppUpdate();
      }
    } catch (_) {}
  }

  static Map<String, dynamic>? _extractPayload(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final rawData = decoded['data'];
      if (rawData is Map) {
        return Map<String, dynamic>.from(rawData);
      }
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static void _applyFromCache(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      final source = _extractPayload(decoded);
      if (source == null) {
        return;
      }
      _setTranslations(_parseLanguageMaps(source));
    } catch (_) {}
  }

  static void _setTranslations(Map<String, Map<String, String>> values) {
    _translations = {
      'en': <String, String>{},
      'hi': Map<String, String>.from(values['hi'] ?? const <String, String>{}),
      'mr': Map<String, String>.from(values['mr'] ?? const <String, String>{}),
    };
    TranslationRegistry.setRemoteTranslations(_translations);
  }

  static Map<String, Map<String, String>> _parseLanguageMaps(
    Map<String, dynamic> raw,
  ) {
    final result = <String, Map<String, String>>{
      'en': <String, String>{},
      'hi': <String, String>{},
      'mr': <String, String>{},
    };

    for (final code in const ['hi', 'mr']) {
      final source = raw[code];
      if (source is! Map) {
        continue;
      }

      final target = result[code]!;
      source.forEach((key, value) {
        final normalizedKey = key.toString().trim();
        final normalizedValue = value?.toString().trim() ?? '';
        if (normalizedKey.isEmpty || normalizedValue.isEmpty) {
          return;
        }
        target[normalizedKey] = normalizedValue;
      });
    }

    return result;
  }
}
