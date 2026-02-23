import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'yc_product_plugin_method_channel.dart';
import 'yc_product_plugin_data_type.dart';

abstract class YcProductPluginPlatform extends PlatformInterface {
  /// Constructs a YcProductPluginPlatform.
  YcProductPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static YcProductPluginPlatform _instance = MethodChannelYcProductPlugin();

  /// The default instance of [YcProductPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelYcProductPlugin].
  static YcProductPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [YcProductPluginPlatform] when
  /// they register themselves.
  static set instance(YcProductPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> initPlugin(
      {bool isReconnectEnable = true, bool isLogEnable = false}) {
    throw UnimplementedError(
        'initPlugin({bool isReconnectEnable = true, bool isLogEnable = false}) has not been implemented.');
  }

  Future<void> clearQueue() {
    throw UnimplementedError('clearQueue has not been implemented.');
  }

  Future<void> resetBond() {
    throw UnimplementedError('resetBond has not been implemented.');
  }

  Future<void> exitScanDevice() {
    throw UnimplementedError('exitScanDevice has not been implemented.');
  }

  Future<List<BluetoothDevice>?> scanDevice({int time = 6}) {
    throw UnimplementedError('scanDevice has not been implemented.');
  }

  Future<void> stopScanDevice() {
    throw UnimplementedError('stopScanDevice has not been implemented.');
  }

  Future<void> setReconnectEnabled(bool isReconnectEnable) {
    throw UnimplementedError('setReconnectEnabled has not been implemented.');
  }

  /// 开启监听
  void onListening(void Function(dynamic event) onData) {
    throw UnimplementedError('onListening has not been implemented.');
  }

  /// 停止监听
  void cancelListening() {
    throw UnimplementedError('cancelListening has not been implemented.');
  }

  // 连接设备
  Future<bool?> connectDevice(String deviceIdentifier) {
    throw UnimplementedError('connectDevice has not been implemented.');
  }

  // 断开连接
  Future<bool?> disconnectDevice({String deviceIdentifier = ""}) {
    throw UnimplementedError('disconnectDevice has not been implemented.');
  }

  Future<int?> getBluetoothState() {
    throw UnimplementedError('getBluetoothState has not been implemented.');
  }

  /// 获取设备功能列表
  Future<DeviceFeature?> getDeviceFeature() {
    throw UnimplementedError('getDeviceFeature has not been implemented.');
  }

  /// 同步健康历史数据
  /// healthDataType - HealthDataType 数据类型
  /// 回值类型  Map {"code": PluginState, "datas": json }
  Future<PluginResponse<List>?> queryDeviceHealthData(int healthDataType) {
    throw UnimplementedError('queryDeviceHealthData has not been implemented.');
  }

  /// 删除健康历史数据
  /// healthDataType - HealthDataType 数据类型
  Future<PluginResponse?> deleteDeviceHealthData(int healthDataType) {
    throw UnimplementedError(
        'deleteDeviceHealthData has not been implemented.');
  }

  /// 查询设备的基本信息
  Future<PluginResponse<DeviceBasicInfo>?> queryDeviceBasicInfo() {
    throw UnimplementedError('queryDeviceBasicInfo has not been implemented.');
  }

  /// 查询设备mac地址
  Future<PluginResponse<String>?> queryDeviceMacAddress() {
    throw UnimplementedError('queryDeviceMacAddress has not been implemented.');
  }

  /// 查询设备型号
  Future<PluginResponse<String>?> queryDeviceModel() {
    throw UnimplementedError('queryDeviceModel has not been implemented.');
  }

  /// 查询设备平台
  Future<PluginResponse<DeviceMcuPlatform>?> queryDeviceMCU() {
    throw UnimplementedError('queryDeviceMCU has not been implemented.');
  }

  /// 设置时间
  Future<PluginResponse?> setDeviceSyncPhoneTime() {
    throw UnimplementedError(
        'setDeviceSyncPhoneTime has not been implemented.');
  }

  /// 设置运动步数目标
  Future<PluginResponse?> setDeviceStepGoal(int step) {
    throw UnimplementedError('setDeviceStepGoal has not been implemented.');
  }

  /// 设置睡眠目标
  Future<PluginResponse?> setDeviceSleepGoal(int hour, int minute) {
    throw UnimplementedError('setDeviceSleepGoal has not been implemented.');
  }

  /// 设置用户信息
  Future<PluginResponse?> setDeviceUserInfo(
      int height, int weight, int age, DeviceUserGender gender) {
    throw UnimplementedError('setDeviceUserInfo has not been implemented.');
  }

  /// 肤色设置
  Future<PluginResponse?> setDeviceSkinColor(
      {DeviceSkinColorLevel level = DeviceSkinColorLevel.yellow}) {
    throw UnimplementedError('setDeviceSkinColor has not been implemented.');
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
    throw UnimplementedError('setDeviceUnit has not been implemented.');
  }

  /// 防丢设置
  Future<PluginResponse?> setDeviceAntiLost(bool isEnable) {
    throw UnimplementedError('setDeviceAntiLost has not been implemented.');
  }

  /// 设置勿扰
  Future<PluginResponse?> setDeviceNotDisturb(bool isEnable, int startHour,
      int startMinute, int endHour, int endMinute) {
    throw UnimplementedError('setDeviceNotDisturb has not been implemented.');
  }

  /// 设置语言
  /// language - DeviceLanguageType
  Future<PluginResponse?> setDeviceLanguage(int language) {
    throw UnimplementedError('setDeviceLanguage has not been implemented.');
  }

  /// 久坐提醒
  /// isEnable 是否开启
  /// startXXX 开始时间
  /// endXXX  结束时间
  /// interval 15 ~ 15 分钟，其它值不可以使用
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
    throw UnimplementedError('setDeviceSedentary has not been implemented.');
  }

