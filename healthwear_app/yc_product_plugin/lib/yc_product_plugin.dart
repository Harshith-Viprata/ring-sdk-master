import 'yc_product_plugin_platform_interface.dart';

import 'dart:io';

// 导入数据类型
import 'yc_product_plugin_data_type.dart';
export 'yc_product_plugin_data_type.dart';
export 'yc_product_plugin_tools.dart';

/*版本号*/
const String PLUGIN_VERION = "0.0.2";

class YcProductPlugin {
  /// 连接设备
  BluetoothDevice? connectedDevice;

  // Future<BluetoothDevice?> get con async {
  //   final st = await getBluetoothState();
  //   if (st != BluetoothState.connected) {
  //     return null;
  //   }
  //   return connectedDevice;
  // }

  /// 实列化
  static final YcProductPlugin _instance = YcProductPlugin._init();

  /// 工厂构造蓝牙类
  factory YcProductPlugin() {
    return _instance;
  }

  /// 私有化命名构造
  YcProductPlugin._init();
}

/*基本信息*/
extension PluginInfo on YcProductPlugin {
  /*获取当前插件的版本*/
  String getPluginVersion() {
    return PLUGIN_VERION;
  }

  /*当前手机系统版本*/
  Future<String?> getPlatformVersion() {
    return YcProductPluginPlatform.instance.getPlatformVersion();
  }
}

// MARK: - 蓝牙操作
extension BleInit on YcProductPlugin {
  /// 插件初始化
  /// isReconnectEnable 是否设置回连
  /// isLogEnable 是否开启回连
  Future<void> initPlugin(
      {bool isReconnectEnable = true, bool isLogEnable = false}) {
    return YcProductPluginPlatform.instance.initPlugin(
        isReconnectEnable: isReconnectEnable, isLogEnable: isLogEnable);
  }

  /// 设置回连是否有效
  /// 此方法暂进只能在iOS中使用
  Future<void> setReconnectEnabled({bool isReconnectEnable = true}) {
    // if (Platform.isAndroid) {
    //   throw ("Android Not Support");
    // }

    return YcProductPluginPlatform.instance
        .setReconnectEnabled(isReconnectEnable);
  }

  /// 开启监听
  void onListening(void Function(dynamic event) onData) {
    return YcProductPluginPlatform.instance.onListening(onData);
  }

  /// 停止监听
  void cancelListening() {
    return YcProductPluginPlatform.instance.cancelListening();
  }

  /// 清除队列
  Future<void> clearQueue() {
    return YcProductPluginPlatform.instance.clearQueue();
  }

  ///重置配对过程
  Future<void> resetBond() {
    return YcProductPluginPlatform.instance.resetBond();
  }

  Future<void> exitScanDevice() {
    return YcProductPluginPlatform.instance.exitScanDevice();
  }

  /// 扫描设备
  Future<List<BluetoothDevice>?> scanDevice({int time = 6}) {
    return YcProductPluginPlatform.instance.scanDevice(time: time);
  }

  /// 停止扫描设备
  Future<void> stopScanDevice() {
    return YcProductPluginPlatform.instance.stopScanDevice();
  }

  /// 连接设备
  Future<bool?> connectDevice(BluetoothDevice device) async {
    final result = await YcProductPluginPlatform.instance
        .connectDevice(device.deviceIdentifier);
    return result;
  }

  /// 断开连接
  Future<bool?> disconnectDevice() async {
    final result = await YcProductPluginPlatform.instance
        .disconnectDevice(deviceIdentifier: "");

    if (result == true) {
      connectedDevice = null;
    }

    return result;
  }

  /// 获取蓝牙状态，返回值 使用  BluetoothState 来判断
  Future<int?> getBluetoothState() {
    return YcProductPluginPlatform.instance.getBluetoothState();
  }

  /// 获取设备功能列表
  Future<DeviceFeature?> getDeviceFeature({BluetoothDevice? device}) async {
    final currentDeviceFeature =
        await YcProductPluginPlatform.instance.getDeviceFeature();
    connectedDevice?.deviceFeature = currentDeviceFeature;
    return currentDeviceFeature;
  }
}

