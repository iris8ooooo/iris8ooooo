import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/db/app_database.dart';
import '../../data/export/work_report_data.dart';
import '../../data/export/work_report_pdf.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/date_key.dart';
import '../../state/backup_providers.dart';
import '../../state/db_providers.dart';
import '../../state/site_providers.dart';
import '../../state/tax_providers.dart';

/// 공수 확인서 내보내기 — 업체/근로자 이름을 고르고 PDF 미리보기·공유,
/// 또는 이미지(PNG)로 공유.
class ReportExportPage extends ConsumerStatefulWidget {
  const ReportExportPage({
    super.key,
    required this.fromKey,
    required this.toKey,
  });

  final int fromKey;
  final int toKey;

  @override
  ConsumerState<ReportExportPage> createState() => _ReportExportPageState();
}

class _ReportExportPageState extends ConsumerState<ReportExportPage> {
  int? _siteId; // null = 전체
  final TextEditingController _nameController = TextEditingController();
  bool _nameLoaded = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _key => periodKey(widget.fromKey, widget.toKey);

  static String _fmt(int key) {
    final d = dateFromKey(key);
    return '${d.year}.${d.month}.${d.day}';
  }

  Future<WorkReportData?> _buildData() async {
    final settlement = ref.read(periodSettlementProvider(_key));
    final entries = ref.read(rangeEntriesProvider(_key)).valueOrNull;
    final items = ref.read(rangeItemsProvider(_key)).valueOrNull;
    final memos = ref.read(rangeMemosProvider(_key)).valueOrNull;
    if (settlement == null ||
        entries == null ||
        items == null ||
        memos == null) {
      return null;
    }
    final rates =
        ref.read(allRatesProvider).valueOrNull ?? const <SiteRateHistory>[];
    final siteById = ref.read(siteByIdProvider);
    final name = _nameController.text.trim();
    await ref
        .read(settingsRepoProvider)
        .set(SettingsRepository.keyReportWorkerName, name);
    return buildWorkReportData(
      fromKey: widget.fromKey,
      toKey: widget.toKey,
      siteId: _siteId,
      siteName: _siteId == null ? null : siteById[_siteId]?.name,
      workerName: name,
      entries: entries,
      items: items,
      memos: memos,
      histories: [
        for (final r in rates)
          (
            siteId: r.siteId,
            effectiveFromDateKey: r.effectiveFromDateKey,
            dailyRateWon: r.dailyRateWon,
          ),
      ],
      siteById: siteById,
      settlement: settlement,
    );
  }

  Future<Uint8List> _buildPdf(WorkReportData data) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'),
    );
    return buildWorkReportPdf(
      data,
      regular: regular,
      bold: bold,
      generatedAt: DateTime.now(),
    );
  }

  String get _fileStem =>
      'gongsu-${widget.fromKey}-${widget.toKey}${_siteId == null ? '' : '-site$_siteId'}';

  Future<void> _preview() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _buildData();
      if (data == null) {
        _showMessage('아직 불러오는 중이에요. 잠시 후 다시 눌러 주세요.');
        return;
      }
      final bytes = await _buildPdf(data);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              _PdfPreviewPage(bytes: bytes, fileName: '$_fileStem.pdf'),
        ),
      );
    } catch (e) {
      _showMessage('PDF를 만들지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _buildData();
      if (data == null) {
        _showMessage('아직 불러오는 중이에요. 잠시 후 다시 눌러 주세요.');
        return;
      }
      final pdf = await _buildPdf(data);
      // 첫 페이지를 이미지로 (한 달 확인서는 대부분 1~2쪽).
      final raster = await Printing.raster(pdf, pages: [0], dpi: 160).first;
      final png = await raster.toPng();
      await ref
          .read(shareServiceProvider)
          .shareBytes(png, fileName: '$_fileStem.png', mimeType: 'image/png');
    } catch (e) {
      _showMessage('이미지를 만들지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
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
    final scheme = Theme.of(context).colorScheme;
    final sites = ref.watch(allSitesProvider).valueOrNull ?? const <Site>[];
    // 저장된 근로자 이름을 한 번만 채운다.
    if (!_nameLoaded) {
      _nameLoaded = true;
      ref
          .read(settingsRepoProvider)
          .get(SettingsRepository.keyReportWorkerName)
          .then((v) {
            if (mounted && v != null && _nameController.text.isEmpty) {
              _nameController.text = v;
            }
          });
    }
    // 데이터 로딩을 미리 시작해 둔다.
    ref.watch(periodSettlementProvider(_key));
    ref.watch(rangeEntriesProvider(_key));
    ref.watch(rangeItemsProvider(_key));
    ref.watch(rangeMemosProvider(_key));

    return Scaffold(
      appBar: AppBar(title: const Text('공수 확인서')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '기간 ${_fmt(widget.fromKey)} ~ ${_fmt(widget.toKey)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '임금체불 분쟁 때 근무 사실을 증명하는 용도로 쓸 수 있어요. 날짜별 공수·단가·금액·부가항목·합계와 서명란이 들어갑니다.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            key: const ValueKey('report-site'),
            initialValue: _siteId,
            decoration: const InputDecoration(
              labelText: '업체(현장)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('전체 업체')),
              for (final s in sites)
                DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
            ],
            onChanged: (v) => setState(() => _siteId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('report-name'),
            controller: _nameController,
            maxLength: 20,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: '근로자 이름 (확인서에 인쇄)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('report-preview'),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF 미리보기 · 공유'),
            onPressed: _busy ? null : _preview,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('report-image'),
            icon: const Icon(Icons.image_outlined),
            label: const Text('이미지로 공유 (카톡 전송용)'),
            onPressed: _busy ? null : _shareImage,
          ),
        ],
      ),
    );
  }
}

class _PdfPreviewPage extends StatelessWidget {
  const _PdfPreviewPage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('미리보기')),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
