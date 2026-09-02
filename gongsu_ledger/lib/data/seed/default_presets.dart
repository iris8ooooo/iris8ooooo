/// 기본 프리셋 시드.
///
/// uid를 고정 상수로 두는 이유: M4 백업 병합·v2 기기 간 병합에서 서로 다른
/// 기기가 만든 "같은 기본 프리셋"이 중복 생성되지 않도록 한다(uid upsert).
///
/// M6 온보딩 직군 선택과의 규칙(지금 확정):
/// 온보딩에서 다른 직군을 고르면 "사용자가 수정하지 않은 시드 프리셋"
/// (uid가 아래 상수 집합에 있고 createdAt == updatedAt)만 보관 처리하고
/// 새 직군 세트를 넣는다. 사용자가 손댄 프리셋은 절대 건드리지 않는다.
library;

class SeedPreset {
  const SeedPreset({
    required this.uid,
    required this.name,
    required this.centiGongsu,
    required this.colorId,
    required this.sortOrder,
  });

  final String uid;
  final String name;
  final int centiGongsu;
  final int colorId;
  final int sortOrder;
}

/// 건설형 (M1 기본. 온보딩 도입 전까지 최초 실행 시 시드)
const List<SeedPreset> constructionSeedPresets = [
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000c0001',
    name: '1공수',
    centiGongsu: 100,
    colorId: 0,
    sortOrder: 0,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000c0002',
    name: '1.5공수',
    centiGongsu: 150,
    colorId: 1,
    sortOrder: 1,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000c0003',
    name: '2공수',
    centiGongsu: 200,
    colorId: 2,
    sortOrder: 2,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000c0004',
    name: '반공수',
    centiGongsu: 50,
    colorId: 4,
    sortOrder: 3,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000c0005',
    name: '휴무',
    centiGongsu: 0,
    colorId: 10,
    sortOrder: 4,
  ),
];

/// 조선소형 (M6 온보딩에서 선택 시 사용 예정 — 지금은 상수만 확정)
const List<SeedPreset> shipyardSeedPresets = [
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000d0001',
    name: 'A(0.9)',
    centiGongsu: 90,
    colorId: 0,
    sortOrder: 0,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000d0002',
    name: 'B(1.0)',
    centiGongsu: 100,
    colorId: 1,
    sortOrder: 1,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000d0003',
    name: 'E잔업',
    centiGongsu: 150,
    colorId: 2,
    sortOrder: 2,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000d0004',
    name: '야간',
    centiGongsu: 200,
    colorId: 3,
    sortOrder: 3,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000d0005',
    name: '반공',
    centiGongsu: 50,
    colorId: 4,
    sortOrder: 4,
  ),
  SeedPreset(
    uid: '00000000-0000-4000-8000-0000000d0006',
    name: '휴무',
    centiGongsu: 0,
    colorId: 10,
    sortOrder: 5,
  ),
];