// MARK: - 健康数据
extension HealthData on YcProductPlugin {
  /// 同步健康历史数据
  /// healthDataType - HealthDataType 数据类型
  /// 回值类型  Map {"code": PluginState, "data": list }
  Future<PluginResponse<List>?> queryDeviceHealthData(int healthDataType) {
    return YcProductPluginPlatform.instance
        .queryDeviceHealthData(healthDataType);
  }

  /// 删除健康历史数据
  /// healthDataType - HealthDataType 数据类型
  /// 返回值类型       -  PluginState 数据类型
  Future<PluginResponse?> deleteDeviceHealthData(int healthDataType) {
    return YcProductPluginPlatform.instance
        .deleteDeviceHealthData(healthDataType);
  }
}

// MARK: - 查询设备信息
extension QueryDeviceData on YcProductPlugin {
  /// 查询设备的基本信息
  Future<PluginResponse<DeviceBasicInfo>?> queryDeviceBasicInfo() {
    return YcProductPluginPlatform.instance.queryDeviceBasicInfo();
  }

  /// 查询设备mac地址
  Future<PluginResponse<String>?> queryDeviceMacAddress() async {
    final value =
        await YcProductPluginPlatform.instance.queryDeviceMacAddress();
    if (value?.statusCode == PluginState.succeed) {
      connectedDevice?.macAddress = value?.data as String;
    }
    return value;
  }

  /// 查询设备型号
  Future<PluginResponse<String>?> queryDeviceModel(
      {BluetoothDevice? device}) async {
    final value = await YcProductPluginPlatform.instance.queryDeviceModel();
    if (value?.statusCode == PluginState.succeed) {
      connectedDevice?.deviceModel = value?.data as String;
    }
    return value;
  }

  /// 查询设备平台
  Future<PluginResponse<DeviceMcuPlatform>?> queryDeviceMCU(
      {BluetoothDevice? device}) async {
    final value = await YcProductPluginPlatform.instance.queryDeviceMCU();
    if (value?.statusCode == PluginState.succeed) {
      connectedDevice?.mcuPlatform = value?.data;
    }
    return value;
  }
}

// MARK: - 设置设备
extension SetDeviceData on YcProductPlugin {
  /// 设置时间(同步手机时间)
  Future<PluginResponse?> setDeviceSyncPhoneTime() {
    return YcProductPluginPlatform.instance.setDeviceSyncPhoneTime();
  }

  /// 设置运动步数目标
  Future<PluginResponse?> setDeviceStepGoal(int step) {
    return YcProductPluginPlatform.instance.setDeviceStepGoal(step);
  }

  /// 设置睡眠目标
  Future<PluginResponse?> setDeviceSleepGoal(int hour, int minute) {
    return YcProductPluginPlatform.instance.setDeviceSleepGoal(hour, minute);
  }

  /// 设置用户信息
  Future<PluginResponse?> setDeviceUserInfo(
      int height, int weight, int age, DeviceUserGender gender) {
    return YcProductPluginPlatform.instance
        .setDeviceUserInfo(height, weight, age, gender);
  }

  /// 肤色设置
  Future<PluginResponse?> setDeviceSkinColor(
      {DeviceSkinColorLevel level = DeviceSkinColorLevel.yellow}) {
    return YcProductPluginPlatform.instance.setDeviceSkinColor(level: level);
  }

  /// 设置单位
  Future<PluginResponse?> setDeviceUnit(
      {DeviceDistanceUnit distance = DeviceDistanceUnit.km,
      DeviceWeightUnit weight = DeviceWeightUnit.kg,
      DeviceTemperatureUnit temperature = DeviceTemperatureUnit.celsius,
      DeviceTimeFormat timeFormat = DeviceTimeFormat.h24,
      DeviceBloodGlucoseOrBloodFatUnit bloodGlucoseOrBloodFat =
          DeviceBloodGlucoseOrBloodFatUnit.millimolePerLiter,
      DeviceUricAcidUnit uricAcid = DeviceUricAcidUnit.microMolePerLiter}) {
    return YcProductPluginPlatform.instance.setDeviceUnit(
        distance: distance,
        weight: weight,
        temperature: temperature,
        timeFormat: timeFormat,
        bloodGlucoseOrBloodFat: bloodGlucoseOrBloodFat,
        uricAcid: uricAcid);
  }

  /// 防丢设置
  Future<PluginResponse?> setDeviceAntiLost(bool isEnable) {
    return YcProductPluginPlatform.instance.setDeviceAntiLost(isEnable);
  }

