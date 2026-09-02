import 'package:flutter/material.dart';

import '../../domain/gongsu_value.dart';

/// 한 번에 입력 가능한 최대 공수 (UI 검증 전용 — 저장 계층은 제한하지 않는다).
/// "18" 오타(1.8 의도)가 그대로 저장되어 월 합계가 조용히 오염되는 것을 막는다.
const int maxCentiPerEntry = 1000;

/// 공수 직접 입력용 자체 키패드.
///
/// 시스템 키보드를 쓰지 않는 이유: 일부 안드로이드 OEM 키보드(특히 삼성
/// 한국어 설정)는 소수점 키보드에서 '.'를 숨기거나 ','를 내보낸다 —
/// 경쟁앱의 "소수점 입력 불가" 리뷰가 이 계열이다. 자체 키패드면 이 버그가
/// 구조적으로 불가능하고, 40~60대 대상 큰 버튼·레이아웃 점프 없음 덤이다.
class GongsuKeypad extends StatefulWidget {
  const GongsuKeypad({
    super.key,
    this.initialCenti,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
  });

  final int? initialCenti;
  final String saveLabel;
  final void Function(int centiGongsu) onSave;
  final VoidCallback onCancel;

  @override
  State<GongsuKeypad> createState() => _GongsuKeypadState();
}

class _GongsuKeypadState extends State<GongsuKeypad> {
  late String _buffer;

  @override
  void initState() {
    super.initState();
    _buffer = widget.initialCenti == null
        ? ''
        : formatGongsu(widget.initialCenti!);
  }

  int? get _parsed => tryParseGongsu(_buffer);

  String? get _errorText {
    if (_buffer.isEmpty) return null;
    final centi = _parsed;
    if (centi == null) return '숫자를 확인해 주세요';
    if (!isValidGongsuStep(centi)) return '0.05 단위로 입력해 주세요';
    if (centi > maxCentiPerEntry) return '한 번에 10공수까지 입력할 수 있어요';
    return null;
  }

  bool get _canSave {
    final centi = _parsed;
    return centi != null &&
        isValidGongsuStep(centi) &&
        centi <= maxCentiPerEntry;
  }

  void _append(String ch) {
    setState(() {
      if (ch == '.' && _buffer.contains('.')) return;
      if (_buffer.length >= 6) return;
      _buffer += ch;
    });
  }

  void _backspace() {
    if (_buffer.isEmpty) return;
    setState(() => _buffer = _buffer.substring(0, _buffer.length - 1));
  }

  void _step(int deltaCenti) {
    final current = _buffer.isEmpty ? 0 : _parsed;
    if (current == null) return;
    final next = current + deltaCenti;
    if (next < 0 || next > maxCentiPerEntry) return;
    setState(() => _buffer = formatGongsu(next));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = _errorText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _buffer.isEmpty ? '공수 입력' : _buffer,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _buffer.isEmpty
                      ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : scheme.onSurface,
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    error,
                    style: TextStyle(fontSize: 14, color: scheme.error),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _step(-gongsuInputStepCenti),
                child: const Text('−0.05'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _step(gongsuInputStepCenti),
                child: const Text('+0.05'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['.', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          key: ValueKey('keypad-$key'),
                          onPressed: key == '⌫'
                              ? _backspace
                              : () => _append(key),
                          child: Text(
                            key,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: widget.onCancel,
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _canSave ? () => widget.onSave(_parsed!) : null,
                child: Text(widget.saveLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
