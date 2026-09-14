import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/local_prefs.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/domain/range_fill.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/prefs_providers.dart';

/// 연속 채우기 — 시트의 날짜부터 고른 날까지 같은 프리셋을 한 번에.
/// 이미 기록이 있는 날은 건너뛰고, 기본으로 일요일·공휴일도 건너뛴다.
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

  /// 이번 달 1일 (달력에 항상 보이는 칸).
  int monthStartKey() {
    final now = DateTime.now();
    return dateKeyOf(DateTime(now.year, now.month, 1));
  }

  Future<void> openRangeDialog(WidgetTester tester, int dateKey) async {
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('range-fill')));
    await tester.pumpAndSettle();
    expect(find.text('연속 채우기'), findsWidgets); // 다이얼로그 제목
  }

  testWidgets('이 달 말까지 기본값: 일요일·공휴일 빼고 1공수가 들어가고 시트가 닫힌다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final from = monthStartKey();
    await openRangeDialog(tester, from);

    final expected = planRangeFill(
      fromKey: from,
      toKey: monthEndKeyOf(from),
      skipRestDays: true,
      occupied: const {},
    );
    expect(
      find.text('${expected.dateKeys.length}일에 1공수 기록이 들어가요.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('range-fill-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('range-fill')), findsNothing); // 시트 닫힘
    expect(
      find.textContaining('${expected.dateKeys.length}일에 1공수 기록을 넣었어요'),
      findsOneWidget,
    );
    final rows = await db.workEntryDao.getRange(from, monthEndKeyOf(from));
    expect(rows.map((r) => r.dateKey).toList()..sort(), expected.dateKeys);
    expect(rows.every((r) => r.centiGongsu == 100), true);
    expect(rows.every((r) => r.labelSnapshot == '1공수'), true);
    await unmountApp(tester);
  });

  testWidgets('기록 있는 날은 그대로 두고, 쉬는 날 포함 + 다른 프리셋 선택', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final from = monthStartKey();
    final occupiedKey = addDaysToKey(from, 2);
    await WorkEntryRepository(
      db.workEntryDao,
    ).addCustom(dateKey: occupiedKey, centiGongsu: 180);
    await tester.pumpAndSettle();
    await openRangeDialog(tester, from);

    // 일주일 + 쉬는 날 포함 + 1.5공수 프리셋
    await tester.tap(find.byKey(const ValueKey('range-week')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('range-skip-rest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('range-preset-2')));
    await tester.pumpAndSettle();
    expect(
      find.text('6일에 1.5공수 기록이 들어가요. 이미 기록이 있는 1일은 그대로 둬요.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('range-fill-confirm')));
    await tester.pumpAndSettle();

    final to = addDaysToKey(from, 6);
    final rows = await db.workEntryDao.getRange(from, to);
    expect(rows.length, 7); // 기존 1.8 한 건 + 새 6건
    final existing = rows.singleWhere((r) => r.dateKey == occupiedKey);
    expect(existing.centiGongsu, 180); // 건드리지 않음
    expect(rows.where((r) => r.centiGongsu == 150).length, 6);
    await unmountApp(tester);
  });

  testWidgets('취소하면 아무것도 넣지 않는다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final from = monthStartKey();
    await openRangeDialog(tester, from);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('range-fill')), findsOneWidget); // 시트 유지
    expect(await db.workEntryDao.getRange(from, monthEndKeyOf(from)), isEmpty);
    await unmountApp(tester);
  });
}
