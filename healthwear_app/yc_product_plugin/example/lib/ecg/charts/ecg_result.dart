import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import 'package:yc_product_plugin_example/ecg/charts/ecg_charts.dart';
import 'package:yc_product_plugin_example/ecg/charts/image_compostion_big_screen.dart';
import 'package:yc_product_plugin_example/ecg/charts/ecg_result.dart';
import 'package:yc_product_plugin_example/ecg/charts/image_compostion_screen.dart';


class EcgResult extends StatefulWidget {
  final List ecgDatas;
  final folderName;
  const EcgResult(
      {required this.ecgDatas, required this.folderName, super.key});

  @override
  State<EcgResult> createState() => _EcgResultState();
}

class _EcgResultState extends State<EcgResult> {
  Timer? _ecgTimer;
  int index = 0;
  int currECGDataIndex = 0;
  List ecgDatas = [];

  double deviceWidth = 0;
  double deviceHeight = 0;

  String ecgResult = "正常心电图";
  String ecgInfo = "详情：QRS波形形态时限振幅正常，P-R间期正常，ST-T无改变，Q-T间期正常。";

  DeviceECGResult ecgData = DeviceECGResult();
  double hrv = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    debugPrint("=====>${widget.folderName}");

    YcProductPlugin().getECGResult().then((value) {
      PluginResponse info = value as PluginResponse;
      ecgData = info.data;
      setState(() {
        ecgData = info.data;
      });
    
      print("ECGAI诊断结果："+ecgData.toString());
      
      if (ecgData.afFlag) {
        ecgResult = "疑似心房颤动";
        ecgInfo = "QRS波形正常，正常P波消失，出现f波，R-R间距不规则。";
      } else {
        if (ecgData.qrsType == 5) {
          ecgResult = "房性早搏";
          ecgInfo = "QRS-T波形宽大变形，QRS波形前无相关P波，QRS时限 > 0.12秒，T波方向与主波相反，完全性代偿间歇。";
        } else if (ecgData.qrsType == 9){
          ecgResult = "房性早搏";
          ecgInfo = "QRS波形正常，变异P波提前出现，P-R > 0.12秒，代偿间歇不完全。";
        } else if (ecgData.hearRate >= 0 && ecgData.hearRate <= 50){
          ecgResult = "疑似心动过缓";
          ecgInfo = "QRS波形正常，R-R间距偏长。";
        } else if (ecgData.hearRate > 120){
          ecgResult = "疑似心动过快";
          ecgInfo = "QRS波形正常，R-R间距偏短。";
        } else if (hrv >= 125){
          ecgResult = "疑似窦性心律不齐";
            ecgInfo = "QRS波形正常，R-R间距变化偏大。";
        } else if (ecgData.qrsType == 1){
          ecgResult = "正常心电图";
          ecgInfo = "QRS波形形态时限振幅正常，P-R间期正常，ST-T无改变，Q-T间期正常。";
        } 
      }

      // print(info.data.toString());
      // heartValue = info.data["heartRate"];
      // bloodPressureValue = "${info.data["systolicBloodPressure"]}/${info.data["diastolicBloodPressure"]}";
      // _displayedText = info.data.toString();
    });

    //250HZ
    int ms = (1.0 / 340.0) * 1000 ~/ 1;

    _ecgTimer ??= Timer.periodic(Duration(milliseconds: ms), (timer) {
      if (mounted) {
        setState(() {
          //datas.add(1.8341000080108643);
          // print("111");
          _addPoint();
        });
      }
    });
  }

void _addPoint() {
  if (index < widget.ecgDatas.length) {
    currECGDataIndex++;
    
    // 检查是否能够安全地计算三个数据点的平均值
    if (currECGDataIndex % 3 == 0 && index + 2 < widget.ecgDatas.length) {
      double ecgData = (widget.ecgDatas[index] +
                        widget.ecgDatas[index + 1] +
                        widget.ecgDatas[index + 2]) / 3;
      ecgDatas.add(ecgData);
      currECGDataIndex = 0;
    }
    index++;  
    // 确保 ecgDatas 不会超过设备宽度
    if (ecgDatas.length > deviceWidth.toInt()) {
      ecgDatas = ecgDatas.sublist(ecgDatas.length - deviceWidth.toInt());
    } 
  }
}


  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text("心电图AI辅诊报告"),
      ),
      body: getBody(),
    );
  }

  Widget getBody() {
    return SingleChildScrollView(
      child: Container(
        height: 2000,
        child: Column(
          children: [
            Container(
                height: 300,
                padding: EdgeInsets.zero,
                child: CustomPaint(
                  size: Size(deviceWidth, deviceHeight * 0.8),
                  painter: ECGPainter(datas: ecgDatas),
                )),
              Container(
                child: Column(
                  children: [
                    Text("诊断结果"),
                    Text(ecgResult),
                    Text(ecgInfo),
                    if (ecgData.heavyLoad != null) Text("负荷指数: ${ecgData.heavyLoad}"),
                    if (ecgData.hrvNorm != null) Text("HRV指数: ${ecgData.hrvNorm}"),
                    if (ecgData.pressure != null) Text("压力指数: ${ecgData.pressure}"),
                    if (ecgData.body != null) Text("身体指数: ${ecgData.body}"),
                    if (ecgData.sympatheticActivityIndex != null) Text("交感神经和副交感神经活跃指数: ${ecgData.sympatheticActivityIndex}"),
                    if (ecgData.respiratoryRate != null) Text("呼吸率: ${ecgData.respiratoryRate}"),
                  ],
                ),
              ),

            GestureDetector(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (context) => ImageCompositionBigScreen(
                //           folderName: widget.folderName)),
                // );
              },
              child: Container(
                height: 138,
                child: ImageCompositionScreen(folderName: widget.folderName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
