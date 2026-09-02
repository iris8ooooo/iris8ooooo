import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/local_prefs.dart';
import 'package:gongsu_ledger/data/repositories/site_repository.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/prefs_providers.dart';

/// M3 플로: 업체 세금 방식 → 월 카드 실수령, 정산 화면, 통계, 세율 설정.
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

  int dayKey(int offset) {
    final today = DateTime.now();
    final day = today.day <= 15 ? today.day + offset : today.day - offset;
    return dateKeyOf(DateTime(today.year, today.month, day));
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  Future<void> openMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  /// 단가 150,000원 업체 + 이번 달 1공수 기록 2건.
  Future<int> pumpWithSiteAndEntries(
    WidgetTester tester, {
    TaxMode taxMode = TaxMode.none,
  }) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final siteId = await SiteRepository(
      db.siteDao,
    ).create(name: 'A현장', colorId: 2, dailyRateWon: 150000, taxMode: taxMode);
    final entries = WorkEntryRepository(db.workEntryDao);
    await entries.addCustom(
      dateKey: dayKey(1),
      centiGongsu: 100,
      siteId: siteId,
    );
    await entries.addCustom(
      dateKey: dayKey(2),
      centiGongsu: 100,
      siteId: siteId,
    );
    await tester.pumpAndSettle();
    return siteId;
  }

  testWidgets('3.3% 업체: 월 카드에 세후 실수령이 뜬다 (300,000 → 290,100)', (tester) async {
    await pumpWithSiteAndEntries(tester, taxMode: TaxMode.withholding33);
    expect(textOf(tester, 'gross-won'), '300,000원');
    // 소득세 9,000 + 지방소득세 900
    expect(textOf(tester, 'net-won'), '290,100원');
    expect(find.text('세금·보험 공제 9,900원'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('세금 방식 미설정이면 실수령 = 세전 + 안내 문구', (tester) async {
    await pumpWithSiteAndEntries(tester);
    expect(textOf(tester, 'net-won'), '300,000원');
    expect(find.text('업체 수정 → 세금 방식을 고르면 공제가 계산돼요'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('업체 수정에서 세금 방식을 4대보험으로 바꾸면 저장되고 카드에 반영된다', (tester) async {
    final siteId = await pumpWithSiteAndEntries(tester);
    await openMenu(tester, '업체(현장) 관리');
    await tester.tap(find.byKey(ValueKey('site-tile-$siteId')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4대보험'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tax-daily-income')), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final site = (await db.siteDao.getById(siteId))!;
    expect(site.taxMode, 'insurance4');
    expect(
      TaxOptions.fromJsonString(site.taxOptionsJson).applyDailyIncomeTax,
      true,
    );

    // 달력으로 복귀 (pageBack()은 영어 툴팁 'Back'을 찾으므로 한국어 앱에선
    // BackButton 타입으로 직접 탭한다)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // 2일 근무(8일 미만): 연금·건강 없음. 일당 150,000 = 일 공제액이라
    // 일용소득세 0. 고용보험 300,000 × 0.9% = 2,700 → 실수령 297,300
    expect(textOf(tester, 'net-won'), '297,300원');
    expect(find.text('세금·보험 공제 2,700원'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('정산 화면: 이번 달 합계와 업체별 카드', (tester) async {
    await pumpWithSiteAndEntries(tester, taxMode: TaxMode.withholding33);
    await openMenu(tester, '정산 (기간 지정)');

    expect(textOf(tester, 'settle-gross'), '300,000원');
    expect(textOf(tester, 'settle-net'), '290,100원');
    expect(find.text('A현장'), findsOneWidget);
    expect(find.text('3.3% 원천징수'), findsOneWidget);
    expect(find.text('소득세'), findsOneWidget);

    // 지난달로 바꾸면 기록이 없다
    await tester.tap(find.text('지난달'));
    await tester.pumpAndSettle();
    expect(find.text('이 기간에는 기록이 없어요.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('통계 화면: 연간 공수와 실수령', (tester) async {
    await pumpWithSiteAndEntries(tester, taxMode: TaxMode.withholding33);
    await openMenu(tester, '통계');
    expect(textOf(tester, 'stats-year'), '${DateTime.now().year}년');
    expect(textOf(tester, 'year-centi'), '2');
    expect(textOf(tester, 'year-net'), '290,100원');
    expect(find.text('월별 추이'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('세율 설정: 항목 수정 → 저장 → 초기화', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openMenu(tester, '세금 · 요율 설정');

    await tester.tap(find.byKey(const ValueKey('rate-pensionEmployeePer100k')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('rate-input')), '5.25');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('5.25%'), findsOneWidget);
    expect(find.text('초기화'), findsOneWidget);

    await tester.tap(find.text('초기화'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('초기화').last); // 다이얼로그 확인
    await tester.pumpAndSettle();
    expect(find.text('5.25%'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('끝전 처리 설정 변경이 저장된다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openMenu(tester, '세금 · 요율 설정');
    await tester.tap(find.text('원 단위 그대로'));
    await tester.pumpAndSettle();
    final rows = await db.select(db.appSettings).get();
    expect(
      rows.any((r) => r.key == 'tax_rounding' && r.value == 'exact'),
      true,
    );
    await unmountApp(tester);
  });
}
