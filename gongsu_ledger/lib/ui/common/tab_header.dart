import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 탭 화면(정산·통계·설정) 머리 — 명조 큰 제목 + 오른쪽 아이콘 버튼.
/// 앱바 대신 쓴다 (달력 홈의 "9월" 과 같은 결).
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFonts.displayStyle(size: 34, color: c.text),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// 화면 안 작은 구획 제목 ("월별 공수 · 실수령", "기록").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.muted = false});

  final String text;

  /// 설정 화면처럼 옅고 작게 (자간 넓힘).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(top: muted ? 18 : 14, bottom: muted ? 2 : 6),
      child: Text(
        text,
        style: muted
            ? TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: c.muted,
              )
            : TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: c.text,
              ),
      ),
    );
  }
}
