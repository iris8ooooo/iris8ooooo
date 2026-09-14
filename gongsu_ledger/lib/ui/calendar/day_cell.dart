import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/korean_holidays.dart';
import '../../domain/marker_palette.dart';
import '../app_theme.dart';

/// 달력 날짜 칸 — 확정 시안 "잉크 농도" 칸.
///
/// 공수가 많을수록 칸이 진해진다(`AppColors.tintForCenti`). 오늘은 금색
/// 동그라미, 일요일·공휴일 숫자는 빨강, 토요일은 파랑, 공휴일 칸에는 빨간
/// 테두리와 짧은 이름. 셀의 정체성은 dateKey(yyyyMMdd int) — 탭 이벤트는
/// 이 int를 그대로 전달하며 DateTime 변환이 다시 등장하지 않는다.
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.dateKey,
    required this.inMonth,
    required this.isToday,
    required this.entries,
    required this.hasMemo,
    required this.onTap,
    this.siteById = const {},
    this.holidayName,
  });

  /// 공휴일 정식 이름 (내장 데이터). 칸에는 짧은 이름으로 보인다.
  final String? holidayName;

  final int dateKey;
  final bool inMonth;
  final bool isToday;
  final List<WorkEntry> entries;
  final bool hasMemo;
  final VoidCallback onTap;

  /// id → 업체 (보관 포함). 업체가 붙은 기록은 프리셋 색 대신 업체 색으로
  /// 표시한다 ("달력에 업체 색상 표시" 명세).
  final Map<int, Site> siteById;

  static const double radius = 10;

  /// 이보다 낮은 칸은 내용을 통째로 축소한다 (숫자 20 + 점 5 + 여백 8 + 값).
  static const double minHeight = 46;

  int _markerColorId(WorkEntry e) {
    final site = e.siteId == null ? null : siteById[e.siteId];
    return site?.colorId ?? e.colorIdSnapshot;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final day = dateKey % 100;
    final weekday = dateFromKey(dateKey).weekday;
    final isHoliday = holidayName != null;

    var totalCenti = 0;
    for (final e in entries) {
      totalCenti += e.centiGongsu;
    }
    final hasEntries = entries.isNotEmpty;
    final dark = hasEntries && c.isDarkTint(totalCenti);
    final onCell = dark ? c.onTintDark : c.text;

    final numberColor = isHoliday || weekday == DateTime.sunday
        ? c.red
        : weekday == DateTime.saturday
        ? c.blue
        : onCell;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
      child: Column(
        children: [
          // 날짜 숫자 — 오늘은 금색 동그라미.
          SizedBox(
            width: 20,
            height: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? c.gold : Colors.transparent,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday ? Colors.white : numberColor,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          // 공휴일 이름 + 공수 값 — 남는 높이에 맞춰 함께 줄어든다
          // (큰글씨·작은 화면에서 넘치지 않도록).
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHoliday)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          holidayShortName(holidayName!),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: c.red,
                            height: 1.1,
                          ),
                        ),
                      ),
                    if (hasEntries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          totalCenti > 0 ? formatGongsu(totalCenti) : '휴',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: totalCenti > 0 ? onCell : c.muted,
                            height: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 업체 점(원) + 메모(네모). 좁은 칸에서는 줄여서 한 줄에.
          SizedBox(
            height: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in entries.take(4))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MarkerPalette.colorOf(
                            _markerColorId(e),
                            brightness: brightness,
                          ),
                        ),
                      ),
                    ),
                  if (hasMemo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: onCell,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: inMonth ? 1 : 0.3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hasEntries ? c.tintForCenti(totalCenti) : null,
            borderRadius: BorderRadius.circular(radius),
            border: isHoliday ? Border.all(color: c.red, width: 1.5) : null,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final h = box.maxHeight;
              if (!h.isFinite || h >= minHeight) return content;
              // 아주 작은 화면·큰글씨로 칸이 낮아지면 넘치는 대신 칸 전체를
              // 같은 비율로 줄인다.
              final k = minHeight / h;
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: box.maxWidth * k,
                  height: minHeight,
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
