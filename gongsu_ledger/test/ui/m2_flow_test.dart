import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/local_prefs.dart';
import 'package:gongsu_ledger/data/repositories/site_repository.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/prefs_providers.dart';

/// M2 플로: 업체 선택 입력 → 세전 수입 카드, 부가항목, 날짜별 단가 오버라이드.
/// (DB 검증은 스트림이 아닌 일반 쿼리만 — CLAUDE.md '테스트 작성 주의')
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  Widget buildApp() {
    db = AppDatabase(NativeDatabase.memory());
    return ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(
          MemoryLocalPrefs({'onboarding_done': '1'}),
        ),
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const GongsuApp(),
    );
  }

  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  int pickEmptyDayKey({int offset = 1}) {
    final today = DateTime.now();
    final day = today.day <= 15 ? today.day + offset : today.day - offset;
    return dateKeyOf(DateTime(today.year, today.month, day));
  }

  int monthStart(int dateKey) => (dateKey ~/ 100) * 100 + 1;
  int monthEnd(int dateKey) => (dateKey ~/ 100) * 100 + 31;

  String grossText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('gross-won'))).data!;

  /// 앱을 띄우고 단가 150,000원짜리 업체 하나를 만든다.
  Future<int> pumpWithSite(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final siteId = await SiteRepository(db.siteDao)
        .create(name: 'A현장', colorId: 2, dailyRateWon: 150000);
    await tester.pumpAndSettle();
    return siteId;
  }

  testWidgets('업체 칩 선택 후 프리셋 입력 → 기록에 업체가 붙고 세전 수입이 뜬다', (tester) async {
    final siteId = await pumpWithSite(tester);
    expect(find.byKey(const ValueKey('gross-won')), findsNothing); // 아직 금액 없음

    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('site-chip-$siteId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-1'))); // 1공수
    await tester.pumpAndSettle();

    final rows = await db.workEntryDao.getRange(
      monthStart(dateKey),
      monthEnd(dateKey),
    );
    expect(rows.single.siteId, siteId);
    expect(grossText(tester), '150,000원');
    await unmountApp(tester);
  });

  testWidgets('마지막에 고른 업체가 다음 입력의 기본값이 된다', (tester) async {
    final siteId = await pumpWithSite(tester);

    final first = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$first')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('site-chip-$siteId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-1')));
    await tester.pumpAndSettle();

    final second = pickEmptyDayKey(offset: 2);
    await tester.tap(find.byKey(ValueKey('day-$second')));
    await tester.pumpAndSettle();
    final chip = tester.widget<ChoiceChip>(
      find.byKey(ValueKey('site-chip-$siteId')),
    );
    expect(chip.selected, true);
    await tester.tap(find.byKey(const ValueKey('preset-1')));
    await tester.pumpAndSettle();

    final rows = await db.workEntryDao.getRange(
      monthStart(second),
      monthEnd(second),
    );
    expect(rows.every((e) => e.siteId == siteId), true);
    expect(grossText(tester), '300,000원');
    await unmountApp(tester);
  });

  testWidgets('부가항목 추가(식비 10,000원) → 세전 수입에 가산된다', (tester) async {
    final siteId = await pumpWithSite(tester);
    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('site-chip-$siteId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-1')));
    await tester.pumpAndSettle(); // 빈 날이라 시트 닫힘

    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-extra-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-식비')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('extra-amount')), '10000');
    await tester.pump();
    await tester.tap(find.text('추가').last);
    await tester.pumpAndSettle();

    expect(find.text('10,000원'), findsWidgets);
    final items = await db.dayItemDao.getRange(
      monthStart(dateKey),
      monthEnd(dateKey),
    );
    expect(items.single.label, '식비');
    expect(items.single.amountWon, 10000);
    expect(items.single.siteId, siteId);
    expect(grossText(tester), '160,000원');
    await unmountApp(tester);
  });

  testWidgets('기록별 "이 날만 단가" 오버라이드가 업체 단가를 이긴다', (tester) async {
    final siteId = await pumpWithSite(tester);
    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('site-chip-$siteId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset-1')));
    await tester.pumpAndSettle();
    expect(grossText(tester), '150,000원');

    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    final entry = (await db.workEntryDao.getRange(
      monthStart(dateKey),
      monthEnd(dateKey),
    )).single;
    await tester.tap(find.byKey(ValueKey('entry-${entry.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('override-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '200000');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final updated = (await db.workEntryDao.getById(entry.id))!;
    expect(updated.unitRateWonOverride, 200000);
    expect(find.text('이 날만 단가: 200,000원'), findsOneWidget);
    expect(grossText(tester), '200,000원');
    await unmountApp(tester);
  });

  testWidgets('업체 관리 화면에 현재 단가가 보이고, 단가 변경으로 이력이 늘어난다', (tester) async {
    final siteId = await pumpWithSite(tester);

    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('업체(현장) 관리'));
    await tester.pumpAndSettle();
    expect(find.text('A현장'), findsOneWidget);
    expect(find.text('현재 단가 150,000원'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('site-tile-$siteId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-rate')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '165000');
    await tester.pump();
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();

    final rates = await db.siteDao.getRatesOfSite(siteId);
    expect(rates.length, 2); // 기본 단가 + 오늘부터 개정
    expect(rates.first.dailyRateWon, 165000); // 최신 적용일 먼저
    expect(find.text('165,000원'), findsOneWidget);
    await unmountApp(tester);
  });
}
