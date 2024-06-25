import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

import 'colors.dart'; // Ensure you have this file with the color definitions

class Data {
  String name = "";
  double value = -1;
  int order = -20;
  double convFact = 1;
  double jokeFact = 1;
  String unit = "{unit}";
  int trunc = 0;
  Data(String nm, double val, int ord, double cF, double jF, String un,
      int tru) {
    name = nm;
    value = val;
    order = ord;
    convFact = cF;
    jokeFact = jF;
    unit = un;
    trunc = tru;
  }
  Data.nu(String nm, double val, int ord, double cF, double jF, int tru) {
    name = nm;
    value = val;
    order = ord;
    convFact = cF;
    jokeFact = jF;
    unit = "NA";
    trunc = tru;
  }
  setName(String nm) {
    name = nm;
  }

  setValue(double val) {
    value = val;
  }
}

List<Data> displayValues = [
  Data.nu("MPH", -1, 1, .160934, 200, 1),
  Data.nu("RPM", -1, 2, 1, 200, 0),
  Data("Voltage", -1, 3, .1, 200, "V", 1),
  Data("Water Temp", -1, 4, .1, 200, "F", 1),
  Data("Oil Temp", -1, 5, .1, 200, "F", 1),
  Data("Oil Pressure", -1, 6, 0.0145038, 200, "PSI", 1),
  Data("Fuel Pressure", -1, 7, 1, 200, "PSI", 1),
  Data("Pitot Left", -1, 8, 1, 200, "PSI", 2),
  Data("Pitot Right", -1, 9, 1, 200, "PSI", 2),
  Data("Pitot Center", -1, 10, 1, 200, "PSI", 2),
  Data("Manifold Abs. Pressure", -1, 11, .0145038, 200, "PSI", 2),
  Data.nu("Lambda", -1, 12, .01, 200, 3),
  Data.nu("Gear Position", -1, 13, 1, 200, 0),
  Data.nu("Shift Request", -1, 14, 1, 200, 0),
  Data.nu("Neutral", -1, 15, 1, 200, 0),
  Data("Steering Angle", -1, 16, .1, 200, "°", 1),
  Data("Lat Load", -1, 17, 0.00980665012, 200, "G", 2),
  Data("Long Load", -1, 18, 0.00980665012, 200, "G", 2),
  Data("Front Brake Pressure", -1, 19, 0.145038, 200, "PSI", 1),
  Data("Rear Brake Pressure", -1, 20, 0.145038, 200, "PSI", 1),
  Data("Brake Bias", -1, -1, 1, 200, "percent", 3),
  Data("FL Damper Pot", -1, 21, 1, 200, "MM", 2),
  Data("FR Damper Pot", -1, 22, 1, 200, "MM", 2),
  Data("RL Damper Pot", -1, 23, 1, 200, "MM", 2),
  Data("RR Damper Pot", -1, 24, 1, 200, "MM", 2),
  Data("Throttle Position", -1, 25, .1, 200, "Percent", 1),

  //Data("Break Pressure Front")
];

class LiveTelemetry extends StatefulWidget {
  const LiveTelemetry({Key? key}) : super(key: key);

  @override
  State<LiveTelemetry> createState() => _LiveTelemetryState();
}

class _LiveTelemetryState extends State<LiveTelemetry> {
  final ScrollController _scrollController = ScrollController();
  String outPutText = "";
  int conBtnState = 0;
  int lengthOfMessageFrame = 0;

  bool needsScroll = false;
  bool realConversionrate = true;

  Timer? _dataFetchTimer;
  // 0 = no, 1 = yes, 2 = request timout
  int _isFetching = 0;
  final int _timeoutmilliseconds = 180;

  terminalPrint(String newLine) {
    setState(() {
      outPutText = "$outPutText\n>$newLine";
    });
    needsScroll = true;
  }

