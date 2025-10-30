import 'package:intl/intl.dart';

/// Converts a millisecond timestamp into a smart human-readable date string.
/// Examples:
/// - "Today at 3:45 PM"
/// - "Yesterday at 10:12 AM"
/// - "28 Oct 2025, 8:30 PM"
///
/// Automatically uses the device or system's local timezone.
String formatSmartDate(int timestamp) {
  if (timestamp <= 0) return "Date unavailable";

  // Convert timestamp to local time (auto-adjusts for device timezone)
  final localDate =
  DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();

  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final orderDay = DateTime(localDate.year, localDate.month, localDate.day);

  final timeFormat = DateFormat('hh:mm a');

  if (orderDay == today) {
    return "Today at ${timeFormat.format(localDate)}";
  } else if (orderDay == yesterday) {
    return "Yesterday at ${timeFormat.format(localDate)}";
  } else {
    return DateFormat('dd MMM yyyy, hh:mm a').format(localDate);
  }
}
