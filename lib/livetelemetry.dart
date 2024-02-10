import 'package:flutter/material.dart';
import 'dart:async';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';
import 'colors.dart';

String eSPaddress = "ec:94:cb:6c:b0:be";
String serviceID = "0000facc-0000-1000-8000-00805F9B34FB";
String charID = "0000dead-0000-1000-8000-00805f9b34fb";

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

class LiveTelemetry extends StatefulWidget {
  const LiveTelemetry({super.key});

  @override
  _LiveTelemetryState createState() => _LiveTelemetryState();
}

class _LiveTelemetryState extends State<LiveTelemetry> {
  bool isBleConnected = false;
  StreamSubscription? scanStream;
  StreamSubscription? connectionStream;
  StreamSubscription? bleStateStream;
  final StreamController<List<int>> _readController =
      StreamController<List<int>>();

  BleState bleState = BleState.Unknown;
  BleDevice? esp;
  String error = "none";

  void initialize() async {
    await WinBle.initialize(
      serverPath: await WinServer.path(),
    );
    //TODO add initialize message
  }

  @override
  void initState() {
    initialize();
    connectionStream = WinBle.connectionStream.listen((event) {});
    scanStream = WinBle.scanStream.listen((event) {
      setState(() {
        if (event.address == eSPaddress) {
          esp = event;
          connect(event.address);
          //TODO add esp found print message
          stopScanning();
        }
      });
    });
    bleStateStream = WinBle.bleState.listen((BleState state) {
      setState(() {
        bleState = state;
      });
    });
    super.initState();
  }

  startScanning() {
    WinBle.startScanning();
  }

  stopScanning() {
    WinBle.stopScanning();
  }

  connect(String address) async {
    try {
      await WinBle.connect(address);
      //TODO add attempting connect message
      final StreamSubscription<List<int>> _readSub =
          _readController.stream.listen((event) {
        updateUIValues(event);
      });
      isBleConnected = true;
      readChar();
      //TODO add reading BLE message
    } catch (e) {
      setState(() {
        error = e.toString();
        //TODO add error message
      });
    }
  }

  updateUIValues(List<int> updatedValues) async {
    int j = 0;
    int i = 0;
    double numb = 0;
    while (i < updatedValues.length) {
      if (updatedValues[i] == 44) {
        // ASCII code for comma
        values[j] = numb;
        j++;
        i++;
        numb = 0;
      } else {
        numb *= 10;
        numb += updatedValues[i] - 48; // ASCII code for '0'
        i++;
      }
    }
    setState(() {});
  }

  readChar() async {
    //TODO add isBLEConnected message
    while (isBleConnected) {
      _readController.sink.add(await WinBle.read(
          address: eSPaddress, serviceId: serviceID, characteristicId: charID));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(alignment: Alignment.center, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                  onPressed: () {
                    startScanning();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: mainColor,
                  ),
                  child: Text("Connect")) //TODO make this change with the state
              ),
          const Align(
            alignment: Alignment.center,
            child: Text(
              'IC Live Telemetry',
              style: TextStyle(color: mainColor, fontSize: 40),
            ),
          ),
        ])
      ],
    ));
  }
}
