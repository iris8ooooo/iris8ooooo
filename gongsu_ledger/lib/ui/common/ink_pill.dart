import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 잉크 알약 — 여러 선택지 중 하나를 고르는 칩. 고른 것은 잉크 바탕 + 흰
/// 글자, 나머지는 옅은 잉크 바탕 (확정 시안). ChoiceChip 대신 앱 전체에서 쓴다.
class InkPill extends StatelessWidget {
  const InkPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.height = 40,
    this.fontSize = 13,
    this.mutedWhenIdle = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 글자 앞 작은 표시(업체 색 점 등).
  final Widget? leading;
  final double height;
  final double fontSize;

  /// 안 골렸을 때 글자를 보조색으로 (예: '업체 없음').
  final bool mutedWhenIdle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onAccent : (mutedWhenIdle ? c.muted : c.text);
    return Material(
      color: selected ? c.accent : c.tint05,
      borderRadius: BorderRadius.circular(height / 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(height / 2),
        child: Semantics(
          selected: selected,
          button: true,
          // alignment 를 주면 Wrap 안에서 가로로 늘어난다 — 크기는 내용에 맞긴다.
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: height * 0.35),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 7)],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
