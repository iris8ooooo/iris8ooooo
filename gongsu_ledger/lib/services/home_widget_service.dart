import 'package:home_widget/home_widget.dart';

/// 홈 위젯 데이터 저장/갱신 추상화. 위젯 코드는 플러그인을 직접 부르지 않는다
/// (CLAUDE.md M4 규칙과 같은 이유 — 위젯 테스트에서 가짜로 바꿔 끼운다).
abstract class HomeWidgetService {
  /// 키/값(전부 표시용 문자열)을 위젯이 읽는 저장소에 쓴다.
  Future<void> saveData(Map<String, String> data);

  /// 위젯에 "다시 그려라" 신호를 보낸다.
  Future<void> requestUpdate();
}

/// home_widget 플러그인 구현.
///
/// - iOS: App Group `appGroupId` 의 UserDefaults 에 저장, WidgetKit 타임라인 리로드
///   (`iosWidgetKind` 는 GongsuWidget.swift 의 `kind` 와 같아야 한다)
/// - Android: 플러그인 SharedPreferences 에 저장, `androidProviderName`
///   (앱 패키지 하위 클래스 GongsuWidgetProvider)로 APPWIDGET_UPDATE 브로드캐스트
class HomeWidgetPluginService implements HomeWidgetService {
  static const String appGroupId = 'group.com.gongsujangbu.gongsuLedger';
  static const String iosWidgetKind = 'GongsuWidget';
  static const String androidProviderName = 'GongsuWidgetProvider';

  bool _groupConfigured = false;

  @override
  Future<void> saveData(Map<String, String> data) async {
    if (!_groupConfigured) {
      await HomeWidget.setAppGroupId(appGroupId);
      _groupConfigured = true;
    }
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }
  }

  @override
  Future<void> requestUpdate() async {
    await HomeWidget.updateWidget(
      iOSName: iosWidgetKind,
      androidName: androidProviderName,
    );
  }
}
