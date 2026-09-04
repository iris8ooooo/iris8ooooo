import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/shared_prefs_local_prefs.dart';
import 'state/prefs_providers.dart';

/// DB 오픈 등 무거운 초기화는 첫 사용 시점에 백그라운드에서 일어난다 —
/// 콜드 스타트 1초 원칙. 첫 프레임에 필요한 화면 설정·온보딩 여부만
/// 경량 저장소(shared_preferences)에서 읽고 시작한다 (깜빡임 방지).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 내장 글꼴(나눔고딕, SIL OFL) 라이선스를 "오픈소스 라이선스" 화면에 표시한다.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'NanumGothic',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(SharedPrefsLocalPrefs(prefs)),
      ],
      child: const GongsuApp(),
    ),
  );
}
