import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gongsu_ledger/app_info.dart';

void main() {
  test('kAppVersion 은 pubspec.yaml 의 version 과 같다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(match!.group(1), kAppVersion);
  });
}
