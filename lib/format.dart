/// Number and date helpers. Digits are always Western (0-9) for readability
/// from a distance; words are Arabic with Iraqi month names.

String _plain(double v) {
  var s = v.toStringAsFixed(4);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

/// 146250 -> "146,250", 0.92 -> "0.92", null -> "—"
String formatRate(double? v) {
  if (v == null) return '—';
  var s = _plain(v);
  final negative = s.startsWith('-');
  if (negative) s = s.substring(1);
  final parts = s.split('.');
  final whole = parts[0];
  final b = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) b.write(',');
    b.write(whole[i]);
  }
  if (parts.length > 1) b.write('.${parts[1]}');
  return negative ? '-$b' : b.toString();
}

/// Value shown inside an edit field (no thousands separators).
String inputText(double? v) => v == null ? '' : _plain(v);

/// Accepts Western, Arabic-Indic and Persian digits, commas and spaces.
double? parseRate(String input) {
  final b = StringBuffer();
  for (final r in input.trim().runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + r - 0x06F0);
    } else if (r == 0x066B) {
      b.write('.'); // Arabic decimal separator
    } else if (r == 0x066C || r == 0x2C || r == 0x20) {
      // thousands separators and spaces are ignored
    } else {
      b.writeCharCode(r);
    }
  }
  final v = double.tryParse(b.toString());
  return (v != null && v.isFinite) ? v : null;
}

const _weekdays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const _months = [
  'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
  'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
];

/// "الاثنين، 23 تشرين الثاني 2026"
String arabicDate(DateTime d) => '${_weekdays[d.weekday - 1]}، ${d.day} ${_months[d.month - 1]} ${d.year}';

/// "10:45"
String clockTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')}';
}

/// ص = AM, م = PM
String amPm(DateTime d) => d.hour < 12 ? 'ص' : 'م';