  /// 设置勿扰
  Future<PluginResponse?> setDeviceNotDisturb(bool isEnable, int startHour,
      int startMinute, int endHour, int endMinute) {
    return YcProductPluginPlatform.instance.setDeviceNotDisturb(
        isEnable, startHour, startMinute, endHour, endMinute);
  }

  /// 设置语言
  /// language - DeviceLanguageType
  Future<PluginResponse?> setDeviceLanguage(int language) {
    return YcProductPluginPlatform.instance.setDeviceLanguage(language);
  }

  /// 久坐提醒
  /// isEnable 是否开启
  /// startXXX 开始时间
  /// endXXX  结束时间
  /// interval 15 ~ 60 分钟，其它值不可以使用
  /// repeat 重复，星期设置 DeviceWeekDay
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
      Set<int> repeat) {
    return YcProductPluginPlatform.instance.setDeviceSedentary(
        isEnable,
        startHour1,
        startMinute1,
        endHour1,
        endMinute1,
        startHour2,
        startMinute2,
        endHour2,
        endMinute2,
        interval,
        repeat);
  }

  /// 左右手设置
  Future<PluginResponse?> setDeviceWearingPosition(
      DeviceWearingPositionType wearingPosition) {
    return YcProductPluginPlatform.instance
        .setDeviceWearingPosition(wearingPosition);
  }

  /// 手机系统设置
  Future<PluginResponse?> setPhoneSystemInfo() {
    return YcProductPluginPlatform.instance.setPhoneSystemInfo();
  }

  /// 通知开关(ANCS)
  /// items - DeviceInfoPushType 成员
  Future<PluginResponse?> setDeviceInfoPush(
      bool isEnable, Set<DeviceInfoPushType> items) {
    return YcProductPluginPlatform.instance.setDeviceInfoPush(isEnable, items);
  }

  /// 健康监测(心率监测)
  /// isEnable - 开关
  /// interval - 1 ~ 60 min
  Future<PluginResponse?> setDeviceHealthMonitoringMode(
      {bool isEnable = true, int interval = 60}) {
    return YcProductPluginPlatform.instance
        .setDeviceHealthMonitoringMode(isEnable: isEnable, interval: interval);
  }

  @Deprecated("Use setDeviceHealthMonitoringMode")

  /// 温度监测
  Future<PluginResponse?> setDeviceTemperatureMonitoringMode(
      {bool isEnable = true, int interval = 60}) {
    return YcProductPluginPlatform.instance.setDeviceTemperatureMonitoringMode(
        isEnable: isEnable, interval: interval);
  }

  /// 心率报警
  Future<PluginResponse?> setDeviceHeartRateAlarm(
      {bool isEnable = true, int maxHeartRate = 100, int minHeartRate = 30}) {
    return YcProductPluginPlatform.instance.setDeviceHeartRateAlarm(
        isEnable: isEnable,
        maxHeartRate: maxHeartRate,
        minHeartRate: minHeartRate);
  }

  /// 血压报警
  Future<PluginResponse?> setDeviceBloodPressureAlarm(
      bool isEnable,
      int maximumSystolicBloodPressure,
      int maximumDiastolicBloodPressure,
      int minimumSystolicBloodPressure,
      int minimumDiastolicBloodPressure) {
    return YcProductPluginPlatform.instance.setDeviceBloodPressureAlarm(
        isEnable,
        maximumSystolicBloodPressure,
        maximumDiastolicBloodPressure,
        minimumSystolicBloodPressure,
        minimumDiastolicBloodPressure);
  }

  /// 血氧报警
  Future<PluginResponse?> setDeviceBloodOxygenAlarm(
      {bool isEnable = true, int minimum = 90}) {
    return YcProductPluginPlatform.instance
        .setDeviceBloodOxygenAlarm(isEnable: isEnable, minimum: minimum);
  }

  /// 呼吸率报警
  Future<PluginResponse?> setDeviceRespirationRateAlarm(
      bool isEnable, int maximum, int minimum) {
    return YcProductPluginPlatform.instance
        .setDeviceRespirationRateAlarm(isEnable, maximum, minimum);
  }

  /// 温度报警
  Future<PluginResponse?> setDeviceTemperatureAlarm(
      bool isEnable, String maximumTemperature, String minimumTemperature) {
    return YcProductPluginPlatform.instance.setDeviceTemperatureAlarm(
        isEnable, maximumTemperature, minimumTemperature);
  }

  /// 获取主题
  Future<PluginResponse<DeviceThemeInfo>?> queryDeviceTheme() {
    return YcProductPluginPlatform.instance.queryDeviceTheme();
  }

  /// 设置主题
  Future<PluginResponse?> setDeviceTheme(int index) {
    return YcProductPluginPlatform.instance.setDeviceTheme(index);
  }

  /// 设置睡眠提醒时间
  Future<PluginResponse?> setDeviceSleepReminder(
      bool isEnable, int hour, int minute, Set<int> repeat) {
    return YcProductPluginPlatform.instance
        .setDeviceSleepReminder(isEnable, hour, minute, repeat);
  }

  /// 抬腕亮屏
  Future<PluginResponse?> setDeviceWristBrightScreen(bool isEnable) {
    return YcProductPluginPlatform.instance
        .setDeviceWristBrightScreen(isEnable);
  }

  /// 亮度设置
  Future<PluginResponse?> setDeviceDisplayBrightness(
      DeviceDisplayBrightnessLevel level) {
    return YcProductPluginPlatform.instance.setDeviceDisplayBrightness(level);
  }

  /// 设置定时任务
  Future<PluginResponse?> setDevicePeriodicReminderTask(
      DevicePeriodicReminderType reminderType,
      bool isEnable,
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
      int interval,
      Set<int> repeat,
      {String content = ""}) {
    return YcProductPluginPlatform.instance.setDevicePeriodicReminderTask(
        reminderType,
        isEnable,
        startHour,
        startMinute,
        endHour,
        endMinute,
        interval,
        repeat,
        content);
  }

  /// 生理周期
  /// time - 开始时间 秒
  /// duration - 经期持续天数
  /// cycle - 经期周期
  Future<PluginResponse?> sendDeviceMenstrualCycle(
      int time, int duration, int cycle) {
    return YcProductPluginPlatform.instance
        .sendDeviceMenstrualCycle(time, duration, cycle);
  }

  /// 发送手机的UUID唯一识别码
  Future<PluginResponse?> sendPhoneUUIDToDevice(String content) {
    return YcProductPluginPlatform.instance.sendPhoneUUIDToDevice(content);
  }

  /// 闹钟

  /// 恢复出厂设置
  Future<PluginResponse?> restoreFactorySettings() {
    return YcProductPluginPlatform.instance.restoreFactorySettings();
  }
}

