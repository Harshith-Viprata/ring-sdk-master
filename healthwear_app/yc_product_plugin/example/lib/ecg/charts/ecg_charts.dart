import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ECGChart extends StatefulWidget {
  final List datas;
  ECGChart({required this.datas});

  @override
  State<ECGChart> createState() => _ECGChartState();
}

class _ECGChartState extends State<ECGChart> {
  List ecgDatas = [];
  Timer? timer;
  int index = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //ecgDatas = widget.datas;

    timer ??= Timer.periodic(Duration(milliseconds: 1), (Timer t) {
      setState(() {
        _addPoint();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _addPoint() {
    if (index < widget.datas.length) {
      ecgDatas.add(widget.datas[index]);
      index++;

      if (ecgDatas.length > 300) {
        ecgDatas = ecgDatas.sublist(ecgDatas.length - 300);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(340, 340),
      painter: ECGPainter(datas: ecgDatas),
    );
  }
}

class ECGPainter extends CustomPainter {
  final List datas;

  ECGPainter({required this.datas});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final gridPaint = Paint()
      ..color = Color.fromARGB(255, 229, 229, 229)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final blodGridPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final greyGridPaint = Paint()
      ..color = Color.fromARGB(255, 209, 209, 209)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw grid
    final double gridSpacing = 5.0;
    for (double y = 0; y < size.height + 1; y += gridSpacing) {
      if(y%25 == 0){
         canvas.drawLine(Offset(0, y), Offset(size.width, y), greyGridPaint);
      }else{
         canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    for (double x = 0; x < size.width + 1; x += gridSpacing) {
      if (x % 25 == 0) {
        if (x % 100 == 0) {
          canvas.drawLine(
              Offset(x, 0), Offset(x, size.height), blodGridPaint); //五格粗一点
        } else {
          canvas.drawLine(
              Offset(x, 0), Offset(x, size.height), greyGridPaint); //五格粗一点
        }
      } else {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }
    
     
    }

    // Draw ECG curve
    final path = Path();
    final List<Offset> points = [];
    final double frequency = 0.1;
    final double amplitude = 50;

    List list = datas;
    // print(datas.length);
    for (int x = 0; x < datas.length; x += 1) {
      double y = 180 - (double.parse(list[x].toString()) * 0.001);
      // debugPrint("x:$x,y:$y");
      if(y > 210) {
        y  = 210;
      }
      if(y < 150) {
        y  = 150;
      }
      points.add(Offset(x / 1, y));
    }

    path.addPolygon(points, false);
    canvas.drawPath(path, paint);
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
