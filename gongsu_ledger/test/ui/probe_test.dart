import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/state/db_providers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('probe: 시트 열고 프리셋 입력 후 언마운트 단계 추적', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      })],
      child: const GongsuApp(),
    ));
    await tester.pumpAndSettle();
    debugPrint('PROBE: app pumped');

    final today = DateTime.now();
    final day = today.day <= 15 ? today.day + 1 : today.day - 1;
    final dateKey = dateKeyOf(DateTime(today.year, today.month, day));
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    debugPrint('PROBE: sheet opened');

    await tester.tap(find.text('1공수'));
    await tester.pumpAndSettle();
    debugPrint('PROBE: preset tapped, sheet closed=${find.text('1공수').evaluate().isEmpty}');

    final rows = await db.workEntryDao.watchMonth(dateKey ~/ 100).first;
    debugPrint('PROBE: db read done rows=${rows.length}');

    await tester.pumpWidget(const SizedBox.shrink());
    debugPrint('PROBE: unmount pumped');
    await tester.pump(const Duration(seconds: 1));
    debugPrint('PROBE: clock advanced');
  }, timeout: const Timeout(Duration(seconds: 60)));
}