// MARK: - App 控制
extension AppControl on YcProductPlugin {
  /// 找设备
  Future<PluginResponse?> findDevice(
      {int remindCount = 5, int remindInterval = 1}) {
    return YcProductPluginPlatform.instance
        .findDevice(remindCount: remindCount, remindInterval: remindInterval);
  }

  /// 关机、复位、重启
  Future<PluginResponse?> deviceSystemOperator(DeviceSystemOperator operator) {
    return YcProductPluginPlatform.instance.deviceSystemOperator(operator);
  }

  /// 血压校准
  Future<PluginResponse?> bloodPressureCalibration(
      int systolicBloodPressure, int diastolicBloodPressure) {
    return YcProductPluginPlatform.instance.bloodPressureCalibration(
        systolicBloodPressure, diastolicBloodPressure);
  }

  /// 温度校准
  Future<PluginResponse?> temperatureCalibration() {
    return YcProductPluginPlatform.instance.temperatureCalibration();
  }

  /// 血糖标定
  Future<PluginResponse?> bloodGlucoseCalibration(
      DeviceBloodGlucoseCalibrationaMode mode, String value) {
    return YcProductPluginPlatform.instance
        .bloodGlucoseCalibration(mode, value);
  }

  /// 发送天气
  Future<PluginResponse?> sendTodayWeather(DeviceWeatherType weatherType,
      int lowestTemperature, int highestTemperature, int realTimeTemperature) {
    return YcProductPluginPlatform.instance.sendTodayWeather(weatherType,
        lowestTemperature, highestTemperature, realTimeTemperature);
  }

  Future<PluginResponse?> waveDataUpload(
      YCWaveUploadState state, YCWaveDataType dataType) {
    return YcProductPluginPlatform.instance.waveDataUpload(state, dataType);
  }

