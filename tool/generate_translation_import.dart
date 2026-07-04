import 'dart:io';

class _ParseResult {
  const _ParseResult(this.value, this.nextIndex);
  final String value;
  final int nextIndex;
}

void main() {
  final sourcePath = 'lib/app/core/translations/translations.dart';
  final outputPath = 'translation_import_from_translations.csv';
  final source = File(sourcePath).readAsStringSync();

  final en = {
    ..._parseMap(source, '_en'),
    ..._parseMap(source, '_enExtra'),
  };
  final hi = {
    ..._parseMap(source, '_hi'),
    ..._parseMap(source, '_hiExtra'),
  };
  final mr = {
    ..._parseMap(source, '_mr'),
    ..._parseMap(source, '_mrExtra'),
  };

  final allKeys = <String>{...en.keys, ...hi.keys, ...mr.keys}.toList()..sort();

  final buffer = StringBuffer();
  buffer.write('\uFEFF');
  buffer.writeln('group_name,translation_key,en_value,hi_value,mr_value,is_active');

  for (final key in allKeys) {
    final enValue = en[key] ?? '';
    final hiValue = _resolvedLocalizedValue(hi[key], enValue);
    final mrValue = _resolvedLocalizedValue(mr[key], enValue);

    final row = [
      _groupFor(key),
      key,
      enValue,
      hiValue,
      mrValue,
      '1',
    ].map(_csv).join(',');
    buffer.writeln(row);
  }

  File(outputPath).writeAsStringSync(buffer.toString());
  stdout.writeln('Generated: $outputPath');
  stdout.writeln('Rows: ${allKeys.length}');
}

Map<String, String> _parseMap(String source, String mapName) {
  final marker = "const Map<String, String> $mapName = {";
  final start = source.indexOf(marker);
  if (start == -1) {
    throw StateError('Map $mapName not found');
  }

  var index = start + marker.length;
  final result = <String, String>{};

  while (index < source.length) {
    index = _skipWhitespace(source, index);
    if (index >= source.length) break;
    if (source[index] == '}') break;
    if (source[index] != "'") {
      index++;
      continue;
    }

    final keyResult = _readStringLiteral(source, index);
    final key = keyResult.value;
    index = _skipWhitespace(source, keyResult.nextIndex);
    if (index >= source.length || source[index] != ':') {
      throw StateError('Expected : after key $key in $mapName');
    }
    index++;

    final valueBuffer = StringBuffer();
    while (true) {
      index = _skipWhitespace(source, index);
      if (index < source.length && source[index] == "'") {
        final valueResult = _readStringLiteral(source, index);
        valueBuffer.write(valueResult.value);
        index = valueResult.nextIndex;
        continue;
      }
      break;
    }

    result[key] = valueBuffer.toString();

    while (index < source.length && source[index] != ',') {
      if (source[index] == '}') {
        return result;
      }
      index++;
    }
    if (index < source.length && source[index] == ',') {
      index++;
    }
  }

  return result;
}

int _skipWhitespace(String source, int index) {
  while (index < source.length) {
    final char = source[index];
    if (char == ' ' || char == '\n' || char == '\r' || char == '\t') {
      index++;
      continue;
    }
    break;
  }
  return index;
}

_ParseResult _readStringLiteral(String source, int start) {
  if (source[start] != "'") {
    throw StateError('String literal must start with single quote');
  }

  final buffer = StringBuffer();
  var index = start + 1;
  while (index < source.length) {
    final char = source[index];
    if (char == r'\') {
      if (index + 1 >= source.length) break;
      final next = source[index + 1];
      switch (next) {
        case 'n':
          buffer.write('\n');
          break;
        case 'r':
          buffer.write('\r');
          break;
        case 't':
          buffer.write('\t');
          break;
        case "'":
          buffer.write("'");
          break;
        case r'\':
          buffer.write(r'\');
          break;
        case 'u':
          final unicode = _readUnicodeEscape(source, index);
          buffer.write(unicode.value);
          index = unicode.nextIndex;
          continue;
        default:
          buffer.write(next);
          break;
      }
      index += 2;
      continue;
    }
    if (char == "'") {
      return _ParseResult(buffer.toString(), index + 1);
    }
    buffer.write(char);
    index++;
  }

  throw StateError('Unterminated string literal');
}

_ParseResult _readUnicodeEscape(String source, int slashIndex) {
  final sequenceStart = slashIndex + 2;
  final sequenceEnd = sequenceStart + 4;
  if (sequenceEnd > source.length) {
    throw StateError('Incomplete unicode escape sequence');
  }

  final hex = source.substring(sequenceStart, sequenceEnd);
  final codePoint = int.tryParse(hex, radix: 16);
  if (codePoint == null) {
    throw StateError('Invalid unicode escape sequence: \\u$hex');
  }

  return _ParseResult(String.fromCharCode(codePoint), sequenceEnd);
}

String _resolvedLocalizedValue(String? localizedValue, String fallbackValue) {
  final normalized = localizedValue?.trim() ?? '';
  if (normalized.isNotEmpty) {
    return normalized;
  }
  return fallbackValue;
}

String _csv(String value) {
  final normalized = value.replaceAll('"', '""');
  return '"$normalized"';
}

String _groupFor(String key) {
  final value = key.toLowerCase();

  if (value.contains('animal') ||
      value.contains('cow') ||
      value.contains('calf') ||
      value.contains('heifer') ||
      value.contains('bull') ||
      value.contains('breed') ||
      value.contains('lactation') ||
      value.contains('tag') ||
      value.contains('pan') ||
      value.contains('pen')) {
    return 'animal';
  }
  if (value.contains('milk') || value.contains('snf') || value.contains('shift')) {
    return 'milk';
  }
  if (value.contains('feed') ||
      value.contains('diet') ||
      value.contains('fodder') ||
      value.contains('feeding') ||
      value.contains('subtype') ||
      value.contains('dry_matter') ||
      value.contains('dmi')) {
    return 'feeding';
  }
  if (value.contains('pregnancy') ||
      value.contains('calving') ||
      value.contains('mastitis') ||
      value.contains('vaccine') ||
      value.contains('vaccination') ||
      value.contains('disease') ||
      value.contains('medical')) {
    return 'health';
  }
  if (value.contains('doctor') || value.contains('appointment')) {
    return 'doctor';
  }
  if (value.contains('payment') ||
      value.contains('plan') ||
      value.contains('subscription') ||
      value.contains('razorpay') ||
      value.contains('upgrade')) {
    return 'payment';
  }
  if (value.contains('report') || value.contains('profit') || value.contains('loss') || value.contains('export')) {
    return 'report';
  }
  if (value.contains('dairy')) {
    return 'dairy';
  }
  if (value.contains('shop') || value.contains('cart') || value.contains('order') || value.contains('product')) {
    return 'shop';
  }
  if (value.contains('language') || value.contains('login') || value.contains('otp') || value.contains('profile') || value.contains('home') || value.contains('dashboard')) {
    return 'common';
  }
  return 'common';
}
