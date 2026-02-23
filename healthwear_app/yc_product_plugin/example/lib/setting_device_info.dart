import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'dart:io';

class SettingDeviceWidget extends StatefulWidget {
  const SettingDeviceWidget({super.key});

  @override
  State<SettingDeviceWidget> createState() => _SettingDeviceWidgetState();
}

class _SettingDeviceWidgetState extends State<SettingDeviceWidget> {
  String _displayedText = "";

  final _items = [
    "Sync phone time",
    "Step goal",
    "Sleep goal",
    "User info",
    "Skin color",
    "Unit",
    "NotDisturb",
    "Language",
    "Sedentary",
    "Wearing position",
    "Phone system info",
    "AntiLost",
    "Info push (ANCS)",
    "Health monitoring (HR)",
    "Temperature monitoring(Deprecated)",
    "Heart rate alarm",
    "Blood pressure alarm",
    "Sp02 alarm",
    "Respiration rate alarm",
    "Temperature alarm",
    "Theme",
    "Wrist bright screen",
    "Sleep reminder",
    "Drink water reminder",
    "settingGetAllAlarm",
    "settingAddAlarm",
    "settingModfiyAlarm",
    "call",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Query"),
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
                   //   EasyLoading.show(status: "");
                      setState(() {
                        _displayedText = "";
                      });

                      switch (index) {
                        case 0:
                          YcProductPlugin()
                              .setDeviceSyncPhoneTime()
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 1:
                          YcProductPlugin()
                              .setDeviceStepGoal(10000)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 2:
                          YcProductPlugin()
                              .setDeviceSleepGoal(8, 30)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 3:
                          YcProductPlugin()
                              .setDeviceUserInfo(
                                  170, 65, 18, DeviceUserGender.male)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 4:
                          YcProductPlugin().setDeviceSkinColor().then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 5:
                          YcProductPlugin()
                              .setDeviceUnit(distance: DeviceDistanceUnit.km)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 6:
                          YcProductPlugin()
                              .setDeviceNotDisturb(true, 9, 30, 12, 0)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 7:
                          YcProductPlugin()
                              .setDeviceLanguage(DeviceLanguageType.english)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 8:
                          final Set<int> week = <int>{};
                          week.add(DeviceWeekDay.monday);
                          week.add(DeviceWeekDay.tuesday);
                          week.add(DeviceWeekDay.wednesday);
                          week.add(DeviceWeekDay.thursday);
                          week.add(DeviceWeekDay.friday);
                          week.add(DeviceWeekDay.saturday);
                          week.add(DeviceWeekDay.sunday);
                          YcProductPlugin()
                              .setDeviceSedentary(
                                  true, 9, 30, 12, 0, 14, 0, 18, 30, 30, week)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 9:
                          YcProductPlugin()
                              .setDeviceWearingPosition(
                                  DeviceWearingPositionType.left)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 10:
                          YcProductPlugin().setPhoneSystemInfo().then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 11:
                          YcProductPlugin()
                              .setDeviceAntiLost(true)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 12:
                          final Set<DeviceInfoPushType> items = <DeviceInfoPushType>{};
                          items.add(DeviceInfoPushType.call);
                          items.add(DeviceInfoPushType.sms);
                          items.add(DeviceInfoPushType.wechat);
                          items.add(DeviceInfoPushType.qq);

                          YcProductPlugin().setDeviceInfoPush(
                              true, items
                          ).then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 13: // Health monitoring (HR)
                          YcProductPlugin()
                              .setDeviceHealthMonitoringMode()
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 14: // temperature monitoring(Deprecated)
                          YcProductPlugin()
                              .setDeviceTemperatureMonitoringMode()
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 15: // Heart rate alarm
                          YcProductPlugin()
                              .setDeviceHeartRateAlarm()
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 16: // Blood pressure alarm
                          YcProductPlugin()
                              .setDeviceBloodPressureAlarm(
                                  true, 160, 120, 80, 60)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 17: // Sp02 alarm
                          YcProductPlugin()
                              .setDeviceBloodOxygenAlarm()
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 18: // Respiration rate alarm
                          YcProductPlugin()
                              .setDeviceRespirationRateAlarm(true, 30, 6)
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 19: // Temperature alarm
                          YcProductPlugin()
                              .setDeviceTemperatureAlarm(true, "37.3", "33")
                              .then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 20: // Theme
                          YcProductPlugin().queryDeviceTheme().then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              // EasyLoading.showSuccess("");

                              final info = value?.data as DeviceThemeInfo;

                              YcProductPlugin().setDeviceTheme(info.count - 1).then((value) {

                                  if (value?.statusCode == PluginState.succeed) {

                                    EasyLoading.showSuccess("");

                                  } else {

                                    EasyLoading.showError("Not support");
                                  }

                              });

                              setState(() {
                                _displayedText = info.toString();
                              });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 21: // Wrist bright screen
                            YcProductPlugin().setDeviceWristBrightScreen(true).then((value) {
                              if (value?.statusCode == PluginState.succeed) {
                                EasyLoading.showSuccess("");
                                // final info = value?.data ;
                                // setState(() {
                                //   _displayedText = info.toString();
                                // });
                              } else {
                                EasyLoading.showError("Not support");
                              }
                            });

                        case 22: // Sleep reminder

                          final Set<int> week = <int>{};
                          week.add(DeviceWeekDay.monday);
                          week.add(DeviceWeekDay.tuesday);
                          week.add(DeviceWeekDay.wednesday);
                          week.add(DeviceWeekDay.thursday);
                          week.add(DeviceWeekDay.friday);
                          week.add(DeviceWeekDay.saturday);
                          week.add(DeviceWeekDay.sunday);

                          YcProductPlugin().setDeviceSleepReminder(true, 22, 30, week).then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 23: // 喝水提醒

                          final Set<int> week = <int>{};
                          week.add(DeviceWeekDay.monday);
                          week.add(DeviceWeekDay.tuesday);
                          week.add(DeviceWeekDay.wednesday);
                          week.add(DeviceWeekDay.thursday);
                          week.add(DeviceWeekDay.friday);
                          week.add(DeviceWeekDay.saturday);
                          week.add(DeviceWeekDay.sunday);
                          
                          YcProductPlugin().setDevicePeriodicReminderTask(DevicePeriodicReminderType.drinkWater, true, 9, 30, 18, 0, 0, week).then((value) {

                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess("");
                              // final info = value?.data ;
                              // setState(() {
                              //   _displayedText = info.toString();
                              // });
                            } else {
                              EasyLoading.showError("Not support");
                            }

                          });
                        case 24: // 查询闹钟

                          YcProductPlugin().settingGetAllAlarm().then((value) {

                          //  if (value?.statusCode == PluginState.succeed) {
                            //  EasyLoading.showSuccess("");
                              final info = value?.data ;
                              setState(() {
                                _displayedText = info.toString();
                              });
                         //   } else {
                          //    EasyLoading.showError("Not support");
                         //   }

                          });
                        case 25: // 添加闹钟
                          String weekRepeat = "10000111";
                          YcProductPlugin().settingAddAlarm(0, 10, 30, weekRepeat, 10).then((value) {

                        //    if (value?.statusCode == PluginState.succeed) {
                         //     EasyLoading.showSuccess("");
                              final info = value?.statusCode ;
                              setState(() {
                                _displayedText = info.toString();
                              });
                         //   } else {
                         //     EasyLoading.showError("Not support");
                         //   }

                          });
                        case 26: // 修改闹钟

                          // String newWeekRepeat = "10000011";
                          String newWeekRepeat = "11111111";

                          YcProductPlugin().settingModfiyAlarm(8, 30, 0, 9, 30, newWeekRepeat, 10).then((value) {

                           if (value?.statusCode == PluginState.succeed) {
                         //     EasyLoading.showSuccess("");
                              final info = value?.statusCode ;
                              setState(() {
                                _displayedText = info.toString();
                              });
                           } else {
                             EasyLoading.showError("Not support");
                           }

                          });
                        case 27: // 来电提醒

                          YcProductPlugin().updateCallAlerts(true).then((value) {

                            //   if (value?.statusCode == PluginState.succeed) {
                            //     EasyLoading.showSuccess("");
                            final info = value?.statusCode ;
                            setState(() {
                              _displayedText = info.toString();
                            });
                            //      } else {
                            //       EasyLoading.showError("Not support");
                            //      }

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
