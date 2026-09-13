import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app_info.dart';

/// 앱 이름은 `lib/app_info.dart` 의 `kAppName` 한 곳이 진실이다.
///
/// 이름을 다시 바꿀 때 놓치는 곳이 없도록:
/// - Dart 코드는 상수만 쓰고 이름 글자를 직접 박지 않는다
/// - 네이티브(Info.plist·strings.xml·위젯 Swift/Kotlin)는 상수와 같은 글자여야 한다
/// - 스토어에 뺏긴 옛 이름 "공수장부" 는 사용자에게 보이는 어디에도 남지 않는다
///   (시장조사 문서는 경쟁앱 이름으로 언급하므로 제외)
void main() {
  const oldName = '공수장부';

  Iterable<File> filesUnder(String dir, bool Function(String) keep) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => keep(f.path));

  String stripComments(String source) => source
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');

  test('Dart 코드는 앱 이름 글자를 직접 쓰지 않는다 (app_info.dart 만 예외)', () {
    final offenders = <String>[];
    for (final f in filesUnder(
      'lib',
      (p) => p.endsWith('.dart') && !p.endsWith('.g.dart'),
    )) {
      if (f.path.endsWith('app_info.dart')) continue;
      if (stripComments(f.readAsStringSync()).contains(kAppName)) {
        offenders.add(f.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '앱 이름은 kAppName 상수로만 쓴다 — 위반: $offenders',
    );
  });

  test('네이티브 표시 이름 4곳이 kAppName 과 같다', () {
    final nativeFiles = {
      'ios/Runner/Info.plist': '<string>$kAppName</string>',
      'ios/GongsuWidget/Info.plist': '<string>$kAppName</string>',
      'android/app/src/main/res/values/strings.xml':
          '<string name="app_name">$kAppName</string>',
      'ios/GongsuWidget/GongsuWidget.swift': 'Text("$kAppName")',
      'android/app/src/main/kotlin/com/gongsujangbu/gongsu_ledger/GongsuWidgetProvider.kt':
          '"$kAppName"',
    };
    for (final entry in nativeFiles.entries) {
      final text = File(entry.key).readAsStringSync();
      expect(
        text.contains(entry.value),
        true,
        reason: '${entry.key} 에 "$kAppName" 이 없다 — 이름 바꿀 때 네이티브도 함께',
      );
    }
  });

  test('옛 이름은 사용자에게 보이는 곳 어디에도 없다', () {
    final roots = [
      'lib',
      'ios/Runner',
      'ios/GongsuWidget',
      'android/app/src/main',
      'tool',
      'docs',
      'pubspec.yaml',
    ];
    final offenders = <String>[];
    for (final root in roots) {
      final entity = FileSystemEntity.typeSync(root);
      final files = entity == FileSystemEntityType.file
          ? [File(root)]
          : filesUnder(root, (p) => !p.contains('MARKET_RESEARCH'));
      for (final f in files) {
        final bytes = f.readAsBytesSync();
        // 이진 파일(아이콘 등)은 건너뛴다
        if (bytes.any((b) => b == 0)) continue;
        if (String.fromCharCodes(bytes).contains(oldName)) {
          offenders.add(f.path);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '"$oldName" 는 다른 개발사가 App Store 에 등록한 이름 — 남은 곳: $offenders',
    );
  });

  test('프로 상품 이름은 앱 이름에서 파생된다', () {
    expect(kProName, '$kAppName 프로');
  });
}
