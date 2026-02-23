import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'package:path_provider/path_provider.dart';

class OtaDeviceWidget extends StatefulWidget {
  const OtaDeviceWidget({super.key});

  @override
  State<OtaDeviceWidget> createState() => _OtaDeviceWidgetState();
}

class _OtaDeviceWidgetState extends State<OtaDeviceWidget> {
  String _displayedText = "Result";

  /// 项目
  final _items = [
    "NRF ota",
    "RTK ota",
    "JL Ota",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device ota"),
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
                    onTap: () async {

                      EasyLoading.show(status: "");

                      setState(() {
                        _displayedText = "";
                      });

                      final mcu = YcProductPlugin().connectedDevice?.mcuPlatform ?? DeviceMcuPlatform.nrf52832;

                      final documentsDirectory =
                          await getApplicationDocumentsDirectory();
                      final documentsPath = documentsDirectory.path;
                      debugPrint("目标地址: $documentsPath");


                      switch (index) {
                        case 0:
                          String filePath = "assets/files/M18DLC1.zip";
                          ByteData data = await rootBundle.load(filePath);
                          List<int> bytes = data.buffer.asUint8List();

                          // 目标路径
                          String destinationPath = '$documentsPath/M18DLC1.zip';

                          // 写入文件
                          File(destinationPath)
                              .writeAsBytes(bytes)
                              .then((value) {
                            debugPrint("写入成功 ${value.toString()}");

                            YcProductPlugin().deviceUpgrade(mcu, destinationPath, (code, process, errorString) {

                              if (code == DeviceUpdateState.start) {

                                debugPrint("开始升级");

                              } else if (code == DeviceUpdateState.upgradingFirmware) {

                                EasyLoading.showProgress(process, status: "Upgrading ${(process * 100).toInt()}%");

                              } else if (code == DeviceUpdateState.succeed){

                                EasyLoading.showSuccess("Ota succeed");

                              } else if (code == DeviceUpdateState.failed) {

                                EasyLoading.showError("Ota failed: \n$errorString");

                              }

                            }).then((value) {

                              debugPrint("--来了---");
                              EasyLoading.showSuccess("");

                            });

                          });



                        case 1:
                          String filePath = "assets/files/E300D.bin";
                          ByteData data = await rootBundle.load(filePath);
                          List<int> bytes = data.buffer.asUint8List();

                          // 目标路径
                          String destinationPath = '$documentsPath/E300.bin';

                          // 写入文件
                          File(destinationPath)
                              .writeAsBytes(bytes)
                              .then((value) {

                            debugPrint("写入成功 ${value.toString()}");

                            YcProductPlugin().deviceUpgrade(mcu, destinationPath, (code, process, errorString) {

                              if (code == DeviceUpdateState.start) {

                                debugPrint("开始升级");

                              } else if (code == DeviceUpdateState.upgradingFirmware) {

                                EasyLoading.showProgress(process, status: "Upgrading ${(process * 100).toInt()}%");

                              } else if (code == DeviceUpdateState.succeed){

                                EasyLoading.showSuccess("Ota succeed");

                              } else if (code == DeviceUpdateState.failed) {

                                EasyLoading.showError("Ota failed: \n$errorString");

                              }

                            }).then((value) {

                              EasyLoading.showSuccess("");

                            });


                          });

                        case 2:
                          String filePath = "assets/files/ET310A3.00.zip";
                          ByteData data = await rootBundle.load(filePath);
                          List<int> bytes = data.buffer.asUint8List();

                          // 目标路径
                          String destinationPath = '$documentsPath/ET310A3.00.zip';

                          // 写入文件
                          File(destinationPath)
                              .writeAsBytes(bytes)
                              .then((value) {

                            debugPrint("写入成功 ${value.toString()}");

                            YcProductPlugin().deviceUpgrade(mcu, destinationPath, (code, process, errorString) {

                              if (code == DeviceUpdateState.start) {

                                debugPrint("开始升级");

                              } else if (code == DeviceUpdateState.upgradingResources) {

                                EasyLoading.showProgress(
                                process,
                                status: "Upgrading Resource ${(process * 100).toInt()}%"
                                );

                              } else if (code == DeviceUpdateState.upgradeResourcesFinished) {

                                EasyLoading.show(status: "reconnected device");

                              } else if (code == DeviceUpdateState.upgradingFirmware) {

                                EasyLoading.showProgress(process, status: "Upgrading ${(process * 100).toInt()}%");

                              } else if (code == DeviceUpdateState.succeed) {

                                EasyLoading.showSuccess("Ota succeed");

                              } else if (code == DeviceUpdateState.failed) {

                                EasyLoading.showError("Ota failed: \n$errorString");

                              }

                            }).then((value) {

                              EasyLoading.showSuccess("");

                            });


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
