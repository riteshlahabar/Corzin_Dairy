import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalApiCacheService {
  LocalApiCacheService._();

  static final LocalApiCacheService instance = LocalApiCacheService._();

  Directory? _cacheDir;

  Future<Map<String, dynamic>?> readMap(String key) async {
    final text = await _readText(key);
    if (text == null || text.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> readList(String key) async {
    final text = await _readText(key);
    if (text == null || text.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> writeJson(String key, dynamic value) async {
    try {
      final file = await _fileForKey(key);
      await file.writeAsString(jsonEncode(value), flush: false);
    } catch (_) {}
  }

  Future<bool> isFresh(String key, Duration maxAge) async {
    try {
      final file = await _fileForKey(key);
      if (!await file.exists()) return false;
      final modified = await file.lastModified();
      return DateTime.now().difference(modified) <= maxAge;
    } catch (_) {
      return false;
    }
  }

  Future<void> remove(String key) async {
    try {
      final file = await _fileForKey(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<String?> _readText(String key) async {
    try {
      final file = await _fileForKey(key);
      if (!await file.exists()) return null;
      return file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<File> _fileForKey(String key) async {
    final dir = await _directory();
    return File('${dir.path}/${_safeKey(key)}.json');
  }

  Future<Directory> _directory() async {
    final current = _cacheDir;
    if (current != null) return current;

    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/api_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _safeKey(String value) {
    final bytes = utf8.encode(value);
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
