import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/ui/common/app_icons.dart';

/// 앱 안 아이콘은 Phosphor 한 벌만 쓴다.
///
/// - `AppIcons` 의 코드포인트가 내장 글꼴(Regular/Fill)에 실제로 있는지
/// - lib 의 화면 코드가 Material `Icons.` 를 직접 쓰지 않는지
void main() {
  /// TTF 의 cmap(format 4/12)에서 코드포인트 집합을 읽는다 — 패키지 없이.
  Set<int> codepointsOf(String path) {
    final b = File(path).readAsBytesSync().buffer.asByteData();
    final numTables = b.getUint16(4);
    int? cmapOffset;
    for (var i = 0; i < numTables; i++) {
      final rec = 12 + i * 16;
      final tag = String.fromCharCodes([
        b.getUint8(rec),
        b.getUint8(rec + 1),
        b.getUint8(rec + 2),
        b.getUint8(rec + 3),
      ]);
      if (tag == 'cmap') cmapOffset = b.getUint32(rec + 8);
    }
    expect(cmapOffset, isNotNull, reason: '$path 에 cmap 테이블이 없다');
    final base = cmapOffset!;
    final n = b.getUint16(base + 2);
    final out = <int>{};
    for (var i = 0; i < n; i++) {
      final sub = base + b.getUint32(base + 4 + i * 8 + 4);
      final format = b.getUint16(sub);
      if (format == 4) {
        final segX2 = b.getUint16(sub + 6);
        final ends = sub + 14;
        final starts = ends + segX2 + 2;
        for (var s = 0; s < segX2 ~/ 2; s++) {
          final end = b.getUint16(ends + s * 2);
          final start = b.getUint16(starts + s * 2);
          for (var c = start; c <= end && c != 0xFFFF; c++) {
            out.add(c);
          }
        }
      } else if (format == 12) {
        final groups = b.getUint32(sub + 12);
        for (var g = 0; g < groups; g++) {
          final rec = sub + 16 + g * 12;
          final start = b.getUint32(rec);
          final end = b.getUint32(rec + 4);
          for (var c = start; c <= end; c++) {
            out.add(c);
          }
        }
      }
    }
    return out;
  }

  test('AppIcons 코드포인트가 전부 내장 Phosphor 글꼴에 있다', () {
    final fonts = {
      'PhosphorRegular': codepointsOf('assets/fonts/Phosphor-Regular.ttf'),
      'PhosphorFill': codepointsOf('assets/fonts/Phosphor-Fill.ttf'),
    };
    final source = File('lib/ui/common/app_icons.dart').readAsStringSync();
    final matches = RegExp(
      r"IconData\((0x[0-9a-fA-F]+), fontFamily: '(\w+)'\)",
    ).allMatches(source);
    expect(matches, isNotEmpty);
    final missing = <String>[];
    for (final m in matches) {
      final code = int.parse(m.group(1)!);
      final family = m.group(2)!;
      if (!(fonts[family]?.contains(code) ?? false)) {
        missing.add('${m.group(1)} ($family)');
      }
    }
    expect(missing, isEmpty, reason: '글꼴에 없는 아이콘: $missing');
    // 실제 상수도 같은 글꼴 이름을 쓴다
    expect(AppIcons.calendar.fontFamily, 'PhosphorRegular');
    expect(AppIcons.calendarFill.fontFamily, 'PhosphorFill');
    expect(AppIcons.calendar, isA<IconData>());
  });

  test('화면 코드는 Material Icons 를 직접 쓰지 않는다 (한 벌 원칙)', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
      final code = f
          .readAsStringSync()
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
          .replaceAll(RegExp(r'//[^\n]*'), '');
      if (RegExp(r'(?<![A-Za-z])Icons\.\w+').hasMatch(code)) offenders.add(f.path);
    }
    expect(offenders, isEmpty, reason: 'Material 아이콘 직접 사용: $offenders');
  });
}
