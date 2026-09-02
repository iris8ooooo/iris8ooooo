// 화면 캡쳐 생성기 — 시뮬레이터 없이 앱 화면을 PNG로 뽑는다 (오너 확인용·스토어 스크린샷용).
//
//   flutter test test/screenshots/screenshots_test.dart --dart-define=SHOT_DIR=/절대/경로
//
// SHOT_DIR이 없으면 건너뛰므로 일반 `flutter test`에는 영향이 없다.
// 위젯 테스트 환경은 글꼴이 없어 네모로 그려지므로 나눔고딕·머티리얼 아이콘을 직접 올린다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/backup/snapshot_service.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/export/work_report_data.dart';
import 'package:gongsu_ledger/data/export/work_report_pdf.dart';
import 'package:gongsu_ledger/data/repositories/day_item_repository.dart';
import 'package:gongsu_ledger/data/repositories/memo_repository.dart';
import 'package:gongsu_ledger/data/repositories/settings_repository.dart';
import 'package:gongsu_ledger/data/repositories/site_repository.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:gongsu_ledger/state/backup_providers.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/site_providers.dart';
import 'package:gongsu_ledger/state/tax_providers.dart';
import 'package:gongsu_ledger/ui/app_theme.dart';
import 'package:gongsu_ledger/ui/calendar/calendar_page.dart';
import 'package:pdf/widgets.dart' as pw;

