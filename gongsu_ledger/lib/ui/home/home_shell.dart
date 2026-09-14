import 'package:flutter/material.dart';

import '../calendar/calendar_page.dart';
import '../settings/settings_page.dart';
import '../settlement/settlement_page.dart';
import '../stats/stats_page.dart';
import 'ink_nav_bar.dart';

/// 홈 껍데기: 탭 4개(달력·정산·통계·설정)를 떠 있는 알약 탭으로 오간다.
///
/// 한 번 연 탭은 상태를 유지하고(Offstage), 아직 안 연 탭은 만들지 않는다 —
/// 콜드 스타트에 정산·통계 쿼리가 같이 돌지 않게 (콜드 스타트 1초 원칙).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final Set<int> _built = {0};

  static Widget _page(int i) => switch (i) {
    0 => const CalendarPage(),
    1 => const SettlementPage(),
    2 => const StatsPage(),
    _ => const SettingsPage(),
  };

  void _select(int i) {
    if (i == _index) return;
    setState(() {
      _built.add(i);
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          for (var i = 0; i < InkNavBar.tabs.length; i++)
            if (_built.contains(i))
              Offstage(
                offstage: i != _index,
                child: TickerMode(enabled: i == _index, child: _page(i)),
              ),
          Positioned(
            left: InkNavBar.bottomGap,
            right: InkNavBar.bottomGap,
            bottom:
                InkNavBar.bottomGap + MediaQuery.viewPaddingOf(context).bottom,
            child: InkNavBar(index: _index, onChanged: _select),
          ),
        ],
      ),
    );
  }
}
