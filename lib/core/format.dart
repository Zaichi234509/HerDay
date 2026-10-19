import 'package:intl/intl.dart';

final NumberFormat _pesoFmt = NumberFormat('#,##0.##');

/// ₱1,250 style formatting.
String peso(num v) => '₱${_pesoFmt.format(v)}';

/// yyyy-MM-dd (local date key used across all tables).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// yyyy-MM (budget month key).
String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

DateTime parseDate(String? s) {
  if (s == null || s.isEmpty) return DateTime.now();
  return DateTime.tryParse(s) ?? DateTime.now();
}

String friendlyDate(DateTime d) => DateFormat('EEEE, MMMM d').format(d);

String shortDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
