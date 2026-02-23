import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'dart:async';

import 'package:yc_product_plugin_example/ecg/charts/ecg_charts.dart';
import 'package:yc_product_plugin_example/ecg/charts/ecg_result.dart';
import 'package:yc_product_plugin_example/ecg/charts/image_compostion_screen.dart';

/**
 * 绘制背景格子
 *  粗线条 颜色、和细线条格子
 *
 */

class EcgDataWidget extends StatefulWidget {
  const EcgDataWidget({super.key});

  @override
  State<EcgDataWidget> createState() => _EcgDataWidgetState();
}

class _EcgDataWidgetState extends State<EcgDataWidget> {
  String _displayedText = "Result";

  // 定时器相关
  bool _timerStarted = false;
  Timer? _timer;
  int _remainingSeconds = 60;
  List datas = [];
  List ecgOriDatas = [];
  List ecgDatas = [];
  Timer? _ecgTimer;
  int index = 0;
  int currECGDataIndex = 0;
  String startEcgButtonText = "Start ECG";

  String heartValue = "--";
  String bloodPressureValue = "--/--";
  String hrvValue = "--";

  Timer? _imageTimer;
  List<FileSystemEntity>? _imageFiles;

  GlobalKey _globalKey = GlobalKey();
  String folderName = "3";

  double deviceWidth = 0;
  double deviceHeight = 0;

  bool ecgStatus = false; // 电极状态

