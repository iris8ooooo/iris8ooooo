import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/marker_palette.dart';
import '../../state/calendar_providers.dart';
import '../../state/db_providers.dart';
import '../../state/preset_providers.dart';
import '../common/gongsu_keypad.dart';
import '../presets/preset_list_page.dart';

/// 날짜 탭 → 이 시트. 프리셋 버튼 탭이 두 번째(마지막) 탭이 되도록 설계
/// (요구: 3탭 이내, 실제 2탭).
Future<void> showEntrySheet(BuildContext context, int dateKey) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // 드래그로 닫기 비활성: 키패드/버튼을 누르다 실수로 시트가 내려가
    // 작성 중인 메모가 유실되는 경로를 없앤다. 닫기는 스크림 탭·뒤로가기
    // (메모 작성 중엔 PopScope가 확인을 거침)로 충분하다.
    enableDrag: false,
    builder: (_) => EntrySheet(dateKey: dateKey),
  );
}

enum _SheetMode { list, input, memo }

class EntrySheet extends ConsumerStatefulWidget {
  const EntrySheet({super.key, required this.dateKey});

  final int dateKey;

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  _SheetMode _mode = _SheetMode.list;

  /// 수정 중인 기록. null이면 새 직접 입력.
  WorkEntry? _editing;

  /// 저장/삭제 이중 실행 방지 (두 손가락 동시 탭 → 이중 insert + 이중 pop으로
  /// 달력 화면까지 닫히는 사고 차단).
  bool _busy = false;

  /// 시트 내 '실행 취소' (모달 위에서는 스낵바가 가려지므로 시트 안에 표시).
  int? _lastDeletedId;
  Timer? _undoTimer;

  final TextEditingController _memoController = TextEditingController();
  bool _memoLoaded = false;

  @override
  void initState() {
    super.initState();
    // 메모 내용이 바뀔 때마다 rebuild — PopScope의 canPop(작성 중 여부)이
    // 항상 최신 텍스트 기준으로 계산되게 한다.
    _memoController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _memoController.dispose();
    super.dispose();
  }

  static const List<String> _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

  String get _title {
    final d = dateFromKey(widget.dateKey);
    return '${d.month}월 ${d.day}일 (${_weekdayNames[d.weekday - 1]})';
  }

  /// 이 시트 라우트가 아직 최상단일 때만 pop — 이중 pop으로 달력 화면까지
  /// 닫히는 사고를 막는다.
  void _popSheetOnce() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addFromPreset(Preset preset) async {
    if (_busy) return;
    _busy = true;
    final wasEmpty = ref.read(dayEntriesProvider(widget.dateKey)).isEmpty;
    try {
      await ref
          .read(workEntryRepoProvider)
          .addFromPreset(dateKey: widget.dateKey, preset: preset);
    } catch (e) {
      _showError('저장하지 못했어요. 다시 시도해 주세요.');
      return;
    } finally {
      _busy = false;
    }
    if (!mounted) return;
    if (wasEmpty) {
      // 빈 날 첫 입력은 저장 후 자동 닫힘. 기록이 있던 날은 시트를 유지해
      // 오전/오후·잔업 연속 입력(하루 무제한 여러 건)이 바로 이어진다.
      _popSheetOnce();
    }
  }

  Future<void> _saveCustom(int centi) async {
    if (_busy) return;
    _busy = true;
    final repo = ref.read(workEntryRepoProvider);
    final wasEmpty = ref.read(dayEntriesProvider(widget.dateKey)).isEmpty;
    try {
      if (_editing == null) {
        await repo.addCustom(dateKey: widget.dateKey, centiGongsu: centi);
      } else {
        await repo.updateValue(id: _editing!.id, centiGongsu: centi);
      }
    } catch (e) {
      _showError('저장하지 못했어요. 다시 시도해 주세요.');
      return;
    } finally {
      _busy = false;
    }
    if (!mounted) return;
    if (_editing == null && wasEmpty) {
      _popSheetOnce();
      return;
    }
    setState(() {
      _editing = null;
      _mode = _SheetMode.list;
    });
  }

