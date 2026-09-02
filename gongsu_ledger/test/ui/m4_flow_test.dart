import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app.dart';
import 'package:gongsu_ledger/data/backup/backup_codec.dart';
import 'package:gongsu_ledger/data/backup/backup_text_codec.dart';
import 'package:gongsu_ledger/data/backup/snapshot_service.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/local_prefs.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/domain/date_key.dart';
import 'package:gongsu_ledger/services/share_service.dart';
import 'package:gongsu_ledger/state/backup_providers.dart';
import 'package:gongsu_ledger/state/db_providers.dart';
import 'package:gongsu_ledger/state/prefs_providers.dart';

class FakeShareService implements ShareService {
  final List<String> texts = [];
  final List<({String fileName, String mimeType, Uint8List bytes})> files = [];

  @override
  Future<void> shareText(String text, {String? subject}) async =>
      texts.add(text);

  @override
  Future<void> shareBytes(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async => files.add((fileName: fileName, mimeType: mimeType, bytes: bytes));
}

class FakeBackupFileService implements BackupFileService {
  String? next;

  @override
  Future<String?> pickBackupText() async => next;
}

/// M4 플로: 텍스트/파일/스냅샷 백업·복원, 달력 캡쳐 공유.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late Directory tempDir;
  late FakeShareService share;
  late FakeBackupFileService picker;
  String? clipboard;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('m4_test');
    share = FakeShareService();
    picker = FakeBackupFileService();
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
            return null;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    tempDir.deleteSync(recursive: true);
  });

  Widget buildApp() {
    db = AppDatabase(NativeDatabase.memory());
    return ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(
          MemoryLocalPrefs({'onboarding_done': '1', 'pro_unlocked': '1'}),
        ),
        databaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        snapshotServiceProvider.overrideWithValue(
          SnapshotService(rootDirectory: () async => tempDir),
        ),
        shareServiceProvider.overrideWithValue(share),
        backupFileServiceProvider.overrideWithValue(picker),
      ],
      child: const GongsuApp(),
    );
  }

  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openBackup(WidgetTester tester) async {
    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('백업 / 복원'));
    await tester.pumpAndSettle();
  }

  int todayKey() => dateKeyOf(DateTime.now());

  /// 백업 화면은 긴 ListView — 아래쪽 항목은 스크롤 전엔 빌드되지 않는다.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('앱 시작 시 오늘 스냅샷이 자동 생성된다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final file = File('${tempDir.path}/snapshots/snapshot_${todayKey()}.gsjb');
    expect(file.existsSync(), true);
    expect(file.readAsStringSync().startsWith('GSJB1:'), true);
    await unmountApp(tester);
  });

  testWidgets('백업 텍스트 복사 → 붙여넣어 복원 (왕복)', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await WorkEntryRepository(db.workEntryDao)
        .addCustom(dateKey: 20260901, centiGongsu: 180);
    await openBackup(tester);

    await tester.tap(find.byKey(const ValueKey('copy-text-backup')));
    await tester.pumpAndSettle();
    expect(find.text('복사 완료'), findsOneWidget);
    expect(clipboard, isNotNull);
    expect(clipboard!.startsWith('GSJB1:'), true);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('import-text')),
      clipboard!,
    );
    await tester.tap(find.byKey(const ValueKey('restore-button')));
    await tester.pumpAndSettle();
    expect(find.text('데이터 병합 복원'), findsOneWidget);
    await tester.tap(find.text('복원'));
    await tester.pumpAndSettle();
    expect(find.text('복원 완료'), findsOneWidget);
    // 같은 데이터라 중복 없음
    expect((await db.workEntryDao.getRange(20260901, 20260901)).length, 1);
    await unmountApp(tester);
  });

  testWidgets('잘못된 텍스트는 복원 불가 안내, 데이터 불변', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openBackup(tester);
    await tester.enterText(find.byKey(const ValueKey('import-text')), '안녕하세요');
    await tester.tap(find.byKey(const ValueKey('restore-button')));
    await tester.pumpAndSettle();
    expect(find.text('복원 불가'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('JSON 파일 내보내기는 공유 시트에 파일을 올린다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openBackup(tester);
    await scrollTo(tester, find.byKey(const ValueKey('export-file')));
    await tester.tap(find.byKey(const ValueKey('export-file')));
    await tester.pumpAndSettle();

    expect(share.files.length, 1);
    expect(share.files.single.fileName.endsWith('.json'), true);
    expect(share.files.single.mimeType, 'application/json');
    final decoded = jsonDecode(utf8.decode(share.files.single.bytes)) as Map;
    expect(decoded['format'], backupFormatTag);
    await unmountApp(tester);
  });

  testWidgets('파일에서 가져오기: 다른 기기의 백업이 병합된다', (tester) async {
    // 다른 기기 흉내: 별도 DB에서 내보낸 텍스트
    final other = AppDatabase(NativeDatabase.memory());
    await WorkEntryRepository(other.workEntryDao)
        .addCustom(dateKey: 20260815, centiGongsu: 150);
    picker.next = encodeBackupText(await exportBackupJson(other));
    await other.close();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openBackup(tester);
    await scrollTo(tester, find.byKey(const ValueKey('import-file')));
    await tester.tap(find.byKey(const ValueKey('import-file')));
    await tester.pumpAndSettle();
    // 스냅샷 타일의 '복원'도 화면에 있으므로 다이얼로그(맨 위 라우트) 버튼을 고른다.
    await tester.tap(find.text('복원').last);
    await tester.pumpAndSettle();
    expect(find.text('복원 완료'), findsOneWidget);
    final rows = await db.workEntryDao.getRange(20260815, 20260815);
    expect(rows.single.centiGongsu, 150);
    await unmountApp(tester);
  });

  testWidgets('스냅샷 목록에 오늘 항목이 있고 복원 버튼이 동작한다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await openBackup(tester);
    await scrollTo(tester, find.byKey(const ValueKey('snapshot-now')));
    expect(find.byKey(ValueKey('snapshot-tile-${todayKey()}')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('snapshot-now')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('snapshot-now')));
    expect(find.byKey(ValueKey('snapshot-tile-${todayKey()}')), findsOneWidget);

    await tester.tap(find.text('복원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복원').last);
    await tester.pumpAndSettle();
    expect(find.text('복원 완료'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('달력 이미지 공유: PNG 바이트가 공유 서비스로 간다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('capture-share')));
      await tester.pump();
      for (var i = 0; i < 40 && share.files.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    expect(share.files.length, 1);
    expect(share.files.single.mimeType, 'image/png');
    final b = share.files.single.bytes;
    expect(b.length, greaterThan(1000));
    expect([b[0], b[1], b[2], b[3]], [0x89, 0x50, 0x4E, 0x47]); // PNG 시그니처
    await unmountApp(tester);
  });

  testWidgets('정산 화면에서 공수 확인서 화면으로 진입한다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('정산 (기간 지정)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-pdf')));
    await tester.pumpAndSettle();
    expect(find.text('공수 확인서'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-preview')), findsOneWidget);
    expect(find.text('전체 업체'), findsOneWidget);
    await unmountApp(tester);
  });
}
