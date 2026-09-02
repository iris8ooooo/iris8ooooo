import 'package:flutter/material.dart';

/// 여러 값 중 하나를 고르는 칩 줄. SegmentedButton 은 좁은 폰(360dp)·큰글씨에서
/// 글자가 잘리므로 앱 전체에서 이 Wrap 을 쓴다 (줄바꿈으로 항상 다 보인다).
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.keyOf,
    this.avatarOf,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final String Function(T)? keyOf;
  final Widget Function(T)? avatarOf;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final option in options)
        ChoiceChip(
          key: keyOf == null ? null : ValueKey(keyOf!(option)),
          avatar: avatarOf?.call(option),
          label: Text(labelOf(option)),
          selected: option == selected,
          onSelected: (_) => onSelected(option),
        ),
    ],
  );
}
