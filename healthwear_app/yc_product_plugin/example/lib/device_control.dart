import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'dart:io';

class DeviceControlWidget extends StatefulWidget {
  const DeviceControlWidget({super.key});

  @override
  State<DeviceControlWidget> createState() => _DeviceControlWidgetState();
}

class _DeviceControlWidgetState extends State<DeviceControlWidget> {
  String _displayedText = "";

  final _items = [
    "App photo on",
    "App photo off",
    "Start run",
    "Stop run",
    "Start measure heart rate",
    "Stop measure heart rate",
    "Start measure blood pressure",
    "Stop measure blood pressure",
    "Start measure blood oxygen",
    "Stop measure blood oxygen",
    "Start measure temperature",
    "Stop measure temperature",
    "Start measure pressure",
    "Stop measure pressure",
    "Start measure blood glucose",
    "Stop measure blood glucose",
    "Start measure hrv",
    "Stop measure hrv",
    // "Start measure vo2max",
    // "Stop measure vo2max"
  ];

  @override
  void initState() {
    super.initState();

    YcProductPlugin().onListening((event) {
      debugPrint("--${toString()} -- ${event.toString()}");

      if (event.keys
          .contains(NativeEventType.deviceControlFindPhoneStateChange)) {
        final int index =
            event[NativeEventType.deviceControlFindPhoneStateChange];
        final state = DeviceControlState.values[index];

        setState(() {
          _displayedText = "Find phone ${state.toString()}";
        });
      }

      if (event.keys.contains(NativeEventType.deviceControlPhotoStateChange)) {
        final int index = event[NativeEventType.deviceControlPhotoStateChange];
        final state = DeviceControlPhotoState.values[index];

        setState(() {
          _displayedText = "Device photo ${state.toString()}";
        });
      }

      // 一键测量状态
      final Map? measureStateInfo =
          event[NativeEventType.deviceHealthDataMeasureStateChange];
      if (measureStateInfo != null) {
        debugPrint(
            "measureStateInfo, ${measureStateInfo.runtimeType.toString()} ,key=>${measureStateInfo.toString()},event=>${event.toString()}");

        setState(() {
          _displayedText = "MeasureState ${measureStateInfo.toString()}";
        });
      }

      // 心率
      final int? hrValue = event[NativeEventType.deviceRealHeartRate];
      if (hrValue != null) {
        setState(() {
          _displayedText = "HeartRate  $hrValue";
        });
      }

      // 血压
      final Map? bpInfo = event[NativeEventType.deviceRealBloodPressure];
      if (bpInfo != null) {
        setState(() {
          _displayedText = "BloodPressure  ${bpInfo.toString()}";
        });
      }

      // 血氧
      final int? bloodOxygenInfo = event[NativeEventType.deviceRealBloodOxygen];
      if (bloodOxygenInfo != null) {
        setState(() {
          _displayedText = "BloodOxygen  $bloodOxygenInfo";
        });
      }

      // 温度
      final String? temInfo = event[NativeEventType.deviceRealTemperature];
      if (temInfo != null) {
        setState(() {
          _displayedText = "Temperature $temInfo";
        });
      }

      //压力
      final String? pressureInfo = event[NativeEventType.deviceRealPressure].toString();
      if (pressureInfo != null){
        setState(() {
          _displayedText = "Pressure $pressureInfo";
        });
      }

      //血糖
      final String? bloodGlucoseInfo = event[NativeEventType.deviceRealBloodGlucose];
      if (bloodGlucoseInfo != null){
        setState(() {
          _displayedText = "BloodGlucose $bloodGlucoseInfo";
        });
      }

      //hrv
      final String? hrvInfo = event[NativeEventType.deviceRealHRV].toString();
      if (hrvInfo != null&&hrvInfo!="null"){
        setState(() {
          _displayedText = "HRV $hrvInfo";
        });
      }

      // 实时运动
      final Map? sportInfo = event[NativeEventType.deviceRealSport];
      if (sportInfo != null) {
        setState(() {
          _displayedText = "Sport: $sportInfo";
        });
      }

      final Map? sportStateInfo = event[NativeEventType.deviceSportStateChange];
      if (sportStateInfo != null) {
        setState(() {
          _displayedText = "Sport State: $sportStateInfo";
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint("-- ${toString()} 界面消失 -- ");
    YcProductPlugin().cancelListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device control"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _displayedText,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    onTap: () {
                      EasyLoading.show(status: "");
                      setState(() {
                        _displayedText = "";
                      });

                      switch (index) {
                        case 0:
                          YcProductPlugin()
                              .appControlTakePhoto(true)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 1:
                          YcProductPlugin()
                              .appControlTakePhoto(false)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 2:
                          YcProductPlugin()
                              .appControlSport(
                                  DeviceSportState.start, DeviceSportType.run)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 3:
                          YcProductPlugin()
                              .appControlSport(
                                  DeviceSportState.stop, DeviceSportType.run)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 4:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  true,
                                  DeviceAppControlMeasureHealthDataType
                                      .heartRate)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 5:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  false,
                                  DeviceAppControlMeasureHealthDataType
                                      .heartRate)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 6:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  true,
                                  DeviceAppControlMeasureHealthDataType
                                      .bloodPressure)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 7:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  false,
                                  DeviceAppControlMeasureHealthDataType
                                      .bloodPressure)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 8:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  true,
                                  DeviceAppControlMeasureHealthDataType
                                      .bloodOxygen)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 9:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  false,
                                  DeviceAppControlMeasureHealthDataType
                                      .bloodOxygen)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 10:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  true,
                                  DeviceAppControlMeasureHealthDataType
                                      .bodyTemperature)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                        case 11:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                                  false,
                                  DeviceAppControlMeasureHealthDataType
                                      .bodyTemperature)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });
                          case 12:
                        YcProductPlugin()
                            .appControlMeasureHealthData(
                            true,
                            DeviceAppControlMeasureHealthDataType
                                .pressure)
                            .then((value) {
                          if (value?.statusCode == PluginState.succeed) {
                            EasyLoading.showSuccess(_items[index]);
                            // final info = value?.data ;
                            // setState(() {
                            //   _displayedText = info.toString();
                            // });
                          } else {
                            EasyLoading.showError("${_items[index]} failed");
                          }
                        });

                        case 13:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                              false,
                              DeviceAppControlMeasureHealthDataType
                                  .pressure)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });
                          case 14:
                        YcProductPlugin()
                            .appControlMeasureHealthData(
                            true,
                            DeviceAppControlMeasureHealthDataType
                                .bloodGlucose)
                            .then((value) {
                          if (value?.statusCode == PluginState.succeed) {
                            EasyLoading.showSuccess(_items[index]);
                            // final info = value?.data ;
                            // setState(() {
                            //   _displayedText = info.toString();
                            // });
                          } else {
                            EasyLoading.showError("${_items[index]} failed");
                          }
                        });

                        case 15:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                              false,
                              DeviceAppControlMeasureHealthDataType
                                  .bloodGlucose)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });
                          case 16:
                        YcProductPlugin()
                            .appControlMeasureHealthData(
                            true,
                            DeviceAppControlMeasureHealthDataType
                                .hrv)
                            .then((value) {
                          if (value?.statusCode == PluginState.succeed) {
                            EasyLoading.showSuccess(_items[index]);
                            // final info = value?.data ;
                            // setState(() {
                            //   _displayedText = info.toString();
                            // });
                          } else {
                            EasyLoading.showError("${_items[index]} failed");
                          }
                        });

                        case 17:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                              false,
                              DeviceAppControlMeasureHealthDataType
                                  .hrv)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });

                            case 18:
                        YcProductPlugin()
                            .appControlMeasureHealthData(
                            true,
                            DeviceAppControlMeasureHealthDataType
                                .vo2max)
                            .then((value) {
                          if (value?.statusCode == PluginState.succeed) {
                            EasyLoading.showSuccess(_items[index]);
                            // final info = value?.data ;
                            // setState(() {
                            //   _displayedText = info.toString();
                            // });
                          } else {
                            EasyLoading.showError("${_items[index]} failed");
                          }
                        });

                        case 19:
                          YcProductPlugin()
                              .appControlMeasureHealthData(
                              false,
                              DeviceAppControlMeasureHealthDataType
                                  .vo2max)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });
                        default:
                          break;
                      }
                      
                    },
                    child: ListTile(
                      title: Text("${index + 1}. ${_items[index]}"),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider();
                },
                itemCount: _items.length),
          ),
        ],
      ),
    );
  }
}
