import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/day_item_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/korean_holidays.dart';
import '../../domain/marker_palette.dart';
import '../../domain/range_fill.dart';
import '../../domain/rate_resolver.dart';
import '../../state/calendar_providers.dart';
import '../../state/db_providers.dart';
import '../../state/preset_providers.dart';
import '../../state/site_providers.dart';
import '../app_theme.dart';
import '../common/dashed_border.dart';
import '../common/gongsu_keypad.dart';
import '../common/won_format.dart';
import '../presets/preset_list_page.dart';
import 'extra_item_dialog.dart';
import 'range_fill_dialog.dart';
import 'site_chips.dart';
import '../common/app_icons.dart';

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

/// 시트 내 실행 취소 대상 (기록 또는 부가항목).
typedef _Deleted = ({bool isItem, int id});

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
  _Deleted? _lastDeleted;
  Timer? _undoTimer;

  final TextEditingController _memoController = TextEditingController();
  bool _memoLoaded = false;

  /// 새 입력에 붙일 업체. 사용자가 칩을 고르기 전에는 "마지막에 고른 업체"
  /// 설정값을 따른다.
  int? _selectedSiteId;
  bool _siteChosen = false;

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

  static const List<String> _weekdayNames = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  /// 이 시트 라우트가 아직 최상단일 때만 pop — 이중 pop으로 달력 화면까지
  /// 닫히는 사고를 막는다.
  void _popSheetOnce() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      Navigator.of(context).pop();
    }
  }

  /// 새 입력에 붙일 업체 id (활성 업체 중에서만).
  int? _effectiveSiteId(List<Site> activeSites) {
    final candidate = _siteChosen
        ? _selectedSiteId
        : ref.watch(lastSiteIdProvider).valueOrNull;
    if (candidate == null) return null;
    return activeSites.any((s) => s.id == candidate) ? candidate : null;
  }

  void _chooseSite(int? siteId) {
    setState(() {
      _siteChosen = true;
      _selectedSiteId = siteId;
    });
    ref
        .read(settingsRepoProvider)
        .setInt(SettingsRepository.keyLastSiteId, siteId);
  }

  Future<void> _addFromPreset(Preset preset, int? siteId) async {
    if (_busy) return;
    _busy = true;
    final wasEmpty = ref.read(dayEntriesProvider(widget.dateKey)).isEmpty;
    try {
      await ref
          .read(workEntryRepoProvider)
          .addFromPreset(
            dateKey: widget.dateKey,
            preset: preset,
            siteId: siteId,
          );
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

  Future<void> _saveCustom(int centi, int? siteId) async {
    if (_busy) return;
    _busy = true;
    final repo = ref.read(workEntryRepoProvider);
    final wasEmpty = ref.read(dayEntriesProvider(widget.dateKey)).isEmpty;
    try {
      if (_editing == null) {
        await repo.addCustom(
          dateKey: widget.dateKey,
          centiGongsu: centi,
          siteId: siteId,
        );
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

  Future<void> _changeEntrySite(WorkEntry entry, int? siteId) async {
    try {
      await ref
          .read(workEntryRepoProvider)
          .updateSite(id: entry.id, siteId: siteId);
    } catch (e) {
      _showError('업체를 바꾸지 못했어요.');
    }
  }

  Future<void> _editOverride(WorkEntry entry) async {
    final controller = TextEditingController(
      text: entry.unitRateWonOverride == null
          ? ''
          : '${entry.unitRateWonOverride}',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이 날만 단가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: wonInputFormatters,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: '1공수 단가 (원)',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '이 기록에만 적용돼요. 업체 단가 이력은 바뀌지 않아요.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (entry.unitRateWonOverride != null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('clear'),
              child: const Text('해제'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final repo = ref.read(workEntryRepoProvider);
    try {
      if (result == 'clear') {
        await repo.updateRateOverride(id: entry.id, unitRateWonOverride: null);
      } else {
        final won = parseWon(controller.text);
        if (won == null) {
          _showError('단가 금액을 입력해 주세요.');
          return;
        }
        await repo.updateRateOverride(id: entry.id, unitRateWonOverride: won);
      }
    } catch (e) {
      _showError('단가를 저장하지 못했어요.');
    }
  }

  Future<void> _delete(WorkEntry entry) async {
    try {
      await ref.read(workEntryRepoProvider).softDelete(entry.id);
    } catch (e) {
      _showError('삭제하지 못했어요. 다시 시도해 주세요.');
      return;
    }
    _markDeleted((isItem: false, id: entry.id));
  }

  Future<void> _deleteItem(DayExtraItem item) async {
    try {
      await ref.read(dayItemRepoProvider).softDelete(item.id);
    } catch (e) {
      _showError('삭제하지 못했어요. 다시 시도해 주세요.');
      return;
    }
    _markDeleted((isItem: true, id: item.id));
  }

  void _markDeleted(_Deleted deleted) {
    if (!mounted) return;
    _undoTimer?.cancel();
    setState(() => _lastDeleted = deleted);
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _lastDeleted = null);
    });
  }

  Future<void> _undoDelete() async {
    final deleted = _lastDeleted;
    if (deleted == null) return;
    _undoTimer?.cancel();
    try {
      if (deleted.isItem) {
        await ref.read(dayItemRepoProvider).restore(deleted.id);
      } else {
        await ref.read(workEntryRepoProvider).restore(deleted.id);
      }
    } catch (e) {
      _showError('되돌리지 못했어요.');
    }
    if (mounted) setState(() => _lastDeleted = null);
  }

  Future<void> _addExtraItem(int? siteId) async {
    final input = await showExtraItemDialog(context);
    if (input == null || !mounted) return;
    try {
      await ref
          .read(dayItemRepoProvider)
          .add(
            dateKey: widget.dateKey,
            kind: input.kind,
            label: input.label,
            amountWon: input.amountWon,
            siteId: siteId,
            isTaxable: input.isTaxable,
          );
    } catch (e) {
      _showError('부가항목을 저장하지 못했어요.');
    }
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

  /// 연속 채우기: 이 날부터 고른 날까지 같은 프리셋·업체를 한 번에.
  Future<void> _fillRange(List<Preset> presets, int? siteId) async {
    if (presets.isEmpty) {
      _showError('먼저 프리셋(공수 버튼)을 만들어 주세요.');
      return;
    }
    final fromKey = widget.dateKey;
    final Set<int> occupied;
    try {
      final rows = await ref
          .read(databaseProvider)
          .workEntryDao
          .getRange(fromKey, addDaysToKey(fromKey, maxRangeFillDays));
      occupied = {for (final r in rows) r.dateKey};
    } catch (e) {
      _showError('기록을 읽지 못했어요. 다시 시도해 주세요.');
      return;
    }
    if (!mounted) return;
    final input = await showRangeFillDialog(
      context,
      fromKey: fromKey,
      presets: presets,
      occupied: occupied,
    );
    if (input == null || !mounted || _busy) return;
    final plan = planRangeFill(
      fromKey: fromKey,
      toKey: input.toKey,
      skipRestDays: input.skipRestDays,
      occupied: occupied,
    );
    _busy = true;
    int inserted;
    try {
      inserted = await ref
          .read(workEntryRepoProvider)
          .addFromPresetMany(
            dateKeys: plan.dateKeys,
            preset: input.preset,
            siteId: siteId,
          );
    } catch (e) {
      _showError('저장하지 못했어요. 다시 시도해 주세요.');
      return;
    } finally {
      _busy = false;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    _popSheetOnce();
    final skipped = plan.skippedRest + plan.skippedOccupied;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '$inserted일에 ${input.preset.name} 기록을 넣었어요.'
          '${skipped > 0 ? ' ($skipped일 건너뜀)' : ''}',
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(dayEntriesProvider(widget.dateKey));
    // 시트가 열려 있는 동안 구독을 build 레벨에서 유지 — 모드 전환 시
    // autoDispose 재구독으로 인한 깜빡임/재쿼리를 막는다.
    final presetsAsync = ref.watch(presetsProvider);
    final memoAsync = ref.watch(dayMemoProvider(widget.dateKey));
    final sites = ref.watch(sitesProvider).valueOrNull ?? const <Site>[];
    final siteById = ref.watch(siteByIdProvider);
    final rates =
        ref.watch(allRatesProvider).valueOrNull ?? const <SiteRateHistory>[];
    final items = ref.watch(dayExtraItemsProvider(widget.dateKey));
    final siteId = _effectiveSiteId(sites);
    final memo = memoAsync.valueOrNull;

    // 메모 작성 중(저장 안 된 변경 있음)에는 스크림 탭/뒤로가기로 시트가
    // 그냥 닫히지 않게 확인을 거친다 — 무경고 유실 방지.
    // 메모 화면에서 '취소'로 나왔어도 쓰다 만 글이 남아 있으면 지켜 준다.
    final memoDirty =
        _memoLoaded && _memoController.text.trim() != (memo?.body ?? '');

    return PopScope(
      canPop: !memoDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscardMemo();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: context.colors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _buildHeader(
                context,
                memo: memo,
                memoReady: memoAsync.hasValue,
              ),
              const SizedBox(height: 14),
              switch (_mode) {
                _SheetMode.list => _buildListMode(
                  context,
                  entries: entries,
                  presetsAsync: presetsAsync,
                  memo: memo,
                  sites: sites,
                  siteById: siteById,
                  rates: rates,
                  items: items,
                  siteId: siteId,
                ),
                _SheetMode.input => _buildInputMode(
                  context,
                  sites: sites,
                  siteById: siteById,
                  siteId: siteId,
                ),
                _SheetMode.memo => _buildMemoMode(context),
              },
            ],
          ),
        ),
      ),
    );
  }

  /// "25일  9월 · 금요일 · 추석" + 오른쪽 메모 버튼.
  Widget _buildHeader(
    BuildContext context, {
    required DayMemo? memo,
    required bool memoReady,
  }) {
    final c = context.colors;
    final d = dateFromKey(widget.dateKey);
    final holiday = koreanHolidayName(widget.dateKey);
    final sub = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: c.muted,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            runSpacing: 2,
            children: [
              Text(
                '${d.day}일',
                key: const ValueKey('sheet-day'),
                style: AppFonts.displayStyle(size: 40, color: c.text),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(
                  TextSpan(
                    style: sub,
                    children: [
                      TextSpan(
                        text: '${d.month}월 · ${_weekdayNames[d.weekday - 1]}',
                      ),
                      if (holiday != null) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: holiday,
                          style: TextStyle(
                            color: c.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_mode == _SheetMode.list)
          TextButton.icon(
            key: const ValueKey('memo-button'),
            icon: const Icon(AppIcons.memo, size: 18),
            label: Text(memo == null ? '메모' : '메모 수정'),
            style: TextButton.styleFrom(
              foregroundColor: c.text,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            // 메모 스트림이 아직 도착하지 않았을 때 진입하면 기존 메모를
            // 빈 값으로 덮어쓸 수 있다 — 로딩이 끝난 뒤에만 활성화.
            onPressed: !memoReady
                ? null
                : () {
                    if (!_memoLoaded) {
                      _memoController.text = memo?.body ?? '';
                      _memoLoaded = true;
                    }
                    setState(() => _mode = _SheetMode.memo);
                  },
          ),
      ],
    );
  }

  Widget _buildInputMode(
    BuildContext context, {
    required List<Site> sites,
    required Map<int, Site> siteById,
    required int? siteId,
  }) {
    final editing = _editing;
    final c = context.colors;
    // 수정 중인 기록은 스트림 갱신분(업체/오버라이드 변경)을 반영해서 보여준다.
    final live = editing == null
        ? null
        : ref
              .watch(dayEntriesProvider(widget.dateKey))
              .where((e) => e.id == editing.id)
              .firstOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sites.isNotEmpty) ...[
          SiteChips(
            sites: sites,
            selectedId: editing == null ? siteId : (live ?? editing).siteId,
            onSelected: editing == null
                ? _chooseSite
                : (id) => _changeEntrySite(live ?? editing, id),
          ),
          const SizedBox(height: 10),
        ],
        if (editing != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              key: const ValueKey('override-button'),
              icon: const Icon(AppIcons.rate),
              label: Text(
                (live ?? editing).unitRateWonOverride == null
                    ? '이 날만 단가 설정'
                    : '이 날만 단가: ${formatWon((live ?? editing).unitRateWonOverride!)}',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: (live ?? editing).unitRateWonOverride == null
                    ? c.muted
                    : c.accent,
              ),
              onPressed: () => _editOverride(live ?? editing),
            ),
          ),
        GongsuKeypad(
          initialCenti: editing?.centiGongsu,
          saveLabel: editing == null ? '저장' : '수정',
          onSave: (centi) => _saveCustom(centi, siteId),
          onCancel: () => setState(() {
            _editing = null;
            _mode = _SheetMode.list;
          }),
        ),
      ],
    );
  }

  Widget _buildListMode(
    BuildContext context, {
    required List<WorkEntry> entries,
    required AsyncValue<List<Preset>> presetsAsync,
    required DayMemo? memo,
    required List<Site> sites,
    required Map<int, Site> siteById,
    required List<SiteRateHistory> rates,
    required List<DayExtraItem> items,
    required int? siteId,
  }) {
    final c = context.colors;
    final presets = presetsAsync.valueOrNull ?? const <Preset>[];
    final histories = [
      for (final r in rates)
        (
          siteId: r.siteId,
          effectiveFromDateKey: r.effectiveFromDateKey,
          dailyRateWon: r.dailyRateWon,
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_lastDeleted != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: c.tint05,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _lastDeleted!.isItem ? '부가항목 1건을 삭제했어요' : '기록 1건을 삭제했어요',
                    style: TextStyle(fontSize: 14, color: c.text),
                  ),
                ),
                TextButton(onPressed: _undoDelete, child: const Text('실행 취소')),
              ],
            ),
          ),
        if (sites.isNotEmpty) ...[
          SiteChips(sites: sites, selectedId: siteId, onSelected: _chooseSite),
          const SizedBox(height: 14),
        ],
        if (entries.isNotEmpty) ...[
          _EntriesCard(
            entries: entries,
            siteById: siteById,
            histories: histories,
            onEdit: (entry) => setState(() {
              _editing = entry;
              _mode = _SheetMode.input;
            }),
            onDelete: _delete,
          ),
          const SizedBox(height: 14),
        ],
        if (memo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.memo, size: 16, color: c.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    memo.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: c.muted),
                  ),
                ),
              ],
            ),
          ),
        _PresetTiles(
          presets: presets,
          usedPresetIds: {for (final e in entries) ?e.presetId},
          onPreset: (preset) => _addFromPreset(preset, siteId),
          onCustom: () => setState(() {
            _editing = null;
            _mode = _SheetMode.input;
          }),
        ),
        if (presets.isEmpty && presetsAsync.hasValue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Text(
                  '공수 버튼(프리셋)이 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted),
                ),
                TextButton(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const PresetListPage(),
                      ),
                    );
                  },
                  child: const Text('프리셋 편집'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        _buildExtraItems(context, items, siteById, siteId),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('range-fill'),
                onPressed: () => _fillRange(presets, siteId),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('연속 채우기'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                key: const ValueKey('sheet-close'),
                onPressed: _popSheetOnce,
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExtraItems(
    BuildContext context,
    List<DayExtraItem> items,
    Map<int, Site> siteById,
    int? siteId,
  ) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                  children: [
                    const TextSpan(text: '부가항목 '),
                    TextSpan(
                      text: '일비·식비·공제',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('add-extra-item'),
              icon: const Icon(AppIcons.add, size: 16),
              label: const Text('추가'),
              style: TextButton.styleFrom(
                foregroundColor: c.text,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _addExtraItem(siteId),
            ),
          ],
        ),
        for (final item in items)
          Padding(
            key: ValueKey('item-${item.id}'),
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.tint05,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${ExtraItemKind.fromCode(item.kind) == ExtraItemKind.deduction ? '−' : '+'} ${item.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          ExtraItemKind.fromCode(item.kind) ==
                              ExtraItemKind.deduction
                          ? c.red
                          : c.text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.siteId != null && siteById[item.siteId] != null
                        ? siteById[item.siteId]!.name
                        : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: c.muted),
                  ),
                ),
                Text(
                  formatWon(item.amountWon),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: c.text,
                  ),
                ),
                IconButton(
                  tooltip: '삭제',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(AppIcons.delete, size: 20, color: c.muted),
                  onPressed: () => _deleteItem(item),
                ),
              ],
            ),
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

