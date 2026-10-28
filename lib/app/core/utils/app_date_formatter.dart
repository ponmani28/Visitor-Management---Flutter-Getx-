import 'package:intl/intl.dart';

abstract final class AppDateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _longDateFormat = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String date(DateTime? value) {
    if (value == null) return 'Not available';
    return _dateFormat.format(value);
  }

  static String longDate(DateTime? value) {
    if (value == null) return 'Not available';
    return _longDateFormat.format(value);
  }

  static String time(DateTime? value) {
    if (value == null) return 'Not available';
    return _timeFormat.format(value);
  }

  static String dateTime(DateTime? value) {
    if (value == null) return 'Not available';
    return _dateTimeFormat.format(value);
  }

  static String smartDate(DateTime value) {
    final today = _startOfDay(DateTime.now());
    final target = _startOfDay(value);
    final difference = target.difference(today).inDays;

    return switch (difference) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => date(value),
    };
  }

  static String smartDateTime(DateTime value) {
    return '${smartDate(value)}, ${time(value)}';
  }

  static bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static bool isToday(DateTime value) => isSameDay(value, DateTime.now());

  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
