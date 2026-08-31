import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/state/db_providers.dart';

void main() {
  late AppDatabase db;

  Widget buildApp() {
    db = AppDatabase(NativeDatabase.memory());
    return ProviderScope(
      overrides: [databaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      })],
      child: const GongsuApp(),
    );
  }

  /// 오늘이 속한 달에서 "오늘이 아닌 빈 날"의 dateKey를 하나 고른다.
  int pickEmptyDayKey() {
    final today = DateTime.now();
    final day = today.day <= 15 ? today.day + 1 : today.day - 1;
    return dateKeyOf(DateTime(today.year, today.month, day));
  }

  testWidgets('앱 실행 → 달력과 월 합계가 바로 보인다 (로그인/온보딩 없음)',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final today = DateTime.now();
    expect(find.text('${today.year}년 ${today.month}월'), findsOneWidget);
    expect(find.text('${today.month}월 총 공수'), findsOneWidget);
    expect(find.text('0 공수'), findsOneWidget);
    expect(
        find.byKey(ValueKey('day-${dateKeyOf(today)}')), findsOneWidget);
  });

  testWidgets('빈 날: 날짜 탭 → 프리셋 탭, 2탭으로 입력 완료 + 시트 자동 닫힘',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();

    expect(find.text('1공수'), findsOneWidget); // 시드 프리셋 버튼
    await tester.tap(find.text('1공수'));
    await tester.pumpAndSettle();

    // 시트가 닫혔고(프리셋 버튼 사라짐) 저장은 정확히 그 날짜로 되었다.
    expect(find.text('1공수'), findsNothing);
    final rows = await db.workEntryDao.watchMonth(dateKey ~/ 100).first;
    expect(rows.single.dateKey, dateKey);
    expect(rows.single.centiGongsu, 100);
    expect(find.text('1 공수'), findsOneWidget); // 월 합계 갱신
  });

  testWidgets('기록 있는 날: 프리셋 탭해도 시트 유지 → 연속 입력', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1공수'));
    await tester.pumpAndSettle();

    // 두 번째 열기: 이미 기록이 있으므로 프리셋 탭 후에도 시트가 남는다.
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5공수'));
    await tester.pumpAndSettle();

    expect(find.text('합계'), findsOneWidget); // 시트가 아직 열려 있다
    expect(find.text('2.5 공수'), findsWidgets); // 시트 내 합계
    final rows = await db.workEntryDao.watchMonth(dateKey ~/ 100).first;
    expect(rows.length, 2);
  });

  testWidgets('직접 입력: 자체 키패드로 1.8 → 반올림 없이 그대로 저장',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.tap(find.text('.'));
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final rows = await db.workEntryDao.watchMonth(dateKey ~/ 100).first;
    expect(rows.single.centiGongsu, 180); // 1.8은 1.8이다
    expect(find.text('1.8 공수'), findsOneWidget); // 월 합계 카드
  });

  testWidgets('키패드는 0.05 단위 위반을 저장하지 못하게 막는다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();

    for (final key in ['1', '.', '3', '3']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    expect(find.text('0.05 단위로 입력해 주세요'), findsOneWidget);

    final saveButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '저장'));
    expect(saveButton.onPressed, null); // 비활성

    final rows = await db.workEntryDao.watchMonth(dateKey ~/ 100).first;
    expect(rows, isEmpty);
  });

  testWidgets('큰글씨(2.0배)에서도 홈 화면과 시트가 그려진다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('day-${dateKeyOf(DateTime.now())}')),
        findsOneWidget);

    await tester.tap(find.byKey(ValueKey('day-${pickEmptyDayKey()}')));
    await tester.pumpAndSettle();
    expect(find.text('직접 입력'), findsOneWidget);
  });
}
