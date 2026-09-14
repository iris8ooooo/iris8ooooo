import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../common/app_icons.dart';

/// 하단 탭 4개(달력·정산·통계·설정). 확정 시안의 "떠 있는 알약" —
/// 화면 아래 18px 위에 떠 있고, 켜진 탭은 옅은 잉크 바탕 + 채운 아이콘.
class InkNavBar extends StatelessWidget {
  const InkNavBar({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  /// 알약 높이.
  static const double height = 62;

  /// 화면 아래 여백.
  static const double bottomGap = 18;

  /// 탭 정의 — 순서가 곧 탭 인덱스.
  static const List<InkTab> tabs = [
    InkTab('calendar', '달력', AppIcons.calendar, AppIcons.calendarFill),
    InkTab('settlement', '정산', AppIcons.settlement, AppIcons.settlementFill),
    InkTab('stats', '통계', AppIcons.stats, AppIcons.statsFill),
    InkTab('settings', '설정', AppIcons.settings, AppIcons.settingsFill),
  ];

  /// 알약이 가리는 만큼 화면 아래에 둘 여백 (안전 영역 포함).
  static double reservedBottom(BuildContext context) =>
      height + bottomGap + 12 + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: c.line.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _InkTabButton(
                tab: tabs[i],
                selected: i == index,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// 탭 화면의 `bottomNavigationBar` 자리에 두는 투명 여백 — 떠 있는 알약이
/// 내용을 가리지 않게 한다 (안전 영역 포함).
class NavSpacer extends StatelessWidget {
  const NavSpacer({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SizedBox(height: InkNavBar.height + InkNavBar.bottomGap + 12),
  );
}

class InkTab {
  const InkTab(this.id, this.label, this.icon, this.iconFill);

  final String id;
  final String label;
  final IconData icon;
  final IconData iconFill;
}

class _InkTabButton extends StatelessWidget {
  const _InkTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final InkTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.text : c.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        key: ValueKey('nav-${tab.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? c.tint05 : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? tab.iconFill : tab.icon, size: 22, color: color),
              const SizedBox(height: 2),
              // 큰글씨 단계에서도 알약 높이를 넘지 않게 라벨은 줄이지 않고
              // 스케일만 제한한다.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