  Future<PluginResponse?> setDevicePeriodicReminderTask(
      DevicePeriodicReminderType reminderType,
      bool isEnable,
      int startHour,
      int startMinute,
      int endHour,
      int endMinute,
      int interval,
      Set<int> repeat,
      String content) {
    throw UnimplementedError(
        'setDevicePeriodicReminderTask has not been implemented.');
  }

  /// 左右手设置
  Future<PluginResponse?> setDeviceWearingPosition(
      DeviceWearingPositionType wearingPosition) {
    throw UnimplementedError(
        'setDeviceWearingPosition has not been implemented.');
  }

  /// 手机系统设置
  Future<PluginResponse?> setPhoneSystemInfo() {
    throw UnimplementedError('setPhoneSystemInfo has not been implemented.');
  }

  /// 抬腕亮屏
  Future<PluginResponse?> setDeviceWristBrightScreen(bool isEnable) {
    throw UnimplementedError(
        'setDeviceWristBrightScreen has not been implemented.');
  }

  /// 亮度设置
  Future<PluginResponse?> setDeviceDisplayBrightness(
      DeviceDisplayBrightnessLevel level) {
    throw UnimplementedError(
        'DeviceDisplayBrightnessLevel has not been implemented.');
  }

  /// 健康监测(心率监测)
  Future<PluginResponse?> setDeviceHealthMonitoringMode(
      {bool isEnable = true, int interval = 60}) {
    throw UnimplementedError(
        'setDeviceHealthMonitoringMode has not been implemented.');
  }

  /// 温度监测
  Future<PluginResponse?> setDeviceTemperatureMonitoringMode(
      {bool isEnable = true, int interval = 60}) {
    throw UnimplementedError(
        'setDeviceTemperatureMonitoringMode has not been implemented.');
  }

  /// 心率报警
  Future<PluginResponse?> setDeviceHeartRateAlarm(
      {bool isEnable = true, int maxHeartRate = 100, int minHeartRate = 30}) {
    throw UnimplementedError(
        'setDeviceHeartRateAlarm has not been implemented.');
  }

  /// 血压报警
  Future<PluginResponse?> setDeviceBloodPressureAlarm(
      bool isEnable,
      int maximumSystolicBloodPressure,
      int maximumDiastolicBloodPressure,
      int minimumSystolicBloodPressure,
      int minimumDiastolicBloodPressure) {
    throw UnimplementedError(
        'setDeviceBloodPressureAlarm has not been implemented.');
  }

  /// 血氧报警
  Future<PluginResponse?> setDeviceBloodOxygenAlarm(
      {bool isEnable = true, int minimum = 90}) {
    throw UnimplementedError(
        'setDeviceBloodOxygenAlarm has not been implemented.');
  }

  /// 呼吸率报警
  Future<PluginResponse?> setDeviceRespirationRateAlarm(
      bool isEnable, int maximum, int minimum) {
    throw UnimplementedError(
        'setDeviceRespirationRateAlarm has not been implemented.');
  }

