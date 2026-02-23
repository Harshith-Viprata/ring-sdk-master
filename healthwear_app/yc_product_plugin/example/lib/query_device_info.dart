import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

class QueryDeviceInfoWidget extends StatefulWidget {
  const QueryDeviceInfoWidget({super.key});

  @override
  State<QueryDeviceInfoWidget> createState() => _QueryDeviceInfoWidgetState();
}

class _QueryDeviceInfoWidgetState extends State<QueryDeviceInfoWidget> {
  String _displayedText = "Result";

  final _items = [
    "Basic info",
    "Mac Address",
    "Device model",
    "Mcu",
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
            flex: 2,
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
                          YcProductPlugin().queryDeviceBasicInfo().then((value) {

                            if (value?.statusCode == PluginState.succeed) {

                              EasyLoading.showSuccess("");
                              final info = value?.data ;
                              setState(() {
                                _displayedText = info.toString();
                              });
                            } else {
                              EasyLoading.showError("Not support");
                            }

                          },);

                        case 1:
                          YcProductPlugin()
                              .queryDeviceMacAddress()
                              .then((value) {

                            if (value?.statusCode == PluginState.succeed) {

                              EasyLoading.showSuccess("");
                              final macAddress = value?.data ?? "";
                              setState(() {
                                _displayedText = macAddress;
                              });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });


                        case 2:
                          YcProductPlugin().queryDeviceModel().then((value) {
                            if (value?.statusCode == PluginState.succeed) {
                              final model = value?.data ?? "";

                              EasyLoading.showSuccess("");
                              setState(() {
                                _displayedText = model;
                              });
                            } else {
                              EasyLoading.showError("Not support");
                            }
                          });

                        case 3:
                          YcProductPlugin().queryDeviceMCU().then((value) {
                            if (value?.statusCode == PluginState.succeed) {

                              EasyLoading.showSuccess("");
                              final mcu =
                                  value?.data ?? DeviceMcuPlatform.nrf52832;
                              setState(() {
                                _displayedText = mcu.toString();
                              });
                            } else {
                              EasyLoading.showError("Not support");
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
