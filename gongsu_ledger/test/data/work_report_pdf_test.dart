import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/export/work_report_data.dart';
import 'package:gongsu_ledger/data/export/work_report_pdf.dart';
import 'package:gongsu_ledger/domain/tax_engine.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  late pw.Font regular;
  late pw.Font bold;

  setUpAll(() {
    regular = pw.Font.ttf(
      File('assets/fonts/NanumGothic-Regular.ttf')
          .readAsBytesSync()
          .buffer
          .asByteData(),
    );
    bold = pw.Font.ttf(
      File('assets/fonts/NanumGothic-Bold.ttf')
          .readAsBytesSync()
          .buffer
          .asByteData(),
    );
  });

  WorkReportData sample({bool money = true}) => WorkReportData(
    fromKey: 20260901,
    toKey: 20260930,
    siteName: 'A현장',
    workerName: '홍길동',
    taxMode: TaxMode.withholding33,
    days: [
      for (var d = 1; d <= 22; d++)
        ReportDay(
          dateKey: 20260900 + d,
          entries: [
            ReportEntryLine(
              label: '1공수',
              centi: 100,
              rateWon: money ? 150000 : null,
              amountWon: money ? 150000 : null,
            ),
            if (d % 5 == 0)
              ReportEntryLine(
                label: '잔업',
                centi: 50,
                rateWon: money ? 150000 : null,
                amountWon: money ? 75000 : null,
              ),
          ],
          items: d == 3
              ? const [
                  ReportItemLine(
                    label: '식비',
                    amountWon: 10000,
                    isDeduction: false,
                  ),
                ]
              : const [],
          memo: d == 7 ? '거푸집 해체 · 야간 대기' : null,
        ),
    ],
    totalCenti: 2400,
    workedDays: 22,
    laborWon: money ? 3600000 : 0,
    allowanceWon: money ? 10000 : 0,
    deductionWon: 0,
    tax: money
        ? const TaxBreakdown(incomeTaxWon: 108000, localIncomeTaxWon: 10800)
        : TaxBreakdown.zero,
    unpricedCenti: money ? 0 : 2400,
    hasMoney: money,
  );

  test('한 달치 확인서 PDF가 생성된다 (한글 폰트 내장, 여러 페이지)', () async {
    final bytes = await buildWorkReportPdf(
      sample(),
      regular: regular,
      bold: bold,
      generatedAt: DateTime(2026, 9, 2, 14, 30),
    );
    expect(bytes.length, greaterThan(20000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // 폰트가 임베드되어 있다 (한글 깨짐 방지)
    final head = String.fromCharCodes(bytes.take(200000));
    expect(head.contains('/FontFile2'), true);
  });

  test('금액 정보가 없으면 단가/금액 없이도 생성된다', () async {
    final bytes = await buildWorkReportPdf(
      sample(money: false),
      regular: regular,
      bold: bold,
      generatedAt: DateTime(2026, 9, 2),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('기록이 하나도 없는 기간도 빈 표로 생성된다', () async {
    final bytes = await buildWorkReportPdf(
      const WorkReportData(
        fromKey: 20261001,
        toKey: 20261031,
        siteName: null,
        workerName: '',
        taxMode: TaxMode.none,
        days: [],
        totalCenti: 0,
        workedDays: 0,
        laborWon: 0,
        allowanceWon: 0,
        deductionWon: 0,
        tax: TaxBreakdown.zero,
        unpricedCenti: 0,
        hasMoney: false,
      ),
      regular: regular,
      bold: bold,
      generatedAt: DateTime(2026, 9, 2),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