  void startFetchingData() {
    _terminalPrint("Attempting to read data");
    _dataFetchTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      fetchDataFromESP();
    });
  }

  void stopFetchingData() {
    _terminalPrint("Data reading closed");
    setState(() => _isFetching = 0);
    // Cancel the timer
    _dataFetchTimer?.cancel();
  }

  void fetchDataFromESP() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.4.1/'))
          .timeout(Duration(milliseconds: _timeoutmilliseconds), onTimeout: () {
        return http.Response("no lol", 1208);
      });
      if (response.statusCode == 200) {
        setState(() {
          _updateUIValues(jsonDecode(response.body));
          _isFetching = 1;
        });
      } else {
        if (_isFetching != 2) {
          _terminalPrint("request Timeout");
          _terminalPrint(
              'Failed to load data Status code: ${response.statusCode}, Attempting to reconnect');
          setState(() {
            _isFetching = 2;
          });
        }
      }
    } catch (e) {
      if (_isFetching != 2) {
        _terminalPrint("Connection error");
      }
      setState(() {
        _isFetching = 2;
      });

      // _terminalPrint(e.toString());
    }
  }

  void _updateUIValues(Map<String, dynamic> data) {
    if (data.containsKey('Length') && data.containsKey('Data')) {
      //int lengthOfMessageFrame = data['Length'];
      List<dynamic> dataArray = data['Data'];
      for (var element in dataArray) {
        if (element.containsKey('index') && element.containsKey('value')) {
          int index = element['index'];
          int value = element['value'];
          for (int i = 0; i < displayValues.length; i++) {
            if (index == displayValues[i].order) {
              displayValues[i].value = value *
                  ((realConversionrate)
                      ? displayValues[i].convFact
                      : displayValues[i].jokeFact);
            }

            if (index == 19) {
              double front = 0;
              double back = 0;
              for (int j = 0; j < displayValues.length; j++) {
                if (displayValues[j].order == 19) {
                  front = displayValues[j].value;
                }
                if (displayValues[j].order == 20) {
                  back = displayValues[j].value;
                }
              }
              for (int j = 0; j < displayValues.length; j++) {
                if (displayValues[j].order == -1) {
                  if (back + front != 0) {
                    displayValues[j].setValue((front / (back + front)) * 100);
                  } else {
                    displayValues[j].setValue(-2);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  void _terminalPrint(String message) {
    setState(() {
      outPutText += "\n> $message";
      // Auto-scroll to new messages
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.bounceIn);
      });
    });
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
  void dispose() {
    _dataFetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /*
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
                      switch (_isFetching) {
                        case 0:
                          //startScanning();
                          startFetchingData();
                          break;
                        case 1:
                          //stopSearching();
                          stopFetchingData();
                          break;
                        default:
                          //disconnect();
                          stopFetchingData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: mainColor,
                    ),
                    child: switch (_isFetching) {
                      0 => const Text("Connect"),
                      2 => LoadingAnimationWidget.newtonCradle(
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
                      terminalPrint("Lmao this might be a while");
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
              maxCrossAxisExtent: 800,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              mainAxisExtent: 150,
            ),
            itemCount: displayValues.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              String displayTitle;
              if (displayValues[index].unit != "NA") {
                displayTitle =
                    "${displayValues[index].name} (${displayValues[index].unit})";
              } else {
                displayTitle = displayValues[index].name;
              }
              double adjustableNumber = displayValues[index].value *
                  (realConversionrate
                      ? displayValues[index].convFact
                      : displayValues[index].jokeFact);
              if (displayValues[index].unit == "F") adjustableNumber -= 40;
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
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    controller: _scrollController,
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
                          ) {
                        realConversionrate = !realConversionrate;
                      },
                      icon: const Icon(Icons.settings),
                      color: accent),
                ),
              )
            ],
          ),
        )
      ],
    ));
    */
    ///*
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            height: 75,
            decoration: BoxDecoration(
                border: Border.all(color: mainColor), color: background),
            //color: background,
            child: Stack(alignment: Alignment.center, children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: ElevatedButton(
                        onPressed: () {
                          switch (_isFetching) {
                            case 0:
                              //startScanning();
                              startFetchingData();
                              break;
                            case 1:
                              //stopSearching();
                              stopFetchingData();
                              break;
                            default:
                              //disconnect();
                              stopFetchingData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: background,
                            minimumSize: const Size(150, 100),
                            shape: const RoundedRectangleBorder()),
                        child: switch (_isFetching) {
                          0 => const Text("Connect"),
                          2 => LoadingAnimationWidget.newtonCradle(
                              color: background,
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
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),

                    child: ElevatedButton(
                        onPressed: () {
                          terminalPrint("Lmao this might be a while");
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: background,
                            minimumSize: const Size(150, 100),
                            shape: const RoundedRectangleBorder()),
                        child: const Text(
                            "Graphs Coming Soon")), //TODO far in the future
                  )),
            ]),
          ),
          SingleChildScrollView(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: mainColor,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: background),
                        child: const SizedBox(
                          width: 70000,
                          child: Center(
                            child: Text(
                              "Temps & Pressures",
                              style: TextStyle(
                                color: accent,
                                fontSize: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          display(100, 3, 11, 1, 2, accent, background),
                          display(100, 5, 1, 0, 3, accent, background),
                          display(100, 3, 3, 0, 3, accent, background),
                          display(100, 3, 4, 0, 3, accent, background),
                          display(100, 3, 5, 0, 3, accent, background),
                          display(100, 3, 6, 0, 3, accent, background),
                          display(100, 3, 2, 2, 3, accent, background),
                        ],
                      ),
                    ],
                  ),
                ),
                //note the end
                Container(
                  margin: const EdgeInsets.all(0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: mainColor,
                              ),
                              child: const SizedBox(
                                child: Center(
                                  child: Text(
                                    "Driver Info",
                                    style: TextStyle(
                                      color: background,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                display(100, 2, 25, 1, 1, mainColor, mainColor),
                                display(100, 3, 18, 0, 1, mainColor, mainColor),
                                display(100, 1, 14, 2, 1, mainColor, mainColor),
                              ],
                            ),
                            Row(
                              children: [
                                display(100, 2, 15, 1, 0, mainColor, mainColor),
                                display(100, 3, 19, 0, 0, mainColor, mainColor),
                                display(100, 1, 13, 2, 0, mainColor, mainColor),
                              ],
                            ),
                            Row(
                              children: [
                                display(100, 2, 0, 1, 2, mainColor, mainColor),
                                display(100, 3, 20, 0, 2, mainColor, mainColor),
                                display(100, 1, 12, 2, 2, mainColor, mainColor),
                              ],
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: mainColor),
                              child: const SizedBox(
                                child: Center(
                                  child: Text(
                                    "Vehicle Dynamics",
                                    style: TextStyle(
                                      color: background,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                display(100, 1, 21, 1, 1, mainColor, mainColor),
                                display(100, 1, 22, 0, 1, mainColor, mainColor),
                                display(100, 1, 23, 0, 1, mainColor, mainColor),
                                display(100, 1, 24, 2, 1, mainColor, mainColor),
                              ],
                            ),
                            Row(
                              children: [
                                display(100, 1, 7, 1, 0, mainColor, mainColor),
                                display(100, 1, 8, 0, 0, mainColor, mainColor),
                                display(100, 1, 9, 2, 0, mainColor, mainColor),
                              ],
                            ),
                            Row(
                              children: [
                                display(100, 1, 16, 1, 2, mainColor, mainColor),
                                display(100, 1, 17, 0, 2, mainColor, mainColor),
                                display(100, 1, 10, 2, 2, mainColor, mainColor),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            color: const Color.fromRGBO(100, 100, 100, 1),
            child: const SizedBox(
              height: 30,
              child: Text(
                "Terminal:",
                style: TextStyle(color: mainColor, fontSize: 20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  outPutText,
                  style: const TextStyle(color: accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    //*/
  }
}

Widget display(
  double height,
  int digits,
  int dP,
  int loREdge,
  int toBEdge,
  Color labelColor,
  Color borderColor,
) {
  TextStyle valTextStyle = const TextStyle(
    color: mainColor,
    fontSize: 40,
  );
  TextStyle labelTextStyle = const TextStyle(
    color: background,
    fontSize: 15,
  );
  double leftmar;
  double rightmar;
  double topmar;
  double botmar;
  Data dp = displayValues[dP];
  switch (loREdge) {
    case 1:
      leftmar = 8;
      rightmar = 4;
      break;
    case 2:
      leftmar = 4;
      rightmar = 8;
      break;
    default:
      leftmar = 4;
      rightmar = 4;
  }
  switch (toBEdge) {
    case 1:
      topmar = 4;
      botmar = 4;
      break;
    case 2:
      topmar = 4;
      botmar = 8;
      break;
    case 3:
      topmar = 4;
      botmar = 8;
      break;
    default:
      topmar = 4;
      botmar = 4;
  }
  EdgeInsets iNSETS = EdgeInsets.fromLTRB(leftmar, topmar, rightmar, botmar);
  return Expanded(
    flex: digits,
    child: Container(
      margin: iNSETS,
      decoration: BoxDecoration(color: borderColor),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.all(0),
        decoration: const BoxDecoration(color: background),
        child: Column(
          children: [
            SizedBox(
              height: height,
              //width: digits * 50 + 20,
              child: Center(
                child: Text(
                  dp.value.toStringAsFixed(dp.trunc),
                  style: valTextStyle,
                ),
              ),
            ),
            Container(
                color: labelColor,
                child: SizedBox(
                  height: 30,
                  //width: digits * 50 + 20,
                  child: Center(
                    child: (dp.unit != "NA")
                        ? Text(
                            "${dp.name} (${dp.unit})",
                            style: labelTextStyle,
                          )
                        : Text(
                            dp.name,
                            style: labelTextStyle,
                          ),
                  ),
                ))
          ],
        ),
      ),
    ),
  );
}
