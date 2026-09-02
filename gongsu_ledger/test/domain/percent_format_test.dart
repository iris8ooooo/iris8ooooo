import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/percent_format.dart';

void main() {
  test('포맷: 후행 0 제거', () {
    expect(formatPercentPer100k(4750), '4.75');
    expect(formatPercentPer100k(900), '0.9');
    expect(formatPercentPer100k(12950), '12.95');
    expect(formatPercentPer100k(3595), '3.595');
    expect(formatPercentPer100k(100000), '100');
    expect(formatPercentPer100k(0), '0');
  });

  test('파싱: 소수 3자리까지, 범위 0~100', () {
    expect(parsePercentPer100k('4.75'), 4750);
    expect(parsePercentPer100k('3.595'), 3595);
    expect(parsePercentPer100k('0.9'), 900);
    expect(parsePercentPer100k('.9'), 900);
    expect(parsePercentPer100k('9.'), 9000);
    expect(parsePercentPer100k('12,95'), 12950);
    expect(parsePercentPer100k(' 100 % '), 100000);
    expect(parsePercentPer100k('100.001'), null);
    expect(parsePercentPer100k('3.5951'), null); // 4자리 — 자르지 않고 거부
    expect(parsePercentPer100k('abc'), null);
    expect(parsePercentPer100k(''), null);
    expect(parsePercentPer100k('-1'), null);
  });

  test('왕복', () {
    for (final v in [0, 5, 900, 3595, 4750, 12950, 55000, 100000]) {
      expect(parsePercentPer100k(formatPercentPer100k(v)), v);
    }
  });
}
