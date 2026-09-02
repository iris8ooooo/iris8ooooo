import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/date_key.dart';
import '../../state/backup_providers.dart';
import '../../state/db_providers.dart';

/// 자동 로컬 스냅샷 트리거 — 절대 원칙 4(a).
///
/// - 첫 프레임 뒤: 오늘 스냅샷이 없으면 만든다
/// - 앱이 백그라운드로 갈 때: 오늘 스냅샷을 갱신한다 (그날 입력 반영)
/// 실패(플러그인 없음·디스크 오류)는 조용히 무시한다 — 스냅샷은 안전망이지
/// 앱 동작의 전제가 아니다.
class SnapshotScheduler extends ConsumerStatefulWidget {
  const SnapshotScheduler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SnapshotScheduler> createState() => _SnapshotSchedulerState();
}

class _SnapshotSchedulerState extends ConsumerState<SnapshotScheduler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureToday());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _refreshToday();
  }

  Future<void> _ensureToday() async {
    try {
      await ref
          .read(snapshotServiceProvider)
          .ensureDailySnapshot(
            ref.read(databaseProvider),
            dateKeyOf(DateTime.now()),
          );
    } catch (_) {
      // 테스트/플러그인 미지원 환경 등 — 무시
    }
  }

  Future<void> _refreshToday() async {
    try {
      await ref
          .read(snapshotServiceProvider)
          .writeSnapshot(ref.read(databaseProvider), dateKeyOf(DateTime.now()));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
