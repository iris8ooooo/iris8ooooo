/// 경량 동기 저장소 — 첫 프레임에 필요한 값(화면 설정·온보딩 완료·프로 여부)의
/// 미러. 원본은 AppSettings(DB)에도 같이 쓰지만, DB는 lazy 오픈이라 첫 프레임에
/// 읽을 수 없어 깜빡임이 생긴다(M1 아키텍처 결정). 값은 전부 문자열.
abstract class LocalPrefs {
  String? getString(String key);

  Future<void> setString(String key, String value);
}

/// 테스트·기본값용 메모리 구현.
class MemoryLocalPrefs implements LocalPrefs {
  MemoryLocalPrefs([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
