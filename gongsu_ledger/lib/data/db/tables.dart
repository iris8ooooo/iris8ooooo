import 'package:drift/drift.dart';

/// 공수 기록 — 유일한 사실의 원천. 하루 무제한 여러 건.
///
/// 설계 원칙:
/// - 기록은 스냅샷: 입력 시점의 프리셋 이름/색을 자체 컬럼에 복사한다.
///   프리셋을 수정·보관해도 과거 기록의 표시는 절대 변하지 않는다.
/// - 삭제는 soft delete(deletedAtMillis)만. 물리 삭제 경로는 존재하지 않는다.
/// - FK 제약은 걸지 않는다: 프리셋은 보관만 하므로 행이 사라지지 않고,
///   제약이 없어야 백업 복원·마이그레이션 순서가 자유롭다.
///   무결성은 repository 계층 + 테스트로 지킨다.
/// - siteId/unitRateWonOverride는 M2(업체·단가) 예약 컬럼.
///   NULL = "업체 미지정/기본 단가"라는 하위호환 의미가 자명하다.
@TableIndex(name: 'idx_work_entries_date', columns: {#dateKey})
class WorkEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 기기 간 병합/백업 재가져오기용 전역 키 (UUIDv4).
  TextColumn get uid => text().withLength(min: 36, max: 36).unique()();

  /// yyyyMMdd 정수. DateTime/타임존은 DB에 절대 들어가지 않는다.
  IntColumn get dateKey => integer()();

  /// centi-공수 (1공수 = 100). 0 = 휴무. double 경유 절대 금지.
  IntColumn get centiGongsu => integer()();

  /// 입력에 사용한 프리셋 id. NULL = 직접 입력.
  IntColumn get presetId => integer().nullable()();

  /// 입력 시점 스냅샷 — 프리셋 이름. 직접 입력이면 빈 문자열.
  TextColumn get labelSnapshot => text().withDefault(const Constant(''))();

  /// 입력 시점 스냅샷 — MarkerPalette id.
  IntColumn get colorIdSnapshot => integer().withDefault(const Constant(0))();

  /// M2 예약: 업체 id. NULL = 미지정.
  IntColumn get siteId => integer().nullable()();

  /// M2 예약: 이 기록만 단가 오버라이드(원). NULL = 업체 단가 이력을 따름.
  IntColumn get unitRateWonOverride => integer().nullable()();

  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();

  /// soft delete. NULL = 살아있음. 같은 날 여러 건의 표시 순서는 id 오름차순.
  IntColumn get deletedAtMillis => integer().nullable()();
}

/// 공수 프리셋 — 유저 자유 정의 (이름 + 공수값 + 색).
class Presets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().withLength(min: 36, max: 36).unique()();
  TextColumn get name => text().withLength(min: 1, max: 20)();

  /// centi-공수. 0 = 휴무 프리셋.
  IntColumn get centiGongsu => integer()();

  /// MarkerPalette id. 색값(ARGB)이 아니라 팔레트 id를 저장 —
  /// 팔레트 색을 개선해도 데이터 마이그레이션이 필요 없다.
  IntColumn get colorId => integer().withDefault(const Constant(0))();

  IntColumn get sortOrder => integer()();

  /// 삭제 대신 보관. 과거 기록의 presetId가 이 행을 계속 가리킬 수 있다.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();
}

/// 날짜별 메모 — 날짜당 1건. 본문 검색(M1 검색 화면은 추후) 대상.
class DayMemos extends Table {
  IntColumn get dateKey => integer()();
  TextColumn get body => text()();
  IntColumn get updatedAtMillis => integer()();

  @override
  Set<Column> get primaryKey => {dateKey};
}

/// 업체(현장). 삭제 대신 보관 — 기록의 siteId 참조가 계속 유효하다.
/// (schemaVersion 2에서 추가. taxMode는 M3에서 ADD COLUMN 예정)
class Sites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().withLength(min: 36, max: 36).unique()();
  TextColumn get name => text().withLength(min: 1, max: 30)();

  /// MarkerPalette id.
  IntColumn get colorId => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();
}

/// 단가 이력 — 적용 시작일 기준 개정. 단가는 기록에 저장하지 않고 조회 시점에
/// "그 날짜 이하의 가장 늦은 effectiveFrom 행"으로 해석한다. 그래서 단가를
/// 올려도 과거 기록은 당시 단가로 계산이 유지된다(커뮤니티 핵심 요구).
@TableIndex(
  name: 'idx_site_rates_site_from',
  columns: {#siteId, #effectiveFromDateKey},
)
class SiteRateHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().withLength(min: 36, max: 36).unique()();
  IntColumn get siteId => integer()();

  /// yyyyMMdd. 이 날짜부터(포함) 적용.
  IntColumn get effectiveFromDateKey => integer()();

  /// 1.0공수당 원.
  IntColumn get dailyRateWon => integer()();
  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();

  /// soft delete. 잘못 넣은 이력을 지울 때도 물리 삭제하지 않는다.
  IntColumn get deletedAtMillis => integer().nullable()();
}

/// 일 단위 부가 항목 — 일비/식비/숙식비(가산), 공제(차감).
/// amountWon은 항상 0 이상이고 방향은 kind로 정한다 (부호 실수 방지).
@TableIndex(name: 'idx_day_extra_items_date', columns: {#dateKey})
class DayExtraItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().withLength(min: 36, max: 36).unique()();
  IntColumn get dateKey => integer()();

  /// 업체 귀속. NULL = 업체 무관.
  IntColumn get siteId => integer().nullable()();

  /// 'allowance'(가산) | 'deduction'(차감). enum ordinal이 아닌 안정된 문자열.
  TextColumn get kind => text()();
  TextColumn get label => text().withLength(min: 1, max: 20)();
  IntColumn get amountWon => integer()();

  /// M3 예약: 세금 계산에 포함할지. 기본 false(일비/식비는 통상 비과세).
  BoolColumn get isTaxable => boolean().withDefault(const Constant(false))();
  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();
  IntColumn get deletedAtMillis => integer().nullable()();
}

/// key-value 설정. 값은 JSON 문자열 — 스키마 변경 없이 설정을 확장한다.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
