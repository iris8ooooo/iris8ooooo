/// 월 공수 확인서 PDF — 4강 전원이 못 하는 차별화 기능.
///
/// 품질 기준: 임금체불 분쟁 때 노동청에 들이밀 수 있는 수준. 날짜별 표,
/// 단가·금액, 부가항목, 합계·공제·실수령, 서명란, 생성 일시, 페이지 번호.
/// 한글은 앱에 내장한 나눔고딕(OFL)으로 그린다 — 네트워크 없이 동작.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/date_key.dart';
import '../../domain/gongsu_value.dart';
import '../../domain/korean_holidays.dart';
import 'work_report_data.dart';

const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

String _won(int won) {
  final s = won.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${won < 0 ? '-' : ''}$buf원';
}

String _date(int key) {
  final d = dateFromKey(key);
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

String _dayLabel(int key) {
  final d = dateFromKey(key);
  final holiday = koreanHolidayName(key);
  final wd = _weekdays[d.weekday - 1];
  return holiday == null
      ? '${d.month}/${d.day} ($wd)'
      : '${d.month}/${d.day} ($wd·공휴일)';
}

Future<Uint8List> buildWorkReportPdf(
  WorkReportData data, {
  required pw.Font regular,
  required pw.Font bold,
  required DateTime generatedAt,
}) async {
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);
  final doc = pw.Document(
    title: '공수 확인서 ${_date(data.fromKey)}~${_date(data.toKey)}',
    author: '공수장부',
    theme: theme,
  );
  final money = data.hasMoney;
  final grey = PdfColor.fromInt(0xFF555555);
  final light = PdfColor.fromInt(0xFFF2F2F2);

  final headers = money
      ? ['날짜', '내용', '공수', '단가', '금액', '부가항목 / 메모']
      : ['날짜', '내용', '공수', '메모'];

  List<String> rowOf(ReportDay d) {
    final content = d.entries.map((e) => e.label).join('\n');
    final centi = d.entries.map((e) => formatGongsu(e.centi)).join('\n');
    final rate = d.entries
        .map((e) => e.rateWon == null ? '-' : _won(e.rateWon!))
        .join('\n');
    final amount = d.entries
        .map((e) => e.amountWon == null ? '-' : _won(e.amountWon!))
        .join('\n');
    final extras = [
      for (final it in d.items)
        '${it.label} ${it.isDeduction ? '-' : '+'}${_won(it.amountWon)}',
      if (d.memo != null && d.memo!.isNotEmpty) '메모: ${d.memo}',
    ].join('\n');
    return money
        ? [_dayLabel(d.dateKey), content, centi, rate, amount, extras]
        : [_dayLabel(d.dateKey), content, centi, extras];
  }

  pw.Widget totalLine(String label, String value, {bool strong = false}) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: strong ? 12 : 10)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: strong ? 13 : 10,
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      );

  final t = data.tax;
  final taxLines = <pw.Widget>[
    if (t.incomeTaxWon > 0) totalLine('소득세', '-${_won(t.incomeTaxWon)}'),
    if (t.localIncomeTaxWon > 0)
      totalLine('지방소득세', '-${_won(t.localIncomeTaxWon)}'),
    if (t.pensionWon > 0) totalLine('국민연금', '-${_won(t.pensionWon)}'),
    if (t.healthWon > 0) totalLine('건강보험', '-${_won(t.healthWon)}'),
    if (t.longTermCareWon > 0)
      totalLine('장기요양보험', '-${_won(t.longTermCareWon)}'),
    if (t.employmentWon > 0) totalLine('고용보험', '-${_won(t.employmentWon)}'),
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 36),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '공수장부 앱에서 생성 · ${generatedAt.year}.${generatedAt.month.toString().padLeft(2, '0')}.${generatedAt.day.toString().padLeft(2, '0')} ${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}',
            style: pw.TextStyle(fontSize: 8, color: grey),
          ),
          pw.Text(
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: grey),
          ),
        ],
      ),
      build: (ctx) => [
        pw.Center(
          child: pw.Text(
            '공 수 확 인 서',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: grey, width: 0.5),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '기간: ${_date(data.fromKey)} ~ ${_date(data.toKey)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '업체(현장): ${data.siteName ?? '전체'}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '근로자: ${data.workerName.isEmpty ? '________________' : data.workerName}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '총 공수: ${formatGongsu(data.totalCenti)}공수 / 근무일 ${data.workedDays}일',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: [for (final d in data.days) rowOf(d)],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: pw.BoxDecoration(color: light),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: money
              ? {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerLeft,
                }
              : {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerLeft,
                },
          columnWidths: money
              ? {
                  0: const pw.FixedColumnWidth(62),
                  1: const pw.FlexColumnWidth(2.2),
                  2: const pw.FixedColumnWidth(36),
                  3: const pw.FixedColumnWidth(62),
                  4: const pw.FixedColumnWidth(66),
                  5: const pw.FlexColumnWidth(2.4),
                }
              : {
                  0: const pw.FixedColumnWidth(70),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FlexColumnWidth(2),
                },
          border: pw.TableBorder.all(color: grey, width: 0.4),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 3,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: grey, width: 0.5),
            color: light,
          ),
          child: pw.Column(
            children: [
              totalLine(
                '총 공수',
                '${formatGongsu(data.totalCenti)}공수',
                strong: true,
              ),
              totalLine('근무일', '${data.workedDays}일'),
              if (money) ...[
                pw.Divider(color: grey, height: 10, thickness: 0.4),
                totalLine('노무비 (공수 × 단가)', _won(data.laborWon)),
                if (data.allowanceWon > 0)
                  totalLine('가산 항목', '+${_won(data.allowanceWon)}'),
                if (data.deductionWon > 0)
                  totalLine('공제 항목', '-${_won(data.deductionWon)}'),
                totalLine('세전 합계', _won(data.grossWon), strong: true),
                if (taxLines.isNotEmpty) ...[
                  pw.Divider(color: grey, height: 10, thickness: 0.4),
                  ...taxLines,
                ],
                totalLine('실수령', _won(data.netWon), strong: true),
                if (data.unpricedCenti > 0)
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      '※ 단가 없는 ${formatGongsu(data.unpricedCenti)}공수는 금액에서 제외',
                      style: pw.TextStyle(fontSize: 8, color: grey),
                    ),
                  ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 22),
        pw.Text(
          '위 기간의 공수 및 금액이 사실과 같음을 확인합니다.',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          children: [
            pw.Expanded(child: _signatureBox('근로자', data.workerName)),
            pw.SizedBox(width: 24),
            pw.Expanded(child: _signatureBox('업체(확인자)', data.siteName ?? '')),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _signatureBox(String role, String name) => pw.Container(
  height: 64,
  padding: const pw.EdgeInsets.all(8),
  decoration: pw.BoxDecoration(
    border: pw.Border.all(color: PdfColor.fromInt(0xFF555555), width: 0.5),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(role, style: const pw.TextStyle(fontSize: 9)),
      pw.Spacer(),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(name, style: const pw.TextStyle(fontSize: 10)),
          pw.Text('(서명)', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    ],
  ),
);
