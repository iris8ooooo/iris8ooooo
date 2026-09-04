import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pro_limits.dart';
import '../../state/pro_providers.dart';
import '../pro/pro_gate.dart';

import '../../data/db/app_database.dart';
import '../../domain/date_key.dart';
import '../../domain/marker_palette.dart';
import '../../domain/rate_resolver.dart';
import '../../state/db_providers.dart';
import '../../state/site_providers.dart';
import '../common/won_format.dart';
import 'site_edit_page.dart';

/// 업체(현장) 관리: 추가 / 수정 / 단가 이력 / 순서 / 보관.
class SiteListPage extends ConsumerWidget {
  const SiteListPage({super.key});

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    Site site,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('\'${site.name}\' 삭제'),
        content: const Text('이 업체로 입력한 과거 기록과 단가는 그대로 유지되고, 새 입력 목록에서만 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(siteRepoProvider).archive(site.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesProvider);
    final sites = sitesAsync.valueOrNull ?? const <Site>[];
    final rates =
        ref.watch(allRatesProvider).valueOrNull ?? const <SiteRateHistory>[];
    final histories = [
      for (final r in rates)
        (
          siteId: r.siteId,
          effectiveFromDateKey: r.effectiveFromDateKey,
          dailyRateWon: r.dailyRateWon,
        ),
    ];
    final todayKey = dateKeyOf(DateTime.now());
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('업체(현장) 관리')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('업체 추가'),
        onPressed: () async {
          if (!sitesAsync.hasValue) return; // 목록이 오기 전엔 판정하지 않는다
          // 무료 티어 업체 상한 — 프로가 아니면 페이월.
          if (!canAddSite(
            activeSites: sites.length,
            isPro: ref.read(proProvider),
          )) {
            final ok = await ensurePro(context, ref, feature: ProFeature.sites);
            if (!ok) return;
          }
          if (!context.mounted) return;
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SiteEditPage()));
        },
      ),
      body: sites.isEmpty && sitesAsync.hasValue
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '업체를 추가하면 기록에 업체를 붙이고\n단가로 예상 수입을 계산할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: sites.length,
              onReorderItem: (oldIndex, newIndex) {
                final ids = sites.map((s) => s.id).toList();
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                ref.read(siteRepoProvider).reorder(ids);
              },
              itemBuilder: (context, index) {
                final site = sites[index];
                final rate = resolveSiteRateWon(
                  histories: histories,
                  siteId: site.id,
                  dateKey: todayKey,
                );
                return ListTile(
                  key: ValueKey('site-tile-${site.id}'),
                  leading: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MarkerPalette.colorOf(
                        site.colorId,
                        brightness: Theme.of(context).brightness,
                      ),
                    ),
                  ),
                  title: Text(site.name),
                  subtitle: Text(
                    rate == null ? '단가 미설정' : '현재 단가 ${formatWon(rate)}',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SiteEditPage(site: site)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '삭제',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmArchive(context, ref, site),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
