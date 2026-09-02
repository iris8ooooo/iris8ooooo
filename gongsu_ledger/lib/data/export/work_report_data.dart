/// 공수 확인서 데이터 — DB 행 + 정산 결과를 PDF 빌더가 쓰기 좋은 형태로.
library;

import '../../domain/gongsu_value.dart';
import '../../domain/rate_resolver.dart';
import '../../domain/settlement.dart';
import '../../domain/tax_engine.dart';
import '../db/app_database.dart';
import '../repositories/day_item_repository.dart';

class ReportEntryLine {
  const ReportEntryLine({
    required this.label,
    required this.centi,
    required this.rateWon,
    required this.amountWon,
  });

  final String label;
  final int centi;
  final int? rateWon;
  final int? amountWon;
}

class ReportItemLine {
  const ReportItemLine({
    required this.label,
    required this.amountWon,
    required this.isDeduction,
  });

  final String label;
  final int amountWon;
  final bool isDeduction;
}

class ReportDay {
  const ReportDay({
    required this.dateKey,
    required this.entries,
    required this.items,
    required this.memo,
  });

  final int dateKey;
  final List<ReportEntryLine> entries;
  final List<ReportItemLine> items;
  final String? memo;

  int get centi => entries.fold(0, (s, e) => s + e.centi);

  int? get amountWon {
    var sum = 0;
    var any = false;
    for (final e in entries) {
      if (e.amountWon != null) {
        sum += e.amountWon!;
        any = true;
      }
    }
    return any ? sum : null;
  }
}

class WorkReportData {
  const WorkReportData({
    required this.fromKey,
    required this.toKey,
    required this.siteName,
    required this.workerName,
    required this.taxMode,
    required this.days,
    required this.totalCenti,
    required this.workedDays,
    required this.laborWon,
    required this.allowanceWon,
    required this.deductionWon,
    required this.tax,
    required this.unpricedCenti,
    required this.hasMoney,
  });

  final int fromKey;
  final int toKey;

  /// null = 전체 업체.
  final String? siteName;
  final String workerName;
  final TaxMode taxMode;
  final List<ReportDay> days;
  final int totalCenti;
  final int workedDays;
  final int laborWon;
  final int allowanceWon;
  final int deductionWon;
  final TaxBreakdown tax;
  final int unpricedCenti;
  final bool hasMoney;

  int get grossWon => laborWon + allowanceWon - deductionWon;
  int get netWon => grossWon - tax.totalWon;
}

/// 확인서 데이터 조립. [siteId]가 null이면 전체, 아니면 그 업체만.
WorkReportData buildWorkReportData({
  required int fromKey,
  required int toKey,
  required int? siteId,
  required String? siteName,
  required String workerName,
  required Iterable<WorkEntry> entries,
  required Iterable<DayExtraItem> items,
  required Iterable<DayMemo> memos,
  required Iterable<RateHistoryEntry> histories,
  required Map<int, Site> siteById,
  required PeriodSettlement settlement,
}) {
  final histList = histories.toList();
  final byDay = <int, List<ReportEntryLine>>{};
  final itemsByDay = <int, List<ReportItemLine>>{};
  final memoByDay = {for (final m in memos) m.dateKey: m.body};

  for (final e in entries) {
    if (e.dateKey < fromKey || e.dateKey > toKey) continue;
    if (siteId != null && e.siteId != siteId) continue;
    final rate = resolveEntryRateWon(
      dateKey: e.dateKey,
      siteId: e.siteId,
      unitRateWonOverride: e.unitRateWonOverride,
      histories: histList,
    );
    final site = e.siteId == null ? null : siteById[e.siteId];
    final base = e.labelSnapshot.isEmpty
        ? '${formatGongsu(e.centiGongsu)}공수'
        : e.labelSnapshot;
    final label = siteId == null && site != null
        ? '$base (${site.name})'
        : base;
    (byDay[e.dateKey] ??= []).add(
      ReportEntryLine(
        label: label,
        centi: e.centiGongsu,
        rateWon: rate,
        amountWon: rate == null
            ? null
            : calcAmountWon(centiGongsu: e.centiGongsu, dailyRateWon: rate),
      ),
    );
  }

  for (final it in items) {
    if (it.dateKey < fromKey || it.dateKey > toKey) continue;
    if (siteId != null && it.siteId != siteId) continue;
    (itemsByDay[it.dateKey] ??= []).add(
      ReportItemLine(
        label: it.label,
        amountWon: it.amountWon,
        isDeduction: ExtraItemKind.fromCode(it.kind) == ExtraItemKind.deduction,
      ),
    );
  }

  final dayKeys = {...byDay.keys, ...itemsByDay.keys}.toList()..sort();
  final days = [
    for (final d in dayKeys)
      ReportDay(
        dateKey: d,
        entries: byDay[d] ?? const [],
        items: itemsByDay[d] ?? const [],
        memo: memoByDay[d],
      ),
  ];

  // 합계·공제는 정산 결과에서 (화면과 숫자가 같도록).
  if (siteId == null) {
    return WorkReportData(
      fromKey: fromKey,
      toKey: toKey,
      siteName: null,
      workerName: workerName,
      taxMode: settlement.hasTaxConfigured ? TaxMode.insurance4 : TaxMode.none,
      days: days,
      totalCenti: settlement.totalCenti,
      workedDays: settlement.workedDays,
      laborWon: settlement.sites.fold(0, (s, x) => s + x.laborWon),
      allowanceWon: settlement.sites.fold(0, (s, x) => s + x.allowanceWon),
      deductionWon: settlement.sites.fold(0, (s, x) => s + x.deductionWon),
      tax: settlement.tax,
      unpricedCenti: settlement.unpricedCenti,
      hasMoney: settlement.hasMoney,
    );
  }
  final site = settlement.sites.where((s) => s.siteId == siteId).firstOrNull;
  return WorkReportData(
    fromKey: fromKey,
    toKey: toKey,
    siteName: siteName,
    workerName: workerName,
    taxMode: site?.taxMode ?? TaxMode.none,
    days: days,
    totalCenti: site?.centi ?? 0,
    workedDays: site?.workedDays ?? 0,
    laborWon: site?.laborWon ?? 0,
    allowanceWon: site?.allowanceWon ?? 0,
    deductionWon: site?.deductionWon ?? 0,
    tax: site?.tax ?? TaxBreakdown.zero,
    unpricedCenti: site?.unpricedCenti ?? 0,
    hasMoney: site?.hasMoney ?? false,
  );
}