  /// 温度报警
  Future<PluginResponse?> setDeviceTemperatureAlarm(
      bool isEnable, String maximumTemperature, String minimumTemperature) {
    throw UnimplementedError(
        'setDeviceTemperatureAlarm has not been implemented.');
  }

  /// 获取主题
  Future<PluginResponse<DeviceThemeInfo>?> queryDeviceTheme() {
    throw UnimplementedError('queryDeviceTheme has not been implemented.');
  }

  /// 设置主题
  Future<PluginResponse?> setDeviceTheme(int index) {
    throw UnimplementedError('setDeviceTheme has not been implemented.');
  }

  /// 设置睡眠提醒时间
  Future<PluginResponse?> setDeviceSleepReminder(
      bool isEnable, int hour, int minute, Set<int> repeat) {
    throw UnimplementedError(
        'setDeviceSleepReminder has not been implemented.');
  }

  /// 通知开关(ANCS)
  /// items - DeviceInfoPushType 成员
  Future<PluginResponse?> setDeviceInfoPush(
      bool isEnable, Set<DeviceInfoPushType> items) {
    throw UnimplementedError('setDeviceInfoPush has not been implemented.');
  }

  /// 恢复出厂设置
  Future<PluginResponse?> restoreFactorySettings() {
    throw UnimplementedError(
        'restoreFactorySettings has not been implemented.');
  }

  /// 生理周期
  /// time - 开始时间 秒
  /// duration - 经期持续天数
  /// cycle - 经期周期
  Future<PluginResponse?> sendDeviceMenstrualCycle(
      int time, int duration, int cycle) {
    throw UnimplementedError(
        'sendDeviceMenstrualCycle has not been implemented.');
  }

  /// 发送手机的UUID唯一识别码
  Future<PluginResponse?> sendPhoneUUIDToDevice(String content) {
    throw UnimplementedError('sendPhoneUUIDToDevice has not been implemented.');
  }

  /// 找设备
  Future<PluginResponse?> findDevice(
      {int remindCount = 5, int remindInterval = 1}) {
    throw UnimplementedError('findDevice has not been implemented.');
  }

  /// 关机、复位、重启
  Future<PluginResponse?> deviceSystemOperator(DeviceSystemOperator operator) {
    throw UnimplementedError('deviceSystemOperator has not been implemented.');
  }

  /// 血压校准
  Future<PluginResponse?> bloodPressureCalibration(
      int systolicBloodPressure, int diastolicBloodPressure) {
    throw UnimplementedError(
        'bloodPressureCalibration has not been implemented.');
  }

  /// 温度校准
  Future<PluginResponse?> temperatureCalibration() {
    throw UnimplementedError(
        'temperatureCalibration has not been implemented.');
  }

  /// 血糖标定
  Future<PluginResponse?> bloodGlucoseCalibration(
      DeviceBloodGlucoseCalibrationaMode mode, String value) {
    throw UnimplementedError(
        'bloodGlucoseCalibration has not been implemented.');
  }

  /// 发送天气
  Future<PluginResponse?> sendTodayWeather(DeviceWeatherType weatherType,
      int lowestTemperature, int highestTemperature, int realTimeTemperature) {
    throw UnimplementedError('sendTodayWeather has not been implemented.');
  }

  /// 发送明日天气
  Future<PluginResponse?> sendTomorrowWeather(DeviceWeatherType weatherType,
      int lowestTemperature, int highestTemperature, int realTimeTemperature) {
    throw UnimplementedError('sendTomorrowWeather has not been implemented.');
  }

  /// 波形上传控制
  Future<PluginResponse?> waveDataUpload(
      YCWaveUploadState state, YCWaveDataType dataType) {
    throw UnimplementedError('sendTomorrowWeather has not been implemented.');
  }

  /// 尿酸标定
  /// uricAcid - umol/L
  Future<PluginResponse?> uricAcidCalibration(int uricAcid) {
    throw UnimplementedError('uricAcidCalibration has not been implemented.');
  }

  /// 血脂校准
  /// cholesterol 胆固醇 - mmol/L
  Future<PluginResponse?> bloodFatCalibration(String cholesterol) {
    throw UnimplementedError('bloodFatCalibration has not been implemented.');
  }

  /// 消息推送
  Future<PluginResponse?> appPushNotifications(
      AndroidDevicePushNotificationType type, String title, String contents) {
    throw UnimplementedError('appPushNotifications has not been implemented.');
  }

  /// 名片下发
  Future<PluginResponse?> sendBusinessCard(int type, String contents) {
    throw UnimplementedError('sendBusinessCard has not been implemented.');
  }

