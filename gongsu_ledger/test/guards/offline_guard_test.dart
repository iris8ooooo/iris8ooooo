import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 절대 원칙 1(서버 없음)·3(광고 SDK 금지)을 코드로 증명한다.
///
/// "비행기 모드에서 전 기능 작동"을 사람이 손으로 확인하는 대신,
/// 앱이 네트워크를 쓸 **수단 자체가 없음**을 파일 내용으로 고정한다.
/// 결제(in_app_purchase)만 예외 — 스토어 SDK 가 페이월에서만 쓰고,
/// 우리 코드가 직접 통신하지는 않는다.
void main() {
  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

  String stripComments(String source) => source
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');

  test('앱 코드에 네트워크 호출 수단이 없다 (비행기 모드 보장)', () {
    final banned = <String, String>{
      r'\bHttpClient\b': 'dart:io 의 HTTP 클라이언트',
      r"package:http/": 'http 패키지',
      r'\bWebSocket\b': '웹소켓',
      r'\bSocket\.connect\b': 'TCP 소켓',
      r'\bImage\.network\b': '네트워크 이미지',
      r'\bNetworkImage\b': '네트워크 이미지',
      r'\bhttp://': '평문 HTTP 주소',
    };
    final offenders = <String>[];
    for (final file in dartFiles('lib')) {
      final code = stripComments(file.readAsStringSync());
      for (final entry in banned.entries) {
        if (RegExp(entry.key).hasMatch(code)) {
          offenders.add('${file.path}: ${entry.value}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '서버 없음 원칙 위반 — 앱은 어떤 네트워크 호출도 하지 않는다: $offenders',
    );
  });

  test('의존성에 네트워크·광고·추적 패키지가 없다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies = RegExp(
      r'^dependencies:(.*?)^dev_dependencies:',
      multiLine: true,
      dotAll: true,
    ).firstMatch(pubspec);
    expect(dependencies, isNotNull, reason: 'pubspec 의 dependencies 를 못 찾았다');
    final block = dependencies!.group(1)!;

    const banned = [
      'http:',
      'dio:',
      'retrofit:',
      'graphql',
      'web_socket',
      'firebase',
      'cloud_firestore',
      'supabase',
      'amplify',
      'google_mobile_ads',
      'admob',
      'applovin',
      'unity_ads',
      'facebook_audience',
      'amplitude',
      'mixpanel',
      'sentry',
      'posthog',
      'appsflyer',
      'analytics',
    ];
    final found = banned.where(block.contains).toList();
    expect(found, isEmpty, reason: '광고·추적·서버 SDK 금지 (절대 원칙 1·3) — 발견: $found');
  });

  test('출시용 Android 매니페스트에 INTERNET 권한이 없다', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest.contains('android.permission.INTERNET'),
      false,
      reason:
          '출시 빌드는 인터넷 권한 자체를 요구하지 않는다 — 스토어 설명의 '
          '"인터넷 권한 없음" 주장을 이 테스트가 보증한다. '
          '(debug/profile 매니페스트의 INTERNET 은 Flutter 핫리로드용이라 무관)',
    );
  });
}