  /// 发送明日天气
  Future<PluginResponse?> sendTomorrowWeather(DeviceWeatherType weatherType,
      int lowestTemperature, int highestTemperature, int realTimeTemperature) {
    return YcProductPluginPlatform.instance.sendTomorrowWeather(weatherType,
        lowestTemperature, highestTemperature, realTimeTemperature);
  }

  /// 尿酸标定
  /// uricAcid - umol/L
  Future<PluginResponse?> uricAcidCalibration(int uricAcid) {
    return YcProductPluginPlatform.instance.uricAcidCalibration(uricAcid);
  }

  /// 血脂校准
  /// cholesterol 胆固醇 - mmol/L
  Future<PluginResponse?> bloodFatCalibration(String cholesterol) {
    return YcProductPluginPlatform.instance.bloodFatCalibration(cholesterol);
  }

  /// 消息推送
  Future<PluginResponse?> appPushNotifications(
      AndroidDevicePushNotificationType type, String title, String contents) {
    return YcProductPluginPlatform.instance
        .appPushNotifications(type, title, contents);
  }

  /// 名片下发
  /// type - DeviceBusinessCardType
  Future<PluginResponse?> sendBusinessCard(int type, String contents) {
    return YcProductPluginPlatform.instance.sendBusinessCard(type, contents);
  }

  /// 设备退出睡眠
  Future<PluginResponse?> sendDeviceQuiteSleep() {
    return YcProductPluginPlatform.instance.sendDeviceQuiteSleep();
  }

  /// 查询名片
  /// type - DeviceBusinessCardType
  Future<PluginResponse?> queryBusinessCard(int type) {
    return YcProductPluginPlatform.instance.queryBusinessCard(type);
  }

  /// 控制设备进入或退出拍照
  Future<PluginResponse?> appControlTakePhoto(bool isEnable) {
    return YcProductPluginPlatform.instance.appControlTakePhoto(isEnable);
  }

  /// 控制运动
  Future<PluginResponse?> appControlSport(
      DeviceSportState state, int sportType) {
    return YcProductPluginPlatform.instance.appControlSport(state, sportType);
  }

  /// 测量类型
  Future<PluginResponse?> appControlMeasureHealthData(
      bool isEnable, DeviceAppControlMeasureHealthDataType healthDataType) {
    return YcProductPluginPlatform.instance
        .appControlMeasureHealthData(isEnable, healthDataType);
  }

  /// 开启ECG测量
  Future<PluginResponse?> startECGMeasurement() {
    return YcProductPluginPlatform.instance.startECGMeasurement();
  }

  /// 结束ECG测量
  Future<PluginResponse?> stopECGMeasurement() {
    return YcProductPluginPlatform.instance.stopECGMeasurement();
  }

  /// 获取ECG的结果
  Future<PluginResponse<DeviceECGResult>?> getECGResult() {
    return YcProductPluginPlatform.instance.getECGResult();
  }

  /// 控制实时数据上传
  Future<PluginResponse?> realTimeDataUpload(bool isEnable,
      {DeviceRealTimeDataType dataType = DeviceRealTimeDataType.step}) {
    return YcProductPluginPlatform.instance
        .realTimeDataUpload(isEnable, dataType);
  }

  /// 配置实时采样率
  Future<PluginResponse?> appConfigureSampleRate(
      int dataType, int samplingRate) {
    return YcProductPluginPlatform.instance
        .appConfigureSampleRate(dataType, samplingRate);
  }

