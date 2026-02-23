
import 'package:flutter/material.dart';
import 'dart:ui' as ui;


class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('1mm Grid'),
      ),
      body: Center(
        child: CustomPaint(
          painter: GridPainter(),
          size: Size(100.0, 100.0), // 设置画布大小
        ),
      ),
    );
  }
}



class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1mm在Flutter中对应的逻辑像素数
    final double oneMmInLogicalPixels = 1.0 / ui.window.devicePixelRatio;

    // 绘制格子线
    Paint linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1; // 设置线宽

    // 绘制横线
    for (double i = 0; i < size.height; i += oneMmInLogicalPixels) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // 绘制竖线
    for (double i = 0; i < size.width; i += oneMmInLogicalPixels) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}


