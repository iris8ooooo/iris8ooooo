import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 홈 껍데기(하단 탭 4개) 시대의 화면 이동 도우미.
///
/// 예전 ⋮ 메뉴 항목 이름을 그대로 받아 지금 경로로 바꿔 준다 —
/// 정산·통계·설정은 탭, 업체·프리셋·백업·세율은 설정 안의 줄.
Future<void> goTab(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('nav-$id')));
  await tester.pumpAndSettle();
}

Future<void> openMenu(WidgetTester tester, String item) async {
  switch (item) {
    case '정산 (기간 지정)':
    case '정산':
      await goTab(tester, 'settlement');
    case '통계':
      await goTab(tester, 'stats');
    case '설정':
      await goTab(tester, 'settings');
    case '업체(현장) 관리':
      await _settingsRow(tester, 'sites');
    case '프리셋 관리':
      await _settingsRow(tester, 'presets');
    case '백업 / 복원':
      await _settingsRow(tester, 'backup');
    case '세금 · 요율 설정':
      await _settingsRow(tester, 'tax');
    default:
      throw ArgumentError('모르는 메뉴 항목: $item');
  }
}

Future<void> _settingsRow(WidgetTester tester, String key) async {
  await goTab(tester, 'settings');
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  // 떠 있는 알약 탭 뒤에 걸치지 않게 줄 전체를 화면 안으로.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// 뒤로: 밀어 올린 화면이 있으면 뒤로가기. 홈 껍데기까지 돌아오면 예전
/// (⋮ 메뉴 시절) 과 같이 달력이 보이도록 달력 탭으로 간다.
Future<void> back(WidgetTester tester) async {
  final button = find.byType(BackButton);
  if (button.evaluate().isNotEmpty) {
    await tester.tap(button.first);
    await tester.pumpAndSettle();
  }
  if (find.byType(BackButton).evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('nav-calendar')));
    await tester.pumpAndSettle();
  }
}
