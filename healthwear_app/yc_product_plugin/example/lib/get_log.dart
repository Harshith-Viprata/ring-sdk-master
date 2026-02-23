import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

class GetLogPage extends StatefulWidget {
  const GetLogPage({super.key});

  @override
  State<GetLogPage> createState() => _GetLogPageState();
}

class _GetLogPageState extends State<GetLogPage> {
  String filePath = "";
  bool deviceLogEnable = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Get Log'),
        ),
        body: Center(
          child: Container(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(25),
                  width: MediaQuery.of(context).size.width,
                  height: 150,
                  child: Text("路径地址:$filePath"),
                ),
                Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        PluginResponse? response = await YcProductPlugin()
                            .getLogFilePath(LoggerType.appSdkLog);
                        debugPrint(
                            "获取的文件路径:${response?.statusCode} - ${response?.data}");
                        if (response != null &&
                            response.statusCode == PluginState.succeed) {
                          if (response?.data == null) {
                            filePath = "没有数据";
                          } else {
                            setState(() {
                              filePath = response.data;
                            });
                          }
                        }
                      },
                      child: Text("获取AppSdk的日志路径"),
                    ),
                    TextButton(
                      onPressed: () async {
                        PluginResponse? response = await YcProductPlugin()
                            .getLogFilePath(LoggerType.jlDeviceLog);
                        debugPrint(
                            "获取的文件路径:${response?.statusCode} - ${response?.data}");
                        if (response != null &&
                            response.statusCode == PluginState.succeed) {
                          if (response?.data == null) {
                            filePath = "暂无数据";
                          } else {
                            setState(() {
                              filePath = response.data;
                            });
                          }
                        }else{
                          EasyLoading.showToast( "暂无数据");
                        }
                      },
                      child: Text("获取杰理设备的日志路径"),
                    ),
                    TextButton(
                      
                      onPressed: () async {
                        if(deviceLogEnable == false){
                          return;
                        }
                        PluginResponse? response = await YcProductPlugin()
                            .getLogFilePath(LoggerType.deviceLog);
                        debugPrint(
                            "获取的文件路径:${response?.statusCode} - ${response?.data}");
                        if (response != null &&
                            response.statusCode == PluginState.succeed) {
                          if (response?.data.length == 0) {
                            setState(() {
                              deviceLogEnable = false;
                              filePath = "没有数据";
                            });

                          } else {
                            setState(() {
                              deviceLogEnable = false;
                              filePath = response.data;
                            });
                          }
                        }else{
                          EasyLoading.showToast("暂无数据");
                        }
                      },
                      child: Text("获取设备的日志内容",style: TextStyle(
      color:deviceLogEnable?Colors.blue : Colors.grey, // 设置文字颜色为灰色
    ),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
