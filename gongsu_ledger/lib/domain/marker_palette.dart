import 'package:flutter/material.dart';

/// 프리셋/업체 구분용 고대비 팔레트.
///
/// 경쟁앱 불만("업체별 색상이 비슷해서 구분 안 됨")에 대응해 색상환에서
/// 서로 멀고 명도 차이도 있는 12색을 고정 제공한다. 색은 id로 저장하고
/// (DB에는 int), 실제 색값은 여기서만 해석한다 — 추후 팔레트 개선 시
/// 데이터 마이그레이션이 필요 없다.
class MarkerPalette {
  MarkerPalette._();

  static const List<({int id, String name, Color color})> entries = [
    (id: 0, name: '파랑', color: Color(0xFF1565C0)),
    (id: 1, name: '초록', color: Color(0xFF2E7D32)),
    (id: 2, name: '주황', color: Color(0xFFEF6C00)),
    (id: 3, name: '보라', color: Color(0xFF6A1B9A)),
    (id: 4, name: '청록', color: Color(0xFF00838F)),
    (id: 5, name: '자주', color: Color(0xFFC2185B)),
    (id: 6, name: '갈색', color: Color(0xFF5D4037)),
    (id: 7, name: '남색', color: Color(0xFF283593)),
    (id: 8, name: '올리브', color: Color(0xFF827717)),
    (id: 9, name: '진빨강', color: Color(0xFFB71C1C)),
    (id: 10, name: '회청', color: Color(0xFF455A64)),
    (id: 11, name: '연두', color: Color(0xFF558B2F)),
  ];

  static Color colorOf(int id) =>
      entries[id >= 0 && id < entries.length ? id : 0].color;

  static String nameOf(int id) =>
      entries[id >= 0 && id < entries.length ? id : 0].name;
}
