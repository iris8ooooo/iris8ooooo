import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/local_prefs.dart';
import 'package:gongsu_ledger/data/repositories/day_item_repository.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/prefs_providers.dart';
import 'package:gongsu_ledger/ui/backup/trash_page.dart';

/// 삭제된 기록 되살리기 — 실행 취소를 놓쳐도 지운 기록은 되돌릴 수 있다.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  Widget buildApp() {
    db = AppDatabase(NativeDatabase.memory());
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        localPrefsProvider.overrideWithValue(
          MemoryLocalPrefs({'onboarding_done': '1'}),
        ),
      ],
      child: const GongsuApp(),
    );
  }

  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('설정 → 삭제된 기록 → 되살리기: 지운 공수와 부가항목이 달력으로 돌아온다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final today = dateKeyOf(DateTime.now());
    final entries = WorkEntryRepository(db.workEntryDao);
    final items = DayItemRepository(db.dayItemDao);
    final entryId = await entries.addCustom(dateKey: today, centiGongsu: 180);
    final itemId = await items.add(
      dateKey: today,
      kind: ExtraItemKind.allowance,
      label: '식비',
      amountWon: 10000,
    );
    await entries.softDelete(entryId);
    await items.softDelete(itemId);
    await tester.pumpAndSettle();
    expect(await db.workEntryDao.getRange(today, today), isEmpty);

    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('trash')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('trash')));
    await tester.pumpAndSettle();
    expect(find.byType(TrashPage), findsOneWidget);
    expect(find.byKey(ValueKey('trash-entry-$entryId')), findsOneWidget);
    expect(find.byKey(ValueKey('trash-item-$itemId')), findsOneWidget);
    expect(find.text('1.8공수'), findsNothing); // 라벨 없는 직접 입력 → "1.8공수" 포함 문구
    expect(find.textContaining('1.8공수'), findsOneWidget);

    await tester.tap(find.text('되살리기').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('되살리기').first);
    await tester.pumpAndSettle();
    expect(find.text('삭제된 기록이 없어요.'), findsOneWidget);
    final alive = await db.workEntryDao.getRange(today, today);
    expect(alive.single.centiGongsu, 180);
    expect((await db.dayItemDao.getRange(today, today)).single.label, '식비');
    await unmountApp(tester);
  });
}
