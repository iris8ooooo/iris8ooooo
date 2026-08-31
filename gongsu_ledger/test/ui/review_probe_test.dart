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
      overrides: [
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        })
      ],
      child: const GongsuApp(),
    );
  }

  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  int pickEmptyDayKey() {
    final today = DateTime.now();
    final day = today.day <= 15 ? today.day + 1 : today.day - 1;
    return dateKeyOf(DateTime(today.year, today.month, day));
  }

  testWidgets('PROBE: 빈 날 프리셋 연타 → 이중 저장 + 이중 pop?', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();

    // 연타: 스트림 갱신이 돌아오기 전에 두 번 탭.
    await tester.tap(find.text('1공수'));
    await tester.tap(find.text('1공수'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final rows = await db.workEntryDao.watchMonth(dateKey ~/ 100).first;
    debugPrint('PROBE rows saved = ${rows.length}');
    debugPrint(
        'PROBE calendar visible = ${find.text('월 총 공수').evaluate().isNotEmpty}');
    debugPrint(
        'PROBE any MaterialApp page = ${find.byType(Scaffold).evaluate().length} scaffolds');
    await unmountApp(tester);
  });
}
