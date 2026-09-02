package com.gongsujangbu.gongsu_ledger

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 홈 위젯(소형 1종): 이번 달 총 공수 + 예상 실수령액.
 *
 * 값은 Flutter 쪽 `HomeWidgetSyncer`가 home_widget 플러그인의 SharedPreferences에
 * 문자열로 저장해 둔 것을 그대로 표시한다. 키 이름은 lib/domain/widget_payload.dart 의
 * WidgetKeys 와 반드시 같아야 한다. 위젯은 계산하지 않는다(숫자 정확성은 앱이 책임진다).
 */
class GongsuWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.gongsu_widget)

            // 위젯 탭 → 앱 열기
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)

            val monthLabel = widgetData.getString("widget_month_label", null) ?: "이번 달"
            val gongsu = widgetData.getString("widget_gongsu", null) ?: "0"
            val workedDays = widgetData.getString("widget_worked_days", null) ?: "0"
            val moneyLabel = widgetData.getString("widget_money_label", null) ?: ""
            val money = widgetData.getString("widget_money", null) ?: ""

            views.setTextViewText(R.id.widget_month, "$monthLabel 공수")
            views.setTextViewText(R.id.widget_gongsu, gongsu)
            views.setTextViewText(R.id.widget_days, "근무 ${workedDays}일")
            if (money.isEmpty()) {
                views.setViewVisibility(R.id.widget_money_label, View.GONE)
                views.setViewVisibility(R.id.widget_money, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_money_label, View.VISIBLE)
                views.setViewVisibility(R.id.widget_money, View.VISIBLE)
                views.setTextViewText(R.id.widget_money_label, moneyLabel)
                views.setTextViewText(R.id.widget_money, money)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
