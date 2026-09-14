import 'package:flutter/widgets.dart';

/// 앱 안 아이콘 한 벌 — Phosphor(MIT, `assets/fonts/Phosphor-*.ttf` 내장).
/// 켜진 탭은 채움(Fill), 나머지는 선(Regular).
///
/// Material 아이콘을 직접 쓰지 않는다: 두 세트가 섞이면 굵기·둥글기가 달라
/// 티가 난다. 새 아이콘은 phosphoricons.com 에서 이름을 찾아 코드포인트를
/// 여기에 붙인다 (`test/guards/app_icons_guard_test.dart` 가 글꼴에 있는지 검사).
/// phosphor_flutter 패키지는 Flutter 3.47(IconData final) 과 호환되지 않아
/// 글꼴만 직접 내장한다.
abstract final class AppIcons {
  // 하단 탭
  static const IconData calendar = IconData(0xe7b4, fontFamily: 'PhosphorRegular');
  static const IconData calendarFill = IconData(0xe7b4, fontFamily: 'PhosphorFill');
  static const IconData settlement = IconData(0xe3ec, fontFamily: 'PhosphorRegular');
  static const IconData settlementFill = IconData(0xe3ec, fontFamily: 'PhosphorFill');
  static const IconData stats = IconData(0xe150, fontFamily: 'PhosphorRegular');
  static const IconData statsFill = IconData(0xe150, fontFamily: 'PhosphorFill');
  static const IconData settings = IconData(0xe272, fontFamily: 'PhosphorRegular');
  static const IconData settingsFill = IconData(0xe272, fontFamily: 'PhosphorFill');

  // 달력 상단
  static const IconData share = IconData(0xeaf0, fontFamily: 'PhosphorRegular');
  static const IconData today = IconData(0xe712, fontFamily: 'PhosphorRegular');
  static const IconData more = IconData(0xe208, fontFamily: 'PhosphorRegular');

  // 이동·목록
  static const IconData chevronRight = IconData(0xe13a, fontFamily: 'PhosphorRegular');
  static const IconData chevronLeft = IconData(0xe138, fontFamily: 'PhosphorRegular');
  static const IconData dragHandle = IconData(0xeae2, fontFamily: 'PhosphorRegular');

  // 편집
  static const IconData add = IconData(0xe3d4, fontFamily: 'PhosphorRegular');
  static const IconData addCircle = IconData(0xe3d6, fontFamily: 'PhosphorRegular');
  static const IconData remove = IconData(0xe32c, fontFamily: 'PhosphorRegular');
  static const IconData edit = IconData(0xe3b4, fontFamily: 'PhosphorRegular');
  static const IconData delete = IconData(0xe4a6, fontFamily: 'PhosphorRegular');
  static const IconData check = IconData(0xe182, fontFamily: 'PhosphorRegular');
  static const IconData checkCircle = IconData(0xe184, fontFamily: 'PhosphorFill');
  static const IconData memo = IconData(0xe34c, fontFamily: 'PhosphorRegular');
  static const IconData keypad = IconData(0xe2d8, fontFamily: 'PhosphorRegular');
  static const IconData copy = IconData(0xe1ca, fontFamily: 'PhosphorRegular');
  static const IconData save = IconData(0xe248, fontFamily: 'PhosphorRegular');

  // 기록·백업
  static const IconData restore = IconData(0xe038, fontFamily: 'PhosphorRegular');
  static const IconData history = IconData(0xe1a0, fontFamily: 'PhosphorRegular');
  static const IconData importFile = IconData(0xe4be, fontFamily: 'PhosphorRegular');
  static const IconData folder = IconData(0xe256, fontFamily: 'PhosphorRegular');
  static const IconData document = IconData(0xe23a, fontFamily: 'PhosphorRegular');
  static const IconData pdf = IconData(0xe702, fontFamily: 'PhosphorRegular');
  static const IconData image = IconData(0xe2ca, fontFamily: 'PhosphorRegular');
  static const IconData update = IconData(0xe20c, fontFamily: 'PhosphorRegular');

  // 정산·설정
  static const IconData cycle = IconData(0xe3f6, fontFamily: 'PhosphorRegular');
  static const IconData percent = IconData(0xe3b6, fontFamily: 'PhosphorRegular');
  static const IconData rate = IconData(0xe55c, fontFamily: 'PhosphorRegular');
  static const IconData presets = IconData(0xe434, fontFamily: 'PhosphorRegular');
  static const IconData job = IconData(0xed46, fontFamily: 'PhosphorRegular');
  static const IconData sites = IconData(0xe102, fontFamily: 'PhosphorRegular');
  static const IconData backup = IconData(0xe1ae, fontFamily: 'PhosphorRegular');
  static const IconData privacy = IconData(0xe40c, fontFamily: 'PhosphorRegular');
  static const IconData info = IconData(0xe2ce, fontFamily: 'PhosphorRegular');
  static const IconData pro = IconData(0xe616, fontFamily: 'PhosphorRegular');
  static const IconData verified = IconData(0xe606, fontFamily: 'PhosphorFill');

  // 상태
  static const IconData error = IconData(0xe4e2, fontFamily: 'PhosphorRegular');
}
