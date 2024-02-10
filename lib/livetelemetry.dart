import 'package:flutter/material.dart';
import 'dart:async';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';

import 'colors.dart';

String eSPaddress = "ec:94:cb:6c:b0:be";
String serviceID = "0000facc-0000-1000-8000-00805F9B34FB";
List<String> names = [
  "MPH:",
  "RPM:",
  "Voltage:",
  "Water Temp:",
  "Oil Temp:",
  "Oil Pressure:",
  "Fuel Pressure:",
  "unknown:"
];
List<dynamic> values = [100, 90, 90.0, 90, 990, 90.0, 40.0, 560];

class LiveTelemetry extends StatelessWidget {
  const LiveTelemetry({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: background,
        primaryColor: mainColor,
        secondaryHeaderColor: accent,
      ),
      home: const
    );
  }
}
