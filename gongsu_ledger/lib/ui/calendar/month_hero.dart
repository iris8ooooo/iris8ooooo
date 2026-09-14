import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gongsu_value.dart';
import '../../domain/korean_holidays.dart';
import '../../domain/month_grid.dart';
import '../../state/calendar_providers.dart';
import '../../state/tax_providers.dart';
import '../app_theme.dart';
import '../common/won_format.dart';

/// 달력 위 월 요약 — 확정 시안의 "큰 숫자 하나".
///
/// 금액 정보가 있으면 실수령(세금 방식이 설정된 업체가 있을 때) 또는 세전
/// 예상 수입이 큰 숫자, 공수·근무일·공휴일·세전·공제는 아래 작은 줄.
/// 금액 정보가 없으면 총 공수가 큰 숫자. 숫자는 전부 정산 엔진 결과.
class MonthHero extends ConsumerWidget {
  const MonthHero({super.key, required this.ym});

  final int ym;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider(ym));
    final money = ref.watch(monthMoneyProvider(ym));
    final settlement = ref.watch(monthSettlementProvider(ym));
    final c = context.colors;
    final month = monthOfYm(ym);
    final year = yearOfYm(ym);

    final hasMoney = summary.grossWon != null;
    final taxed = hasMoney && settlement.hasTaxConfigured;

    final String label;
    final Widget headline;
    if (!hasMoney) {
      label = '$month월 총 공수';
      headline = _Headline(
        textKey: const ValueKey('hero-gongsu'),
        value: formatGongsu(summary.totalCenti),
        unit: ' 공수',
        color: c.text,
      );
    } else if (taxed) {
      label = '$month월 실수령';
      headline = _Headline(
        textKey: const ValueKey('net-won'),
        value: _digits(summary.netWon!),
        unit: '원',
        color: c.text,
      );
    } else {
      label = '$month월 예상 수입 (세전)';
      headline = _Headline(
        textKey: const ValueKey('gross-won'),
        value: _digits(summary.grossWon!),
        unit: '원',
        color: c.text,
      );
    }

    final holidayCount = holidaysInMonth(ym).length;
    final hasHolidayData = koreanHolidayYears.contains(year);
    final small = TextStyle(fontSize: 13, color: c.muted, height: 1.3);
    final strong = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: c.text,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 4),
          headline,
          const SizedBox(height: 6),
          // 줄 1: 공수 · 근무일 · 공휴일
          Text.rich(
            TextSpan(
              style: small,
              children: [
                if (hasMoney) ...[
                  TextSpan(text: formatGongsu(summary.totalCenti), style: strong),
                  const TextSpan(text: ' 공수 · '),
                ],
                TextSpan(text: '근무 ${summary.workedDays}일'),
                if (!hasHolidayData)
                  const TextSpan(text: ' · 공휴일 정보 없음')
                else if (holidayCount > 0) ...[
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: '공휴일 $holidayCount일',
                    style: TextStyle(color: c.red, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          // 줄 2: 세전 · 공제 (금액이 있을 때만)
          if (taxed)
            Text.rich(
              TextSpan(
                style: small,
                children: [
                  const TextSpan(text: '세전 '),
                  TextSpan(
                    text: formatWon(summary.grossWon!),
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                  ),
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: settlement.tax.isZero
                        ? '공제 없음'
                        : '세금·보험 공제 ${formatWon(settlement.tax.totalWon)}',
                  ),
                ],
              ),
            )
          else if (hasMoney)
            Text('업체 수정 → 세금 방식을 고르면 공제가 계산돼요', style: small),
          if (hasMoney && money.unpricedCenti > 0)
            Text(
              '단가 없는 ${formatGongsu(money.unpricedCenti)}공수는 제외',
              style: small.copyWith(color: c.red),
            ),
        ],
      ),
    );
  }

  /// "5,318,090" — 단위 없이 자릿수만 (단위는 작은 글자로 따로).
  static String _digits(int won) {
    final s = formatWon(won);
    return s.endsWith('원') ? s.substring(0, s.length - 1) : s;
  }
}

/// 큰 숫자 + 작은 단위. `Text.rich` 하나라 `find.text('5,318,090원')` 으로
/// 통째로 찾힌다.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.textKey,
    required this.value,
    required this.unit,
    required this.color,
  });

  /// 테스트가 `find.byKey` 로 Text 자체를 집을 수 있게 Text.rich 에 붙는 키.
  final Key textKey;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => Text.rich(
    key: textKey,
    TextSpan(
      children: [
        TextSpan(
          text: value,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1,
            color: color,
          ),
        ),
        TextSpan(
          text: unit,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1,
            color: color,
          ),
        ),
      ],
    ),
  );
}
