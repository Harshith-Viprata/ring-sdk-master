import 'package:flutter/material.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info/device_info.dart';


class SearchDeviceWiget extends StatefulWidget {
  const SearchDeviceWiget({super.key});

  @override
  State<SearchDeviceWiget> createState() => _SearchDeviceWigetState();
}

class _SearchDeviceWigetState extends State<SearchDeviceWiget> {
  List<BluetoothDevice> _devices = <BluetoothDevice>[];


  @override
  void initState() {
    YcProductPlugin().getBluetoothState().then((value) {
                if (value != BluetoothState.disconnected) {
                  YcProductPlugin().disconnectDevice();
  
                }
              YcProductPlugin().setReconnectEnabled(isReconnectEnable: false);
              YcProductPlugin().resetBond();
              });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Devices',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () {

              EasyLoading.show(status:'Searching');

              requestNearDevicePermission(context).then((value) {
                if (value == true) {
                  // 搜索设备
                  YcProductPlugin()
                      .scanDevice(time: 3)
                      .then((devices) {
                    // debugPrint("=== 设备 $devices");

                    setState(() {
                      devices?.sort((a, b) =>  (b?.rssiValue.toInt() ?? 0) - (a?.rssiValue.toInt() ?? 0));
                      _devices = devices ?? [];
                      EasyLoading.dismiss();
                    });
                  });
                }
              });


            },
            icon: const Icon(
              Icons.refresh,
              size: 36.0,
            ),
          ),
        ],
      ),
      body: ListView.separated(
          itemCount: _devices.length,
          separatorBuilder: (BuildContext context, int index) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Divider(
                thickness: 0.5,
                color: Colors.grey,
              ),
            );
          },
          itemBuilder: (BuildContext context, int index) {
            var item = _devices[index];
            return InkWell(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(item.macAddress),
                trailing: Text(item.rssiValue.toString()),
              ),
              onTap: () {
                EasyLoading.show(status: "Connecting ${item.name}");
                YcProductPlugin().connectDevice(item).then((value) {

                  if (value == true) {
                    Navigator.pop(context);
                    EasyLoading.showSuccess("Connected");

                  } else {
                    debugPrint("连接失败");
                    EasyLoading.showError("Connect failed");
                  }
                });
              },
            );
          }),
    );
  }

  static Future<bool> requestNearDevicePermission(BuildContext context,
      {Function? confirm, Function? cancel}) async {
    if (Platform.isAndroid) {
      // PermissionStatus status = await Permission.bluetooth.status;
      PermissionStatus status = await Permission.bluetoothScan.status;
      PermissionStatus status1 = await Permission.bluetoothConnect.status;

      PermissionStatus loctionStatus =
      await Permission.locationWhenInUse.status;


      bool isPermission = false;
      //String androidVersion = androidInfo.version.release;
      bool isAndroidVersionGreaterThan12 =  await getNearVersion();//androidVersion.compareTo('12') > 0;
      if (isAndroidVersionGreaterThan12) {
        isPermission = status.isGranted && status1.isGranted;
      } else {
        isPermission = loctionStatus.isGranted;
      }
      if (isPermission) {
        return true;
      } else {
        // if (YCLocalDataTools.instance.getPermissionNear() == true) {
        //   if (isAndroidVersionGreaterThan12) {
        //     showToast("permission_content_android12".tr);
        //   }
        //   return false;
        // }
        if(!isAndroidVersionGreaterThan12){
          return false;
        }

        // ignore: use_build_context_synchronously
        alert(context,
            title: "permission_prompt_android12",
            content: "permission_content_android12", confirm: () async {
              if (confirm != null) {
                confirm();
              }
              //  await _openAndroidSettings();
              openAppSettings();
            }, cancle: () {
              if (cancel != null) {
                cancel();
              }
              //华为审核：用户拒绝了位置请求后，不允许在去申请权限
           //   YCLocalDataTools.instance.saveUserPermissionNear(true);
            });
        return false;
      }
    }
    return true;
  }

  static Future<bool> getNearVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    bool isAndroidVersionGreaterThan12 = androidInfo.version.sdkInt >= 31;
    return isAndroidVersionGreaterThan12;
  }

  static alert(
      BuildContext context, {
        String title = "",
        String content = "",
        String confirmTitle = "",
        String calcelTitle = "",
        GestureTapCallback? confirm,
        GestureTapCallback? cancle,
        bool? confirmBackToPage = false,
        List<Widget>? actions, // 自定义按钮
        bool? showCancel = true,
        bool barrierDismissible = true,
      }) {
    if (title.isEmpty) title = "public_tip";

    if (confirmTitle.isEmpty) confirmTitle = "public_sure";

    if (calcelTitle.isEmpty) calcelTitle = "public_cancel";
    showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) {
          return AppDialog(
            title: title,
            content: content,
            confirm: confirmTitle,
            cancel: calcelTitle,
            confirmAction: confirm,
            cancelAction: cancle,
            confirmBackToPage: confirmBackToPage,
            showCancel: showCancel,
          );

        });
  }
}

