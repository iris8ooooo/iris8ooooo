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

  testWidgets('PROBE2: 모드 전환 직후 메모 버튼 → 기존 메모 유실?', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final dateKey = pickEmptyDayKey();
    // DB에 기존 메모를 심는다.
    await db.memoDao.setMemo(dateKey, '기존 중요 메모', 1000);

    // 시트 열기 (메모 스트림 아직 로딩 중일 수 있음).
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pump(); // 시트 1프레임만 — 스트림 emit 전 상태를 노린다
    final memoBtn = find.text('메모');
    final memoEditBtn = find.text('메모 수정');
    debugPrint('PROBE2 first frame: 메모버튼=${memoBtn.evaluate().length} '
        '메모수정버튼=${memoEditBtn.evaluate().length}');
    if (memoBtn.evaluate().isNotEmpty) {
      await tester.tap(memoBtn);
      await tester.pump();
      // 메모 입력창의 현재 텍스트
      final field = tester.widget<TextField>(find.byType(TextField));
      debugPrint('PROBE2 controller text = "${field.controller?.text}"');
      await tester.tap(find.text('메모 저장'));
      await tester.pumpAndSettle();
      final memo = await db.memoDao.watchMemo(dateKey).first;
      debugPrint('PROBE2 DB memo after save = ${memo?.body}');
    } else {
      debugPrint('PROBE2 stream emitted before first frame — race not hit');
    }
    await unmountApp(tester);
  });

  testWidgets('PROBE2: 직접입력 취소 복귀 프레임에 프리셋 그리드 사라짐?', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final dateKey = pickEmptyDayKey();
    await tester.tap(find.byKey(ValueKey('day-$dateKey')));
    await tester.pumpAndSettle();
    expect(find.text('1공수'), findsOneWidget);

    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle(); // 키패드 모드 — presetsProvider 폐기됨

    await tester.tap(find.text('취소'));
    await tester.pump(); // 복귀 첫 프레임
    debugPrint(
        'PROBE2 back-to-list first frame: preset buttons = ${find.text('1공수').evaluate().length}');
    await tester.pump();
    debugPrint(
        'PROBE2 next frame: preset buttons = ${find.text('1공수').evaluate().length}');
    await tester.pumpAndSettle();
    await unmountApp(tester);
  });
}
