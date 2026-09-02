import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/backup/backup_codec.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/data/repositories/day_item_repository.dart';
import 'package:gongsu_ledger/data/repositories/site_repository.dart';
import 'package:gongsu_ledger/data/repositories/work_entry_repository.dart';
import 'package:gongsu_ledger/domain/rate_resolver.dart';

void main() {
  late AppDatabase db;
  late SiteRepository sites;
  late WorkEntryRepository entries;
  late DayItemRepository items;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sites = SiteRepository(db.siteDao);
    entries = WorkEntryRepository(db.workEntryDao);
    items = DayItemRepository(db.dayItemDao);
  });

  tearDown(() => db.close());

  Future<List<RateHistoryEntry>> allRates() async {
    final rows = await db.siteDao.watchAllRates().first;
    return [
      for (final r in rows)
        (
          siteId: r.siteId,
          effectiveFromDateKey: r.effectiveFromDateKey,
          dailyRateWon: r.dailyRateWon,
        ),
    ];
  }

  group('업체 + 단가 이력', () {
    test('기본 단가로 업체를 만들면 모든 날짜에 그 단가가 적용된다', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 0,
        dailyRateWon: 150000,
      );
      final rates = await allRates();
      expect(
        resolveSiteRateWon(histories: rates, siteId: siteId, dateKey: 20200101),
        150000,
      );
      expect(
        resolveSiteRateWon(histories: rates, siteId: siteId, dateKey: 20990101),
        150000,
      );
    });

    test('단가 개정: 적용 시작일 이후만 새 단가, 이전 날짜는 옛 단가 유지 (핵심)', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 0,
        dailyRateWon: 150000,
      );
      await sites.setRate(
        siteId: siteId,
        effectiveFromDateKey: 20260901,
        dailyRateWon: 165000,
      );
      final rates = await allRates();
      expect(rates.length, 2); // 과거 이력이 덮어써지지 않았다
      expect(
        resolveSiteRateWon(histories: rates, siteId: siteId, dateKey: 20260831),
        150000,
      );
      expect(
        resolveSiteRateWon(histories: rates, siteId: siteId, dateKey: 20260901),
        165000,
      );
    });

    test('같은 시작일로 다시 설정하면 중복 이력 없이 갱신된다', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 0,
        dailyRateWon: 150000,
      );
      await sites.setRate(
        siteId: siteId,
        effectiveFromDateKey: 20260901,
        dailyRateWon: 160000,
      );
      await sites.setRate(
        siteId: siteId,
        effectiveFromDateKey: 20260901,
        dailyRateWon: 165000,
      );
      final rates = await allRates();
      expect(rates.where((r) => r.effectiveFromDateKey == 20260901).length, 1);
      expect(
        resolveSiteRateWon(histories: rates, siteId: siteId, dateKey: 20260915),
        165000,
      );
    });

    test('이력 삭제는 soft delete — 조회에서 빠지고 DB에는 남는다', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 0,
        dailyRateWon: 150000,
      );
      final rateId = await sites.setRate(
        siteId: siteId,
        effectiveFromDateKey: 20260901,
        dailyRateWon: 165000,
      );
      await sites.deleteRate(rateId);
      final rates = await allRates();
      expect(rates.length, 1);
      expect(
        resolveSiteRateWon(histories: rates, siteId: siteId, dateKey: 20260915),
        150000,
      ); // 삭제된 개정 대신 기본 단가로 복귀
      final all = await db.select(db.siteRateHistories).get();
      expect(all.length, 2);
    });

    test('업체 보관 후에도 기록의 참조와 업체 정보는 유지된다', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 3,
        dailyRateWon: 150000,
      );
      await entries.addCustom(
        dateKey: 20260805,
        centiGongsu: 100,
        siteId: siteId,
      );
      await sites.archive(siteId);

      expect(await db.siteDao.getActive(), isEmpty);
      final site = await db.siteDao.getById(siteId);
      expect(site?.name, 'A현장'); // 보관 = 행 유지
      final entry = (await db.workEntryDao.getRange(20260805, 20260805)).single;
      expect(entry.siteId, siteId);
    });

    test('입력 검증: 빈 이름·음수 단가·범위 밖 날짜 거부', () async {
      expect(() => sites.create(name: ' ', colorId: 0), throwsArgumentError);
      expect(() => sites.create(name: 'A', colorId: 99), throwsArgumentError);
      final siteId = await sites.create(name: 'A', colorId: 0);
      expect(
        () => sites.setRate(
          siteId: siteId,
          effectiveFromDateKey: 20260901,
          dailyRateWon: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => sites.setRate(
          siteId: siteId,
          effectiveFromDateKey: 99999999,
          dailyRateWon: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('기록의 업체/오버라이드', () {
    test('기록별 단가 오버라이드와 업체 변경', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 0,
        dailyRateWon: 150000,
      );
      final id = await entries.addCustom(dateKey: 20260805, centiGongsu: 100);
      await entries.updateSite(id: id, siteId: siteId);
      await entries.updateRateOverride(id: id, unitRateWonOverride: 180000);
      final entry = (await db.workEntryDao.getById(id))!;
      expect(entry.siteId, siteId);
      expect(entry.unitRateWonOverride, 180000);

      await entries.updateRateOverride(id: id, unitRateWonOverride: null);
      expect((await db.workEntryDao.getById(id))!.unitRateWonOverride, null);
      expect(
        () => entries.updateRateOverride(id: id, unitRateWonOverride: -5),
        throwsArgumentError,
      );
    });
  });

  group('부가 항목', () {
    test('추가/조회/soft delete/복원', () async {
      final id = await items.add(
        dateKey: 20260805,
        kind: ExtraItemKind.allowance,
        label: '식비',
        amountWon: 10000,
      );
      await items.add(
        dateKey: 20260805,
        kind: ExtraItemKind.deduction,
        label: '안전용품비',
        amountWon: 15000,
      );
      await items.add(
        dateKey: 20260905,
        kind: ExtraItemKind.allowance,
        label: '일비',
        amountWon: 1,
      );

      final aug = await db.dayItemDao.watchMonth(202608).first;
      expect(aug.length, 2); // 월 경계
      expect(aug.first.kind, 'allowance');

      await items.softDelete(id);
      expect((await db.dayItemDao.watchMonth(202608).first).length, 1);
      await items.restore(id);
      expect((await db.dayItemDao.watchMonth(202608).first).length, 2);
    });

    test('검증: 음수 금액·빈 이름 거부', () async {
      expect(
        () => items.add(
          dateKey: 20260805,
          kind: ExtraItemKind.allowance,
          label: '식비',
          amountWon: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => items.add(
          dateKey: 20260805,
          kind: ExtraItemKind.allowance,
          label: '',
          amountWon: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('백업 — 업체/단가/부가항목', () {
    test('라운드트립: 기록↔업체, 이력↔업체 연결이 uid로 재매핑된다', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 2,
        dailyRateWon: 150000,
      );
      await sites.setRate(
        siteId: siteId,
        effectiveFromDateKey: 20260901,
        dailyRateWon: 165000,
      );
      await entries.addCustom(
        dateKey: 20260805,
        centiGongsu: 100,
        siteId: siteId,
      );
      await items.add(
        dateKey: 20260805,
        kind: ExtraItemKind.allowance,
        label: '식비',
        amountWon: 10000,
        siteId: siteId,
      );
      final json = await exportBackupJson(db);

      // 대상 기기는 자기 업체를 먼저 만들어 id가 어긋난 상태
      final target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      await SiteRepository(target.siteDao).create(name: '내현장', colorId: 5);
      final result = await importBackupJson(target, json);
      expect(result.skipped, 0);

      final tSite = (await target.select(target.sites).get()).firstWhere(
        (s) => s.name == 'A현장',
      );
      final tEntry = (await target.workEntryDao.getRange(
        20260805,
        20260805,
      )).single;
      expect(tEntry.siteId, tSite.id);
      final tRates = await target.siteDao.getRatesOfSite(tSite.id);
      expect(tRates.length, 2);
      expect(tRates.every((r) => r.siteId == tSite.id), true);
      final tItem = (await target.dayItemDao.getRange(
        20260805,
        20260805,
      )).single;
      expect(tItem.siteId, tSite.id);
      expect(tItem.label, '식비');
    });

    test('업체 uid를 못 찾는 단가 이력은 건너뛰고 보고한다', () async {
      final siteId = await sites.create(
        name: 'A현장',
        colorId: 2,
        dailyRateWon: 150000,
      );
      final json = await exportBackupJson(db);
      final broken = json.replaceAll(
        (await db.siteDao.getById(siteId))!.uid,
        '99999999-9999-4999-8999-999999999999',
      );
      // 업체 행 자체는 uid가 바뀌어 새 업체로 들어가고, 이력의 siteUid도 같이
      // 바뀌었으므로 정상 연결된다 — 대신 sites 배열을 통째로 비워 고아를 만든다.
      final envelope = broken.replaceFirst(
        RegExp(r'"sites":\[[^\]]*\]'),
        '"sites":[]',
      );

      final target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      final result = await importBackupJson(target, envelope);
      expect(result.skipped, 1); // 고아 단가 이력
      expect(await target.select(target.siteRateHistories).get(), isEmpty);
    });

    test('v1 백업(업체 정보 없음)도 v2 앱에서 정상 병합된다', () async {
      await entries.addCustom(dateKey: 20260805, centiGongsu: 180);
      final json = await exportBackupJson(db);
      final v1Like = json
          .replaceFirst('"schemaVersion":2', '"schemaVersion":1')
          .replaceFirst(RegExp(r',"sites":\[[^\]]*\]'), '')
          .replaceFirst(RegExp(r',"siteRateHistories":\[[^\]]*\]'), '')
          .replaceFirst(RegExp(r',"dayExtraItems":\[[^\]]*\]'), '');

      final target = AppDatabase(NativeDatabase.memory());
      addTearDown(target.close);
      final result = await importBackupJson(target, v1Like);
      expect(result.skipped, 0);
      final entry = (await target.workEntryDao.getRange(
        20260805,
        20260805,
      )).single;
      expect(entry.centiGongsu, 180);
      expect(entry.siteId, null);
    });
  });
}