class AppDialog extends Dialog {
  final String title;
  final String? confirm;
  final String? cancel;
  final String? content;
  final String? cancelColor;
  final String? confirmColor;
  final bool? showCancel;
  //final OnDialogClickListener? clickListener;
  final GestureTapCallback? confirmAction;
  final GestureTapCallback? cancelAction;
  final bool? confirmBackToPage;

  const AppDialog(
      {this.cancelColor = '#00000',
        this.confirmColor = '#576B95',
        this.title = 'title',
        this.cancel = 'cancel',
        this.confirm = 'confirm',
        this.content = '',
        this.showCancel = true,
        this.confirmAction,
        this.cancelAction,
        this.confirmBackToPage = false,
        Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        width: double.infinity,
        margin: const EdgeInsets.all(30),
        decoration: const ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0)))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Offstage(
              offstage: content!.isEmpty,
              child: Container(
                margin: const EdgeInsets.only(bottom: 17),
                padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                child: Text(
                  textAlign: TextAlign.center,
                  content!,
                  style: TextStyle(
                      fontSize: 17, color: Color.fromARGB(255, 127, 127, 127)),
                ),
              ),
            ),
            Container(
              height: 0.7,
              color: Color.fromARGB(255, 232, 232, 232),
            ),
            getBottomWidget(context),
          ],
        ),
      ),
    );
  }

  getBottomWidget(context) {
    if (showCancel!) {
      return SizedBox(
        height: 64,
        child: Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      alignment: Alignment.center,
                      child: Text(
                        // 'public_cancel'.tr,
                        cancel ?? 'public_cancel',
                        style: TextStyle(
                            fontSize: (cancel ?? 'public_cancel').length > 15
                                ? 13
                                : 17,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  //clickListener?.onCancel(),
                  if (cancelAction != null) {
                    cancelAction!();
                  }

                  Navigator.of(context).pop();
                },
              ),
            ),
            Container(
              height: 43,
              width: 0.7,
              color: Color.fromARGB(255, 232, 232, 232),
            ),
            Expanded(
              child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      alignment: Alignment.center,
                      child: Text(
                        confirm ?? "public_sure",
                        style: TextStyle(
                            fontSize: (confirm ?? "public_sure").length > 15
                                ? 13
                                : 17,
                            color: Color.fromARGB(255, 81, 177, 196),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (confirmAction != null) {
                    //Future.delayed(const Duration(milliseconds: 10), () {
                    confirmAction!();
                    //});
                  }
                  if (confirmBackToPage == false) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return InkWell(
        child: Container(
          height: 43,
          alignment: Alignment.center,
          child: Text(
            confirm!,
            style: TextStyle(
                fontSize: 17,
                color:Color.fromARGB(255, 81, 177, 196),
                fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          if (confirmAction != null) {
            confirmAction!();
          }
          Navigator.of(context).pop();
        },
      );
    }
  }
}
