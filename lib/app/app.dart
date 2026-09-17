import 'package:flutter/material.dart';

import '../screens/map_screen.dart';

/// Wurzel-Widget von OPR NOW.
///
/// Hier werden App-Titel, Theme und der Startbildschirm festgelegt.
/// Navigation zwischen mehreren Screens kommt in späteren Phasen hinzu.
class OprNowApp extends StatelessWidget {
  const OprNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OPR NOW',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MapScreen(),
    );
  }
}
