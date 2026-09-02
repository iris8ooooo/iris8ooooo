import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _grouped = NumberFormat('#,###');

/// 1234000 → "1,234,000원"
String formatWon(int won) => '${_grouped.format(won)}원';

/// 숫자만 남기고 파싱. "165,000" / "165000원" → 165000. 실패 시 null.
int? parseWon(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// 원 단위 정수 입력용 포맷터: 숫자만 허용, 최대 10자리(99억).
final List<TextInputFormatter> wonInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];
