import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../theme_provider.dart';
import 'transport_screen.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyBackgroundTaskHandler());
}

void main() {
  FlutterForegroundTask.initCommunicationPort();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const NudgeApp(),
    ),
  );
}

class NudgeApp extends StatelessWidget {
  const NudgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Nudge 2.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: theme.background,
        useMaterial3: true,
      ),
      home: const TransportScreen(),
    );
  }
}

class MyBackgroundTaskHandler extends TaskHandler {
  @override
  void onRepeatEvent(DateTime timestamp) async {
    // Your location tracking logic runs here safely in the background
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}