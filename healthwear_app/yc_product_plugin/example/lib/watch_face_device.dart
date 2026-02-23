import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class WatchFaceWidget extends StatefulWidget {
  const WatchFaceWidget({super.key});

  @override
  State<WatchFaceWidget> createState() => _WatchFaceWidgetState();
}

class _WatchFaceWidgetState extends State<WatchFaceWidget> {
  String _displayedText = "Result";

  /// 分类
  final _groups = ["YC", "JL"];

  /// 项目
  final _items = [
    "Query",
    "Change",
    "Delete",
    "Download",
    "Custom dial",
  ];

  @override
  void initState() {
    super.initState();

    YcProductPlugin().onListening((event) {
      // debugPrint("===== 事件类型 $event, ${event.keys}");

      if (event.keys.contains(NativeEventType.deviceWatchFaceChange)) {
        int dialId = event[NativeEventType.deviceWatchFaceChange];

        setState(() {
          _displayedText = "Watch face change: $dialId";
        });
      } else if (event.keys
          .contains(NativeEventType.deviceJieLiWatchFaceChange)) {
        String watchName = event[NativeEventType.deviceJieLiWatchFaceChange];
        setState(() {
          _displayedText = "Watch face change: $watchName";
        });
      }
    });
  }

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

            // 删除

