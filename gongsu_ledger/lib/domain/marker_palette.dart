import 'package:flutter/material.dart';

/// 프리셋/업체 구분용 고대비 팔레트.
///
/// 경쟁앱 불만("업체별 색상이 비슷해서 구분 안 됨")에 대응해 색상환에서
/// 서로 멀고 명도 차이도 있는 12색을 고정 제공한다. 색은 id로 저장하고
/// (DB에는 int), 실제 색값은 여기서만 해석한다 — 추후 팔레트 개선 시
/// 데이터 마이그레이션이 필요 없다.
///
/// 다크모드 변형: 라이트용 진한 색은 다크 서피스 위에서 대비 3:1에
/// 미달하는 것이 실측으로 확인되어(남색 1.79:1 등), 다크모드에서는
/// Material 300 톤의 밝은 변형을 쓴다(전부 4.8:1 이상).
class MarkerPalette {
  MarkerPalette._();

  static const List<({int id, String name, Color color, Color darkColor})>
      entries = [
    (id: 0, name: '파랑', color: Color(0xFF1565C0), darkColor: Color(0xFF64B5F6)),
    (id: 1, name: '초록', color: Color(0xFF2E7D32), darkColor: Color(0xFF81C784)),
    (id: 2, name: '주황', color: Color(0xFFEF6C00), darkColor: Color(0xFFFFB74D)),
    (id: 3, name: '보라', color: Color(0xFF6A1B9A), darkColor: Color(0xFFBA68C8)),
    (id: 4, name: '청록', color: Color(0xFF00838F), darkColor: Color(0xFF4DD0E1)),
    (id: 5, name: '자주', color: Color(0xFFC2185B), darkColor: Color(0xFFF06292)),
    (id: 6, name: '갈색', color: Color(0xFF5D4037), darkColor: Color(0xFFA1887F)),
    (id: 7, name: '남색', color: Color(0xFF283593), darkColor: Color(0xFF7986CB)),
    (id: 8, name: '올리브', color: Color(0xFF827717), darkColor: Color(0xFFDCE775)),
    (id: 9, name: '진빨강', color: Color(0xFFB71C1C), darkColor: Color(0xFFE57373)),
    (id: 10, name: '회청', color: Color(0xFF455A64), darkColor: Color(0xFF90A4AE)),
    (id: 11, name: '연두', color: Color(0xFF558B2F), darkColor: Color(0xFFAED581)),
  ];

  static ({int id, String name, Color color, Color darkColor}) _of(int id) =>
      entries[id >= 0 && id < entries.length ? id : 0];

  static Color colorOf(int id, {Brightness brightness = Brightness.light}) =>
      brightness == Brightness.dark ? _of(id).darkColor : _of(id).color;

  static String nameOf(int id) => _of(id).name;
}
