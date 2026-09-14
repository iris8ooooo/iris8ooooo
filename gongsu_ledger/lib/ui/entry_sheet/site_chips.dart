import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../domain/marker_palette.dart';
import '../app_theme.dart';

/// 업체 선택 알약 줄. 맨 앞은 '업체 없음'. 가로 스크롤.
/// 고른 알약은 잉크 바탕 + 흰 글자, 나머지는 옅은 잉크 바탕 (확정 시안).
class SiteChips extends StatelessWidget {
  const SiteChips({
    super.key,
    required this.sites,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Site> sites;
  final int? selectedId;
  final void Function(int? siteId) onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          SitePill(
            key: const ValueKey('site-chip-none'),
            label: '업체 없음',
            selected: selectedId == null,
            mutedWhenIdle: true,
            onTap: () => onSelected(null),
          ),
          for (final site in sites)
            SitePill(
              key: ValueKey('site-chip-${site.id}'),
              label: site.name,
              dotColor: MarkerPalette.colorOf(
                site.colorId,
                brightness: brightness,
              ),
              selected: selectedId == site.id,
              onTap: () => onSelected(site.id),
            ),
        ],
      ),
    );
  }
}

class SitePill extends StatelessWidget {
  const SitePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
    this.mutedWhenIdle = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;
  final bool mutedWhenIdle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onAccent : (mutedWhenIdle ? c.muted : c.text);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? c.accent : c.tint05,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Semantics(
            selected: selected,
            button: true,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
