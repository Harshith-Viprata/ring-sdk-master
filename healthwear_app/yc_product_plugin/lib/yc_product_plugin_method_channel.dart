import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import 'yc_product_plugin_platform_interface.dart';
import 'yc_product_plugin_data_type.dart';

class MethodChannelYcProductPlugin extends YcProductPluginPlatform {
  @visibleForTesting

  /// method channel
  final methodChannel =
      const MethodChannel('ycaviation.com/yc_product_plugin_method_channel');

  /// event channel
  final eventChannel =
      const EventChannel('ycaviation.com/yc_product_plugin_event_channel');

  /// 监听
  void Function(dynamic event)? onData;

  /// 订阅 - 解决  eventChannel 重复订阅的问题
  StreamSubscription? _subscription;

  // MARK: - 订阅

  /// 升级进度
  OTAProcessCallback? _otaCallback;

  /// 初始化通道
  void initChannel() {
    methodChannel.setMethodCallHandler((call) async {
      // debugPrint("原生调用 ${call.toString}");

      String method = call.method;
      dynamic arguments = call.arguments;

      switch (method) {
        case "upgradeState":
          debugPrint("ota 参数 ${arguments.toString()}");
          final info = arguments as Map;
          int code = info["code"];
          double process = double.parse(info["progress"].toString());
          String? error = info["error"];
          // if (_otaCallback != null) {
          // _otaCallback!(code, process, error);
          _otaCallback?.call(code, process, error);
        // }

        default:
          break;
      }
    });

    // eventChannel.receiveBroadcastStream().listen((event) {
    //
    // });

    // _subscription = eventChannel.receiveBroadcastStream().listen((event) {
    //
    //   if (onData != null) {
    //     onData!(event);
    //   }
    //
    //   // final eventMap = event;
    //   //
    //   // // 找手机
    //   // if (eventMap.keys.contains(NativeEventType.deviceControlFindPhoneStateChange)) {
    //   //   final int index = eventMap[NativeEventType.deviceControlFindPhoneStateChange];
    //   //   final state = DeviceControlState.values[index];
    //   //
    //   //   onData({
    //   //     NativeEventType.deviceControlFindPhoneStateChange: state,
    //   //   });
    //   //
    //   //   return;
    //   // }
    //   //
    //   // // 拍照
    //   // if (eventMap.keys.contains(NativeEventType.deviceControlPhotoStateChange)) {
    //   //   final int index = eventMap[NativeEventType.deviceControlPhotoStateChange];
    //   //   final state = DeviceControlPhotoState.values[index];
    //   //
    //   //   onData({
    //   //     NativeEventType.deviceControlFindPhoneStateChange: state,
    //   //   });
    //   //
    //   //   return;
    //   // }
    //
    // }, onError: (error) {
    //   debugPrint("出错了 ${error.toString()}");
    // });
  }

  /// 获取设备平台
  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  // MARK: - 蓝牙设备相关
  @override
  Future<void> initPlugin(
      {bool isReconnectEnable = true, bool isLogEnable = false}) async {
    // 初始化
    initChannel();

    await methodChannel
        .invokeMethod("initPlugin", [isReconnectEnable, isLogEnable]);
  }

  @override
  Future<void> setReconnectEnabled(bool isReconnectEnable) async {
    await methodChannel.invokeMethod("setReconnectEnabled", isReconnectEnable);
  }

  @override
  void cancelListening() {
    // debugPrint("===== 订阅取消 ==== ");
    _subscription?.cancel();
    _subscription = null;
  }

  /// 开启监听
  @override
  void onListening(void Function(dynamic event) onData) {
    _subscription?.cancel();

    _subscription = eventChannel.receiveBroadcastStream().listen((event) async {
      if (event is! Map) {
        return;
      }

      debugPrint("===== onListening ==== " +
          event.keys.toString() +
          "====" +
          event.values.toString());

      // 处理一下回连的问题
      if (event.keys.contains(NativeEventType.bluetoothStateChange) &&
          event.keys.contains(NativeEventType.deviceInfo)) {
        final int connectState = event[NativeEventType.bluetoothStateChange];
        debugPrint("===== onListening connectState ==== $connectState");
        if (connectState == BluetoothState.connected) {
          final deviceInfo = event[NativeEventType.deviceInfo];

          final connectedDevice = BluetoothDevice.formJson(deviceInfo);

          debugPrint("===== onListening deviceInfo ==== $deviceInfo");

          // 清空队列
          clearQueue();

          debugPrint("===== onListening getDeviceFeature");
          getDeviceFeature(device: connectedDevice);
          debugPrint("===== onListening queryDeviceMCU");
          queryDeviceMCU(device: connectedDevice);
          debugPrint("===== onListening queryDeviceModel");
          queryDeviceModel(device: connectedDevice);
          debugPrint("===== onListening end");
          // connectedDevice.deviceFeature = feature;
          // connectedDevice.mcuPlatform = mcu?.data;
          // connectedDevice.deviceModel = deviceModel?.data;

          YcProductPlugin().connectedDevice = connectedDevice;
        }
      }

      // 执行回调
      onData(event);
    });
  }

  @override
  Future<void> clearQueue() async {
    await methodChannel.invokeMethod("clearQueue");
  }

  @override
  Future<List<BluetoothDevice>?> scanDevice({int time = 6}) async {
    final devices = await methodChannel.invokeListMethod("scanDevice", time);

    if (devices?.isEmpty ?? false) {
      return [];
    }
    print("设备列表$devices");
    return List<BluetoothDevice>.generate(devices?.length ?? 0, (index) {
      return BluetoothDevice.formJson(devices?[index]);
    });
  }