  /// 配置实时PPG参数
  Future<PluginResponse?> appConfigureRealTimePpg(
      List<int> ledCombination, // 1. LED组合列表（YCUsedLedCombinationType的rawValue）
      //    类型：case usedLedGreen   = 1  // 使用的LED-绿光
      //         case usedLedRed     = 2  // 使用的LED-红光
      //         case usedLedInfrared = 4  // 使用的LED-红外光
      int proximityLed, // 2. 接近检测LED（YCProximityDetectionLedType的rawValue）
      //    类型：case proximityLedGreen   = 1  // 接近检测LED-绿光
      //         case proximityLedRed     = 2  // 接近检测LED-红光
      //         case proximityLedInfrared = 4  // 接近检测LED-红外光
      List<int>
          redPdCombination, // 3. 红光通道PD组合列表（YCRedChannelPdCombinationType的rawValue）
      //    类型：case redChannelPd0 = 1    // 红光通道-PD0
      //         case redChannelPd1 = 2    // 红光通道-PD1
      //         case redChannelPd2 = 4    // 红光通道-PD2
      //         case redChannelPd3 = 8    // 红光通道-PD3
      //         case redChannelPd4 = 16   // 红光通道-PD4
      //         case redChannelPd5 = 32   // 红光通道-PD5
      //         case redChannelPd6 = 64   // 红光通道-PD6
      //         case redChannelPd7 = 128  // 红光通道-PD7
      List<int>
          infraredPdCombination, // 4. 红外光通道PD组合列表（YCInfraredChannelPdCombinationType的rawValue）
      //    类型：case infraredChannelPd0 = 1    // 红外通道-PD0
      //         case infraredChannelPd1 = 2    // 红外通道-PD1
      //         case infraredChannelPd2 = 4    // 红外通道-PD2
      //         case infraredChannelPd3 = 8    // 红外通道-PD3
      //         case infraredChannelPd4 = 16   // 红外通道-PD4
      //         case infraredChannelPd5 = 32   // 红外通道-PD5
      //         case infraredChannelPd6 = 64   // 红外通道-PD6
      //         case infraredChannelPd7 = 128  // 红外通道-PD7
      List<int>
          greenPdCombination, // 5. 绿光通道PD组合列表（YCGreenChannelPdCombinationType的rawValue）
      //    类型：case greenChannelPd0 = 1    // 绿光通道-PD0
      //         case greenChannelPd1 = 2    // 绿光通道-PD1
      //         case greenChannelPd2 = 4    // 绿光通道-PD2
      //         case greenChannelPd3 = 8    // 绿光通道-PD3
      //         case greenChannelPd4 = 16   // 绿光通道-PD4
      //         case greenChannelPd5 = 32   // 绿光通道-PD5
      //         case greenChannelPd6 = 64   // 绿光通道-PD6
      //         case greenChannelPd7 = 128  // 绿光通道-PD7
      List<int>
          redLedCombination, // 6. 红光通道LED组合列表（YCRedChannelLedCombinationType的rawValue）
      //    类型：case redChannelLed0 = 1    // 红光通道-LED0
      //         case redChannelLed1 = 2    // 红光通道-LED1
      //         case redChannelLed2 = 4    // 红光通道-LED2
      //         case redChannelLed3 = 8    // 红光通道-LED3
      //         case redChannelLed4 = 16   // 红光通道-LED4
      //         case redChannelLed5 = 32   // 红光通道-LED5
      //         case redChannelLed6 = 64   // 红光通道-LED6
      //         case redChannelLed7 = 128  // 红光通道-LED7
      List<int>
          infraredLedCombination, // 7. 红外光通道LED组合列表（YCInfraredChannelLedCombinationType的rawValue）
      //    类型：case infraredChannelLed0 = 1    // 红外光通道-LED0
      //         case infraredChannelLed1 = 2    // 红外光通道-LED1
      //         case infraredChannelLed2 = 4    // 红外光通道-LED2
      //         case infraredChannelLed3 = 8    // 红外光通道-LED3
      //         case infraredChannelLed4 = 16   // 红外光通道-LED4
      //         case infraredChannelLed5 = 32   // 红外光通道-LED5
      //         case infraredChannelLed6 = 64   // 红外光通道-LED6
      //         case infraredChannelLed7 = 128  // 红外光通道-LED7
      List<int>
          greenLedCombination // 8. 绿光通道LED组合列表（YCGreenChannelLedCombinationType的rawValue）
      //    类型：case greenChannelLed0 = 1    // 绿光通道-LED0
      //         case greenChannelLed1 = 2    // 绿光通道-LED1
      //         case greenChannelLed2 = 4    // 绿光通道-LED2
      //         case greenChannelLed3 = 8    // 绿光通道-LED3
      //         case greenChannelLed4 = 16   // 绿光通道-LED4
      //         case greenChannelLed5 = 32   // 绿光通道-LED5
      //         case greenChannelLed6 = 64   // 绿光通道-LED6
      //         case greenChannelLed7 = 128  // 绿光通道-LED7
      ) {
    return YcProductPluginPlatform.instance.appConfigureRealTimePpg(
        ledCombination,
        proximityLed,
        redPdCombination,
        infraredPdCombination,
        greenPdCombination,
        redLedCombination,
        infraredLedCombination,
        greenLedCombination);
  }

