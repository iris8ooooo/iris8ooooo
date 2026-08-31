import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/domain/marker_palette.dart';

void main() {
  test('12색 팔레트 — 라이트/다크 각각 서로 다른 색', () {
    expect(MarkerPalette.entries.length, 12);
    final light = MarkerPalette.entries.map((e) => e.color).toSet();
    final dark = MarkerPalette.entries.map((e) => e.darkColor).toSet();
    expect(light.length, 12, reason: '라이트 색 중복');
    expect(dark.length, 12, reason: '다크 색 중복');
  });

  test('colorOf는 밝기에 따라 변형을 돌려준다', () {
    for (final e in MarkerPalette.entries) {
      expect(MarkerPalette.colorOf(e.id), e.color);
      expect(
          MarkerPalette.colorOf(e.id, brightness: Brightness.dark), e.darkColor);
    }
  });

  test('범위 밖 id는 0번으로 폴백 (오염 데이터 방어)', () {
    expect(MarkerPalette.colorOf(-1), MarkerPalette.entries[0].color);
    expect(MarkerPalette.colorOf(999), MarkerPalette.entries[0].color);
    expect(MarkerPalette.nameOf(999), MarkerPalette.entries[0].name);
  });

  test('다크 변형은 다크 서피스 위에서 대비 3:1 이상 (비텍스트 기준)', () {
    const darkSurface = Color(0xFF141218);
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final lighter = la > lb ? la : lb;
      final darker = la > lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

    for (final e in MarkerPalette.entries) {
      expect(contrast(e.darkColor, darkSurface), greaterThanOrEqualTo(3.0),
          reason: '${e.name} 다크 변형 대비 미달');
    }
  });
}