  @override
  Future<void> stopScanDevice() async {
    await methodChannel.invokeMethod("stopScanDevice");
  }

  @override
  Future<void> exitScanDevice() async {
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod("exitScanDevice");
    }
  }

  @override
  Future<void> resetBond() async {
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod("resetBond");
    }
  }

  @override
  Future<bool?> connectDevice(String deviceIdentifier) async {
    return await methodChannel.invokeMethod<bool>(
        "connectDevice", deviceIdentifier);
  }

  @override
  Future<bool?> disconnectDevice({String deviceIdentifier = ""}) async {
    return await methodChannel.invokeMethod<bool>(
        "disconnectDevice", deviceIdentifier);
  }

  @override
  Future<int?> getBluetoothState() async {
    return await methodChannel.invokeMethod<int>("getBluetoothState");
  }

  /// 获得功能列表
  @override
  Future<DeviceFeature?> getDeviceFeature({BluetoothDevice? device}) async {
    try {
      final result = await methodChannel.invokeMethod("getDeviceFeature");
      final code = result?["code"];

      if (code == PluginState.succeed) {
        final map = result?["data"];
        if (device != null)
          device.deviceFeature = DeviceFeature.fromJson(map as Map);
        return DeviceFeature.fromJson(map as Map);
      }
    } catch (e) {
      print('获取设备功能失败: $e');
      // 返回默认的DeviceFeature或null
      return null;
    }
    return null;
  }

  @override
  Future<PluginResponse<List>?> queryDeviceHealthData(
      int healthDataType) async {
    final result = await methodChannel.invokeMethod(
        "queryDeviceHealthData", healthDataType);

    final code = result?["code"];

    int statusCode = code;
    List list = [];

    // 有数据才解析
    if (code == PluginState.succeed) {
      final data = result?["data"] as List;

      switch (healthDataType) {
        case HealthDataType.step:
          for (var element in data) {
            StepDataInfo info = StepDataInfo.fromJson(element as Map);
            list.add(info);
          }

        case HealthDataType.sleep:
          debugPrint("睡眠");
          for (var element in data) {
            SleepDataInfo info = SleepDataInfo.fromJson(element as Map);
            list.add(info);
          }

        // 心率
        case HealthDataType.heartRate:
          for (var element in data) {
            HeartRateDataInfo info = HeartRateDataInfo.fromJson(element as Map);
            list.add(info);
          }

        case HealthDataType.bloodPressure:
          for (var element in data) {
            BloodPressureDataInfo info =
                BloodPressureDataInfo.fromJson(element as Map);
            list.add(info);
          }

        case HealthDataType.combinedData:
          for (var element in data) {
            CombinedDataDataInfo info =
                CombinedDataDataInfo.fromJson(element as Map);
            list.add(info);
          }

        case HealthDataType.invasiveComprehensiveData:
          for (var element in data) {
            InvasiveComprehensiveDataInfo info =
                InvasiveComprehensiveDataInfo.fromJson(element as Map);
            list.add(info);
          }

        case HealthDataType.sportHistoryData:
          for (var element in data) {
            SportModeDataInfo info = SportModeDataInfo.fromJson(element as Map);
            list.add(info);
          }

        case HealthDataType.bodyIndexData:
          for (var element in data) {
            BodyIndexDataInfo info = BodyIndexDataInfo.fromJson(element);
            list.add(info);
          }
        case HealthDataType.historyWearData:
          for (var element in data) {
            HistoryWearInfo info = HistoryWearInfo.fromJson(element);
            list.add(info);
          }
      }
    }

    return PluginResponse(statusCode, list);
  }

  @override
  Future<PluginResponse?> deleteDeviceHealthData(int healthDataType) async {
    final result = await methodChannel.invokeMethod(
        "deleteDeviceHealthData", healthDataType);

    int statusCode = result?["code"];
    final data = result?["data"];

    return PluginResponse(statusCode, data);
  }

  @override
  Future<PluginResponse<DeviceBasicInfo>?> queryDeviceBasicInfo() async {
    final result =
        await methodChannel.invokeMethod<Map>('queryDeviceBasicInfo');

    final int statusCode = result?["code"];
    final dict = result?["data"];
    final info = DeviceBasicInfo.fromJson(dict);

    return PluginResponse(statusCode, info);
  }

  @override
  Future<PluginResponse<String>?> queryDeviceMacAddress() async {
    final info = await methodChannel.invokeMethod<Map>('queryDeviceMacAddress');

    final int statusCode = info?["code"];
    final macAddress = info?["data"] ?? "";

    return PluginResponse(statusCode, macAddress);
  }

  @override
  Future<PluginResponse<String>?> queryDeviceModel(
      {BluetoothDevice? device}) async {
    final info = await methodChannel.invokeMethod<Map>('queryDeviceModel');

    final int statusCode = info?["code"];
    final model = info?["data"] ?? "";
    if (device != null) device.deviceModel = model;
    return PluginResponse(statusCode, model);
  }

  @override
  Future<PluginResponse<DeviceMcuPlatform>?> queryDeviceMCU(
      {BluetoothDevice? device}) async {
    final info = await methodChannel.invokeMethod<Map>('queryDeviceMCU');

    final int statusCode = info?["code"];
    int mcu = info?["data"] ?? 0;
    if (mcu > 4) {
      mcu = 0;
    }
    DeviceMcuPlatform mcuPlatform = DeviceMcuPlatform.values[mcu];
    if (device != null) device.mcuPlatform = mcuPlatform;
    return PluginResponse(statusCode, mcuPlatform);
  }

  /// 设置时间
  @override
  Future<PluginResponse?> setDeviceSyncPhoneTime() async {
    final info =
        await methodChannel.invokeMethod<Map>('setDeviceSyncPhoneTime');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置步数目标
  @override
  Future<PluginResponse?> setDeviceStepGoal(int step) async {
    final info =
        await methodChannel.invokeMethod<Map>('setDeviceStepGoal', step);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置睡眠目标
  @override
  Future<PluginResponse?> setDeviceSleepGoal(int hour, int minute) async {
    final info = await methodChannel
        .invokeMethod<Map>('setDeviceSleepGoal', [hour, minute]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置用户信息
  @override
  Future<PluginResponse?> setDeviceUserInfo(
      int height, int weight, int age, DeviceUserGender gender) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceUserInfo', [height, weight, gender.index, age]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 肤色设置
  @override
  Future<PluginResponse?> setDeviceSkinColor(
      {DeviceSkinColorLevel level = DeviceSkinColorLevel.yellow}) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceSkinColor', level.index);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置单位
  @override
  Future<PluginResponse?> setDeviceUnit(
      {DeviceDistanceUnit distance = DeviceDistanceUnit.km,
      DeviceWeightUnit weight = DeviceWeightUnit.kg,
      DeviceTemperatureUnit temperature = DeviceTemperatureUnit.celsius,
      DeviceTimeFormat timeFormat = DeviceTimeFormat.h24,
      DeviceBloodGlucoseOrBloodFatUnit bloodGlucoseOrBloodFat =
          DeviceBloodGlucoseOrBloodFatUnit.millimolePerLiter,
      DeviceUricAcidUnit uricAcid =
          DeviceUricAcidUnit.microMolePerLiter}) async {
    final info = await methodChannel.invokeMethod<Map>('setDeviceUnit', [
      distance.index,
      weight.index,
      temperature.index,
      timeFormat.index,
      bloodGlucoseOrBloodFat.index,
      uricAcid.index
    ]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 防丢设置
  @override
  Future<PluginResponse?> setDeviceAntiLost(bool isEnable) async {
    final info =
        await methodChannel.invokeMethod<Map>('setDeviceAntiLost', isEnable);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置勿扰
  @override
  Future<PluginResponse?> setDeviceNotDisturb(bool isEnable, int startHour,
      int startMinute, int endHour, int endMinute) async {
    final info = await methodChannel.invokeMethod<Map>('setDeviceNotDisturb',
        [isEnable ? 1 : 0, startHour, startMinute, endHour, endMinute]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置语言
  /// language - DeviceLanguageType
  @override
  Future<PluginResponse?> setDeviceLanguage(int language) async {
    final info =
        await methodChannel.invokeMethod<Map>('setDeviceLanguage', language);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 久坐提醒
  @override
  Future<PluginResponse?> setDeviceSedentary(
      bool isEnable,
      int startHour1,
      int startMinute1,
      int endHour1,
      int endMinute1,
      int startHour2,
      int startMinute2,
      int endHour2,
      int endMinute2,
      int interval,
      Set<int> repeat) async {
    int repeatValue = 0;
    for (var element in repeat) {
      repeatValue += element;
    }

    if (isEnable) {
      repeatValue += 0x80;
    }

    final info = await methodChannel.invokeMethod<Map>('setDeviceSedentary', [
      startHour1,
      startMinute1,
      endHour1,
      endMinute1,
      startHour2,
      startMinute2,
      endHour2,
      endMinute2,
      interval,
      repeatValue
    ]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  @override
  Future<PluginResponse?> setDeviceWearingPosition(
      DeviceWearingPositionType wearingPosition) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceWearingPosition', wearingPosition.index);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置手机系统信息
  @override
  Future<PluginResponse?> setPhoneSystemInfo() async {
    final info = await methodChannel.invokeMethod<Map>('setPhoneSystemInfo');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 抬腕亮屏
  @override
  Future<PluginResponse?> setDeviceWristBrightScreen(bool isEnable) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceWristBrightScreen', isEnable);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 亮度设置
  @override
  Future<PluginResponse?> setDeviceDisplayBrightness(
      DeviceDisplayBrightnessLevel level) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceDisplayBrightness', level.index);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 健康监测(心率监测)
  @override
  Future<PluginResponse?> setDeviceHealthMonitoringMode(
      {bool isEnable = true, int interval = 60}) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceHealthMonitoringMode', [isEnable ? 1 : 0, interval]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 温度监测 (一般不需要使用)
  @override
  Future<PluginResponse?> setDeviceTemperatureMonitoringMode(
      {bool isEnable = true, int interval = 60}) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceTemperatureMonitoringMode', [isEnable ? 1 : 0, interval]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 心率报警
  @override
  Future<PluginResponse?> setDeviceHeartRateAlarm(
      {bool isEnable = true,
      int maxHeartRate = 100,
      int minHeartRate = 30}) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceHeartRateAlarm',
        [isEnable ? 1 : 0, maxHeartRate, minHeartRate]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 血压报警
  @override
  Future<PluginResponse?> setDeviceBloodPressureAlarm(
      bool isEnable,
      int maximumSystolicBloodPressure,
      int maximumDiastolicBloodPressure,
      int minimumSystolicBloodPressure,
      int minimumDiastolicBloodPressure) async {
    final info =
        await methodChannel.invokeMethod<Map>('setDeviceBloodPressureAlarm', [
      isEnable ? 1 : 0,
      maximumSystolicBloodPressure,
      maximumDiastolicBloodPressure,
      minimumSystolicBloodPressure,
      minimumDiastolicBloodPressure
    ]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 血氧报警
  @override
  Future<PluginResponse?> setDeviceBloodOxygenAlarm(
      {bool isEnable = true, int minimum = 90}) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceBloodOxygenAlarm', [isEnable ? 1 : 0, minimum]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 呼吸率报警
  @override
  Future<PluginResponse?> setDeviceRespirationRateAlarm(
      bool isEnable, int maximum, int minimum) async {
    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceRespirationRateAlarm', [isEnable ? 1 : 0, maximum, minimum]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 温度报警
  @override
  Future<PluginResponse?> setDeviceTemperatureAlarm(bool isEnable,
      String maximumTemperature, String minimumTemperature) async {
    int highTemperatureIntegerValue = 0;
    int highTemperatureDecimalValue = 0;
    int lowTemperatureIntegerValue = 0;
    int lowTemperatureDecimalValue = 0;

    // 上限
    if (maximumTemperature.contains(".")) {
      final tem = maximumTemperature.split(".");
      highTemperatureIntegerValue = num.parse(tem.first).toInt();
      highTemperatureDecimalValue = num.parse(tem.last).toInt();
    } else {
      highTemperatureIntegerValue = num.parse(maximumTemperature).toInt();
      highTemperatureDecimalValue = 0;
    }

    // 下限
    if (minimumTemperature.contains(".")) {
      final tem = minimumTemperature.split(".");
      lowTemperatureIntegerValue = num.parse(tem.first).toInt();
      lowTemperatureDecimalValue = num.parse(tem.last).toInt();
    } else {
      lowTemperatureIntegerValue = num.parse(minimumTemperature).toInt();
      lowTemperatureDecimalValue = 0;
    }

    final info =
        await methodChannel.invokeMethod<Map>('setDeviceTemperatureAlarm', [
      isEnable ? 1 : 0,
      highTemperatureIntegerValue,
      highTemperatureDecimalValue,
      lowTemperatureIntegerValue,
      lowTemperatureDecimalValue
    ]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 获取主题
  @override
  Future<PluginResponse<DeviceThemeInfo>?> queryDeviceTheme() async {
    final info = await methodChannel.invokeMethod<Map>('queryDeviceTheme');

    final int statusCode = info?["code"];
    final Map dict = info?["data"];

    final theme = DeviceThemeInfo.fromJson(dict);

    return PluginResponse(statusCode, theme);
  }

  /// 设置主题
  @override
  Future<PluginResponse?> setDeviceTheme(int index) async {
    final info = await methodChannel.invokeMethod<Map>('setDeviceTheme', index);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 设置睡眠提醒时间
  @override
  Future<PluginResponse?> setDeviceSleepReminder(
      bool isEnable, int hour, int minute, Set<int> repeat) async {
    int repeatValue = 0;
    for (var element in repeat) {
      repeatValue += element;
    }

    if (isEnable) {
      repeatValue += 0x80;
    }

    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceSleepReminder', [hour, minute, repeatValue]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 通知开关(ANCS)
  /// items - DeviceInfoPushType 成员
  @override
  Future<PluginResponse?> setDeviceInfoPush(
      bool isEnable, Set<DeviceInfoPushType> items) async {
    int item1 = 0;
    int item2 = 0;
    int item3 = 0;

    for (var element in items) {
      switch (element) {
        case DeviceInfoPushType.call:
          item1 += (1 << 7);

        case DeviceInfoPushType.sms:
          item1 += (1 << 6);

        case DeviceInfoPushType.email:
          item1 += (1 << 5);

        case DeviceInfoPushType.wechat:
          item1 += (1 << 4);

        case DeviceInfoPushType.qq:
          item1 += (1 << 3);

        case DeviceInfoPushType.weibo:
          item1 += (1 << 2);

        case DeviceInfoPushType.facebook:
          item1 += (1 << 1);

        case DeviceInfoPushType.twitter:
          item1 += (1 << 0);

        //------------------------------------

        case DeviceInfoPushType.messenger:
          item2 += (1 << 7);

        case DeviceInfoPushType.whatsAPP:
          item2 += (1 << 6);

        case DeviceInfoPushType.linkedIn:
          item2 += (1 << 5);

        case DeviceInfoPushType.instagram:
          item2 += (1 << 4);

        case DeviceInfoPushType.skype:
          item2 += (1 << 3);

        case DeviceInfoPushType.line:
          item2 += (1 << 2);

        case DeviceInfoPushType.snapchat:
          item2 += (1 << 1);

        case DeviceInfoPushType.telegram:
          item2 += (1 << 0);

        //------------------------------------
        case DeviceInfoPushType.other:
          item3 += (1 << 0);

        case DeviceInfoPushType.viber:
          item3 += (1 << 1);

        case DeviceInfoPushType.zoom:
          item3 += (1 << 2);

        case DeviceInfoPushType.tiktok:
          item3 += (1 << 3);

        case DeviceInfoPushType.kaKaoTalk:
          item3 += (1 << 4);
      }
    }

    final info = await methodChannel.invokeMethod<Map>(
        'setDeviceInfoPush', [isEnable ? 1 : 0, item1, item2, item3]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 定时任务
  @override
  Future<PluginResponse?> setDevicePeriodicReminderTask(
      DevicePeriodicReminderType reminderType,
      bool isEnable,
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
      int interval,
      Set<int> repeat,
      String content) async {
    int repeatValue = 0;
    for (var element in repeat) {
      repeatValue += element;
    }

    if (isEnable) {
      repeatValue += 0x80;
    }

    final info =
        await methodChannel.invokeMethod<Map>('setDevicePeriodicReminderTask', [
      reminderType.index,
      startHour,
      startMinute,
      endHour,
      endMinute,
      interval,
      repeatValue,
      content,
    ]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 恢复出厂设置
  @override
  Future<PluginResponse?> restoreFactorySettings() async {
    final info =
        await methodChannel.invokeMethod<Map>('restoreFactorySettings');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 发送生理周期
  @override
  Future<PluginResponse?> sendDeviceMenstrualCycle(
      int time, int duration, int cycle) async {
    final info = await methodChannel
        .invokeMethod<Map>('sendDeviceMenstrualCycle', [time, duration, cycle]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 发送手机UUID
  @override
  Future<PluginResponse?> sendPhoneUUIDToDevice(String content) async {
    final info =
        await methodChannel.invokeMethod<Map>('sendPhoneUUIDToDevice', content);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 找设备
  @override
  Future<PluginResponse?> findDevice(
      {int remindCount = 5, int remindInterval = 1}) async {
    final info = await methodChannel
        .invokeMethod<Map>('findDevice', [remindCount, remindInterval]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 关机、复位
  @override
  Future<PluginResponse?> deviceSystemOperator(
      DeviceSystemOperator operator) async {
    final info = await methodChannel.invokeMethod<Map>(
        'deviceSystemOperator', operator.index + 1);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 血压校准
  @override
  Future<PluginResponse?> bloodPressureCalibration(
      int systolicBloodPressure, int diastolicBloodPressure) async {
    final info = await methodChannel.invokeMethod<Map>(
        'bloodPressureCalibration',
        [systolicBloodPressure, diastolicBloodPressure]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 温度校准
  @override
  Future<PluginResponse?> temperatureCalibration() async {
    final info =
        await methodChannel.invokeMethod<Map>('temperatureCalibration');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 血糖标定
  @override
  Future<PluginResponse?> bloodGlucoseCalibration(
      DeviceBloodGlucoseCalibrationaMode mode, String value) async {
    int intValue = 0;
    int floatValue = 0;

    if (value.contains(".")) {
      final tem = value.split(".");
      intValue = num.parse(tem.first).toInt();
      floatValue = num.parse(tem.last).toInt();
    } else {
      intValue = num.parse(value).toInt();
    }

    final info = await methodChannel.invokeMethod<Map>(
        'bloodGlucoseCalibration', [mode.index, intValue, floatValue]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 今日天气
  @override
  Future<PluginResponse?> sendTodayWeather(
      DeviceWeatherType weatherType,
      int lowestTemperature,
      int highestTemperature,
      int realTimeTemperature) async {
    final info = await methodChannel.invokeMethod<Map>('sendTodayWeather', [
      weatherType.index,
      lowestTemperature,
      highestTemperature,
      realTimeTemperature
    ]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 波形数据上传
  @override
  Future<PluginResponse?> waveDataUpload(
      YCWaveUploadState state, YCWaveDataType dataType) async {
    final info = await methodChannel
        .invokeMethod<Map>('waveDataUpload', [state.index, dataType.index]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 明日天气
  @override
  Future<PluginResponse?> sendTomorrowWeather(
      DeviceWeatherType weatherType,
      int lowestTemperature,
      int highestTemperature,
      int realTimeTemperature) async {
    final info = await methodChannel.invokeMethod<Map>('sendTomorrowWeather', [
      weatherType.index,
      lowestTemperature,
      highestTemperature,
      realTimeTemperature
    ]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 尿酸标定
  @override
  Future<PluginResponse?> uricAcidCalibration(int uricAcid) async {
    final info =
        await methodChannel.invokeMethod<Map>('uricAcidCalibration', uricAcid);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 血脂标定
  @override
  Future<PluginResponse?> bloodFatCalibration(String cholesterol) async {
    final info = await methodChannel.invokeMethod<Map>(
        'bloodFatCalibration', cholesterol);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 消息推送(Android)
  @override
  Future<PluginResponse?> appPushNotifications(
      AndroidDevicePushNotificationType type,
      String title,
      String contents) async {
    if (Platform.isIOS) {
      return PluginResponse(PluginState.unavailable, null);
    }

    final info = await methodChannel.invokeMethod<Map>(
        'appPushNotifications', [type.index, title, contents]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 名片下发
  @override
  Future<PluginResponse?> sendBusinessCard(int type, String contents) async {
    final info = await methodChannel
        .invokeMethod<Map>('sendBusinessCard', [type, contents]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 查询名片
  @override
  Future<PluginResponse?> queryBusinessCard(int type) async {
    final info =
        await methodChannel.invokeMethod<Map>('queryBusinessCard', type);

    final int statusCode = info?["code"];
    final String contents = info?["data"];

    return PluginResponse(statusCode, contents);
  }

  /// 设备退出睡眠
  @override
  Future<PluginResponse?> sendDeviceQuiteSleep() async {
    final info = await methodChannel.invokeMethod<Map>('sendDeviceQuiteSleep');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, "");
  }

  /// 拍照
  @override
  Future<PluginResponse?> appControlTakePhoto(bool isEnable) async {
    final info =
        await methodChannel.invokeMethod<Map>('appControlTakePhoto', isEnable);

    final int statusCode = info?["code"];
    final String contents = info?["data"];

    return PluginResponse(statusCode, contents);
  }

  @override
  Future<PluginResponse?> appControlSport(
      DeviceSportState state, int sportType) async {
    final info = await methodChannel
        .invokeMethod<Map>('appControlSport', [state.index, sportType]);

    final int statusCode = info?["code"];
    final String contents = info?["data"];

    return PluginResponse(statusCode, contents);
  }

  /// 测量类型
  @override
  Future<PluginResponse?> appControlMeasureHealthData(bool isEnable,
      DeviceAppControlMeasureHealthDataType healthDataType) async {
    final info = await methodChannel.invokeMethod<Map>(
        'appControlMeasureHealthData',
        [isEnable ? 1 : 0, healthDataType.index]);
    debugPrint("测量返回值$info");
    final int statusCode = info?["code"];
    final String contents = info?["data"];
    debugPrint("成功码:$statusCode测量返回值$info");
    return PluginResponse(statusCode, contents);
  }

  /// 控制实时数据上传
  @override
  Future<PluginResponse?> realTimeDataUpload(
      bool isEnable, DeviceRealTimeDataType dataType) async {
    final info = await methodChannel
        .invokeMethod<Map>('realTimeDataUpload', [isEnable, dataType.index]);

    final int statusCode = info?["code"];
    final String contents = info?["data"];

    return PluginResponse(statusCode, contents);
  }

  /// 开启ECG测量
  @override
  Future<PluginResponse?> startECGMeasurement() async {
    final info = await methodChannel.invokeMethod<Map>('startECGMeasurement');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  /// 结束ECG测量
  @override
  Future<PluginResponse?> stopECGMeasurement() async {
    final info = await methodChannel.invokeMethod<Map>('stopECGMeasurement');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, null);
  }

  @override
  Future<PluginResponse<DeviceECGResult>?> getECGResult() async {
    final info = await methodChannel.invokeMethod<Map>('getECGResult');

    final int statusCode = info?["code"];
    final map = info?["data"] as Map;

    final result = DeviceECGResult.fromMap(map);

    return PluginResponse(statusCode, result);
  }

  // MARK: - 历史ECG

  /// 查询基本信息
  @override
  Future<PluginResponse?> queryCollectDataBasicInfo(
      DeviceCollectDataType type) async {
    final info = await methodChannel.invokeMethod<Map>(
        'queryCollectDataBasicInfo', type.index);

    final int statusCode = info?["code"];
    final data = info?["data"];

    return PluginResponse(statusCode, data);
  }

  /// 1. 配置实时采样率
  /// - Parameters:
  ///   - type: 数据类型（对应YCQuerySampleRateType的index）
  ///   - sampleRate: 采样率值（4字节范围）
  @override
  Future<PluginResponse?> appConfigureSampleRate(
      int type, int sampleRate) async {
    final result = await methodChannel.invokeMethod<Map>(
      'appConfigureSampleRate',
      [type, sampleRate], // 按顺序传递参数：类型index、采样率值
    );

    final int statusCode = result?["code"] ?? -1;
    final data = result?["data"];

    return PluginResponse(statusCode, data);
  }

  /// 2. 配置实时PPG参数
  /// - Parameters:
  ///   - ledCombination: LED组合列表（YCUsedLedCombinationType的index集合）
  ///   - proximityLed: 接近检测LED类型（YCProximityDetectionLedType的index）
  ///   - redLightPdCombination: 红光PD组合列表
  ///   - infraredLightPdCombination: 红外光PD组合列表
  ///   - greenLightPdCombination: 绿光PD组合列表
  ///   - redLightLedCombination: 红光LED组合列表
  ///   - infraredLightLedCombination: 红外光LED组合列表
  ///   - greenLightLedCombination: 绿光LED组合列表
  @override
  Future<PluginResponse?> appConfigureRealTimePpg(
    List<int> ledCombination,
    int proximityLed,
    List<int> redLightPdCombination,
    List<int> infraredLightPdCombination,
    List<int> greenLightPdCombination,
    List<int> redLightLedCombination,
    List<int> infraredLightLedCombination,
    List<int> greenLightLedCombination,
  ) async {
    final result = await methodChannel.invokeMethod<Map>(
      'appConfigureRealTimePpg',
      [
        ledCombination,
        proximityLed,
        redLightPdCombination,
        infraredLightPdCombination,
        greenLightPdCombination,
        redLightLedCombination,
        infraredLightLedCombination,
        greenLightLedCombination,
      ], // 按顺序传递8个参数
    );

    final int statusCode = result?["code"] ?? -1;
    final data = result?["data"];

    return PluginResponse(statusCode, data);
  }

  /// 3. 查询MEMS传感器配置
  @override
  Future<PluginResponse?> appQueryMems() async {
    final result = await methodChannel.invokeMethod<Map>(
      'appQueryMems',
      null, // 无参数
    );

    final int statusCode = result?["code"] ?? -1;
    final data = result?["data"]; // 成功时返回传感器类型index列表

    return PluginResponse(statusCode, data);
  }

  /// 4. 控制MEMS开关
  /// - Parameters:
  ///   - onOff: 开关状态（0=关闭，非0=打开）
  ///   - types: 传感器类型列表（YCMEMSSensorType的index集合）
  @override
  Future<PluginResponse?> appMemsSwitch(bool onOff, List<int> types) async {
    final result = await methodChannel.invokeMethod<Map>(
      'appMemsSwitch',
      [onOff, types], // 按顺序传递参数：开关状态、传感器类型列表
    );

    final int statusCode = result?["code"] ?? -1;
    final data = result?["data"];

    return PluginResponse(statusCode, data);
  }

  /// 查询指信息
  @override
  Future<PluginResponse?> queryCollectDataInfo(
      DeviceCollectDataType type, int index) async {
    final info = await methodChannel
        .invokeMethod<Map>('queryCollectDataInfo', [type.index, index]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, "");
  }

  /// 删除
  @override
  Future<PluginResponse?> deleteCollectData(
      DeviceCollectDataType type, int index) async {
    final info = await methodChannel
        .invokeMethod<Map>('deleteCollectData', [type.index, index]);

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, "");
  }

  /// 开始语音识别
  @override
  Future<PluginResponse?> startSpeechRecognition() async {
    final info =
        await methodChannel.invokeMethod<Map>('startSpeechRecognition');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, "");
  }

  /// 结束语音识别
  @override
  Future<PluginResponse?> stopSpeechRecognition() async {
    final info = await methodChannel.invokeMethod<Map>('stopSpeechRecognition');

    final int statusCode = info?["code"];

    return PluginResponse(statusCode, "");
  }

  /// 固件升级
  @override
  Future<void> deviceUpgrade(DeviceMcuPlatform mcuPlatform,
      String firmwareAbsolutePath, OTAProcessCallback processCallBack) async {
    _otaCallback = processCallBack;

    await methodChannel.invokeMethod(
        'deviceUpgrade', [mcuPlatform.index, firmwareAbsolutePath]);
  }

  /// 查询表盘信息
  @override
  Future<PluginResponse<List<DeviceWatchInfo>>?> queryWatchFaceInfo() async {
    final result = await methodChannel.invokeMapMethod("queryWatchFaceInfo");

    final int statusCode = result?["code"];
    final data = result?["data"] as List;

    List<DeviceWatchInfo> list = [];

    for (var element in data) {
      final dial = DeviceWatchInfo.fromMap(element);
      list.add(dial);
    }

    return PluginResponse(statusCode, list);
  }

  /// 切换表盘
  @override
  Future<PluginResponse?> changeWatchFace(int dialID) async {
    final result =
        await methodChannel.invokeMapMethod("changeWatchFace", dialID);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 删除表盘
  @override
  Future<PluginResponse?> deleteWatchFace(int dialID) async {
    final result =
        await methodChannel.invokeMapMethod("deleteWatchFace", dialID);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 下载表盘
  @override
  Future<PluginResponse?> installWatchFace(
      bool isEnable,
      int dialID,
      int blockCount,
      int dialVersion,
      String filePath,
      ProcessCallback processCallback) async {
    _otaCallback = processCallback;

    final result = await methodChannel.invokeMapMethod("installWatchFace",
        [isEnable, dialID, blockCount, dialVersion, filePath]);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 查询缩略图的信息
  @override
  Future<PluginResponse<DeviceCustomWatchFaceDataInfo>?>
      queryDeviceCustomWatchFaceInfo(String filePath) async {
    final result = await methodChannel.invokeMapMethod(
        "queryDeviceCustomWatchFaceInfo", filePath);
    final int statusCode = result?["code"];
    final map = result?["data"];
    final info = DeviceCustomWatchFaceDataInfo.fromMap(map);

    return PluginResponse(statusCode, info);
  }

  /// 安装自定义表盘
  @override
  Future<PluginResponse>? installCustomWatchFace(
      int dialID,
      String filePath,
      String backgroundImage,
      String thumbnail,
      int timeX,
      int timeY,
      int redColor,
      int greenColor,
      int blueColor,
      ProcessCallback processCallback) async {
    _otaCallback = processCallback;
    final result =
        await methodChannel.invokeMapMethod("installCustomWatchFace", [
      dialID,
      filePath,
      backgroundImage,
      thumbnail,
      timeX,
      timeY,
      redColor,
      greenColor,
      blueColor
    ]);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 切换杰理表盘
  @override
  Future<PluginResponse?> changeJieLiWatchFace(String watchName) async {
    final result =
        await methodChannel.invokeMapMethod("changeJieLiWatchFace", watchName);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 删除杰理表盘
  @override
  Future<PluginResponse?> deleteJieLiWatchFace(String watchName) async {
    final result =
        await methodChannel.invokeMapMethod("deleteJieLiWatchFace", watchName);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 下载杰理表盘
  @override
  Future<PluginResponse?> installJieLiWatchFace(String watchName,
      String filePath, ProcessCallback processCallback) async {
    _otaCallback = processCallback;

    final result = await methodChannel
        .invokeMapMethod("installJieLiWatchFace", [watchName, filePath]);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 查询设备信息
  @override
  Future<PluginResponse<DeviceDisplayParametersInfo>?>
      queryDeviceDisplayParametersInfo() async {
    final result =
        await methodChannel.invokeMapMethod("queryDeviceDisplayParametersInfo");
    final int statusCode = result?["code"];
    final map = result?["data"];
    final info = DeviceDisplayParametersInfo.fromMap(map);
    return PluginResponse(statusCode, info);
  }

  /// 安装杰理自定义表盘
  @override
  Future<PluginResponse?> installJieLiCustomWatchFace(
      String watchName,
      String backgroundPath,
      String thumbnailPath,
      DeviceWatchFaceTimePosition timePosition,
      int timeTextColor,
      DeviceDisplayParametersInfo info,
      ProcessCallback processCallback) async {
    _otaCallback = processCallback;

    final result =
        await methodChannel.invokeMapMethod("installJieLiCustomWatchFace", [
      watchName,
      backgroundPath,
      info.widthPixels,
      info.heightPixels,
      info.filletRadiusPixels,
      thumbnailPath,
      info.thumbnailWidthPixels,
      info.thumbnailHeightPixels,
      info.thumbnailRadiusPixels,
      timePosition.index + 1,
      timeTextColor
    ]);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 查询杰理通讯录
  @override
  Future<PluginResponse<List<DeviceContactInfo>>?>
      queryJieLiDeviceContacts() async {
    final result =
        await methodChannel.invokeMapMethod("queryJieLiDeviceContacts");
    final int statusCode = result?["code"];
    final data = result?["data"] as List;

    List<DeviceContactInfo> items = [];

    for (var element in data) {
      final item = DeviceContactInfo(element["name"], element["phone"]);
      items.add(item);
    }

    return PluginResponse(statusCode, items);
  }

  /// 更新杰理通讯录
  @override
  Future<PluginResponse?> updateJieLiDeviceContacts(
      List<DeviceContactInfo> items) async {
    if (items.length > 10) {
      return PluginResponse(PluginState.failed, "Contact number limit");
    }

    var jsonData = [];
    for (var element in items) {
      jsonData.add(element.toJson());
    }

    final result = await methodChannel.invokeMapMethod(
        "updateJieLiDeviceContacts", jsonData);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 更新通讯录
  @override
  Future<PluginResponse?> updateDeviceContacts(
      List<DeviceContactInfo> items) async {
    if (items.length > 30) {
      return PluginResponse(PluginState.failed, "Contact number limit");
    }

    var jsonData = [];
    for (var element in items) {
      jsonData.add(element.toJson());
    }

    final result =
        await methodChannel.invokeMapMethod("updateDeviceContacts", jsonData);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  /// 获取日志文件
  @override
  Future<PluginResponse?> getLogFilePath(LoggerType logType) async {
    if (logType == LoggerType.appSdkLog) {
      final result = await methodChannel.invokeMapMethod("getLogFilePath");
      // print("结果$result");
      final int statusCode = result?["code"];
      final String filePath = result?["data"];
      return PluginResponse(statusCode, filePath);
    } else if (logType == LoggerType.jlDeviceLog) {
      final result =
          await methodChannel.invokeMapMethod("getJLDeviceLogFilePath");
      final int statusCode = result?["code"];
      final String filePath = result?["data"];
      return PluginResponse(statusCode, filePath);
    } else if (logType == LoggerType.deviceLog) {
      final result =
          await methodChannel.invokeMapMethod("getDeviceLogFilePath");
      final int statusCode = result?["code"];
      final String data = result?["data"];
      return PluginResponse(statusCode, data);
    }
    return null;
  }

  /// 清除日志文件
  @override
  Future<PluginResponse?> clearSDKLog() async {
    final result = await methodChannel.invokeMapMethod("clearSDKLog");
    final int statusCode = result?["code"];
    final String data = result?["data"];
    return PluginResponse(statusCode, data);
  }

  @override
  Future<PluginResponse?> shareLogFile() async {
    final result = await methodChannel.invokeMapMethod("shareLogFile");
    final int statusCode = result?["code"];
    final String data = result?["data"];
    return PluginResponse(statusCode, data);
  }

  @override
  Future<PluginResponse?> settingGetAllAlarm() async {
    final result = await methodChannel.invokeMapMethod("settingGetAllAlarm");
    // final Map map = info?["data"];
    // return PluginResponse(0, map);
    List list = [];
    final data = result?["data"] as List;
    print("settingGetAllAlarm结果 ${data.length}");
    for (var element in data) {
      AlarmClockInfo info = AlarmClockInfo.fromJson(element as Map);
      list.add(info);
    }
    return PluginResponse(0, list);
  }

  @override
  Future<PluginResponse?> settingAddAlarm(int type, int startHour, int startMin,
      String weekRepeat, int delayTime) async {
    final result = await methodChannel.invokeMapMethod(
        "settingAddAlarm", [type, startHour, startMin, weekRepeat, delayTime]);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  @override
  Future<PluginResponse?> settingModfiyAlarm(
      int startHour,
      int startMin,
      int newType,
      int newStartHour,
      int newStartMin,
      String newWeekRepeat,
      int newDelayTime) async {
    final result = await methodChannel.invokeMapMethod("settingModfiyAlarm", [
      startHour,
      startMin,
      newType,
      newStartHour,
      newStartMin,
      newWeekRepeat,
      newDelayTime
    ]);
    final int statusCode = result?["code"];
    return PluginResponse(statusCode, "");
  }

  @override
  Future<PluginResponse?> updateCallAlerts(bool isAlerts) async {
    final result =
        await methodChannel.invokeMapMethod("updateCallAlerts", [isAlerts]);
    return PluginResponse(0, "");
  }

  @override
  Future<PluginResponse?> shutdown() async {
    final result = await methodChannel.invokeMapMethod("shutdown");
    final int statusCode = result?["code"];
    final String data = result?["data"];
    return PluginResponse(statusCode, data);
  }

  @override
  Future<PluginResponse?> startListening() async {
    final result = await methodChannel.invokeMapMethod("startListening");
    final int statusCode = result?["code"];
    final String data = result?["data"];
    return PluginResponse(statusCode, data);
  }

  @override
  Future<PluginResponse?> settingVibrationIntensity(int level) async {
    final result = await methodChannel.invokeMapMethod("startListening", level);
    final int statusCode = result?["code"];
    final String data = result?["data"];
    return PluginResponse(statusCode, data);
  }
}
