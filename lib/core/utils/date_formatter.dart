import 'package:intl/intl.dart';

/// Butun ilova bo'ylab har qanday sana formatini (2026-09-14, 2026-09-14 12:00:00, va h.k.) 
/// BITTALIK standart va chiroyli [dd.MM.yyyy] (masalan: 14.09.2026) ko'rinishiga o'tkazib beruvchi universal funksiya.
String formatAppDate(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) return '';
  final str = rawDate.trim();

  // Agar allaqachon dd.MM.yyyy (30.08.2026) ko'rinishida bo'lsa o'zini qaytaradi
  if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(str)) {
    return str;
  }

  try {
    // ISO va standart formatlarni o'qish (2026-09-14 yoki 2026-09-14 10:00:00)
    final parsed = DateTime.parse(str.contains(' ') ? str.replaceFirst(' ', 'T') : str);
    return DateFormat('dd.MM.yyyy').format(parsed);
  } catch (_) {}

  try {
    final dateOnly = str.split(' ')[0];
    final parsed = DateFormat('yyyy-MM-dd').parse(dateOnly);
    return DateFormat('dd.MM.yyyy').format(parsed);
  } catch (_) {}

  return str;
}
