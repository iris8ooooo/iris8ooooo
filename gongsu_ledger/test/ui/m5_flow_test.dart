import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/site_repository.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:gongsu_ledger/domain/widget_payload.dart';
import 'package:gongsu_ledger/services/home_widget_service.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/widget_providers.dart';

/// 가짜 위젯 서비스: 저장된 값과 갱신 횟수를 기록한다.
class FakeHomeWidgetService implements HomeWidgetService {
  final Map<String, String> saved = {};
  int saves = 0;
  int updates = 0;

  @override
  Future<void> saveData(Map<String, String> data) async {
    saved.addAll(data);
    saves++;
  }

  @override
  Future<void> requestUpdate() async {
    updates++;
  }
}

/// M5 플로: 앱 시작·기록 변경 시 홈 위젯 값이 저장되고 갱신 신호가 간다.
/// (DB 검증은 스트림이 아닌 일반 쿼리만 — CLAUDE.md '테스트 작성 주의')
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late FakeHomeWidgetService widgetService;

  Widget buildApp() {
    db = AppDatabase(NativeDatabase.memory());
    widgetService = FakeHomeWidgetService();
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        homeWidgetServiceProvider.overrideWithValue(widgetService),
      ],
      child: const GongsuApp(),
    );
  }

  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  int todayKey() => dateKeyOf(DateTime.now());
  String thisMonthLabel() => '${DateTime.now().month}월';

  testWidgets('앱 시작 시 이번 달 위젯 값이 저장되고 갱신 신호가 간다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(widgetService.saved[WidgetKeys.monthLabel], thisMonthLabel());
    expect(widgetService.saved[WidgetKeys.gongsu], '0');
    expect(widgetService.saved[WidgetKeys.workedDays], '0');
    expect(widgetService.saved[WidgetKeys.money], '');
    expect(widgetService.updates, greaterThanOrEqualTo(1));
    await unmountApp(tester);
  });

  testWidgets('기록을 추가하면 위젯 공수가 반올림 없이 갱신된다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final before = widgetService.updates;

    await WorkEntryRepository(db.workEntryDao)
        .addCustom(dateKey: todayKey(), centiGongsu: 180);
    await tester.pumpAndSettle();

    expect(widgetService.saved[WidgetKeys.gongsu], '1.8');
    expect(widgetService.saved[WidgetKeys.workedDays], '1');
    expect(widgetService.saved[WidgetKeys.money], '');
    expect(widgetService.updates, greaterThan(before));
    await unmountApp(tester);
  });

  testWidgets('3.3% 업체 기록이면 실수령 금액 줄이 채워진다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final siteId = await SiteRepository(db.siteDao).create(
      name: 'A현장',
      colorId: 2,
      dailyRateWon: 200000,
      taxMode: TaxMode.withholding33,
    );
    await WorkEntryRepository(db.workEntryDao)
        .addCustom(dateKey: todayKey(), centiGongsu: 100, siteId: siteId);
    await tester.pumpAndSettle();

    // 200,000 − 소득세 6,000 − 지방소득세 600
    expect(widgetService.saved[WidgetKeys.moneyLabel], '실수령');
    expect(widgetService.saved[WidgetKeys.money], '193,400원');
    await unmountApp(tester);
  });

  testWidgets('표시 값이 같으면 다시 보내지 않는다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final saves = widgetService.saves;

    // 화면만 다시 그린다 (값 변화 없음)
    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 300));
    await tester.pumpAndSettle();

    expect(widgetService.saves, saves);
    await unmountApp(tester);
  });
}
