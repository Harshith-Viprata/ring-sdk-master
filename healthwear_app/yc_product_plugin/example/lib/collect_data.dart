import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'dart:io';

class CollectDataWidget extends StatefulWidget {
  const CollectDataWidget({super.key});

  @override
  State<CollectDataWidget> createState() => _CollectDataWidgetState();
}

class _CollectDataWidgetState extends State<CollectDataWidget> {

  String _displayedText = "";

  final _items = [
    "ECG basic info",
    "ECG data (first)",
    "Delete data",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collect data"),
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
                          YcProductPlugin().queryCollectDataBasicInfo(DeviceCollectDataType.ecg).then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              EasyLoading.showSuccess(_items[index]);
                              final info = value?.data ;
                              setState(() {
                                _displayedText = info.toString();
                              });
                            } else {
                              EasyLoading.showError("${_items[index]} failed");
                            }
                          });


                        case 1:
                          YcProductPlugin().queryCollectDataInfo(DeviceCollectDataType.ecg, 0).then((value) {
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
                          YcProductPlugin().deleteCollectData(DeviceCollectDataType.ecg, 0).then((value) {
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
