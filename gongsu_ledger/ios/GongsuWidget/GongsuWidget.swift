//
//  GongsuWidget.swift
//  공수장부 홈 위젯 (소형 1종): 이번 달 총 공수 + 예상 실수령액.
//
//  값은 Flutter 쪽 HomeWidgetSyncer 가 App Group 의 UserDefaults 에 문자열로 저장해 둔
//  것을 그대로 표시한다. 키 이름은 lib/domain/widget_payload.dart 의 WidgetKeys 와
//  반드시 같아야 한다. 위젯은 계산하지 않는다(숫자 정확성은 앱이 책임진다).
//

import SwiftUI
import WidgetKit

private let appGroupId = "group.com.gongsujangbu.gongsuLedger"
private let accent = Color(red: 0.06, green: 0.30, blue: 0.60)

struct GongsuEntry: TimelineEntry {
  let date: Date
  let monthLabel: String
  let gongsu: String
  let workedDays: String
  let moneyLabel: String
  let money: String
  let locked: Bool

  static func load() -> GongsuEntry {
    let defaults = UserDefaults(suiteName: appGroupId)
    let month = Calendar.current.component(.month, from: Date())
    return GongsuEntry(
      date: Date(),
      monthLabel: defaults?.string(forKey: "widget_month_label") ?? "\(month)월",
      gongsu: defaults?.string(forKey: "widget_gongsu") ?? "0",
      workedDays: defaults?.string(forKey: "widget_worked_days") ?? "0",
      moneyLabel: defaults?.string(forKey: "widget_money_label") ?? "",
      money: defaults?.string(forKey: "widget_money") ?? "",
      locked: defaults?.string(forKey: "widget_locked") == "1"
    )
  }

  static let placeholder = GongsuEntry(
    date: Date(), monthLabel: "9월", gongsu: "21.5", workedDays: "18",
    moneyLabel: "실수령", money: "3,870,000원", locked: false)
}

struct GongsuProvider: TimelineProvider {
  func placeholder(in context: Context) -> GongsuEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (GongsuEntry) -> Void) {
    completion(context.isPreview ? .placeholder : .load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<GongsuEntry>) -> Void) {
    // 주기 갱신 없음: 앱이 값을 바꿀 때 reloadTimelines 로 갱신한다.
    completion(Timeline(entries: [.load()], policy: .never))
  }
}

struct GongsuWidgetView: View {
  let entry: GongsuEntry

  var body: some View {
    if entry.locked {
      lockedBody
    } else {
      numbersBody
    }
  }

  /// 프로가 아닐 때: 숫자 대신 안내.
  private var lockedBody: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("공수장부")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary)
      Image(systemName: "lock.fill")
        .font(.system(size: 22))
        .foregroundColor(accent)
      Text("위젯은 프로에서\n사용할 수 있어요")
        .font(.system(size: 14, weight: .semibold))
      Text("앱 → 설정 → 프로")
        .font(.system(size: 12))
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .modifier(GongsuWidgetBackground())
  }

  private var numbersBody: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(entry.monthLabel) 공수")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.secondary)
      Text(entry.gongsu)
        .font(.system(size: 36, weight: .heavy, design: .rounded))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
      Text("근무 \(entry.workedDays)일")
        .font(.system(size: 13))
        .foregroundColor(.secondary)
      if !entry.money.isEmpty {
        Spacer(minLength: 4)
        Text(entry.moneyLabel)
          .font(.system(size: 11))
          .foregroundColor(.secondary)
        Text(entry.money)
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(accent)
          .minimumScaleFactor(0.7)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .modifier(GongsuWidgetBackground())
  }
}

/// iOS 17 부터는 containerBackground 가 필수, 그 아래는 직접 패딩+배경.
struct GongsuWidgetBackground: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    } else {
      content.padding().background(Color(UIColor.systemBackground))
    }
  }
}

@main
struct GongsuWidget: Widget {
  // Flutter 쪽 HomeWidgetPluginService.iosWidgetKind 와 같아야 갱신 신호를 받는다.
  let kind: String = "GongsuWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: GongsuProvider()) { entry in
      GongsuWidgetView(entry: entry)
    }
    .configurationDisplayName("이번 달 공수")
    .description("이번 달 총 공수와 예상 실수령액을 보여줘요.")
    .supportedFamilies([.systemSmall])
  }
}
