import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../domain/marker_palette.dart';

/// 업체 선택 칩 행. 맨 앞은 '업체 없음'. 가로 스크롤.
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
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: const ValueKey('site-chip-none'),
              label: const Text('업체 없음'),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final site in sites)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: ValueKey('site-chip-${site.id}'),
                avatar: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MarkerPalette.colorOf(
                      site.colorId,
                      brightness: brightness,
                    ),
                  ),
                ),
                label: Text(site.name),
                selected: selectedId == site.id,
                onSelected: (_) => onSelected(site.id),
              ),
            ),
        ],
      ),
    );
  }
}
