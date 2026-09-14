import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/db/app_database.dart';
import 'package:gongsu_ledger/ui/app_theme.dart';
import 'package:gongsu_ledger/ui/calendar/day_cell.dart';

/// 확정 시안 "잉크 농도" 칸 — 색·이름·오늘 표시가 규칙대로인지, 큰글씨에서
/// 넘치지 않는지. 날짜에 의존하지 않도록 칸 하나만 띄운다.
void main() {
  WorkEntry entry(int centi, {int? siteId, int colorId = 0}) => WorkEntry(
    id: centi,
    uid: 'u$centi',
    dateKey: 20260925,
    centiGongsu: centi,
    presetId: null,
    labelSnapshot: '',
    colorIdSnapshot: colorId,
    siteId: siteId,
    unitRateWonOverride: null,
    createdAtMillis: 0,
    updatedAtMillis: 0,
    deletedAtMillis: null,
  );

  Future<AppColors> pumpCell(
    WidgetTester tester, {
    required int dateKey,
    List<WorkEntry> entries = const [],
    bool isToday = false,
    bool inMonth = true,
    bool hasMemo = false,
    String? holidayName,
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
    Size size = const Size(46, 62),
  }) async {
    final theme = buildAppTheme(brightness);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox.fromSize(
                size: size,
                child: DayCell(
                  dateKey: dateKey,
                  inMonth: inMonth,
                  isToday: isToday,
                  entries: entries,
                  hasMemo: hasMemo,
                  holidayName: holidayName,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return theme.extension<AppColors>()!;
  }

  /// 칸 바탕(둥근 모서리 DecoratedBox) — 오늘 동그라미(shape: circle)와 구분.
  BoxDecoration cellDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  testWidgets('공수 농도: 1.5 이하는 옅은 잉크 + 잉크 글자, 2.8 은 진한 잉크 + 흰 글자', (
    tester,
  ) async {
    var c = await pumpCell(tester, dateKey: 20260915, entries: [entry(150)]);
    expect(cellDecoration(tester).color, c.tint15);
    expect(styleOf(tester, '1.5').color, c.text);
    expect(styleOf(tester, '15').color, c.text);

    c = await pumpCell(tester, dateKey: 20260916, entries: [entry(280)]);
    expect(cellDecoration(tester).color, c.tint20);
    expect(styleOf(tester, '2.8').color, c.onTintDark);
    expect(styleOf(tester, '16').color, c.onTintDark); // 평일 숫자도 흰색
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 날은 바탕 없음, 휴무(0공수)는 옅은 잉크에 "휴"', (tester) async {
    var c = await pumpCell(tester, dateKey: 20260915);
    expect(cellDecoration(tester).color, isNull);
    expect(find.text('휴'), findsNothing);

    c = await pumpCell(tester, dateKey: 20260915, entries: [entry(0)]);
    expect(cellDecoration(tester).color, c.tint05);
    expect(styleOf(tester, '휴').color, c.muted);
  });

  testWidgets('공휴일: 짧은 이름 + 빨간 테두리 + 빨간 숫자 (진한 칸에서도)', (tester) async {
    final c = await pumpCell(
      tester,
      dateKey: 20260928, // 월요일, 대체공휴일
      holidayName: '대체공휴일',
      entries: [entry(200)],
    );
    expect(find.text('대체휴일'), findsOneWidget);
    expect(find.text('대체공휴일'), findsNothing);
    final border = cellDecoration(tester).border! as Border;
    expect(border.top.color, c.red);
    expect(border.top.width, 1.5);
    expect(styleOf(tester, '28').color, c.red);
    expect(styleOf(tester, '대체휴일').color, c.red);
  });

  testWidgets('일요일 빨강, 토요일 파랑, 평일 잉크', (tester) async {
    var c = await pumpCell(tester, dateKey: 20260913); // 일
    expect(styleOf(tester, '13').color, c.red);
    c = await pumpCell(tester, dateKey: 20260912); // 토
    expect(styleOf(tester, '12').color, c.blue);
    c = await pumpCell(tester, dateKey: 20260914); // 월
    expect(styleOf(tester, '14').color, c.text);
    expect(cellDecoration(tester).border, isNull);
  });

  testWidgets('오늘: 금색 동그라미 + 흰 굵은 숫자', (tester) async {
    final c = await pumpCell(tester, dateKey: 20260913, isToday: true);
    final circle = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.shape == BoxShape.circle);
    expect(circle.color, c.gold);
    expect(styleOf(tester, '13').color, Colors.white);
    expect(styleOf(tester, '13').fontWeight, FontWeight.w800);
  });

  testWidgets('이웃 달 칸은 흐리게(0.3)', (tester) async {
    await pumpCell(tester, dateKey: 20261001, inMonth: false);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.3);
    await pumpCell(tester, dateKey: 20260930);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);
  });

  testWidgets('아주 크게 글씨(1.3×)·좁은 칸에서도 공휴일+2.8공수+점 5개가 넘치지 않는다', (
    tester,
  ) async {
    await pumpCell(
      tester,
      dateKey: 20260928,
      holidayName: '대체공휴일',
      hasMemo: true,
      isToday: true,
      entries: [entry(100, siteId: 1), entry(180), entry(0), entry(0)],
      textScale: 1.3,
      size: const Size(40, 44), // 작은 화면(iPhone SE)급 칸 높이
    );
    expect(tester.takeException(), isNull);
    expect(find.text('2.8'), findsOneWidget);
    expect(find.text('대체휴일'), findsOneWidget);
  });

  testWidgets('다크모드: 진한 칸 글자는 종이색, 테두리는 다크 빨강', (tester) async {
    final c = await pumpCell(
      tester,
      dateKey: 20260925,
      holidayName: '추석',
      entries: [entry(300)],
      brightness: Brightness.dark,
    );
    expect(styleOf(tester, '3').color, c.onTintDark);
    expect((cellDecoration(tester).border! as Border).top.color, c.red);
  });
}
