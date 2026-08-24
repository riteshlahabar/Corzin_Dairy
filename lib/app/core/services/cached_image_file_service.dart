import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CachedImageFileService {
  CachedImageFileService._();

  static final CachedImageFileService instance = CachedImageFileService._();

  final Map<String, Future<File?>> _downloads = <String, Future<File?>>{};
  Directory? _cacheDir;

  Future<File?> getImageFile(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return null;

    final file = await _fileForUrl(trimmedUrl);
    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    return _downloads.putIfAbsent(trimmedUrl, () async {
      try {
        final response = await http.get(Uri.parse(trimmedUrl));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        await file.writeAsBytes(response.bodyBytes, flush: false);
        return file;
      } catch (_) {
        return null;
      } finally {
        _downloads.remove(trimmedUrl);
      }
    });
  }

  void preCacheImages(Iterable<String> urls) {
    for (final url in urls) {
      final trimmedUrl = url.trim();
      if (trimmedUrl.isEmpty) continue;
      unawaited(getImageFile(trimmedUrl));
    }
  }

  Future<File> _fileForUrl(String url) async {
    final dir = await _directory();
    return File('${dir.path}/${_safeKey(url)}.img');
  }

  Future<Directory> _directory() async {
    final current = _cacheDir;
    if (current != null) return current;

    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/image_cache');
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
