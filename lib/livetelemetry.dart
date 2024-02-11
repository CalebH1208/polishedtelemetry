import 'package:flutter/material.dart';
import 'dart:async';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'colors.dart';

String eSPaddress = "ec:94:cb:6c:b0:be";
String serviceID = "0000facc-0000-1000-8000-00805F9B34FB";
String charID = "0000dead-0000-1000-8000-00805f9b34fb";

class Data {
  String name = "";
  double value = -1;
  Data(String nm, double val) {
    name = nm;
    value = val;
  }
  setName(String nm) {
    name = nm;
  }

  setValue(double val) {
    value = val;
  }
}

List<Data> displayValues = [
  Data("MPH", -1),
  Data("RPM", -1),
  Data("Voltage", -1),
  Data("Water Temp", -1),
  Data("Oil Temp", -1),
  Data("Oil Pressure", -1),
  Data("Fuel Pressure", -1),
  Data("WHo knows", -1)
];

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

      // ignore: unused_local_variable
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
        displayValues[j].setValue(numb);
        j++;
        i++;
        numb = 0;
      } else {
        numb *= 10;
        numb += updatedValues[i] - 48; // ASCII code for '0'
        i++;
      }
    }
    print(displayValues[2].value);
    setState(() {});
  }

  readChar() async {
    //TODO add isBLEConnected message
    while (isBleConnected) {
      _readController.sink.add(await WinBle.read(
          address: eSPaddress, serviceId: serviceID, characteristicId: charID));
    }
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
                      startScanning();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: mainColor,
                    ),
                    child: Text("Connect")),
              ) //TODO make this change with the state
              ),
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
                    child: Text("Graphs Coming Soon")), //TODO far in the future
              )),
        ]),
        const Divider(
          height: 16.0,
          thickness: 8.0,
          color: mainColor,
        ),
        Expanded(
          child: ReorderableGridView.extent(
            maxCrossAxisExtent: 700,
            onReorder: _onReorder,
            childAspectRatio: 3,
            children: displayValues.map((datapoint) {
              return Card(
                key: Key(datapoint.name),
                color: accent,
                child: SizedBox(
                  child: Column(children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          datapoint.value.toString(),
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
                      datapoint.name,
                      style: const TextStyle(
                          color: background,
                          fontSize: 30,
                          fontWeight: FontWeight.w500),
                    )
                  ]),
                ),
              );
            }

                // return DisplayBox(
                //     key: ValueKey(datapoint.name),
                //     name: datapoint.name,
                //     value: datapoint.value);
                ).toList(),
          ),
        ),
        const Divider(
          height: 8.0,
          thickness: 8.0,
          color: mainColor,
        ),
        SizedBox(
          height: 75,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Expanded(
                child: Text(
                  "hi",
                  style: TextStyle(color: accent),
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

class DisplayBox extends StatefulWidget {
  String name;
  double value;
  DisplayBox({
    super.key,
    required this.name,
    required this.value,
  });

  @override
  _DisplayBoxState createState() => _DisplayBoxState();
}

class _DisplayBoxState extends State<DisplayBox> {
  String name = '';
  double value = -1;
  setName(String newName) {
    name = newName;
    setState(() {});
  }

  setValue(double newValue) {
    value = newValue;
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    name = widget.name;
    value = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: accent,
      child: SizedBox(
        child: Column(children: [
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "$value",
                style: const TextStyle(color: background, fontSize: 50),
              ),
            ),
          ),
          const Divider(
            height: 8.0,
            thickness: 4.0,
            color: background,
          ),
          Text(
            name,
            style: const TextStyle(
                color: background, fontSize: 30, fontWeight: FontWeight.w500),
          )
        ]),
      ),
    );
  }
}
