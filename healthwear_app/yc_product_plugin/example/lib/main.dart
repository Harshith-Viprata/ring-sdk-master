import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'package:yc_product_plugin_example/app_control_devcie.dart';
import 'package:yc_product_plugin_example/device_control.dart';
import 'package:yc_product_plugin_example/ecg_data.dart';
import 'package:yc_product_plugin_example/get_log.dart';
import 'package:yc_product_plugin_example/health_data.dart';
import 'package:yc_product_plugin_example/jlvideo.dart';
import 'package:yc_product_plugin_example/ota_device.dart';
import 'package:yc_product_plugin_example/query_device_info.dart';
import 'package:yc_product_plugin_example/setting_device_info.dart';
import 'package:yc_product_plugin_example/collect_data.dart';
import 'package:yc_product_plugin_example/test_page.dart';
import 'package:yc_product_plugin_example/watch_face_device.dart';
import 'search_device.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'test_page.dart';

void main() {
  runApp(const MyApp());
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _st = 0;

  @override
  void initState() {
    super.initState();

    // init plugin
    YcProductPlugin().initPlugin(isReconnectEnable: true, isLogEnable: true);

    // ble state change
    YcProductPlugin().onListening((event) {
      if (event.keys.contains(NativeEventType.bluetoothStateChange)) {
        final int st = event[NativeEventType.bluetoothStateChange];
        debugPrint('蓝牙状态变化 $st');
        debugPrint(YcProductPlugin()
            .connectedDevice
            ?.deviceFeature
            ?.isSupportBloodPressure
            .toString());
        setState(() {
          _st = st;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(bleState: _st),
      builder: EasyLoading.init(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.bleState});

  final int bleState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        actions: [
          IconButton(
            onPressed: () {
              YcProductPlugin().getBluetoothState().then((value) {
                if (value == BluetoothState.connected) {
                  YcProductPlugin().disconnectDevice();
                  // return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SearchDeviceWiget()),
                );
              });
            },
            icon: const Icon(
              Icons.search,
              size: 36.0,
            ),
          ),
        ],
      ),
      body: setupChild(context),
    );
  }

  /// 设置子组件
  Widget setupChild(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    double screenHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        kToolbarHeight;

    if (bleState == BluetoothState.connected) {
      final items = [
        "Disconnect device",
        "Health data",
        "Query",
        "Setting",
        "App control",
        "Device control",
        "ECG",
        "OtaDeviceWidget",
        "Collection data",
        "Watch face",
        "Log",
        "Test",
        "jlvideo",
      ];

      return Container(
        // margin: EdgeInsets.zero,
        // padding: EdgeInsets.zero,
        width: double.infinity,
        // color: Colors.orange,
        height: screenHeight,
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              splashColor: Colors.grey,
              onTap: () {
                switch (index) {
                  case 0:
                    YcProductPlugin().disconnectDevice().then((value) {});

                  case 1:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HealthDataWidget()),
                    );

                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const QueryDeviceInfoWidget()),
                    );

                  case 3:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingDeviceWidget()),
                    );

                  case 4:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AppControlWidget()),
                    );

                  case 5:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DeviceControlWidget()),
                    );

                  case 6:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EcgDataWidget()),
                    );

                  case 7:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OtaDeviceWidget()),
                    );

                  case 8:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CollectDataWidget()),
                    );

                  case 9:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WatchFaceWidget()),
                    );
                  case 10:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GetLogPage()),
                    );
                  case 11:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TestWidget()),
                    );
                  case 12:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RecordTestPage()),
                    );

                  default:
                    break;
                }
              },
              child: ListTile(
                title: Text(
                  "${index + 1}. ${items[index]}",
                  style: const TextStyle(fontSize: 26.0),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return const Center(
        child: SizedBox(
          height: 200,
          width: 200,
          child: Text(
            'Please connect the device',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30.0),
          ),
        ),
      );
    }
  }
}
