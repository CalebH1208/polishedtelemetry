import 'package:flutter/material.dart';
//import 'livetelemetry.dart';
import 'LiveTelemetryQB.dart';
import 'colors.dart';

class InitailPage extends StatelessWidget {
  const InitailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: background,
        primaryColor: mainColor,
        secondaryHeaderColor: accent,
      ),
      home: const LiveTelemetry(),
    );
  }
}
