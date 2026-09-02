import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/data/backup/backup_codec.dart';
import 'package:gongsu_ledger/data/backup/backup_text_codec.dart';

void main() {
  const json =
      '{"format":"gongsu_ledger_backup","schemaVersion":3,"workEntries":[{"uid":"x","dateKey":20260901,"centiGongsu":180}]}';

  test('GSJB1 텍스트 왕복', () {
    final text = encodeBackupText(json);
    expect(text.startsWith('GSJB1:'), true);
    expect(decodeBackupText(text), json);
  });

  test('메신저가 끼워 넣는 줄바꿈·공백·앞뒤 잡문자를 견딘다', () {
    final text = encodeBackupText(json);
    final body = text.substring(6);
    final mangled =
        '백업입니다\n GSJB1:${body.substring(0, 10)}\n${body.substring(10, 20)} ${body.substring(20)}\n';
    expect(decodeBackupText(mangled), json);
  });

  test('원시 JSON(M1 간이 백업)도 그대로 받는다', () {
    expect(decodeBackupText('  $json \n'), json);
  });

  test('압축으로 길이가 줄어든다 (기록 500건)', () {
    final rows = List.generate(
      500,
      (i) =>
          '{"uid":"00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}","dateKey":${20260101 + i % 28},"centiGongsu":100,"labelSnapshot":"1공수","createdAtMillis":1,"updatedAtMillis":1}',
    ).join(',');
    final big =
        '{"format":"gongsu_ledger_backup","schemaVersion":3,"workEntries":[$rows]}';
    final text = encodeBackupText(big);
    expect(text.length, lessThan(big.length ~/ 3));
    expect(decodeBackupText(text), big);
  });

  test('손상/무관 텍스트는 거부 (데이터 불변)', () {
    expect(() => decodeBackupText('안녕하세요'), throwsA(isA<BackupFormatError>()));
    expect(
      () => decodeBackupText('GSJB1:!!!notbase64!!!'),
      throwsA(isA<BackupFormatError>()),
    );
    expect(
      () => decodeBackupText('GSJB1:aGVsbG8='),
      throwsA(isA<BackupFormatError>()),
    ); // base64지만 gzip 아님
  });
}
