/// 직군 교체 계획 산출 — 순수 함수 (M6 온보딩 규칙, CLAUDE.md 선확정).
///
/// 규칙: 사용자가 수정하지 않은 시드 프리셋(uid 가 시드 집합에 있고
/// createdAt == updatedAt)만 건드린다. 손댄 프리셋·사용자가 만든 프리셋은 불변.
/// - 대상 직군의 시드가 이미 있으면(보관됐더라도) 되살린다
/// - 다른 직군의 미수정 시드는 보관한다
/// - 대상 직군의 시드가 없으면 새로 넣는다 (타임스탬프 0 = 미수정 표식)
library;

import 'default_presets.dart';

typedef ExistingPreset = ({
  int id,
  String uid,
  bool isArchived,
  int createdAtMillis,
  int updatedAtMillis,
});

class SeedSwitchPlan {
  const SeedSwitchPlan({
    required this.archiveIds,
    required this.unarchiveIds,
    required this.inserts,
  });

  final List<int> archiveIds;
  final List<int> unarchiveIds;
  final List<SeedPreset> inserts;

  bool get isNoop =>
      archiveIds.isEmpty && unarchiveIds.isEmpty && inserts.isEmpty;
}

bool isUntouchedSeed(ExistingPreset p, Set<String> seedUids) =>
    seedUids.contains(p.uid) && p.createdAtMillis == p.updatedAtMillis;

SeedSwitchPlan planSeedSwitch({
  required List<ExistingPreset> existing,
  required List<SeedPreset> target,
  Set<String>? seedUids,
}) {
  final allSeeds = seedUids ?? allSeedPresetUids;
  final targetUids = {for (final s in target) s.uid};
  final archive = <int>[];
  final unarchive = <int>[];
  final present = <String>{};

  for (final p in existing) {
    if (targetUids.contains(p.uid)) present.add(p.uid);
    if (!isUntouchedSeed(p, allSeeds)) continue;
    if (targetUids.contains(p.uid)) {
      if (p.isArchived) unarchive.add(p.id);
    } else if (!p.isArchived) {
      archive.add(p.id);
    }
  }

  final inserts = [
    for (final s in target)
      if (!present.contains(s.uid)) s,
  ];
  return SeedSwitchPlan(
    archiveIds: archive,
    unarchiveIds: unarchive,
    inserts: inserts,
  );
}
