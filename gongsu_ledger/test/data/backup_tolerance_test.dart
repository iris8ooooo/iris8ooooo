import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/backup/backup_codec.dart';
import 'package:gongsu_ledger/data/backup/backup_text_codec.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/settings_repository.dart';
import 'package:gongsu_ledger/data/repositories/site_repository.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('손상된 행 하나는 건너뛰고 나머지는 들어온다 (skipped 로 보고)', () async {
    final envelope = {
      'format': backupFormatTag,
      'schemaVersion': AppDatabase.codeSchemaVersion,
      'workEntries': [
        {
          'uid': '11111111-1111-4111-8111-111111111111',
          'dateKey': 20260901,
          'centiGongsu': 100,
          'labelSnapshot': 12345, // 문자열이 아님 → 관대하게 문자열화
          'createdAtMillis': 1,
          'updatedAtMillis': 1,
        },
        {
          'uid': '22222222-2222-4222-8222-222222222222',
          'dateKey': 20260230, // 없는 날짜 → 건너뜀
          'centiGongsu': 100,
          'createdAtMillis': 1,
          'updatedAtMillis': 1,
        },
        {
          'uid': '33333333-3333-4333-8333-333333333333',
          'dateKey': 20260902,
          'centiGongsu': 'abc', // 숫자가 아님 → 건너뜀
          'createdAtMillis': 1,
          'updatedAtMillis': 1,
        },
      ],
      'sites': [
        {
          'uid': '44444444-4444-4444-8444-444444444444',
          'name': '이름이 아주 길어서 서른 자를 훌쩍 넘어가는 업체 이름 테스트용',
          'isArchived': 0,
          'createdAtMillis': 1,
          'updatedAtMillis': 1,
        },
      ],
    };
    final result = await importBackupJson(db, jsonEncode(envelope));
    expect(result.inserted, 2);
    expect(result.skipped, 2);
    final entries = await db.workEntryDao.getRange(20260901, 20260930);
    expect(entries.single.labelSnapshot, '12345');
    final sites = await db.siteDao.getActive();
    expect(sites.single.name.length, 30);
  });

  test('설정(요율 오버라이드·끝전·마감일·이름·직군)이 백업에 실리고, 없을 때만 복원된다', () async {
    final settings = SettingsRepository(db);
    await settings.set(SettingsRepository.keyReportWorkerName, '홍길동');
    await settings.set(SettingsRepository.keyTaxRounding, 'exact');
    await settings.setTaxRatesOverride(2026, {'pensionEmployeePer100k': 5000});
    await settings.set(SettingsRepository.keyProUnlocked, '1'); // 기기 고유 → 제외
    final json = await exportBackupJson(db);
    final decoded = jsonDecode(json) as Map<String, Object?>;
    final keys = [
      for (final r in decoded['appSettings'] as List)
        (r as Map)['key'] as String,
    ];
    expect(
      keys,
      containsAll([
        'report_worker_name',
        'tax_rounding',
        'tax_rates_override_2026',
      ]),
    );
    expect(keys, isNot(contains('pro_unlocked')));

    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    final otherSettings = SettingsRepository(other);
    await otherSettings.set(SettingsRepository.keyTaxRounding, 'floor10');
    final result = await importBackupJson(other, json);
    expect(
      await otherSettings.get(SettingsRepository.keyReportWorkerName),
      '홍길동',
    );
    expect(
      await otherSettings.get(SettingsRepository.keyTaxRounding),
      'floor10',
      reason: '기존 값 우선',
    );
    expect(
      (await otherSettings.getTaxRatesOverride(
        2026,
      ))?['pensionEmployeePer100k'],
      5000,
    );
    expect(await otherSettings.get(SettingsRepository.keyProUnlocked), isNull);
    expect(result.inserted, greaterThanOrEqualTo(2));
  });

  test('텍스트 백업에 보이지 않는 문자와 잘린 패딩이 섞여도 복원된다', () async {
    await WorkEntryRepository(db.workEntryDao)
        .addCustom(dateKey: 20260903, centiGongsu: 180);
    final text = encodeBackupText(await exportBackupJson(db));
    final mangled = text
        .replaceFirst('GSJB1:', 'GSJB1:​')
        .replaceAll('=', '')
        .replaceRange(20, 20, '​ ');
    final json = decodeBackupText(mangled);
    expect(jsonDecode(json), isA<Map>());
  });

  test('업체 생성은 원자적: 잘못된 단가면 업체도 만들어지지 않는다', () async {
    final repo = SiteRepository(db.siteDao);
    await expectLater(
      repo.create(name: 'A', colorId: 1, dailyRateWon: -5),
      throwsArgumentError,
    );
    expect(await db.siteDao.getActive(), isEmpty);
  });
}
