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

  final missingHi = <String>[];
  final missingMr = <String>[];

  for (final key in en.keys.toList()..sort()) {
    final hiValue = (hi[key] ?? '').trim();
    final mrValue = (mr[key] ?? '').trim();
    if (hiValue.isEmpty || hiValue == en[key]) missingHi.add(key);
    if (mrValue.isEmpty || mrValue == en[key]) missingMr.add(key);
  }

  stdout.writeln('missingHi=${missingHi.length}');
  for (final key in missingHi.take(120)) {
    stdout.writeln('HI:$key => ${en[key]}');
  }
  stdout.writeln('missingMr=${missingMr.length}');
  for (final key in missingMr.take(120)) {
    stdout.writeln('MR:$key => ${en[key]}');
  }
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