const String shotDir = String.fromEnvironment('SHOT_DIR');
const String _font = 'NanumGothic';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  final shotKey = GlobalKey();
  final snapshotRoot = Directory.systemTemp.createTempSync('gongsu_shots_');

  setUpAll(() async {
    if (shotDir.isEmpty) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    Directory(shotDir).createSync(recursive: true);
    ByteData bytesOf(String path) =>
        ByteData.sublistView(File(path).readAsBytesSync());
    final nanum = FontLoader(_font)
      ..addFont(Future.value(bytesOf('assets/fonts/NanumGothic-Regular.ttf')))
      ..addFont(Future.value(bytesOf('assets/fonts/NanumGothic-Bold.ttf')));
    await nanum.load();
    // flutter_tester: <flutter>/bin/cache/artifacts/engine/linux-x64/flutter_tester
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
    final icons = File(
      '${artifacts.path}/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(bytesOf(icons.path)));
      await loader.load();
    }
  });

  /// 앱 테마에 캡쳐용 글꼴을 입힌다 (테마 자체는 건드리지 않는다).
  ThemeData shotTheme(Brightness b) {
    final t = buildAppTheme(b);
    TextStyle? fix(TextStyle? s) => s?.copyWith(fontFamily: _font);
    WidgetStateProperty<TextStyle?>? fixProp(ButtonStyle? s) =>
        WidgetStatePropertyAll(fix(s?.textStyle?.resolve({})));
    return t.copyWith(
      textTheme: t.textTheme.apply(fontFamily: _font),
      primaryTextTheme: t.primaryTextTheme.apply(fontFamily: _font),
      listTileTheme: t.listTileTheme.copyWith(
        titleTextStyle: fix(t.listTileTheme.titleTextStyle),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: t.filledButtonTheme.style?.copyWith(
          textStyle: fixProp(t.filledButtonTheme.style),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: t.textButtonTheme.style?.copyWith(
          textStyle: fixProp(t.textButtonTheme.style),
        ),
      ),
    );
  }

  Widget buildApp({ThemeMode mode = ThemeMode.light}) {
    return RepaintBoundary(
      key: shotKey,
      child: ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          // path_provider 플러그인이 없는 테스트 환경 — 임시 폴더로 대체.
          snapshotServiceProvider.overrideWithValue(
            SnapshotService(rootDirectory: () async => snapshotRoot),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: shotTheme(Brightness.light),
          darkTheme: shotTheme(Brightness.dark),
          themeMode: mode,
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const CalendarPage(),
        ),
      ),
    );
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(shotKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shotDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> openMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  /// 데모 데이터: 업체 2곳(3.3% / 4대보험), 3~9월 근무 기록, 부가항목, 메모.
  Future<({int siteA, int siteB})> seed() async {
    final sites = SiteRepository(db.siteDao);
    final siteA = await sites.create(
      name: '대성건설 2공구',
      colorId: 2,
      dailyRateWon: 180000,
      taxMode: TaxMode.withholding33,
    );
    final siteB = await sites.create(
      name: '한빛플랜트',
      colorId: 5,
      dailyRateWon: 200000,
      taxMode: TaxMode.insurance4,
    );
    final presets = await db.presetDao.getActive();
    Preset byCenti(int c) => presets.firstWhere((p) => p.centiGongsu == c);
    final entries = WorkEntryRepository(db.workEntryDao);
    for (var month = 3; month <= 9; month++) {
      final days = DateTime(2026, month + 1, 0).day;
      for (var d = 1; d <= days; d++) {
        final date = DateTime(2026, month, d);
        final key = dateKeyOf(date);
        if (date.weekday == DateTime.sunday) continue;
        final siteId = (d >= 20 && d <= 24) ? siteB : siteA;
        switch (date.weekday) {
          case DateTime.saturday:
            if (d % 2 == 0) {
              await entries.addFromPreset(
                dateKey: key,
                preset: byCenti(50),
                siteId: siteId,
              );
            }
          case DateTime.friday:
            await entries.addFromPreset(
              dateKey: key,
              preset: byCenti(150),
              siteId: siteId,
            );
          default:
            await entries.addFromPreset(
              dateKey: key,
              preset: byCenti(100),
              siteId: siteId,
            );
        }
        if (month == 9 && (d == 9 || d == 23)) {
          await entries.addFromPreset(
            dateKey: key,
            preset: byCenti(200),
            siteId: siteId,
          );
        }
        if (month == 9 && d == 16) {
          await entries.addCustom(
            dateKey: key,
            centiGongsu: 180,
            siteId: siteA,
          );
        }
      }
    }
    final items = DayItemRepository(db.dayItemDao);
    for (final d in [3, 10, 17]) {
      await items.add(
        dateKey: 20260900 + d,
        kind: ExtraItemKind.allowance,
        label: '식비',
        amountWon: 10000,
        siteId: siteA,
      );
    }
    await items.add(
      dateKey: 20260915,
      kind: ExtraItemKind.deduction,
      label: '가불',
      amountWon: 200000,
      siteId: siteA,
    );
    final memos = MemoRepository(db.memoDao);
    await memos.setMemo(dateKey: 20260908, body: '2층 배관 마감. 자재 부족으로 오후 대기');
    await memos.setMemo(dateKey: 20260916, body: '비 와서 오후 철수 (1.8공수 인정)');
    await SettingsRepository(db)
        .set(SettingsRepository.keyReportWorkerName, '홍길동');
    return (siteA: siteA, siteB: siteB);
  }

  testWidgets('앱 화면 캡쳐 + 공수 확인서 PDF 샘플 생성', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final ids = await seed();
    await tester.pumpAndSettle();

    await shot(tester, '01_달력_홈');

    await tester.tap(find.byKey(const ValueKey('day-20260910')));
    await shot(tester, '02_공수_입력_시트');
    await tester.tap(find.text('직접 입력'));
    await shot(tester, '03_직접_입력_키패드');
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await openMenu(tester, '업체(현장) 관리');
    await shot(tester, '04_업체_관리');
    await back(tester);

    await openMenu(tester, '정산 (기간 지정)');
    await shot(tester, '05_정산');
    await tester.tap(find.byKey(const ValueKey('export-pdf')));
    await tester.pumpAndSettle();
    await shot(tester, '06_공수_확인서_만들기');
    await back(tester);
    await back(tester);

    await openMenu(tester, '통계');
    await shot(tester, '07_통계');
    await back(tester);

    await openMenu(tester, '백업 / 복원');
    await shot(tester, '08_백업_복원');
    await back(tester);

    await openMenu(tester, '세금 · 요율 설정');
    await shot(tester, '09_세금_요율_설정');
    await back(tester);

    // 공수 확인서 PDF (앱의 확인서 화면과 같은 조립 경로).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarPage)),
    );
    final key = periodKey(20260901, 20260930);
    final subs = [
      container.listen(periodSettlementProvider(key), (_, _) {}),
      container.listen(rangeEntriesProvider(key), (_, _) {}),
      container.listen(rangeItemsProvider(key), (_, _) {}),
      container.listen(rangeMemosProvider(key), (_, _) {}),
      container.listen(allRatesProvider, (_, _) {}),
      container.listen(siteByIdProvider, (_, _) {}),
    ];
    await tester.pumpAndSettle();
    final settlement = container.read(periodSettlementProvider(key))!;
    final siteById = container.read(siteByIdProvider);
    final rates = container.read(allRatesProvider).requireValue;
    final data = buildWorkReportData(
      fromKey: 20260901,
      toKey: 20260930,
      siteId: ids.siteA,
      siteName: siteById[ids.siteA]!.name,
      workerName: '홍길동',
      entries: container.read(rangeEntriesProvider(key)).requireValue,
      items: container.read(rangeItemsProvider(key)).requireValue,
      memos: container.read(rangeMemosProvider(key)).requireValue,
      histories: [
        for (final r in rates)
          (
            siteId: r.siteId,
            effectiveFromDateKey: r.effectiveFromDateKey,
            dailyRateWon: r.dailyRateWon,
          ),
      ],
      siteById: siteById,
      settlement: settlement,
    );
    for (final s in subs) {
      s.close();
    }
    await tester.runAsync(() async {
      ByteData bytesOf(String path) =>
          ByteData.sublistView(File(path).readAsBytesSync());
      final pdf = await buildWorkReportPdf(
        data,
        regular: pw.Font.ttf(bytesOf('assets/fonts/NanumGothic-Regular.ttf')),
        bold: pw.Font.ttf(bytesOf('assets/fonts/NanumGothic-Bold.ttf')),
        generatedAt: DateTime(2026, 9, 2, 14, 30),
      );
      File('$shotDir/공수확인서_샘플_2026-09.pdf').writeAsBytesSync(pdf);
    });

    // 다크모드 달력.
    await tester.pumpWidget(buildApp(mode: ThemeMode.dark));
    await tester.pumpAndSettle();
    await shot(tester, '10_다크모드_달력');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }, skip: shotDir.isEmpty); // SHOT_DIR 미지정이면 건너뜀 (캡쳐 생성 전용)
}
