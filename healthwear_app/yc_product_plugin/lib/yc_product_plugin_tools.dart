
import 'dart:ui';
import 'package:flutter/foundation.dart';


/// 工具类
class YcProductPluginTools {

   static void test() {
     debugPrint("Hello");
   }


   /// 普通RGB颜色转换为RGB565
   static int colorToRGB565(Color color) {
     int red = (color.red >> 3) & 0x1F;
     int green = (color.green >> 2) & 0x3F;
     int blue = (color.blue >> 3) & 0x1F;

     return (red << 11) | (green << 5) | blue;
   }

}

