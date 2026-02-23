import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

/// JL音频录音测试页面（适配现有YcProductPlugin监听逻辑）
class RecordTestPage extends StatefulWidget {
  const RecordTestPage({super.key});

  @override
  State<RecordTestPage> createState() => _RecordTestPageState();
}

class _RecordTestPageState extends State<RecordTestPage> {
  // 状态变量
  String _recordStatus = "就绪"; // 录音状态
  bool _startButtonEnabled = true; // 开始按钮是否可用
  bool _stopButtonEnabled = false; // 停止按钮是否可用
  String _recordResult = ""; // 录音结果文本

  // 原生通信通道（仅用于调用方法，监听用现有onListening）
  static const MethodChannel _channel =
      MethodChannel('yc_product_sdk/jl_audio');

  @override
  void initState() {
    super.initState();

    // 2. 注册杰理音频事件监听（复用项目现有监听体系）
    _registerJLAudioListener();
  }

  /// 注册杰理音频事件监听（核心：复用YcProductPlugin的onListening）
  void _registerJLAudioListener() {
    // 复用你项目现有监听逻辑
    YcProductPlugin().onListening((event) {
      debugPrint("--JL Audio Event -- ${event.toString()}");

      // ========== 1. 处理录音状态变化事件 ==========
      if (event.keys.contains(NativeEventType.deviceJLAudioState)) {
        // 获取状态字符串（对应原生的state值）
        final String state = event[NativeEventType.deviceJLAudioState] ?? "未知";

        setState(() {
          _recordStatus = "状态: $state";
          // 根据状态更新按钮可用性
          switch (state) {
            case "空闲":
              _startButtonEnabled = true;
              _stopButtonEnabled = false;
              break;
            case "录音中":
              _startButtonEnabled = false;
              _stopButtonEnabled = true;
              break;
            case "已完成":
            case "失败":
              _startButtonEnabled = true;
              _stopButtonEnabled = false;
              break;
            default:
              break;
          }
        });
      }

      // ========== 2. 处理录音结果完成事件 ==========
      if (event.keys.contains(NativeEventType.deviceJLAudioComplete)) {
        // 获取结果字典（对应原生的userInfo）
        final Map? resultMap = event[NativeEventType.deviceJLAudioComplete];
        if (resultMap != null) {
          setState(() {
            final text = resultMap['text'] ?? "无识别结果";
            final wavPath = resultMap['wavFilePath'] ?? "无WAV路径";
            final opusPath = resultMap['opusFilePath'] ?? "无OPUS路径";
            final isDeviceInitiated = resultMap['isDeviceInitiated'] ?? false;
            final error = resultMap['error'];

            _recordResult = """
识别结果: $text
WAV路径: $wavPath
OPUS路径: $opusPath
是否设备触发: ${isDeviceInitiated ? "是" : "否"}
${error != null ? "错误信息: $error" : ""}
""";
          });
        }
      }
    });
  }

  /// 开始录音
  Future<void> _startRecording() async {
    try {
      YcProductPlugin().startSpeechRecognition();
    } on PlatformException catch (e) {
      _showAlert("开始录音失败：${e.message}");
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    try {
      YcProductPlugin().stopSpeechRecognition();
    } on PlatformException catch (e) {
      _showAlert("停止录音失败：${e.message}");
    }
  }

  /// 显示提示弹窗
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("提示"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("录音测试"),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // 状态标签
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  _recordStatus,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              // 开始/停止按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 开始按钮
                  SizedBox(
                    width: 150,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _startButtonEnabled ? _startRecording : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "开始录音",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  // 停止按钮
                  SizedBox(
                    width: 150,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _stopButtonEnabled ? _stopRecording : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "停止录音",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 结果文本框
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Text(
                      _recordResult,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
