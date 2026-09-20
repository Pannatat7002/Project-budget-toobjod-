import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayMonthYear = DateFormat('dd MMM yyyy', 'th_TH');
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'th_TH');
  static final DateFormat _dayOnly = DateFormat('dd');
  static final DateFormat _monthOnly = DateFormat('MMM', 'th_TH');
  static final DateFormat _timeOnly = DateFormat('HH:mm:ss');
  static final DateFormat _timeShort = DateFormat('HH:mm');

  /// Formats date to '25 ส.ค. 2026'
  static String formatFull(DateTime date) {
    try {
      return _dayMonthYear.format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Alias for formatFull ('25 ส.ค. 2026')
  static String formatDate(DateTime date) => formatFull(date);

  /// Formats date to '25/08/2026'
  static String formatShort(DateTime date) {
    return _shortDate.format(date);
  }

  /// Formats date to 'สิงหาคม 2026'
  static String formatMonthYear(DateTime date) {
    try {
      return _monthYear.format(date);
    } catch (_) {
      return '${date.month}/${date.year}';
    }
  }

  /// Formats to '14:30:15' (ชั่วโมง:นาที:วินาที)
  static String formatTime(DateTime date) {
    return _timeOnly.format(date);
  }

  /// Formats to '14:30' (ชั่วโมง:นาที)
  static String formatTimeShort(DateTime date) {
    return _timeShort.format(date);
  }

  /// Formats date and time to '25 ส.ค. 2026 14:30:15'
  static String formatDateTime(DateTime date) {
    return '${formatFull(date)} ${formatTime(date)}';
  }

  /// Human-friendly relative or formatted date (วันนี้, เมื่อวาน, หรือ วันที่)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'วันนี้';
    } else if (difference == 1) {
      return 'เมื่อวาน';
    } else {
      return formatFull(date);
    }
  }

  /// Relative date with full time including seconds: 'วันนี้ 14:30:15 น.'
  static String formatRelativeWithTime(DateTime date) {
    return '${formatRelative(date)} ${formatTime(date)} น.';
  }

  static String getDay(DateTime date) => _dayOnly.format(date);
  static String getMonth(DateTime date) => _monthOnly.format(date);
}
