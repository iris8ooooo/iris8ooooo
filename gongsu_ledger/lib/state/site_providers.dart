import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/settings_repository.dart';
import 'db_providers.dart';

/// 보관되지 않은 업체 (sortOrder 순) — 선택 UI용.
final sitesProvider = StreamProvider.autoDispose<List<Site>>((ref) {
  return ref.watch(databaseProvider).siteDao.watchActive();
});

/// 보관 포함 전체 업체 — 과거 기록의 업체명/색 표시용.
final allSitesProvider = StreamProvider.autoDispose<List<Site>>((ref) {
  return ref.watch(databaseProvider).siteDao.watchAll();
});

/// id → 업체 (보관 포함). 달력 셀·시트에서 업체 색/이름을 그릴 때 사용.
final siteByIdProvider = Provider.autoDispose<Map<int, Site>>((ref) {
  final sites = ref.watch(allSitesProvider).valueOrNull ?? const <Site>[];
  return {for (final s in sites) s.id: s};
});

/// 전체 살아있는 단가 이력 — 월 정산은 이 하나로 모든 업체를 해석한다.
final allRatesProvider = StreamProvider.autoDispose<List<SiteRateHistory>>((
  ref,
) {
  return ref.watch(databaseProvider).siteDao.watchAllRates();
});

/// 특정 업체의 단가 이력 (최신 적용일 먼저).
final siteRatesProvider = StreamProvider.autoDispose
    .family<List<SiteRateHistory>, int>((ref, siteId) {
      return ref.watch(databaseProvider).siteDao.watchRatesOfSite(siteId);
    });

/// 입력 시트에서 마지막으로 고른 업체 id (설정에 저장). null = 미지정.
final lastSiteIdProvider = StreamProvider.autoDispose<int?>((ref) {
  return ref
      .watch(settingsRepoProvider)
      .watchInt(SettingsRepository.keyLastSiteId);
});
