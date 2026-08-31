/// 공수 값 파싱/포맷/계산.
///
/// 내부 표현은 centi-공수 정수(1공수 = 100). 어디에서도 double을 경유하지
/// 않는다 — 경쟁앱들의 "1.8이 2.0으로 반올림", "소수점 입력 불가" 버그를
/// 구조적으로 차단하기 위한 규칙이다.
library;

/// 공수 1단위 = 100 centi.
const int centiPerGongsu = 100;

/// 직접 입력 허용 최소 단위: 0.05공수 = 5 centi.
const int gongsuInputStepCenti = 5;

final RegExp _gongsuPattern = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$');

/// 사용자 입력 문자열을 centi-공수로 파싱한다. 실패하면 null.
///
/// - 소수점 최대 2자리 ("1.855"는 거부 — 조용히 자르거나 반올림하지 않는다)
/// - 일부 한국어 숫자 키패드가 쉼표를 내보내므로 ','는 '.'로 취급
/// - ".5" → 0.5, "1." → 1 처럼 관용적 입력 허용
int? tryParseGongsu(String input) {
  var s = input.trim().replaceAll(',', '.');
  if (s.isEmpty || s == '.') return null;
  if (s.startsWith('.')) s = '0$s';
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  final match = _gongsuPattern.firstMatch(s);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fracDigits = match.group(2) ?? '';
  final frac = fracDigits.isEmpty ? 0 : int.parse(fracDigits.padRight(2, '0'));
  return whole * centiPerGongsu + frac;
}

/// 0.05 단위인지 검사한다. 직접 입력 UI에서 사용.
bool isValidGongsuStep(int centi) => centi % gongsuInputStepCenti == 0;

/// centi-공수를 표시 문자열로 포맷한다. 후행 0 제거, 정수는 소수점 없이.
///
/// 180 → "1.8", 50 → "0.5", 200 → "2", 175 → "1.75"
String formatGongsu(int centi) {
  assert(centi >= 0, '공수는 음수가 될 수 없다');
  final whole = centi ~/ centiPerGongsu;
  final frac = centi % centiPerGongsu;
  if (frac == 0) return '$whole';
  if (frac % 10 == 0) return '$whole.${frac ~/ 10}';
  return '$whole.${frac.toString().padLeft(2, '0')}';
}

/// centi-공수 × 일당(원) → 금액(원). 정수 연산, 1원 미만 절사.
///
/// 절사 규칙은 테스트로 고정되어 있다. 변경 시 반드시 사용자 확인.
int calcAmountWon({required int centiGongsu, required int dailyRateWon}) {
  assert(centiGongsu >= 0 && dailyRateWon >= 0);
  return (centiGongsu * dailyRateWon) ~/ centiPerGongsu;
}
