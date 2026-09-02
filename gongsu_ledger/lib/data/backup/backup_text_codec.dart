/// 텍스트 백업 봉투 — "복사 → 카톡 나에게 보내기 → 새 기기에서 붙여넣기" 용.
///
/// 형식: `GSJB1:` + base64(gzip(utf8(JSON 봉투))). gzip으로 길이를 크게
/// 줄여(기록 수천 건도 수십 KB) 메신저·메모 앱에 붙여넣기 쉽게 한다.
/// 복원은 이 텍스트와 M1의 원시 JSON 둘 다 받는다.
library;

import 'dart:convert';
import 'dart:io';

import 'backup_codec.dart';

const String backupTextPrefix = 'GSJB1:';

String encodeBackupText(String json) =>
    backupTextPrefix + base64Encode(gzip.encode(utf8.encode(json)));

/// 붙여넣은 텍스트를 JSON 문자열로 정규화한다.
/// - `{`로 시작하면 원시 JSON으로 간주 (M1 간이 백업 호환)
/// - `GSJB1:` 뒤의 본문에서 공백·줄바꿈(메신저가 끼워 넣는)을 제거하고 해독
/// - 그 외는 [BackupFormatError]
String decodeBackupText(String text) {
  final trimmed = text.trim();
  if (trimmed.startsWith('{')) return trimmed;
  final start = trimmed.indexOf(backupTextPrefix);
  if (start < 0) {
    throw BackupFormatError('공수장부 백업 텍스트(GSJB1:)가 아님');
  }
  // 메신저·키보드가 끼워 넣는 공백/줄바꿈/보이지 않는 문자(U+200B 등)를 전부
  // 걷어내고, 잘린 '=' 패딩은 normalize 로 되살린다.
  final body = trimmed
      .substring(start + backupTextPrefix.length)
      .replaceAll(RegExp(r'[^A-Za-z0-9+/=_-]'), '');
  try {
    final compressed = base64Decode(base64.normalize(body));
    return utf8.decode(gzip.decode(compressed));
  } on FormatException {
    // base64 오류와 gzip 오류(dart:io는 FormatException) 모두 여기로.
    throw BackupFormatError('백업 텍스트가 손상됨');
  } catch (e) {
    throw BackupFormatError('백업 텍스트를 해독할 수 없음: $e');
  }
}
