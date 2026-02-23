import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompositionBigScreen extends StatefulWidget {
  final String? folderName;
  const ImageCompositionBigScreen({required this.folderName, super.key});
  @override
  _ImageCompositionBigScreenState createState() =>
      _ImageCompositionBigScreenState();
}

class _ImageCompositionBigScreenState extends State<ImageCompositionBigScreen> {
  List<ui.Image> images = [];

  @override
  void initState() {
    super.initState();

    loadImages();
  }

  Future<void> loadImages() async {
    final directory = await getApplicationDocumentsDirectory();

    final newDir =
        Directory('${directory.path}/ecgImages/${widget.folderName}');
    print("===>${newDir.path}");
    // 检查目录是否存在
    if (await newDir.exists()) {
    } else {
      // 创建目录
      await newDir.create(recursive: true);
    }

    final imagesDir = Directory(
        '${directory.path}/ecgImages/${widget.folderName}'); // 假设你的图片存放在 images 文件夹里

    final imageFiles = Directory(imagesDir.path).listSync().where((file) {
      return file.path.endsWith('.png') || file.path.endsWith('.jpg');
    }).toList();
    // 过滤出文件，并按名称排序
    imageFiles.sort((a, b) {
      return a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last);
    });

    for (var file in imageFiles) {
      if (file is File && file.path.endsWith('.png')) {
        // 假设图片格式为 PNG
        final ByteData data = await file
            .readAsBytes()
            .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
        final ui.Codec codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        images.add(frameInfo.image);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("大图展示"),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            height: 450,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 3350,
                child: CustomPaint(
                  size: Size(1350, 350), // 设置画布大小
                  painter: ImagePainter(images),
                ),
              ),
            ),
          ),
        ));
  }
}

class ImagePainter extends CustomPainter {
  final List<ui.Image> images;

  ImagePainter(this.images);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    double width = size.width / 5; // 每行 5 张
    double height = size.height / 1 ; // 两行

    for (int i = 0; i < images.length; i++) {
      int row = 0;//i ~/ 1; // 行数
      int col = i % 40; // 列数

      // 计算缩放比例
      double scaleX = 0.5; width / images[i].width;
      double scaleY = 0.5; height / images[i].height;
      double scale = scaleX < scaleY ? scaleX : scaleY; // 按较小的比例缩放

      // 计算缩放后的尺寸
      double newWidth = images[i].width * scale;
      double newHeight = images[i].height * scale;

      // 计算绘制位置
      double x = col * width + (width - newWidth) / 2;
      double y = row * height + (height - newHeight) / 2;

      // 创建 Paint 对象
      Paint paint = Paint();
      canvas.drawImageRect(
          images[i],
          Rect.fromLTWH(
              0, 0, images[i].width.toDouble(), images[i].height.toDouble()),
          Rect.fromLTWH(x, y, newWidth, newHeight),
          paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
