import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/date_key.dart';
import '../../domain/month_grid.dart';
import '../../domain/settlement.dart';
import '../../domain/widget_payload.dart';
import '../../state/pro_providers.dart';
import '../../state/tax_providers.dart';
import '../../state/widget_providers.dart';

/// 홈 위젯 동기화 — 차별화 #2.
///
/// "이번 달" 정산(월 카드와 같은 monthSettlementProvider)을 구독해, 표시 문자열이
/// 바뀔 때마다 위젯 저장소에 쓰고 갱신 신호를 보낸다. 같은 값이면 보내지 않는다.
/// 앱이 다시 앞으로 올 때(resumed) 달이 바뀌었으면 구독 달을 옮긴다.
/// 실패(플러그인 없음·App Group 미설정)는 조용히 무시한다 — 위젯은 부가 기능이지
/// 앱 동작의 전제가 아니다.
class HomeWidgetSyncer extends ConsumerStatefulWidget {
  const HomeWidgetSyncer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeWidgetSyncer> createState() => _HomeWidgetSyncerState();
}

class _HomeWidgetSyncerState extends ConsumerState<HomeWidgetSyncer>
    with WidgetsBindingObserver {
  late int _ym = _currentYm();
  Map<String, String>? _lastSent;

  static int _currentYm() => ymOfDateKey(dateKeyOf(DateTime.now()));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final ym = _currentYm();
    if (ym != _ym) setState(() => _ym = ym);
  }

  void _maybePush(PeriodSettlement settlement, {required bool isPro}) {
    // 위젯은 프로 기능 — 프로가 아니면 숫자 대신 잠김 표식만 보낸다.
    final payload = isPro
        ? buildWidgetPayload(
            ym: _ym,
            settlement: settlement,
            now: DateTime.now(),
          )
        : buildLockedWidgetPayload(ym: _ym, now: DateTime.now());
    final last = _lastSent;
    if (last != null && _sameDisplay(payload, last)) return;
    _lastSent = payload;
    WidgetsBinding.instance.addPostFrameCallback((_) => _push(payload));
  }

  /// 갱신 시각만 다른 것은 "같은 값"으로 본다.
  static bool _sameDisplay(Map<String, String> a, Map<String, String> b) =>
      WidgetKeys.all
          .where((k) => k != WidgetKeys.updatedAt)
          .every((k) => a[k] == b[k]);

  Future<void> _push(Map<String, String> payload) async {
    if (!mounted) return;
    try {
      final service = ref.read(homeWidgetServiceProvider);
      await service.saveData(payload);
      await service.requestUpdate();
    } catch (_) {
      // 테스트/플러그인 미지원 환경, App Group 미설정 등 — 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybePush(
      ref.watch(monthSettlementProvider(_ym)),
      isPro: ref.watch(proProvider),
    );
    return widget.child;
  }
}
