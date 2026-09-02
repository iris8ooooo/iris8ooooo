import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pro_limits.dart';
import '../../state/pro_providers.dart';
import 'paywall_page.dart';

/// 프로가 아니면 페이월을 띄우고, 돌아왔을 때 프로 여부를 돌려준다.
Future<bool> ensurePro(
  BuildContext context,
  WidgetRef ref, {
  required ProFeature feature,
}) async {
  if (ref.read(proProvider)) return true;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PaywallPage(feature: feature)),
  );
  return ref.read(proProvider);
}
