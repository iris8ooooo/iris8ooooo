/// 공유/파일 플러그인 추상화 — 위젯 테스트에서 가짜로 바꿔 끼운다.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup/backup_codec.dart';

abstract class ShareService {
  Future<void> shareText(String text, {String? subject});

  /// 바이트를 임시 파일로 만들어 공유 시트에 올린다 (JSON/PNG/PDF).
  Future<void> shareBytes(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  });
}

class SharePlusService implements ShareService {
  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<void> shareBytes(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType, name: fileName)],
      ),
    );
  }
}

/// 가져오기 파일 크기 상한. 백업 JSON은 수년치라도 수 MB 수준이다.
const int maxBackupFileBytes = 20 * 1024 * 1024;

abstract class BackupFileService {
  /// 사용자가 고른 백업 파일의 내용. 취소하면 null.
  Future<String?> pickBackupText();
}

class FilePickerBackupFileService implements BackupFileService {
  @override
  Future<String?> pickBackupText() async {
    // file_picker 12: 취소 시 빈 목록. 내용은 readAsBytes로 읽는다.
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return null;
    // 실수로 고른 동영상 같은 큰 파일을 통째로 읽다 죽지 않게.
    final length = await files.first.length();
    if (length > maxBackupFileBytes) {
      throw BackupFormatError('백업 파일이 너무 큽니다 (20MB 초과)');
    }
    final bytes = await files.first.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);
    // 일부 편집기가 붙이는 BOM 제거
    return text.startsWith('\uFEFF') ? text.substring(1) : text;
  }
}