            if (0 == group) {
              switch (i) {
                // 查询表盘
                case 0:
                  YcProductPlugin().queryWatchFaceInfo().then((result) {
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

                // 设置表盘 - id 只用于切换
                case 1:
                  YcProductPlugin().changeWatchFace(185).then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("");
                    } else {
                      EasyLoading.showError("Not support");
                    }
                  });

                // 删除表盘 - id 只用于举例
                case 2:
                  YcProductPlugin().deleteWatchFace(306).then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("");
                    } else {
                      EasyLoading.showError("Not support");
                    }
                  });

                // 下载普通表盘
                case 3:
                  downloadNormalDial();

                // 下载自定义表盘
                case 4:
                  downloadCustomDial();

                default:
                  break;
              }
            } else {
              switch (i) {
                // 查询表盘
                case 0:
                  YcProductPlugin().queryWatchFaceInfo().then((result) {
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

                // 设置表盘 - id 只用于切换
                case 1:
                  YcProductPlugin()
                      .changeJieLiWatchFace("WATCH1")
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("");
                    } else {
                      EasyLoading.showError("Not support");
                    }
                  });

                // 删除表盘 - id 只用于举例
                case 2:
                  YcProductPlugin()
                      .deleteJieLiWatchFace("watch28")
                      .then((result) {
                    if (result?.statusCode == PluginState.succeed) {
                      EasyLoading.showSuccess("");
                    } else {
                      EasyLoading.showError("Not support");
                    }
                  });

                // 下载杰理表盘
                case 3:
                  downloadJieLilDial();

                // 下载自定义表盘
                case 4:
                  downloadCustomJieLiDial();

                default:
                  break;
              }
            }
          },
        ),
      );
    }
    return itemWidgets;
  }

  /// 下载普通表盘
  void downloadNormalDial() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final documentsPath = documentsDirectory.path;
    debugPrint("目标地址: $documentsPath");

    String filePath = "assets/files/E300H1.bin";
    ByteData data = await rootBundle.load(filePath);
    List<int> bytes = data.buffer.asUint8List();

    // 目标路径
    String destinationPath = '$documentsPath/E300H1.bin';

    File(destinationPath).writeAsBytes(bytes).then((value) {
      debugPrint("写入成功 ${value.toString()}");

      YcProductPlugin().installWatchFace(true, 306, 0, 0, destinationPath,
          (code, process, errorString) {
        EasyLoading.showProgress(process,
            status: "Upgrading ${(process * 100).toInt()}%");
      }).then((result) {
        if (result?.statusCode == PluginState.succeed) {
          EasyLoading.showSuccess("");
        } else {
          EasyLoading.showError("Not support");
        }
      });
    });
  }

  /// 下载自定义表盘
  void downloadCustomDial() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final documentsPath = documentsDirectory.path;
    // debugPrint("目标地址: $documentsPath");

    // 表盘文件
    String filePath = "assets/files/customE88E.bin";
    ByteData data = await rootBundle.load(filePath);
    List<int> bytes = data.buffer.asUint8List();

    // 目标路径
    String destinationPath = '$documentsPath/customE88E.bin';

    File(destinationPath).writeAsBytes(bytes).then((value) {
      debugPrint("写入成功 ${value.toString()}");

      // 查询表盘信息
      YcProductPlugin()
          .queryDeviceCustomWatchFaceInfo(destinationPath)
          .then((result) async {
        if (result?.statusCode == PluginState.succeed) {
          EasyLoading.showSuccess("");

          final dialInfo = result?.data;

          setState(() {
            _displayedText = dialInfo?.toString() ?? "";
          });

          // 写入图片 由尺寸大小压缩得到
          String bgPath = "assets/images/2147483615.png";
          ByteData bgImageData = await rootBundle.load(bgPath);
          List<int> bgImageBytes = bgImageData.buffer.asUint8List();
          String bgImageDestinationPath = "$documentsPath/2147483615.png";

          File(bgImageDestinationPath).writeAsBytes(bgImageBytes).then((value) async {

            debugPrint("写入背景图片成功 ${value.toString()}");

            String thumbnailPath = "assets/images/2147483615_thumbnail.png";
            ByteData thumbnailImageData = await rootBundle.load(thumbnailPath);
            List<int> thumbnailImageBytes = thumbnailImageData.buffer.asUint8List();
            String thumbnailImageDestinationPath = "$documentsPath/thumbnail.png";

            File(thumbnailImageDestinationPath).writeAsBytes(thumbnailImageBytes).then((value) {

              debugPrint("写入缩略图片成功 ${value.toString()}");

              int dialID = 2147483615;

              int timeX = (dialInfo?.width ?? 0) ~/ 4;
              int timeY = (dialInfo?.height ?? 0) ~/ 2;

              YcProductPlugin().installCustomWatchFace(dialID, destinationPath, bgImageDestinationPath, thumbnailImageDestinationPath, timeX, timeY, 255, 0, 0, (code, process, errorString) {

                EasyLoading.showProgress(process,
                    status: "Upgrading ${(process * 100).toInt()}%");
              })?.then((result) {


                if (result?.statusCode == PluginState.succeed) {
                  EasyLoading.showSuccess("");
                } else {
                  EasyLoading.showError("Not support");
                }
              });

            });

          });
        } else {
          EasyLoading.showError("Not support");
        }
      });
    });
  }

  /// 下载杰理表盘
  void downloadJieLilDial() async {
    String watchName = "watch28";

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final documentsPath = documentsDirectory.path;
    debugPrint("目标地址: $documentsPath");

    String filePath = "assets/files/$watchName";
    ByteData data = await rootBundle.load(filePath);
    List<int> bytes = data.buffer.asUint8List();

    // 目标路径
    String destinationPath = '$documentsPath/$watchName';

    File(destinationPath).writeAsBytes(bytes).then((value) {
      debugPrint("写入成功 ${value.toString()}");

      YcProductPlugin().installJieLiWatchFace(watchName, destinationPath,
          (code, process, errorString) {
        EasyLoading.showProgress(process,
            status: "Upgrading ${(process * 100).toInt()}%");
      }).then((result) {
        if (result?.statusCode == PluginState.succeed) {
          EasyLoading.showSuccess("");
        } else {
          EasyLoading.showError("Not support");
        }
      });
    });
  }

  /// 下载杰理自定义表盘
  void downloadCustomJieLiDial() {
    YcProductPlugin().queryDeviceDisplayParametersInfo().then((result) async {
      if (result?.statusCode != PluginState.succeed) {
        EasyLoading.showError("Not support");
        return;
      }

      final parametersInfo = result?.data;

      setState(() {
        _displayedText = parametersInfo.toString();
      });

      // 依据  parametersInfo 的图片，进行将图片进行转换为相应尺寸、圆角的两张图片，这里不演示直接得到对应的。

      // 写入图片
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final documentsPath = documentsDirectory.path;

      String bgPath = "assets/images/2147483615.png";
      ByteData bgImageData = await rootBundle.load(bgPath);
      List<int> bgImageBytes = bgImageData.buffer.asUint8List();
      String bgImageDestinationPath = "$documentsPath/background.png";

      // 写入手表
      File(bgImageDestinationPath)
          .writeAsBytes(bgImageBytes)
          .then((value) async {
        String thumbnailPath = "assets/images/2147483615_thumbnail.png";
        ByteData thumbnailImageData = await rootBundle.load(thumbnailPath);
        List<int> thumbnailImageBytes = thumbnailImageData.buffer.asUint8List();
        String thumbnailImageDestinationPath = "$documentsPath/thumbnail.png";

        File(thumbnailImageDestinationPath)
            .writeAsBytes(thumbnailImageBytes)
            .then((value) {
          // 准备转换图片 // BGP_W900
          YcProductPlugin().installJieLiCustomWatchFace(
              "watch900",
              bgImageDestinationPath,
              thumbnailImageDestinationPath,
              DeviceWatchFaceTimePosition.bottom,
              YcProductPluginTools.colorToRGB565(
                  const Color.fromARGB(255, 255, 255, 255)),
              parametersInfo!, (code, process, errorString) {
            EasyLoading.showProgress(process,
                status: "Upgrading ${(process * 100).toInt()}%");
          }).then((value) {
            debugPrint("----- 安装表盘 ---- ");
            if (result?.statusCode == PluginState.succeed) {
              EasyLoading.showSuccess("");
            } else {
              EasyLoading.showError("");
            }
          });
        });
      });
    });
  }
}
