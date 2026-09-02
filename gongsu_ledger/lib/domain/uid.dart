/// UUIDv4 생성. 기록성 행의 전역 키 — M4 백업 병합과 v2 팀장 모드(타 기기
/// 데이터 병합)의 upsert 키다. autoincrement id는 기기 간 충돌하므로
/// 데이터가 쌓이기 전인 지금부터 모든 행에 넣는다.
library;

import 'dart:math';

final Random _secureRandom = Random.secure();

/// RFC 4122 버전 4 UUID 문자열 (36자, 소문자).
String generateUid({Random? random}) {
  final rng = random ?? _secureRandom;
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final RegExp uidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
