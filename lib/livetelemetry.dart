import 'package:flutter/material.dart';
import 'dart:async';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'colors.dart';

String eSPaddress = "ec:94:cb:6c:b0:be";
String serviceID = "0000facc-0000-1000-8000-00805F9B34FB";
String charID = "0000dead-0000-1000-8000-00805f9b34fb";

class Data {
  String name = "";
  double value = -1;
  int order = -20;
  Data(String nm, double val, int ord) {
    name = nm;
    value = val;
    order = ord;
  }
  setName(String nm) {
    name = nm;
  }

  setValue(double val) {
    value = val;
  }
}

List<Data> displayValues = [
  Data("MPH", -1, 0),
  Data("RPM", -1, 1),
  Data("Voltage", -1, 2),
  Data("Water Temp", -1, 3),
  Data("Oil Temp", -1, 4),
  Data("Oil Pressure", -1, 5),
  Data("Fuel Pressure", -1, 6),
  Data("WHo knows", 15000, 7)
];

class LiveTelemetry extends StatefulWidget {
  const LiveTelemetry({super.key});

  @override
  State<LiveTelemetry> createState() => _LiveTelemetryState();
}

class _LiveTelemetryState extends State<LiveTelemetry> {
  /*
  0 = not connected
  1 = attempting to connect
  2 = connected
  */
  int conBtnState = 0;
  bool isBleConnected = false;
  StreamSubscription? scanStream;
  StreamSubscription? connectionStream;
  StreamSubscription? bleStateStream;
  final StreamController<List<int>> _readController =
      StreamController<List<int>>();

  BleState bleState = BleState.Unknown;
  BleDevice? esp;
  String error = "none";
  String outPutText = "";

  void initialize() async {
    await WinBle.initialize(
      serverPath: await WinServer.path(),
    );

    terminalPrint("Initialized");
  }

  terminalPrint(String newLine) {
    outPutText = "$outPutText\n>$newLine";
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
          terminalPrint("ESP found");
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
    conBtnState = 1;
    terminalPrint("Attempting to Connect");
  }

  stopScanning() {
    WinBle.stopScanning();
  }

  connect(String address) async {
    try {
      await WinBle.connect(address);

      // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
      final StreamSubscription<List<int>> _readSub =
          _readController.stream.listen((event) {
        updateUIValues(event);
      });
      isBleConnected = true;
      conBtnState = 2;
      readChar();
      terminalPrint("Reading BLE messages");
    } catch (e) {
      setState(() {
        error = e.toString();

        terminalPrint(e.toString());
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
        //displayValues[j].setValue(numb);
        for (int k = 0; k < displayValues.length; k++) {
          if (j == displayValues[k].order) {
            displayValues[k].setValue(numb);
          }
        }
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
    while (isBleConnected) {
      _readController.sink.add(await WinBle.read(
          address: eSPaddress, serviceId: serviceID, characteristicId: charID));
    }
    conBtnState = 0;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final Data vibe = displayValues.removeAt(oldIndex);
      displayValues.insert(newIndex, vibe);
      //final item = items.removeAt(oldIndex);
      //items.insert(newIndex, item);
    });
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 0, 0),
                child: ElevatedButton(
                    onPressed: () {
                      switch (conBtnState) {
                        case 0:
                          startScanning();
                          break;
                        case 1:
                          terminalPrint("have some patience damn");
                          break;
                        default:
                        //TODO disconnect funtion time
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: mainColor,
                    ),
                    child: switch (conBtnState) {
                      0 => const Text("Connect"),
                      1 => LoadingAnimationWidget.newtonCradle(
                          color: mainColor,
                          size: 50,
                        ),
                      int() => const Text("Disconnect"),
                    }
                    //Text("Connect")
                    ),
              )),
          const Align(
            alignment: Alignment.center,
            child: Text(
              'IC Live Telemetry',
              style: TextStyle(color: mainColor, fontSize: 40),
            ),
          ),
          Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4.0, 16.0, 0),
                child: ElevatedButton(
                    onPressed: () {
                      ();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: mainColor,
                    ),
                    child: const Text(
                        "Graphs Coming Soon")), //TODO far in the future
              )),
        ]),
        const Divider(
          height: 16.0,
          thickness: 8.0,
          color: mainColor,
        ),
        Expanded(
          child: ReorderableGridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 700,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              mainAxisExtent: 150,
            ),
            itemCount: displayValues.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              String displayTitle = displayValues[index].name;
              double adjustableNumber = displayValues[index].value;
              return Card(
                key: Key(displayTitle),
                color: accent,
                child: SizedBox(
                  child: Column(children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          "$adjustableNumber",
                          style:
                              const TextStyle(color: background, fontSize: 50),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 8.0,
                      thickness: 4.0,
                      color: background,
                    ),
                    Text(
                      displayTitle,
                      style: const TextStyle(
                          color: background,
                          fontSize: 30,
                          fontWeight: FontWeight.w500),
                    )
                  ]),
                ),
              );
            },
          ),

          // child: ReorderableGridView.extent(
          //   maxCrossAxisExtent: 700,
          //   onReorder: _onReorder,
          //   childAspectRatio: 3,
          //   children: displayValues.map((datapoint) {
          //     return DisplayBox(
          //         key: ValueKey(datapoint.name),
          //         name: datapoint.name,
          //         value: datapoint.value);
          //   }).toList(),
          // ),
        ),
        const Divider(
          height: 8.0,
          thickness: 8.0,
          color: mainColor,
        ),
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Text(
                      outPutText,
                      style: const TextStyle(color: accent),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                      onPressed: (//TODO add button with settings functionality
                          ) {},
                      icon: const Icon(Icons.settings),
                      color: accent),
                ),
              )
            ],
          ),
        )
      ],
    ));
  }
}