/// 이 날의 기록 카드 — 흰 면, 행마다 색 점·값·업체·금액, 아래 합계.
class _EntriesCard extends StatelessWidget {
  const _EntriesCard({
    required this.entries,
    required this.siteById,
    required this.histories,
    required this.onEdit,
    required this.onDelete,
  });

  final List<WorkEntry> entries;
  final Map<int, Site> siteById;
  final List<RateHistoryEntry> histories;
  final void Function(WorkEntry entry) onEdit;
  final void Function(WorkEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    var totalCenti = 0;
    var dayLaborWon = 0;
    var anyPriced = false;
    final rows = <Widget>[];
    for (final entry in entries) {
      totalCenti += entry.centiGongsu;
      final rate = resolveEntryRateWon(
        dateKey: entry.dateKey,
        siteId: entry.siteId,
        unitRateWonOverride: entry.unitRateWonOverride,
        histories: histories,
      );
      int? amount;
      if (rate != null) {
        anyPriced = true;
        amount = calcAmountWon(
          centiGongsu: entry.centiGongsu,
          dailyRateWon: rate,
        );
        dayLaborWon += amount;
      }
      final site = entry.siteId == null ? null : siteById[entry.siteId];
      final value = '${formatGongsu(entry.centiGongsu)}공수';
      final title = entry.labelSnapshot.isEmpty || entry.labelSnapshot == value
          ? value
          : '${entry.labelSnapshot} · $value';
      final subParts = [
        if (site != null) site.name,
        if (rate != null)
          entry.unitRateWonOverride != null
              ? '이 날만 ${formatWon(rate)}'
              : formatWon(rate),
      ];
      rows.add(
        InkWell(
          key: ValueKey('entry-${entry.id}'),
          onTap: () => onEdit(entry),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MarkerPalette.colorOf(
                      site?.colorId ?? entry.colorIdSnapshot,
                      brightness: brightness,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                      if (subParts.isNotEmpty)
                        Text(
                          subParts.join(' · '),
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                    ],
                  ),
                ),
                if (amount != null)
                  Text(
                    formatWon(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: c.text,
                    ),
                  ),
                IconButton(
                  tooltip: '삭제',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(AppIcons.delete, size: 20, color: c.muted),
                  onPressed: () => onDelete(entry),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line.withValues(alpha: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...rows,
            Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Text(
                    '합계',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        anyPriced
                            ? '${formatGongsu(totalCenti)} 공수 · ${formatWon(dayLaborWon)}'
                            : '${formatGongsu(totalCenti)} 공수',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 프리셋 타일 3열 + 마지막 점선 "직접 입력" 타일. 이 날에 이미 쓴 프리셋은
/// 잉크로 채워 표시한다.
class _PresetTiles extends StatelessWidget {
  const _PresetTiles({
    required this.presets,
    required this.usedPresetIds,
    required this.onPreset,
    required this.onCustom,
  });

  final List<Preset> presets;
  final Set<int> usedPresetIds;
  final void Function(Preset preset) onPreset;
  final VoidCallback onCustom;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    // 큰글씨 배율에서 두 줄 글자가 잘리지 않도록 타일을 세로로 키운다.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final tileHeight = 64.0 * textScale.clamp(1.0, 1.6);

    Widget tile({
      required Key key,
      required Widget child,
      required VoidCallback onTap,
      Color? color,
      bool dashed = false,
    }) {
      final body = Material(
        color: color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(height: tileHeight, child: Center(child: child)),
        ),
      );
      return dashed
          ? DashedBorder(color: c.lineStrong, radius: 14, child: body)
          : body;
    }

    return LayoutBuilder(
      builder: (context, box) {
        final tileWidth = (box.maxWidth - _gap * 2) / 3;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final preset in presets)
              SizedBox(
                width: tileWidth,
                child: Builder(
                  builder: (context) {
                    final on = usedPresetIds.contains(preset.id);
                    final fg = on ? c.onAccent : c.text;
                    final value = preset.centiGongsu == 0
                        ? '휴'
                        : formatGongsu(preset.centiGongsu);
                    return tile(
                      key: ValueKey('preset-${preset.id}'),
                      color: on ? c.accent : c.tint05,
                      onTap: () => onPreset(preset),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: MarkerPalette.colorOf(
                                      preset.colorId,
                                      brightness: brightness,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    preset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: fg.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(
              width: tileWidth,
              child: tile(
                key: const ValueKey('custom-input'),
                dashed: true,
                onTap: onCustom,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.keypad, size: 20, color: c.muted),
                    const SizedBox(height: 3),
                    Text(
                      '직접 입력',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