  @override
  void initState() {
    super.initState();

    //250HZ
    int ms = (1.0 / 450.0) * 1000 ~/ 1;

    _ecgTimer ??= Timer.periodic(Duration(milliseconds: ms), (timer) {
      if (mounted) {
        setState(() {
          //datas.add(1.8341000080108643);
          // print("111");
          _addPoint();
        });
      }
    });

    YcProductPlugin().setDeviceWearingPosition(DeviceWearingPositionType.left);

    YcProductPlugin().onListening((event) {
      final ecgData = event[NativeEventType.deviceRealECGFilteredData];
      if (ecgData != null) {
        // debugPrint("实时ECG: ${ecgData.toString()}");
        ecgOriDatas.addAll(ecgData);
        datas.addAll(ecgData);
      }

      // final ppgData = event[NativeEventType.deviceRealECGData];
      // if (ppgData != null) {
      //   debugPrint("实时PPG: ${ppgData.toString()}");
      // }

      final bloodMap = event[NativeEventType.deviceRealBloodPressure];

      if (bloodMap != null) {
        debugPrint("实时血压: ${bloodMap.toString()}");
        setState(() {
          _displayedText = bloodMap.toString();

          heartValue = "${bloodMap["heartRate"]}";
          bloodPressureValue =
              "${bloodMap["systolicBloodPressure"]}/${bloodMap["diastolicBloodPressure"]}";
        });
        // final hrv =
        //     event[NativeEventType.deviceRealECGAlgorithmHRV];

        // debugPrint("实时HRV: ${hrv.toString()}");
        // if (hrv != 0) {
        //  debugPrint("实时HRV: ${hrv.toString()}");
        //    hrvValue = hrv.toString();
        // }
      }

      if (event.keys.contains(NativeEventType.deviceRealECGAlgorithmHRV)) {
        /// 一键测量hrv数据
        debugPrint(" 实时HRV=>$event");
        setState(() {
          hrvValue =
              (event[NativeEventType.deviceRealECGAlgorithmHRV] ?? 0) == 0
                  ? "--"
                  : event[NativeEventType.deviceRealECGAlgorithmHRV].toString();
        });

        // debugPrint(" 一键测量HRV数据=>$value");
      }

      if (event.keys.contains(NativeEventType.deviceEndECG)) {
        debugPrint("结束测量ECG=>$event"); //ECG的数据检测

       setState(() {
        _timer?.cancel();
        _timer = null;
        _imageTimer?.cancel();
        _imageTimer = null;
        _timerStarted = false;
        ecgStatus = false;
        _remainingSeconds = 60;

        startEcgButtonText = "Start ECG";

       });
       
        

        // 返回上一页
        // Navigator.pop(context, '');
      }

      if (event.keys.contains(NativeEventType.appECGPPGStatus)) {
        debugPrint("电极佩戴状态=>$event"); //ECG的数据检测
        setState(() {
          // 检查 event[NativeEventType.appECGPPGStatus] 是否为 Null
        Map<dynamic, dynamic>? value =
            event[NativeEventType.appECGPPGStatus] as Map<dynamic, dynamic>?;
        if (value != null) {
          ecgStatus =
              (num.parse(value["EcgStatus"].toString()) == 0
                  ? true
                  : false); //结束实时数据
        }
      });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _ecgTimer?.cancel();
    _ecgTimer = null;

    _timer?.cancel();
    _timer = null;

    _imageTimer?.cancel();
    _imageTimer = null;

    YcProductPlugin().stopECGMeasurement().then((value) {});
  }

  void _addPoint() {
    if (index < datas.length) {
      currECGDataIndex++;
      if (currECGDataIndex % 3 == 0 && index + 2 < datas.length) {
        double ecgData =
            (datas[index] + datas[index - 1] + datas[index - 2]) / 3;
        ecgDatas.add(ecgData);
        currECGDataIndex = 0;
      }
      index++;
      if (ecgDatas.length > deviceWidth.toInt()) {
        ecgDatas = ecgDatas.sublist(ecgDatas.length - deviceWidth.toInt());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      deviceWidth = MediaQuery.of(context).size.width;
      deviceHeight = MediaQuery.of(context).size.height;
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text("ECG"),
      ),
      body: SingleChildScrollView(
          child: Container(height: deviceHeight * 0.8, child: getBody())),
    );
  }

  Widget getBody2() {
    final Size screenSize = MediaQuery.of(context).size;

    final double screenWidthInMm = screenSize.width * 25.4; // 屏幕宽度（英寸）转换为毫米
    final double screenHeightInMm = screenSize.height * 25.4; // 屏幕高度（英寸）转换为毫米
    final double screenWidthInPixel = screenSize.width;
    final double screenHeightInPixel = screenSize.height;
    final double mmToPixelRatioWidth =
        screenWidthInPixel / screenWidthInMm; // 每毫米对应的像素值（宽度）
    final double mmToPixelRatioHeight =
        screenHeightInPixel / screenHeightInMm; // 每毫米对应的像素值（高度）

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Screen Width: ${screenSize.width.toStringAsFixed(2)} pixels'),
        Text('Screen Height: ${screenSize.height.toStringAsFixed(2)} pixels'),
        const SizedBox(height: 10),
        Text('Screen Width: ${screenWidthInMm.toStringAsFixed(2)} mm'),
        Text('Screen Height: ${screenHeightInMm.toStringAsFixed(2)} mm'),
        const SizedBox(height: 10),
        Text(
            '1mm corresponds to ${mmToPixelRatioWidth.toStringAsFixed(2)} pixels (width)'),
        Text(
            '1mm corresponds to ${mmToPixelRatioHeight.toStringAsFixed(2)} pixels (height)'),
      ],
    );
  }

  /// 旧代码
  Widget getBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                // padding: const EdgeInsets.symmetric(horizontal: 70.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          heartValue,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "bpm",
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          bloodPressureValue,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "mmHg",
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          hrvValue,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "HRV",
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
          ),
          Expanded(
            flex: 3,
            child: Container(
                padding: EdgeInsets.zero,
                child: RepaintBoundary(
                  key: _globalKey,
                  child: CustomPaint(
                    size: Size(deviceWidth, deviceHeight * 0.8),
                    painter: ECGPainter(datas: ecgDatas),
                  ),
                )),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                SizedBox(height: 15), // 添加上边距
                Text(
                _timerStarted ? "电极佩戴状态: ${ecgStatus ? "正常" : "脱落"}" : "",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: ecgStatus ? Colors.green : Colors.red,
                  ),
                ),