  /// 查询名片
  Future<PluginResponse?> queryBusinessCard(int type) {
    throw UnimplementedError('queryBusinessCard has not been implemented.');
  }

  ///  设备退出睡眠
  Future<PluginResponse?> sendDeviceQuiteSleep() {
    throw UnimplementedError('sendDeviceQuiteSleep has not been implemented.');
  }

  ///  配置实时采样率
  Future<PluginResponse?> appConfigureSampleRate(int type, int sampleRate) {
    throw UnimplementedError(
        'configRealTimeSamplingRate has not been implemented.');
  }

  /// 配置实时PPG参数
  Future<PluginResponse?> appConfigureRealTimePpg(
      List<int> ledCombList,
      int proximityLedRaw,
      List<int> redPdList,
      List<int> infraredPdList,
      List<int> greenPdList,
      List<int> redLedList,
      List<int> infraredLedList,
      List<int> greenLedList) {
    throw UnimplementedError(
        'configRealTimePPGParam has not been implemented.');
  }

  /// 查询MEMS传感器配置
  Future<PluginResponse?> appQueryMems() {
    throw UnimplementedError('queryMemsSensorConfig has not been implemented.');
  }

  ///  MEMS开关控制
  Future<PluginResponse?> appMemsSwitch(bool isEnable, List<int> type) {
    throw UnimplementedError('appControlMems has not been implemented.');
  }

  /// 控制设备进入或退出拍照
  Future<PluginResponse?> appControlTakePhoto(bool isEnable) {
    throw UnimplementedError('appControlTakePhoto has not been implemented.');
  }

  /// 控制运动
  Future<PluginResponse?> appControlSport(
      DeviceSportState state, int sportType) {
    throw UnimplementedError('appControlSport has not been implemented.');
  }

  /// 测试类型
  Future<PluginResponse?> appControlMeasureHealthData(
      bool isEnable, DeviceAppControlMeasureHealthDataType healthDataType) {
    throw UnimplementedError(
        'appControlMeasureHealthData has not been implemented.');
  }

  /// 控制实时数据上传
  Future<PluginResponse?> realTimeDataUpload(
      bool isEnable, DeviceRealTimeDataType dataType) {
    throw UnimplementedError('realTimeDataUpload has not been implemented.');
  }

  /// 开启ECG测量
  Future<PluginResponse?> startECGMeasurement() {
    throw UnimplementedError('startECGMeasurement has not been implemented.');
  }

  /// 结束ECG测量
  Future<PluginResponse?> stopECGMeasurement() {
    throw UnimplementedError('stopECGMeasurement has not been implemented.');
  }

  /// 获取ECG的结果
  Future<PluginResponse<DeviceECGResult>?> getECGResult() {
    throw UnimplementedError('getECGResult has not been implemented.');
  }

  /// 查询基本信息
  Future<PluginResponse?> queryCollectDataBasicInfo(
      DeviceCollectDataType type) {
    throw UnimplementedError(
        'queryCollectDataBasicInfo has not been implemented.');
  }

  /// 查询历史记录
  Future<PluginResponse?> queryCollectDataInfo(
      DeviceCollectDataType type, int index) {
    throw UnimplementedError('queryCollectDataInfo has not been implemented.');
  }

  /// 删除历史记录
  Future<PluginResponse?> deleteCollectData(
      DeviceCollectDataType type, int index) {
    throw UnimplementedError('deleteCollectData has not been implemented.');
  }

  /// 开始语音识别
  Future<PluginResponse?> startSpeechRecognition() {
    throw UnimplementedError(
        'startSpeechRecognition has not been implemented.');
  }

  /// 结束语音识别
  Future<PluginResponse?> stopSpeechRecognition() {
    throw UnimplementedError('stopSpeechRecognition has not been implemented.');
  }

  /// OTA升级
  Future<void> deviceUpgrade(DeviceMcuPlatform mcuPlatform,
      String firmwareAbsolutePath, OTAProcessCallback processCallBack) {
    throw UnimplementedError('deviceUpgrade has not been implemented.');
  }

  /// 查询表盘信息
  Future<PluginResponse<List<DeviceWatchInfo>>?> queryWatchFaceInfo() {
    throw UnimplementedError('queryWatchFaceInfo has not been implemented.');
  }

  /// 切换表盘
  Future<PluginResponse?> changeWatchFace(int dialID) {
    throw UnimplementedError('changeWatchFace has not been implemented.');
  }

