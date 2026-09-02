/// 십만분율(per100k) 정수 ↔ 퍼센트 문자열. double을 경유하지 않는다.
///
/// 4750 ↔ "4.75", 900 ↔ "0.9", 12950 ↔ "12.95", 100000 ↔ "100"
library;

final RegExp _percentPattern = RegExp(r'^(\d{1,3})(?:\.(\d{1,3}))?$');

/// per100k → 퍼센트 문자열 (후행 0 제거).
String formatPercentPer100k(int per100k) {
  assert(per100k >= 0);
  final whole = per100k ~/ 1000;
  final frac = per100k % 1000;
  if (frac == 0) return '$whole';
  var s = frac.toString().padLeft(3, '0');
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return '$whole.$s';
}

/// 퍼센트 문자열 → per100k. 소수 최대 3자리, 0~100% 범위 밖·형식 오류는 null
/// (자르거나 반올림하지 않고 거부한다).
int? parsePercentPer100k(String input) {
  var s = input.replaceAll(',', '.').replaceAll('%', '').trim();
  if (s.isEmpty || s == '.') return null;
  if (s.startsWith('.')) s = '0$s';
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  final m = _percentPattern.firstMatch(s);
  if (m == null) return null;
  final whole = int.parse(m.group(1)!);
  final fracDigits = m.group(2) ?? '';
  final frac = fracDigits.isEmpty ? 0 : int.parse(fracDigits.padRight(3, '0'));
  final value = whole * 1000 + frac;
  if (value > 100000) return null;
  return value;
}
