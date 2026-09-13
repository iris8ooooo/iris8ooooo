import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// iOS 프로젝트 파일(pbxproj)이 빌드되는 상태인지 소스 수준에서 증명한다.
///
/// 네이티브 빌드는 이 환경(리눅스)에서 돌릴 수 없으므로, Xcode 가 거부하는
/// 구성을 파일 내용으로 잡는다. 오너 맥에서 한 번 겪은 실제 실패의 재발 방지.
void main() {
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');

  /// Runner 타깃의 buildPhases 배열 본문.
  String runnerBuildPhases(String source) {
    final target = RegExp(
      r'97C146ED1CF9000F007C117D /\* Runner \*/ = \{.*?name = Runner;',
      dotAll: true,
    ).firstMatch(source);
    expect(target, isNotNull, reason: 'Runner 타깃 블록을 찾지 못했다');
    final phases = RegExp(
      r'buildPhases = \((.*?)\);',
      dotAll: true,
    ).firstMatch(target!.group(0)!);
    expect(phases, isNotNull, reason: 'Runner 의 buildPhases 를 찾지 못했다');
    return phases!.group(1)!;
  }

  test('pbxproj 가 있고 위젯 타깃이 들어 있다', () {
    expect(pbxproj.existsSync(), true);
    final source = pbxproj.readAsStringSync();
    expect(source.contains('GongsuWidget'), true);
    expect(source.contains('Embed Foundation Extensions'), true);
  });

  test(
    'Embed Foundation Extensions 가 Thin Binary 앞에 있다 (Cycle inside Runner 방지)',
    () {
      final phases = runnerBuildPhases(pbxproj.readAsStringSync());
      final embed = phases.indexOf('Embed Foundation Extensions');
      final thin = phases.indexOf('Thin Binary');
      expect(embed, isNot(-1), reason: '위젯 .appex 복사 단계가 없다');
      expect(thin, isNot(-1), reason: 'Flutter 의 Thin Binary 단계가 없다');
      expect(
        embed < thin,
        true,
        reason:
            'Embed Foundation Extensions 가 Thin Binary 뒤에 있으면 Xcode 가 '
            '"Cycle inside Runner" 로 빌드를 거부한다(flutter/flutter#135056). '
            'ruby tool/ios_add_widget_target.rb 를 다시 실행하면 순서가 복구된다.',
      );
    },
  );

  test('프레임워크 참조에 SDK 버전이 박힌 경로가 없다', () {
    final source = pbxproj.readAsStringSync();
    expect(
      RegExp(r'iPhoneOS\d+\.\d+\.sdk').hasMatch(source),
      false,
      reason: 'SDK 버전이 박힌 경로는 다른 Xcode 버전에서 빌드가 깨진다',
    );
  });
}
