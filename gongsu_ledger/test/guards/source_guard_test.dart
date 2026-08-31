import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 절대 원칙을 코드 수준에서 강제하는 가드.
///
/// - 숫자 정확성: domain/data 계층에 double 타입 금지 (반올림 버그의 뿌리)
/// - 날짜 어긋남: DateTime.utc / isSameDay 금지 (매월 1일 버그 계열)
/// - 데이터 유실: DROP TABLE / deleteTable / deleteDatabase 부재
///   (destructive fallback이 코드에 존재하지 않음을 증명)
///
/// 스코프를 lib/ 하위로 한정하고 생성 코드(*.g.dart)와 주석은 제외해
/// 오탐을 막는다.
void main() {
  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

  String stripComments(String source) => source
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');

  void expectNoMatch(String dir, RegExp pattern, String why) {
    final offenders = <String>[];
    for (final file in dartFiles(dir)) {
      final code = stripComments(file.readAsStringSync());
      if (pattern.hasMatch(code)) offenders.add(file.path);
    }
    expect(offenders, isEmpty, reason: '$why — 위반 파일: $offenders');
  }

  test('domain/data 계층에 double 타입이 없다', () {
    expectNoMatch('lib/domain', RegExp(r'\bdouble\b'),
        '공수/금액 계산은 정수 연산만 허용');
    expectNoMatch('lib/data', RegExp(r'\bdouble\b'),
        '저장 경로에 double이 존재하면 안 됨');
  });

  test('lib 전체에 DateTime.utc / isSameDay가 없다', () {
    expectNoMatch(
        'lib', RegExp(r'DateTime\.utc'), '날짜는 로컬 기준 dateKey만 사용');
    expectNoMatch('lib', RegExp(r'\bisSameDay\s*\('),
        '날짜 비교는 dateKey int 동등 비교만 사용');
  });

  test('파괴적 DB 조작 코드가 없다 (destructive fallback 부재 증명)', () {
    expectNoMatch('lib', RegExp(r'DROP\s+TABLE', caseSensitive: false),
        '테이블 드롭 금지');
    expectNoMatch('lib', RegExp(r'\.deleteTable\s*\('), '테이블 삭제 금지');
    expectNoMatch('lib', RegExp(r'deleteDatabase'), 'DB 삭제 금지');
  });

  test('기록 테이블에 물리 DELETE가 없다 (soft delete만)', () {
    // delete(...)는 dayMemos(메모 비우기)에만 허용된다.
    final offenders = <String>[];
    for (final file in dartFiles('lib')) {
      final code = stripComments(file.readAsStringSync());
      for (final m in RegExp(r'delete\s*\(\s*(\w+)').allMatches(code)) {
        final table = m.group(1)!;
        if (table == 'workEntries' || table == 'presets') {
          offenders.add('${file.path} → delete($table)');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: '기록/프리셋은 soft delete만 허용 — 위반: $offenders');
  });
}
