import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'pre_open_guard.dart';

/// 앱 DB 커넥션. lazy — 첫 쿼리 시점에 백그라운드 isolate에서 연다.
/// (main()은 runApp만 하므로 콜드 스타트에 DB 오픈 비용이 들어가지 않는다)
/// DB 파일이 사는 폴더 — 구조(격리) 경로가 같은 위치를 쓴다.
Future<Directory> appDatabaseDirectory() => getApplicationDocumentsDirectory();

QueryExecutor openAppConnection() => LazyDatabase(() async {
  final dir = await appDatabaseDirectory();
  final file = File(p.join(dir.path, 'gongsu.db'));
  await runPreOpenGuard(file, AppDatabase.codeSchemaVersion);
  return NativeDatabase.createInBackground(file);
});