  Future<void> _delete(WorkEntry entry) async {
    try {
      await ref.read(workEntryRepoProvider).softDelete(entry.id);
    } catch (e) {
      _showError('삭제하지 못했어요. 다시 시도해 주세요.');
      return;
    }
    if (!mounted) return;
    _undoTimer?.cancel();
    setState(() => _lastDeletedId = entry.id);
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _lastDeletedId = null);
    });
  }

  Future<void> _undoDelete() async {
    final id = _lastDeletedId;
    if (id == null) return;
    _undoTimer?.cancel();
    try {
      await ref.read(workEntryRepoProvider).restore(id);
    } catch (e) {
      _showError('되돌리지 못했어요.');
    }
    if (mounted) setState(() => _lastDeletedId = null);
  }

  Future<void> _saveMemo() async {
    try {
      await ref
          .read(memoRepoProvider)
          .setMemo(dateKey: widget.dateKey, body: _memoController.text);
    } catch (e) {
      _showError('메모를 저장하지 못했어요.');
      return;
    }
    if (mounted) setState(() => _mode = _SheetMode.list);
  }

  void _showError(String message) {
    // 저장 실패의 무음 처리 금지 — 실패는 반드시 사용자에게 보인다.
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(dayEntriesProvider(widget.dateKey));
    // 시트가 열려 있는 동안 구독을 build 레벨에서 유지 — 모드 전환 시
    // autoDispose 재구독으로 인한 깜빡임/재쿼리를 막는다.
    final presetsAsync = ref.watch(presetsProvider);
    final memoAsync = ref.watch(dayMemoProvider(widget.dateKey));

    // 메모 작성 중(저장 안 된 변경 있음)에는 스크림 탭/뒤로가기로 시트가
    // 그냥 닫히지 않게 확인을 거친다 — 무경고 유실 방지.
    final memoDirty =
        _mode == _SheetMode.memo &&
        _memoController.text.trim() != (memoAsync.valueOrNull?.body ?? '');

    return PopScope(
      canPop: !memoDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscardMemo();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              switch (_mode) {
                _SheetMode.list => _buildListMode(
                  context,
                  entries,
                  presetsAsync,
                  memoAsync,
                ),
                _SheetMode.input => GongsuKeypad(
                  initialCenti: _editing?.centiGongsu,
                  saveLabel: _editing == null ? '저장' : '수정',
                  onSave: _saveCustom,
                  onCancel: () => setState(() {
                    _editing = null;
                    _mode = _SheetMode.list;
                  }),
                ),
                _SheetMode.memo => _buildMemoMode(context),
              },
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDiscardMemo() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('작성 중인 메모가 있어요'),
        content: const Text('저장하지 않고 닫으면 지금 쓴 내용이 사라져요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('keep'),
            child: const Text('계속 작성'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: const Text('버리기'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('저장 후 닫기'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'save':
        await _saveMemo();
        if (mounted) Navigator.of(context).pop();
      case 'discard':
        Navigator.of(context).pop();
      default:
        break; // 계속 작성
    }
  }

  Widget _buildListMode(
    BuildContext context,
    List<WorkEntry> entries,
    AsyncValue<List<Preset>> presetsAsync,
    AsyncValue<DayMemo?> memoAsync,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final presets = presetsAsync.valueOrNull ?? const <Preset>[];
    final memo = memoAsync.valueOrNull;
    // 큰글씨 배율에서 버튼 안 두 줄 텍스트가 잘리지 않도록 셀 비율을
    // 글자 배율에 맞춰 세로로 키운다.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final presetAspectRatio = 1.9 / textScale.clamp(1.0, 2.2);
    var totalCenti = 0;
    for (final e in entries) {
      totalCenti += e.centiGongsu;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_lastDeletedId != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(child: Text('기록 1건을 삭제했어요')),
                TextButton(onPressed: _undoDelete, child: const Text('실행 취소')),
              ],
            ),
          ),
        if (entries.isNotEmpty) ...[
          for (final entry in entries)
            InkWell(
              key: ValueKey('entry-${entry.id}'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() {
                _editing = entry;
                _mode = _SheetMode.input;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MarkerPalette.colorOf(
                          entry.colorIdSnapshot,
                          brightness: Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.labelSnapshot.isEmpty
                            ? '직접 입력'
                            : entry.labelSnapshot,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                    Text(
                      '${formatGongsu(entry.centiGongsu)} 공수',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      tooltip: '삭제',
                      icon: Icon(
                        Icons.delete_outline,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () => _delete(entry),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('합계', style: TextStyle(fontSize: 16)),
                Text(
                  '${formatGongsu(totalCenti)} 공수',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (memo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 18,
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    memo.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (presets.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: presetAspectRatio,
            children: [
              for (final preset in presets)
                FilledButton.tonal(
                  key: ValueKey('preset-${preset.id}'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: () => _addFromPreset(preset),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: MarkerPalette.colorOf(
                                preset.colorId,
                                brightness: Theme.of(context).brightness,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              preset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatGongsu(preset.centiGongsu),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )
        else if (presetsAsync.hasValue)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '프리셋이 없어요. 아래 [프리셋 편집]에서 추가하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.dialpad),
                label: const Text('직접 입력'),
                onPressed: () => setState(() {
                  _editing = null;
                  _mode = _SheetMode.input;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.sticky_note_2_outlined),
                label: Text(memo == null ? '메모' : '메모 수정'),
                // 메모 스트림이 아직 도착하지 않았을 때 진입하면 기존 메모를
                // 빈 값으로 덮어쓸 수 있다 — 로딩이 끝난 뒤에만 활성화.
                onPressed: !memoAsync.hasValue
                    ? null
                    : () {
                        if (!_memoLoaded) {
                          _memoController.text = memo?.body ?? '';
                          _memoLoaded = true;
                        }
                        setState(() => _mode = _SheetMode.memo);
                      },
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            navigator.push(
              MaterialPageRoute(builder: (_) => const PresetListPage()),
            );
          },
          child: const Text('프리셋 편집'),
        ),
      ],
    );
  }

  Widget _buildMemoMode(BuildContext context) {
    return Padding(
      // 메모는 일반 키보드를 쓰므로 키보드 높이만큼 올린다.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _memoController,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
              hintText: '이 날의 메모 (현장, 작업 내용 등)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _mode = _SheetMode.list),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saveMemo,
                  child: const Text('메모 저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
