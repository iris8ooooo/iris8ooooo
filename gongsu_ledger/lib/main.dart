import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// runApp만 한다. DB 오픈 등 무거운 초기화는 첫 사용 시점에 백그라운드에서
/// 일어난다 — 콜드 스타트 1초 원칙.
void main() {
  runApp(const ProviderScope(child: GongsuApp()));
}
