import 'package:intl/intl.dart';

class FeedingDateService {
  const FeedingDateService();

  DateTime? selectedDateFromText(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {
      return parseApiDate(value);
    }
  }

  DateTime? parseApiDate(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {}
    try {
      return DateFormat('d/M/yyyy').parseStrict(text);
    } catch (_) {}
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(text);
    } catch (_) {}
    return null;
  }

  bool isSameDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) return false;
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool isFeedingTime(dynamic value, String expected) {
    return (value ?? '').toString().trim().toLowerCase() ==
        expected.toLowerCase();
  }

  String normalizedFeedingShift(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    if (text.contains('evening')) return 'Evening';
    if (text.contains('morning') || text.contains('afternoon')) {
      return 'Morning';
    }
    return '';
  }

  String formatForApi(String value) {
    try {
      final parsed = DateFormat('dd/MM/yyyy').parse(value);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return value;
    }
  }
}