                SizedBox(height: 15), // 添加上边距
                TextButton(
                  onPressed: () {
                    _timer?.cancel();

                    YcProductPlugin().startECGMeasurement().then((value) {
                      if (value?.statusCode == PluginState.succeed) {
                        EasyLoading.showSuccess("");
                        // final info = value?.data ;
                        // setState(() {
                        //   _displayedText = info.toString();
                        // });
                        _startTimer();
                      } else {
                        EasyLoading.showError("ECG failed");
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue, // 背景颜色
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 圆角半径
                    ),
                    padding: EdgeInsets.symmetric(
                        vertical: 16, horizontal: 102), // 内边距
                  ),
                  child: Text(
                    startEcgButtonText,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                //  getBody2(),
                //Container( padding: EdgeInsets.all(8),child: ECGChart(datas: datas),),
              ],
            ),
          ),

          // Container(
          //   height: 138,
          //   child: ImageCompositionScreen(folderName:folderName),
          // ),
          // _imageFiles == null
          //           ? Center(child: CircularProgressIndicator())
          //           : _imageFiles!.isEmpty
          //               ? Center(child: Text('No images found.'))
          //               : Expanded(
          //                 flex: 3,
          //                 child: GridView.builder(
          //                     gridDelegate:
          //                         SliverGridDelegateWithFixedCrossAxisCount(
          //                       crossAxisCount: 2,
          //                       childAspectRatio: 1,
          //                     ),
          //                     itemCount: 1,
          //                     itemBuilder: (context, index) {
          //                       return Image.file(
          //                         File(_imageFiles![index].path),
          //                         fit: BoxFit.cover,
          //                       );
          //                     },
          //                   ),
          //               ),
        ],
      ),
    );
  }

  void _startTimer() {
    //  Navigator.push(
    //           context,
    //           MaterialPageRoute(builder: (context) => EcgResult(ecgDatas: ecgOriDatas,)),
    //         );
    //         return;
    restore();


    final Random _random = Random();
    folderName = _random.nextInt(1000000000).toString();

    //2.5秒截一张图片
    _imageTimer ??= Timer.periodic(Duration(milliseconds: 2500), (timer) {
      _capturePng(folderName);
    });

    _timerStarted = true;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          startEcgButtonText = _remainingSeconds.toString();
        } else {
          _timer?.cancel();
          _imageTimer?.cancel();
          _timer = null;
          _timerStarted = false;
          _remainingSeconds = 60;

          // index = 0;
          // currECGDataIndex = 0;

          startEcgButtonText = "Start ECG";


          // Navigator.pop(context, '');

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EcgResult(
                      ecgDatas: ecgOriDatas,
                      folderName: folderName,
                    )),
          );


          // 停止测量
          YcProductPlugin().stopECGMeasurement().then((value) {
            //YcProductPlugin().getECGResult().then((value) {
            //PluginResponse info = value as PluginResponse;
            // print(info.data.toString());
            // heartValue = info.data["heartRate"];
            // bloodPressureValue = "${info.data["systolicBloodPressure"]}/${info.data["diastolicBloodPressure"]}";
            // _displayedText = info.data.toString();
            //});
          });
        }
      });
    });
  }

  void restore() {
    setState(() {
      heartValue = "--";
      bloodPressureValue = "--/--";
      hrvValue = "--";
      ecgDatas = [];
      datas = [];
      ecgOriDatas = [];

       _timer?.cancel();
      _timer = null;
      _imageTimer?.cancel();
      _imageTimer = null;
      _timerStarted = false;
      ecgStatus = false;
      _remainingSeconds = 60;

      index = 0;
      currECGDataIndex = 0;

      startEcgButtonText = "Start ECG";
    });
  }

  Future<void> _capturePng(String folderName) async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 获取保存路径
      final directory = await getApplicationDocumentsDirectory();
      final newDir = Directory('${directory.path}/ecgImages/$folderName');
      // 检查目录是否存在
      if (await newDir.exists()) {
      } else {
        // 创建目录
        await newDir.create(recursive: true);
      }

      final imagePath =
          File('${newDir.path}/${DateTime.now().millisecondsSinceEpoch}.png');

      await imagePath.writeAsBytes(pngBytes);
      print("存了一张:${imagePath.path}");
    } catch (e) {
      print(e);
    }
  }
}
