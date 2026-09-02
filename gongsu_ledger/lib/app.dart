import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/app_theme.dart';
import 'ui/calendar/calendar_page.dart';
import 'ui/common/snapshot_scheduler.dart';

class GongsuApp extends StatelessWidget {
  const GongsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공수장부',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SnapshotScheduler(child: CalendarPage()),
    );
  }
}
