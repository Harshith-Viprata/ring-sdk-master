import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

class HealthDataWidget extends StatefulWidget {
  const HealthDataWidget({super.key});

  @override
  State<HealthDataWidget> createState() => _HealthDataWidgetState();
}

class _HealthDataWidgetState extends State<HealthDataWidget> {
  String _displayedText = "Result";

  /// 分类
  final _groups = ["Query", "Delete"];

  /// 项目
  final _items = [
    "Step",
    "Sleep",
    "Heart rate",
    "Blood pressure",
    "CombinedData",
    "InvasiveComprehensiveData",
    "Sport mode record",
    "Body Index data",
    "wear history data"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Health Data'),
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
              flex: 2,
              child: ListView.separated(
                  itemBuilder: (BuildContext context, int index) {
                    return ExpansionTile(
                      title: Text(_groups[index]),
                      children: _buildGroupItems(_items, index),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider(
                        height: 20, color: Colors.grey); // 添加分隔线
                  },
                  itemCount: _groups.length),
            ),
          ],
        ));
  }

  /// 设置子项
  List<Widget> _buildGroupItems(List<String> items, int group) {
    List<Widget> itemWidgets = [];
    for (int i = 0; i < items.length; i++) {
      itemWidgets.add(
        ListTile(
          title: Text(items[i]),
          onTap: () {
            EasyLoading.show(status: "");
            var showStr = "";
            setState(() {
              _displayedText = "";
            });

            if (0 == group) {
              switch (i) {
                case HealthDataType.step:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.step)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();
                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });

                case HealthDataType.sleep:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.sleep)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();
                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });

                case HealthDataType.heartRate:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.heartRate)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();
                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });

                case HealthDataType.bloodPressure:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.bloodPressure)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();
                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });

                case HealthDataType.combinedData:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.combinedData)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();
                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });

                case HealthDataType.invasiveComprehensiveData:
                  YcProductPlugin()
                      .queryDeviceHealthData(
                          HealthDataType.invasiveComprehensiveData)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();
                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });

                case HealthDataType.sportHistoryData:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.sportHistoryData)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();
                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });
                case HealthDataType.bodyIndexData:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.bodyIndexData)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];

                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.pressure.toString();
                        showStr += item.vo2max.toString();

                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });
                case HealthDataType.historyWearData:
                  YcProductPlugin()
                      .queryDeviceHealthData(HealthDataType.historyWearData)
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      final list = result?.data ?? [];
                      print("HistoryWearData: $result");
                      for (var item in list) {
                        // debugPrint(item.toString());
                        showStr += item.toString();

                        showStr += "\n-------------------------\n";
                      }

                      EasyLoading.showSuccess("");
                      setState(() {
                        _displayedText = showStr;
                      });
                    } else {
                      EasyLoading.showError("Not support");
                      setState(() {
                        _displayedText = showStr;
                      });
                    }
                  });
                default:
                  break;
              }

              return;
            }

            // 删除
            switch (i) {
              case HealthDataType.step:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.step)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );

              case HealthDataType.sleep:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.sleep)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );

              case HealthDataType.heartRate:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.heartRate)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );

              case HealthDataType.bloodPressure:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.bloodPressure)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );

              case HealthDataType.combinedData:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.combinedData)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );

              case HealthDataType.invasiveComprehensiveData:
                YcProductPlugin()
                    .deleteDeviceHealthData(
                        HealthDataType.invasiveComprehensiveData)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );

              case HealthDataType.sportHistoryData:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.sportHistoryData)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );

              case HealthDataType.bodyIndexData:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.bodyIndexData)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );
              case HealthDataType.historyWearData:
                YcProductPlugin()
                    .deleteDeviceHealthData(HealthDataType.historyWearData)
                    .then(
                  (value) {
                    if (value?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("succeed");
                    } else if (value?.statusCode == PluginState.failed) {
                      EasyLoading.showError("failed");
                    } else if (value?.statusCode == PluginState.unavailable) {
                      EasyLoading.showError("unavailable");
                    }
                  },
                );
              default:
                break;
            }
          },
        ),
      );
    }
    return itemWidgets;
  }
}