  /// 查询MEMS传感器配置
  Future<PluginResponse?> appQueryMems() {
    return YcProductPluginPlatform.instance.appQueryMems();
  }

  /// MEMS开关控制 (type: YCMEMSSensorType的rawValue) MEMS传感器类型
  // case accelerometer3Axis = 1  //  BIT0: 3轴加速度
  // case gyroscope3Axis     = 2  //  BIT1: 3轴陀螺仪
  // case magnetometer3Axis  = 4  //  BIT2: 3轴磁力计
  Future<PluginResponse?> appMemsSwitch(List<int> type, bool isEnable) {
    return YcProductPluginPlatform.instance.appMemsSwitch(isEnable, type);
  }
}

/// 查询历史采集数据
extension CollectData on YcProductPlugin {
  /// 查询基本信息
  Future<PluginResponse?> queryCollectDataBasicInfo(
      DeviceCollectDataType type) {
    return YcProductPluginPlatform.instance.queryCollectDataBasicInfo(type);
  }

  /// 查询历史记录
  Future<PluginResponse?> queryCollectDataInfo(
      DeviceCollectDataType type, int index) {
    return YcProductPluginPlatform.instance.queryCollectDataInfo(type, index);
  }

  /// 删除历史记录
  Future<PluginResponse?> deleteCollectData(
      DeviceCollectDataType type, int index) {
    return YcProductPluginPlatform.instance.deleteCollectData(type, index);
  }
}
/// jlvideo
extension JlVideo on YcProductPlugin {
  /// 开始语音识别
  Future<PluginResponse?> startSpeechRecognition(
      ) {
    return YcProductPluginPlatform.instance.startSpeechRecognition();
  }

  // 结束语音识别
  Future<PluginResponse?> stopSpeechRecognition(
      ) {
    return YcProductPluginPlatform.instance.stopSpeechRecognition();
  }
}
/// otA
extension DeviceOta on YcProductPlugin {
  Future<void> deviceUpgrade(DeviceMcuPlatform mcuPlatform,
      String firmwareAbsolutePath, OTAProcessCallback processCallBack) {
    return YcProductPluginPlatform.instance
        .deviceUpgrade(mcuPlatform, firmwareAbsolutePath, processCallBack);
  }
}

/// 表盘文件
extension WatchFace on YcProductPlugin {
  /// 查询表盘信息
  Future<PluginResponse<List<DeviceWatchInfo>>?> queryWatchFaceInfo() {
    return YcProductPluginPlatform.instance.queryWatchFaceInfo();
  }

  /// 切换表盘
  Future<PluginResponse?> changeWatchFace(int dialID) {
    return YcProductPluginPlatform.instance.changeWatchFace(dialID);
  }

  /// 删除表盘
  Future<PluginResponse?> deleteWatchFace(int dialID) {
    return YcProductPluginPlatform.instance.deleteWatchFace(dialID);
  }

  /// 下载表盘
  Future<PluginResponse?> installWatchFace(
      bool isEnable,
      int dialID,
      int blockCount,
      int dialVersion,
      String filePath,
      ProcessCallback processCallback) {
    return YcProductPluginPlatform.instance.installWatchFace(
        isEnable, dialID, blockCount, dialVersion, filePath, processCallback);
  }

  /// 获取自定义表盘的参数
  Future<PluginResponse<DeviceCustomWatchFaceDataInfo>?>
      queryDeviceCustomWatchFaceInfo(String filePath) {
    return YcProductPluginPlatform.instance
        .queryDeviceCustomWatchFaceInfo(filePath);
  }

