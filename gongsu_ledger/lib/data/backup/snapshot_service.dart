/// 자동 로컬 스냅샷 — 절대 원칙 4의 (a).
///
/// 하루 한 번(앱 첫 실행 시) + 앱이 백그라운드로 갈 때 그날 파일을 갱신하고,
/// 최근 [keepDays]일치만 남긴다. 파일은 텍스트 백업 봉투(GSJB1)와 같은
/// 형식이라 복원 경로도 같다(병합 전용 — 지우는 경로 없음).
library;

import 'dart:io';

import '../db/app_database.dart';
import 'backup_codec.dart';
import 'backup_text_codec.dart';

class SnapshotInfo {
  const SnapshotInfo({
    required this.file,
    required this.dateKey,
    required this.sizeBytes,
  });

  final File file;
  final int dateKey;
  final int sizeBytes;
}

final RegExp _snapshotName = RegExp(r'^snapshot_(\d{8})\.gsjb$');

class SnapshotService {
  SnapshotService({required this.rootDirectory, this.keepDays = 7});

  /// 스냅샷 폴더의 부모를 준다 (앱 문서 디렉토리 등). 테스트는 임시 폴더.
  final Future<Directory> Function() rootDirectory;
  final int keepDays;

  Future<Directory> _dir() async {
    final root = await rootDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}snapshots');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  File _fileFor(Directory dir, int dateKey) =>
      File('${dir.path}${Platform.pathSeparator}snapshot_$dateKey.gsjb');

  /// 그날 스냅샷을 쓴다(있으면 덮어씀). 임시 파일에 쓴 뒤 이름을 바꿔
  /// 쓰다 죽어도 반쪽 파일이 남지 않게 한다.
  Future<File> writeSnapshot(AppDatabase db, int dateKey) async {
    final dir = await _dir();
    final json = await exportBackupJson(db);
    final target = _fileFor(dir, dateKey);
    final tmp = File('${target.path}.tmp');
    tmp.writeAsStringSync(encodeBackupText(json), flush: true);
    tmp.renameSync(target.path);
    await _rotate(dir);
    return target;
  }

  /// 그날 스냅샷이 없을 때만 만든다 (앱 시작 시 호출).
  Future<bool> ensureDailySnapshot(AppDatabase db, int dateKey) async {
    final dir = await _dir();
    if (_fileFor(dir, dateKey).existsSync()) return false;
    await writeSnapshot(db, dateKey);
    return true;
  }

  /// 최신 날짜 먼저.
  Future<List<SnapshotInfo>> list() async {
    final dir = await _dir();
    final infos = <SnapshotInfo>[];
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      final m = _snapshotName.firstMatch(name);
      if (m == null) continue;
      infos.add(
        SnapshotInfo(
          file: f,
          dateKey: int.parse(m.group(1)!),
          sizeBytes: f.lengthSync(),
        ),
      );
    }
    infos.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return infos;
  }

  /// 스냅샷 파일 → JSON 봉투 문자열.
  Future<String> readJson(SnapshotInfo info) async =>
      decodeBackupText(info.file.readAsStringSync());

  /// 스냅샷을 현재 DB에 병합 복원한다 (지우는 경로 없음).
  Future<ImportResult> restore(AppDatabase db, SnapshotInfo info) async =>
      importBackupJson(db, await readJson(info));

  Future<void> _rotate(Directory dir) async {
    final infos = await list();
    for (final old in infos.skip(keepDays)) {
      old.file.deleteSync();
    }
  }
}