  /// 删除表盘
  Future<PluginResponse?> deleteWatchFace(int dialID) {
    throw UnimplementedError('deleteWatchFace has not been implemented.');
  }

  /// 下载表盘
  Future<PluginResponse?> installWatchFace(
      bool isEnable,
      int dialID,
      int blockCount,
      int dialVersion,
      String filePath,
      ProcessCallback processCallback) {
    throw UnimplementedError('installWatchFace has not been implemented.');
  }

  /// 获取自定义表盘的参数
  Future<PluginResponse<DeviceCustomWatchFaceDataInfo>?>
      queryDeviceCustomWatchFaceInfo(String filePath) {
    throw UnimplementedError(
        'queryDeviceCustomWatchFaceInfo has not been implemented.');
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
    throw UnimplementedError(
        'installCustomWatchFace has not been implemented.');
  }

  /// 切换杰理表盘
  Future<PluginResponse?> changeJieLiWatchFace(String watchName) {
    throw UnimplementedError('changeJieLiWatchFace has not been implemented.');
  }

  /// 删除杰理表盘
  Future<PluginResponse?> deleteJieLiWatchFace(String watchName) {
    throw UnimplementedError('deleteJieLiWatchFace has not been implemented.');
  }

  /// 下载表盘
  Future<PluginResponse?> installJieLiWatchFace(
      String watchName, String filePath, ProcessCallback processCallback) {
    throw UnimplementedError('installJieLiWatchFace has not been implemented.');
  }

  /// 查询设备信息
  Future<PluginResponse<DeviceDisplayParametersInfo>?>
      queryDeviceDisplayParametersInfo() {
    throw UnimplementedError(
        'queryDeviceDisplayParametersInfo has not been implemented.');
  }

  /// 下载自定义杰理表盘
  Future<PluginResponse?> installJieLiCustomWatchFace(
      String watchName,
      String backgroundPath,
      String thumbnailPath,
      DeviceWatchFaceTimePosition timePosition,
      int timeTextColor,
      DeviceDisplayParametersInfo info,
      ProcessCallback processCallback) {
    throw UnimplementedError(
        'installJieLiCustomWatchFace has not been implemented.');
  }

  /// 查询杰理通讯录
  Future<PluginResponse<List<DeviceContactInfo>>?> queryJieLiDeviceContacts() {
    throw UnimplementedError(
        'queryJieLiDeviceContacts has not been implemented.');
  }

  /// 更新杰理通讯录
  Future<PluginResponse?> updateJieLiDeviceContacts(
      List<DeviceContactInfo> items) {
    throw UnimplementedError(
        'updateJieLiDeviceContacts has not been implemented.');
  }

  /// 更新通讯录
  Future<PluginResponse?> updateDeviceContacts(List<DeviceContactInfo> items) {
    throw UnimplementedError('updateDeviceContacts has not been implemented.');
  }

  /// 获取日志文件
  Future<PluginResponse?> getLogFilePath(LoggerType logType) {
    throw UnimplementedError('getLogFilePath has not been implemented.');
  }

  /// 清除日志文件
  Future<PluginResponse?> clearSDKLog() {
    throw UnimplementedError('getLogFilePath has not been implemented.');
  }

  Future<PluginResponse?> shareLogFile() {
    throw UnimplementedError('shareLogFile has not been implemented.');
  }

  Future<PluginResponse?> settingGetAllAlarm() {
    throw UnimplementedError('getLogFilePath has not been implemented.');
  }

  Future<PluginResponse?> settingAddAlarm(
      int type, int startHour, int startMin, String weekRepeat, int delayTime) {
    throw UnimplementedError('getLogFilePath has not been implemented.');
  }

  Future<PluginResponse?> settingModfiyAlarm(
      int startHour,
      int startMin,
      int newType,
      int newStartHour,
      int newStartMin,
      String newWeekRepeat,
      int newDelayTime) {
    throw UnimplementedError('getLogFilePath has not been implemented.');
  }

  Future<PluginResponse?> updateCallAlerts(bool isAlerts) {
    throw UnimplementedError('isAlerts has not been implemented.');
  }

  Future<PluginResponse?> shutdown() {
    throw UnimplementedError('isAlerts has not been implemented.');
  }

  Future<PluginResponse?> startListening() {
    throw UnimplementedError('isAlerts has not been implemented.');
  }

  Future<PluginResponse?> settingVibrationIntensity(int level) {
    throw UnimplementedError(
        'settingVibrationIntensity has not been implemented.');
  }
}
