import 'dart:io';

class _ParseResult {
  const _ParseResult(this.value, this.nextIndex);
  final String value;
  final int nextIndex;
}

void main() {
  final source = File('lib/app/core/translations/translations.dart').readAsStringSync();
  final en = {..._parseMap(source, '_en'), ..._parseMap(source, '_enExtra')};
  final hi = {..._parseMap(source, '_hi'), ..._parseMap(source, '_hiExtra')};
  final mr = {..._parseMap(source, '_mr'), ..._parseMap(source, '_mrExtra')};

  final keys = <String>{...en.keys, ...hi.keys, ...mr.keys}.toList()..sort();

  final importBuffer = StringBuffer();
  importBuffer.write('\uFEFF');
  importBuffer.writeln('group_name,translation_key,en_value,hi_value,mr_value,is_active');

  final missingBuffer = StringBuffer();
  missingBuffer.write('\uFEFF');
  missingBuffer.writeln('group_name,translation_key,en_value,missing_hi,missing_mr');

  var missingCount = 0;

  for (final key in keys) {
    final enValue = en[key] ?? '';
    final hiValue = (hi[key] ?? '').trim();
    final mrValue = (mr[key] ?? '').trim();

    importBuffer.writeln([
      _groupFor(key),
      key,
      enValue,
      hiValue,
      mrValue,
      '1',
    ].map(_csv).join(','));

    final hiMissing = hiValue.isEmpty || hiValue == enValue;
    final mrMissing = mrValue.isEmpty || mrValue == enValue;
    if (hiMissing || mrMissing) {
      missingCount++;
      missingBuffer.writeln([
        _groupFor(key),
        key,
        enValue,
        hiMissing ? '1' : '0',
        mrMissing ? '1' : '0',
      ].map(_csv).join(','));
    }
  }

  File('translation_import_exact_from_translations.csv').writeAsStringSync(importBuffer.toString());
  File('translation_missing_hi_mr.csv').writeAsStringSync(missingBuffer.toString());

  stdout.writeln('Generated: translation_import_exact_from_translations.csv');
  stdout.writeln('Generated: translation_missing_hi_mr.csv');
  stdout.writeln('Rows: ${keys.length}');
  stdout.writeln('Missing rows: $missingCount');
}

Map<String, String> _parseMap(String source, String mapName) {
  final marker = "const Map<String, String> $mapName = {";
  final start = source.indexOf(marker);
  if (start == -1) throw StateError('Map $mapName not found');
  var index = start + marker.length;
  final result = <String, String>{};
  while (index < source.length) {
    index = _skipWhitespace(source, index);
    if (index >= source.length || source[index] == '}') break;
    if (source[index] != "'") {
      index++;
      continue;
    }
    final keyResult = _readStringLiteral(source, index);
    final key = keyResult.value;
    index = _skipWhitespace(source, keyResult.nextIndex);
    if (index >= source.length || source[index] != ':') throw StateError('Expected : after $key');
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
      if (source[index] == '}') return result;
      index++;
    }
    if (index < source.length && source[index] == ',') index++;
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
  final buffer = StringBuffer();
  var index = start + 1;
  while (index < source.length) {
    final char = source[index];
    if (char == r'\') {
      final next = source[index + 1];
      switch (next) {
        case 'n': buffer.write('\n'); break;
        case 'r': buffer.write('\r'); break;
        case 't': buffer.write('\t'); break;
        case "'": buffer.write("'"); break;
        case r'\': buffer.write(r'\'); break;
        case 'u':
          final hex = source.substring(index + 2, index + 6);
          buffer.write(String.fromCharCode(int.parse(hex, radix: 16)));
          index += 6;
          continue;
        default: buffer.write(next); break;
      }
      index += 2;
      continue;
    }
    if (char == "'") return _ParseResult(buffer.toString(), index + 1);
    buffer.write(char);
    index++;
  }
  throw StateError('Unterminated string');
}

String _csv(String value) => '"${value.replaceAll('"', '""')}"';

String _groupFor(String key) {
  final value = key.toLowerCase();
  if (value.contains('animal') || value.contains('cow') || value.contains('calf') || value.contains('heifer') || value.contains('bull') || value.contains('breed') || value.contains('lactation') || value.contains('tag') || value.contains('pan') || value.contains('pen')) return 'animal';
  if (value.contains('milk') || value.contains('snf') || value.contains('shift')) return 'milk';
  if (value.contains('feed') || value.contains('diet') || value.contains('fodder') || value.contains('feeding') || value.contains('subtype') || value.contains('dry_matter') || value.contains('dmi')) return 'feeding';
  if (value.contains('pregnancy') || value.contains('calving') || value.contains('mastitis') || value.contains('vaccine') || value.contains('vaccination') || value.contains('disease') || value.contains('medical')) return 'health';
  if (value.contains('doctor') || value.contains('appointment')) return 'doctor';
  if (value.contains('payment') || value.contains('plan') || value.contains('subscription') || value.contains('razorpay') || value.contains('upgrade')) return 'payment';
  if (value.contains('report') || value.contains('profit') || value.contains('loss') || value.contains('export')) return 'report';
  if (value.contains('dairy')) return 'dairy';
  if (value.contains('shop') || value.contains('cart') || value.contains('order') || value.contains('product')) return 'shop';
  return 'common';
}
