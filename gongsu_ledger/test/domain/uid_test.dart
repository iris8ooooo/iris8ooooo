import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/uid.dart';

void main() {
  test('UUIDv4 형식 (36자, 버전 4, 변형 10xx)', () {
    for (var i = 0; i < 200; i++) {
      final uid = generateUid();
      expect(uid.length, 36);
      expect(uidPattern.hasMatch(uid), true, reason: uid);
    }
  });

  test('시드 고정 시 재현 가능 (테스트용) + 충돌 없음 표본', () {
    final a = generateUid(random: Random(42));
    final b = generateUid(random: Random(42));
    expect(a, b);

    final seen = <String>{};
    for (var i = 0; i < 5000; i++) {
      expect(seen.add(generateUid()), true, reason: '중복 uid 발생');
    }
  });
}
