import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/backup/snapshot_service.dart';
import '../services/share_service.dart';

/// 자동 스냅샷 서비스. 위젯 테스트에서는 임시 폴더로 override한다.
final snapshotServiceProvider = Provider<SnapshotService>(
  (ref) => SnapshotService(rootDirectory: getApplicationDocumentsDirectory),
);

/// 스냅샷 목록 (백업 화면). 새로고침은 ref.invalidate.
final snapshotsProvider = FutureProvider.autoDispose<List<SnapshotInfo>>(
  (ref) => ref.watch(snapshotServiceProvider).list(),
);

final shareServiceProvider = Provider<ShareService>(
  (ref) => SharePlusService(),
);

final backupFileServiceProvider = Provider<BackupFileService>(
  (ref) => FilePickerBackupFileService(),
);