  /// 下载自定义表盘
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
      ProcessCallback processCallback) {
    return YcProductPluginPlatform.instance.installCustomWatchFace(
        dialID,
        filePath,
        backgroundImage,
        thumbnail,
        timeX,
        timeY,
        redColor,
        greenColor,
        blueColor,
        processCallback);
  }

  /// 切换杰理表盘
  Future<PluginResponse?> changeJieLiWatchFace(String watchName) {
    return YcProductPluginPlatform.instance.changeJieLiWatchFace(watchName);
  }

  /// 删除杰理表盘
  Future<PluginResponse?> deleteJieLiWatchFace(String watchName) {
    return YcProductPluginPlatform.instance.deleteJieLiWatchFace(watchName);
  }

  /// 安装杰理表盘
  Future<PluginResponse?> installJieLiWatchFace(
      String watchName, String filePath, ProcessCallback processCallback) {
    return YcProductPluginPlatform.instance
        .installJieLiWatchFace(watchName, filePath, processCallback);
  }

  /// 查询设备信息
  Future<PluginResponse<DeviceDisplayParametersInfo>?>
      queryDeviceDisplayParametersInfo() {
    return YcProductPluginPlatform.instance.queryDeviceDisplayParametersInfo();
  }

  /// 下载杰理自定义表盘
  /// watchName 表盘名称 如 watch900
  /// backgroundPath 背景图片的绝对路径
  /// backgroundImageWidth/backgroundImageHeight 背景图片的宽/高
  /// thumbnailPath 缩略图的绝对路径
  /// thumbnailWidth/thumbnailHeight 缩略图的大小
  /// DeviceWatchFaceTimePosition - 时间显示位置
  /// timeTextColor 时间文字颜色 - RGB565
  /// processCallback 安装进度条
  Future<PluginResponse?> installJieLiCustomWatchFace(
      String watchName,
      String backgroundPath,
      String thumbnailPath,
      DeviceWatchFaceTimePosition timePosition,
      int timeTextColor,
      DeviceDisplayParametersInfo info,
      ProcessCallback processCallback) {
    return YcProductPluginPlatform.instance.installJieLiCustomWatchFace(
        watchName,
        backgroundPath,
        thumbnailPath,
        timePosition,
        timeTextColor,
        info,
        processCallback);
  }

  /// 查询杰理通讯录
  Future<PluginResponse<List<DeviceContactInfo>>?> queryJieLiDeviceContacts() {
    return YcProductPluginPlatform.instance.queryJieLiDeviceContacts();
  }

  /// 更新杰理通讯录
  Future<PluginResponse?> updateJieLiDeviceContacts(
      List<DeviceContactInfo> items) {
    return YcProductPluginPlatform.instance.updateJieLiDeviceContacts(items);
  }

  /// 更新通讯录列表
  Future<PluginResponse?> updateDeviceContacts(List<DeviceContactInfo> items) {
    return YcProductPluginPlatform.instance.updateDeviceContacts(items);
  }

  ///获取日志文件
  Future<PluginResponse?> getLogFilePath(LoggerType logType) {
    return YcProductPluginPlatform.instance.getLogFilePath(logType);
  }

  ///清除SDK日志
  Future<PluginResponse?> clearSDKLog() {
    return YcProductPluginPlatform.instance.clearSDKLog();
  }

  Future<PluginResponse?> shareLogFile() {
    return YcProductPluginPlatform.instance.shareLogFile();
  }

  ///查询闹钟
  Future<PluginResponse?> settingGetAllAlarm() {
    return YcProductPluginPlatform.instance.settingGetAllAlarm();
  }

  ///添加闹钟
  Future<PluginResponse?> settingAddAlarm(
      int type, int startHour, int startMin, String weekRepeat, int delayTime) {
    return YcProductPluginPlatform.instance
        .settingAddAlarm(type, startHour, startMin, weekRepeat, delayTime);
  }

  ///修改闹钟
  Future<PluginResponse?> settingModfiyAlarm(
      int startHour,
      int startMin,
      int newType,
      int newStartHour,
      int newStartMin,
      String newWeekRepeat,
      int newDelayTime) {
    return YcProductPluginPlatform.instance.settingModfiyAlarm(
        startHour,
        startMin,
        newType,
        newStartHour,
        newStartMin,
        newWeekRepeat,
        newDelayTime);
  }

  ///来电提醒
  Future<PluginResponse?> updateCallAlerts(bool isAlerts) {
    return YcProductPluginPlatform.instance.updateCallAlerts(isAlerts);
  }

  Future<PluginResponse?> shutdown() {
    return YcProductPluginPlatform.instance.shutdown();
  }

  Future<PluginResponse?> startListening() {
    return YcProductPluginPlatform.instance.startListening();
  }

  Future<PluginResponse?> settingVibrationIntensity(int level) {
    return YcProductPluginPlatform.instance.settingVibrationIntensity(level);
  }
}
