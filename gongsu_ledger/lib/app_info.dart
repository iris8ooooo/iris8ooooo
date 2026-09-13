/// 앱 표시 버전. pubspec.yaml 의 version 과 일치해야 한다 (테스트로 고정).
const String kAppVersion = '1.0.0';

/// 앱 표시 이름 — 이름을 바꿀 때는 이 한 줄과 네이티브 4곳
/// (ios/Runner/Info.plist, ios/GongsuWidget/Info.plist 의 CFBundleDisplayName,
/// android/.../res/values/strings.xml 의 app_name, 위젯 Swift·Kotlin 문자열)만 바꾼다.
/// 나머지 화면·PDF·백업 문구는 전부 여기서 읽는다. 동기화는 app_name_guard_test 가 강제한다.
const String kAppName = '공수수첩';

/// 프로 상품 표시 이름.
const String kProName = '$kAppName 프로';
