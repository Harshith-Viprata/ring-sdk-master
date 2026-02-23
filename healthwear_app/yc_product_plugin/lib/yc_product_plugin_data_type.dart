// 插件中需要到的类的定义

import 'dart:core';

/// OTA回调
/// code -  状态码 DeviceUpdateState
/// process - 进度 0.0 ~ 1.0
/// errorString - 错误信息
typedef OTAProcessCallback = void Function(
    int code, double process, String? errorString);

/// 普通进度条
typedef ProcessCallback = OTAProcessCallback;

/// 升级状态
class DeviceUpdateState {
  static const int start = 0; // 开始
  static const int upgradingResources = 1; // 升级资源
  static const int upgradeResourcesFinished = 2; // 升级资源结束
  static const int upgradingFirmware = 3; // 升级固件
  static const int succeed = 4;
  static const int failed = 5;

  static const int installingWatchFace = 6; // 安装表盘
}

/// 插件结果
class PluginResponse<T> {
  /// 结果状态  PluginState
  final int statusCode;

  /// 结果列表
  final T data;

  /// 构造
  PluginResponse(this.statusCode, this.data);
}

/// 插件API的状态
class PluginState {
  static const int succeed = 0; // 执行成功
  static const int failed = 1; // 执行失败
  static const int unavailable = 2; // 设备不支持
}

/// 原生传递事件类型
class NativeEventType {
  /// 连接设备信息
  static const String deviceInfo = "deviceInfo";

  /// 蓝牙状态变化
  static const String bluetoothStateChange = "bluetoothStateChange";

  /// 设备拍照状态变化
  static const String deviceControlPhotoStateChange =
      "deviceControlPhotoStateChange";

  /// 设备找手机状态变化
  static const String deviceControlFindPhoneStateChange =
      "deviceControlFindPhoneStateChange";

  /// 设备一键测量状态变化
  static const String deviceHealthDataMeasureStateChange =
      "deviceHealthDataMeasureStateChange";

  /// 设备运动状态变化
  static const String deviceSportStateChange = "deviceSportStateChange";

  /// 设备表盘切换变更
  static const String deviceWatchFaceChange = "deviceWatchFaceChange";

  /// 杰理表盘切换变更
  static const String deviceJieLiWatchFaceChange = "deviceJieLiWatchFaceChange";

  // MARK: - 实时数据

  /// 计步
  static const String deviceRealStep = "deviceRealStep";

  /// 运动
  static const String deviceRealSport = "deviceRealSport";

  /// 心率
  static const String deviceRealHeartRate = "deviceRealHeartRate";

  /// 血压
  static const String deviceRealBloodPressure = "deviceRealBloodPressure";

  /// 血氧
  static const String deviceRealBloodOxygen = "deviceRealBloodOxygen";

  /// 温度
  static const String deviceRealTemperature = "deviceRealTemperature";

  /// 压力
  static const String deviceRealPressure = "deviceRealPressure";

  /// 最大摄氧量
  static const String deviceRealVo2max = "deviceRealVo2max";

  /// 血糖
  static const String deviceRealBloodGlucose = "deviceRealBloodGlucose";

  /// HRV
  static const String deviceRealHRV = "deviceRealHRV";

  /// 实时ECG数据
  static const String deviceRealECGData = "deviceRealECGData";

  /// 实时ACC数据
  static const String deviceRealACCData = "deviceRealACCData";

  /// 实时ECG数据滤波数据
  static const String deviceRealECGFilteredData = "deviceRealECGFilteredData";

  /// 实时PPG数据
  static const String deviceRealPPGData = "deviceRealPPGData";

  /// 多通道PPG数据
  static const String deviceMultiChannelPPGData = "deviceMultiChannelPPGData";

  /// 实时RR数据
  static const String deviceRealECGAlgorithmRR = "deviceRealECGAlgorithmRR";

  /// 实时HRV数据
  static const String deviceRealECGAlgorithmHRV = "deviceRealECGAlgorithmHRV";

  static final String deviceEndECG = "deviceEndECG";

  static final String appECGPPGStatus = "appECGPPGStatus";

  /// 杰理语音识别状态
  static final String deviceJLAudioState = "deviceJLAudioState";

  /// 杰理语音识别完成
  static final String deviceJLAudioComplete = "deviceJLAudioComplete";
}

// ============     蓝牙相关 ================

/// 蓝牙状态
class BluetoothState {
  static const int off = 0; // 蓝牙关闭
  static const int on = 1; // 蓝牙开启
  static const int connected = 2; // 连接
  static const int connectFailed = 3; // 连接失败
  static const int disconnected = 4; // 断开连接
}

/// 蓝牙属性
class BluetoothDevice {
  /// mac地址(iOS可能会获取不到)
  String macAddress = "";

  /// 设备的标示(iOS, Android上与macAddress相同， 连接蓝牙使用)
  String deviceIdentifier = "";

  /// 设备名称
  String name = "";

  /// 信号值
  int rssiValue = 0;

  /// 设备固件版本号
  int firmwareVersion = 0;

  /// 设备圈号
  int deviceSize = 0;

  /// 设备颜色
  int deviceColor = 0;

  /// 图片索引值
  int imageIndex = 0;

  // 实例化蓝牙设备
  BluetoothDevice.formJson(Map json) {
    macAddress = json["macAddress"];
    deviceIdentifier = json["deviceIdentifier"];
    name = json["name"];
    rssiValue = json["rssiValue"];
    if (json.containsKey("firmwareVersion")) {
      firmwareVersion = json["firmwareVersion"];
    }
    if (json.containsKey("deviceSize")) {
      deviceSize = json["deviceSize"];
    }
    if (json.containsKey("deviceColor")) {
      deviceColor = json["deviceColor"];
    }
    if (json.containsKey("imageIndex")) {
      imageIndex = json["imageIndex"];
    }
  }

  /// 功能列表
  DeviceFeature? deviceFeature;

  /// 设备平台
  DeviceMcuPlatform? mcuPlatform;

  /// 设备型号
  String? deviceModel;
}

/// 芯片型号
enum DeviceMcuPlatform { nrf52832, rtk8762c, rtk8762d, jl701n, jl632n }

/// 功能列表
class DeviceFeature {
  /// 血压
  bool isSupportBloodPressure = false;

  /// 语言设置
  bool isSupportLanguageSettings = false;

  /// 消息推送 (总开关)
  bool isSupportInformationPush = false;

  /// 心率
  bool isSupportHeartRate = false;

  /// OTA升级
  bool isSupportOta = true;

  /// 实时数据上传
  bool isSupportRealTimeDataUpload = false;

  /// 睡眠
  bool isSupportSleep = false;

  /// 计步
  bool isSupportStep = false;

  // MARK: - === 主要功能2 ===

  /// 多运动
  bool isSupportSport = false;

  /// HRV
  bool isSupportHRV = false;

  /// 呼吸率
  bool isSupportRespirationRate = false;

  /// 血氧
  bool isSupportBloodOxygen = false;

  /// 历史ECG
  bool isSupportHistoricalECG = false;

  /// 实时ECG
  bool isSupportRealTimeECG = false;

  /// 血压告警
  bool isSupportBloodPressureAlarm = false;

  /// 心率告警
  bool isSupportHeartRateAlarm = false;

  // MARK: - === 闹钟类型 ====

  /// 闹钟数量( alarmClockCount 0表示不支持闹钟)
  bool isSupportAlarm = false;

  /// 闹钟类型 起床
  bool isSupportAlarmTypeWakeUp = false;

  /// 闹钟类型 起床
  bool isSupportAlarmTypeSleep = false;

  /// 闹钟类型 锻炼
  bool isSupportAlarmTypeExercise = false;

  /// 闹钟类型 吃药
  bool isSupportAlarmTypeMedicine = false;

  /// 闹钟类型 约会
  bool isSupportAlarmTypeAppointment = false;

  /// 闹钟类型 聚会
  bool isSupportAlarmTypeParty = false;

  /// 闹钟类型 会议
  bool isSupportAlarmTypeMeeting = false;

  /// 闹钟类型 自定义
  bool isSupportAlarmTypeCustom = false;

  // MARK: - === 消息推送 ===

  // 第一组
  bool isSupportInformationTypeTwitter = false;
  bool isSupportInformationTypeFacebook = false;
  bool isSupportInformationTypeWeiBo = false;
  bool isSupportInformationTypeQQ = false;
  bool isSupportInformationTypeWeChat = false;
  bool isSupportInformationTypeEmail = false;
  bool isSupportInformationTypeSMS = false;
  bool isSupportInformationTypeCall = false;

  // 第二组
  bool isSupportInformationTypeTelegram = false;
  bool isSupportInformationTypeSkype = false;
  bool isSupportInformationTypeSnapchat = false;
  bool isSupportInformationTypeLine = false;
  bool isSupportInformationTypeLinkedIn = false;
  bool isSupportInformationTypeInstagram = false;
  bool isSupportInformationTypeMessenger = false;
  bool isSupportInformationTypeWhatsApp = false;

  // MARK: - === 其它功能1 ===

  /// 翻腕亮屏
  bool isSupportWristBrightScreen = false;

  /// 勿扰模式
  bool isSupportDoNotDisturbMode = false;

  /// 血压水平设置
  bool isSupportBloodPressureLevelSetting = false;

  /// 出厂设置
  bool isSupportFactorySettings = false;

  /// 找设备
  bool isSupportFindDevice = false;

  /// 找手机
  bool isSupportFindPhone = false;

  /// 防丢提醒
  bool isSupportAntiLostReminder = false;

  /// 久坐提醒
  bool isSupportSedentaryReminder = false;

  // MARK: - === 其它功能2 ===

  /// 上传数据 加密
  bool isSupportUploadDataEncryption = false;

  /// 通话
  bool isSupportCall = false;

  /// 心电诊断
  bool isSupportECGDiagnosis = false;

  /// 明日天气
  bool isSupportTomorrowWeather = false;

  /// 今日天气
  bool isSupportTodayWeather = false;

  /// 搜周边
  bool isSupportSearchAround = false;

  /// 微信运动
  bool isSupportWeChatSports = false;

  /// 肤色设置
  bool isSupportSkinColorSettings = false;

  // MARK: - === 其它功能3 ===

  /// 温度
  bool isSupportTemperature = false;

  /// 压力
  bool isSupportPressure = false;

  /// 最大摄据量
  bool isSupportVo2max = false;

  /// 音乐控制
  bool isSupportMusicControl = false;

  /// 主题
  bool isSupportTheme = false;

  /// 电极位置
  bool isSupportElectrodePosition = false;

  /// 血压校准
  bool isSupportBloodPressureCalibration = false;

  /// CVRR
  bool isSupportCVRR = false;

  /// 腋温测量
  bool isSupportAxillaryTemperatureMeasurement = false;

  /// 温度预警
  bool isSupportTemperatureAlarm = false;

  // MARK: - === 其它功能4 ===

  /// 温度校准
  bool isSupportTemperatureCalibration = false;

  /// 机主信息编辑
  bool isSupportHostInfomationEdit = false;

  /// 手动拍照
  bool isSupportManualPhotographing = false;

  /// 摇一摇拍照
  bool isSupportShakePhotographing = false;

  /// 女性生理周期
  bool isSupportFemalePhysiologicalCycle = false;

  /// 表盘功能
  bool isSupportWatchFace = false;

  /// 通讯录
  bool isSupportAddressBook = false;

  /// ECG结果精准
  bool isECGResultsAccurate = true;

  // MARK: - 运动模式

  /// 登山
  bool isSupportMountaineering = false;

  /// 足球
  bool isSupportFootball = false;

  /// 乒乓球
  bool isSupportPingPang = false;

  /// 户外跑步
  bool isSupportOutdoorRunning = false;

  /// 室内跑步
  bool isSupportIndoorRunning = false;

  /// 户外步行
  bool isSupportOutdoorWalking = false;

  /// 室内步行
  bool isSupportIndoorWalking = false;

  /// 实时监护模式
  bool isSupportRealTimeMonitoring = false;

  /// 羽毛球
  bool isSupportBadminton = false;

  /// 健走
  bool isSupportWalk = false;

  /// 游泳
  bool isSupportSwimming = false;

  /// 篮球
  bool isSupportPlayBall = false;

  /// 跳绳
  bool isSupportRopeSkipping = false;

  /// 骑行
  bool isSupportRiding = false;

  /// 健身
  bool isSupportFitness = false;

  /// 跑步
  bool isSupportRun = false;

  /// 室内骑行
  bool isSupportIndoorRiding = false;

  /// 踏步机
  bool isSupportStepper = false;

  /// 划船机
  bool isSupportRowingMachine = false;

  /// 仰卧起坐
  bool isSupportSitUps = false;

  /// 跳跃运动
  bool isSupportJumping = false;

  /// 重量训练
  bool isSupportWeightTraining = false;

  /// 瑜伽
  bool isSupportYoga = false;

  /// 徒步
  bool isSupportOnFoot = false;

  // MARK: - === 扩充功能

  /// 同步运动实时数据
  bool isSupportSyncRealSportData = false;

  /// 启动心率测量
  bool isSupportStartHeartRateMeasurement = false;

  /// 启动血压测量
  bool isSupportStartBloodPressureMeasurement = false;

  /// 启动血氧测量
  bool isSupportStartBloodOxygenMeasurement = false;

  /// 启动体温测量
  bool isSupportStartBodyTemperatureMeasurement = false;

  /// 启动压力测量
  bool isSupportStartPressureMeasurement = false;

  /// 启动呼吸率测量
  bool isSupportStartRespirationRateMeasurement = false;

  /// 启动血糖测量
  bool isSupportStartBloodGlucoseMeasurement = false;

  /// 启动hrv测量
  bool isSupportStartHRVMeasurement = false;

  /// 自定义表盘
  bool isSupportCustomWatchface = false;

  // =================================================================

  /// 精准血压测量
  bool isSupportAccurateBloodPressureMeasurement = false;

  /// SOS开关
  bool isSupportSOS = false;

  /// 血氧报警
  bool isSupportBloodOxygenAlarm = false;

  /// 精准血压实时数据上传
  bool isSupportAccurateBloodPressureRealTimeDataUpload = false;

  /// Viber消息推送
  bool isSupportInformationTypeViber = false;

  /// 其它消息推送
  bool isSupportInformationTypeOther = false;

  /// 自定义表盘颜色翻转
  bool isFlipCustomDialColor = false;

  /// 手表亮度调节五档
  bool isSupportFiveSpeedBrightness = false;

  // =================================================================

  /// 震动强度设置
  bool isSupportVibrationIntensitySetting = false;

  /// 亮屏时间设置
  bool isSupportScreenTimeSetting = false;

  /// 亮屏亮度调节
  bool isSupportScreenBrightnessAdjust = true;

  /// 血糖测量
  bool isSupportBloodGlucose = false;

  /// 运动暂停
  bool isSupportSportPause = false;

  /// 是否支持运动断开延迟
  bool isSupportMotionDelayDisconnect = false;

  /// 喝水提醒
  bool isSupportDrinkWaterReminder = false;

  /// 发送名片
  bool isSupportBusinessCard = false;

  /// 尿酸测量
  bool isSupportUricAcid = false;

  // MARK: - 运动模式4

  /// 网球
  bool isSupportVolleyball = false;

  /// 皮划艇
  bool isSupportKayak = false;

  /// 轮滑
  bool isSupportRollerSkating = false;

  /// 网球
  bool isSupportTennis = false;

  /// 高尔夫
  bool isSupportGolf = false;

  /// 椭圆机
  bool isSupportEllipticalMachine = false;

  /// 舞蹈
  bool isSupportDance = false;

  /// 攀岩
  bool isSupportRockClimbing = false;

  /// 健身操
  bool isSupportAerobics = false;

  /// 其它运动
  bool isSupportOtherSports = false;

  /// 血酮测量
  bool isSupportBloodKetone = false;

  /// 支持支付宝
  bool isSupportAliPay = false;

  /// 安卓绑定
  bool isSupportAndroidBind = false;

  /// 呼吸率告警
  bool isSupportRespirationRateAlarm = false;

  /// 血脂测量
  bool isSupportBloodFat = false;

  /// 独立监测时间(E200测量)
  bool isSupportIndependentMonitoringTime = false;

  /// 本地录音上传
  bool isSupportLocalRecordingFileUpload = false;

  /// 理疗记录
  bool isSupportPhysiotherapyRecords = false;

  /// 是否支持消息推送 Zoom
  bool isSupportInformationTypeZoom = false;

  /// 是否支持消息推送 TikTok
  bool isSupportInformationTypeTikTok = false;

  /// 是否支持消息推送 KakaoTalk
  bool isSupportInformationTypeKaKaoTalk = false;

  // MARK: -

  /// 是否支持睡眠提醒
  bool isSupportSleepReminder = false;

  /// 是否支持设备规格设置
  bool isSupportDeviceSpecificationsSetting = false;

  /// 是否支持设备本地运动上传
  bool isSupportLocalSportDataUpload = false;

  /// 构造
  DeviceFeature.fromJson(Map map) {
    /// 血压
    isSupportBloodPressure = map["isSupportBloodPressure"];

    /// 语言设置
    isSupportLanguageSettings = map["isSupportLanguageSettings"];

    /// 消息推送 (总开关)
    isSupportInformationPush = map["isSupportInformationPush"];

    /// 心率
    isSupportHeartRate = map["isSupportHeartRate"];

    /// OTA升级
    isSupportOta = map["isSupportOta"];

    /// 实时数据上传
    isSupportRealTimeDataUpload = map["isSupportRealTimeDataUpload"];

    /// 睡眠
    isSupportSleep = map["isSupportSleep"];

    /// 计步
    isSupportStep = map["isSupportStep"];

    // MARK: - === 主要功能2 ===

    /// 多运动
    isSupportSport = map["isSupportSport"];

    /// HRV
    isSupportHRV = map["isSupportHRV"];

    /// 呼吸率
    isSupportRespirationRate = map["isSupportRespirationRate"];

    /// 血氧
    isSupportBloodOxygen = map["isSupportBloodOxygen"];

    /// 历史ECG
    isSupportHistoricalECG = map["isSupportHistoricalECG"];

    /// 实时ECG
    isSupportRealTimeECG = map["isSupportRealTimeECG"];

    /// 血压告警
    isSupportBloodPressureAlarm = map["isSupportBloodPressureAlarm"];

    /// 心率告警
    isSupportHeartRateAlarm = map["isSupportHeartRateAlarm"];

    // MARK: - === 闹钟类型 ====

    /// 闹钟数量( alarmClockCount 0表示不支持闹钟)
    isSupportAlarm = map["isSupportAlarm"];

    /// 闹钟类型 起床
    isSupportAlarmTypeWakeUp = map["isSupportAlarmTypeWakeUp"];

    /// 闹钟类型 起床
    isSupportAlarmTypeSleep = map["isSupportAlarmTypeSleep"];

    /// 闹钟类型 锻炼
    isSupportAlarmTypeExercise = map["isSupportAlarmTypeExercise"];

    /// 闹钟类型 吃药
    isSupportAlarmTypeMedicine = map["isSupportAlarmTypeMedicine"];

    /// 闹钟类型 约会
    isSupportAlarmTypeAppointment = map["isSupportAlarmTypeAppointment"];

    /// 闹钟类型 聚会
    isSupportAlarmTypeParty = map["isSupportAlarmTypeParty"];

    /// 闹钟类型 会议
    isSupportAlarmTypeMeeting = map["isSupportAlarmTypeMeeting"];

    /// 闹钟类型 自定义
    isSupportAlarmTypeCustom = map["isSupportAlarmTypeCustom"];

    // MARK: - === 消息推送 ===

    // 第一组
    isSupportInformationTypeTwitter = map["isSupportInformationTypeTwitter"];
    isSupportInformationTypeFacebook = map["isSupportInformationTypeFacebook"];
    isSupportInformationTypeWeiBo = map["isSupportInformationTypeWeiBo"];
    isSupportInformationTypeQQ = map["isSupportInformationTypeQQ"];
    isSupportInformationTypeWeChat = map["isSupportInformationTypeWeChat"];
    isSupportInformationTypeEmail = map["isSupportInformationTypeEmail"];
    isSupportInformationTypeSMS = map["isSupportInformationTypeSMS"];
    isSupportInformationTypeCall = map["isSupportInformationTypeCall"];

    // 第二组
    isSupportInformationTypeTelegram = map["isSupportInformationTypeTelegram"];
    isSupportInformationTypeSkype = map["isSupportInformationTypeSkype"];
    isSupportInformationTypeSnapchat = map["isSupportInformationTypeSnapchat"];
    isSupportInformationTypeLine = map["isSupportInformationTypeLine"];
    isSupportInformationTypeLinkedIn = map["isSupportInformationTypeLinkedIn"];
    isSupportInformationTypeInstagram =
        map["isSupportInformationTypeInstagram"];
    isSupportInformationTypeMessenger =
        map["isSupportInformationTypeMessenger"];
    isSupportInformationTypeWhatsApp = map["isSupportInformationTypeWhatsApp"];

    // MARK: - === 其它功能1 ===

    /// 翻腕亮屏
    isSupportWristBrightScreen = map["isSupportWristBrightScreen"];

    /// 勿扰模式
    isSupportDoNotDisturbMode = map["isSupportDoNotDisturbMode"];

    /// 血压水平设置
    isSupportBloodPressureLevelSetting =
        map["isSupportBloodPressureLevelSetting"];

    /// 出厂设置
    isSupportFactorySettings = map["isSupportFactorySettings"];

    /// 找设备
    isSupportFindDevice = map["isSupportFindDevice"];

    /// 找手机
    isSupportFindPhone = map["isSupportFindPhone"];

    /// 防丢提醒
    isSupportAntiLostReminder = map["isSupportAntiLostReminder"];

    /// 久坐提醒
    isSupportSedentaryReminder = map["isSupportSedentaryReminder"];

    // MARK: - === 其它功能2 ===

    /// 上传数据 加密
    isSupportUploadDataEncryption = map["isSupportUploadDataEncryption"];

    /// 通话
    isSupportCall = map["isSupportCall"];

    /// 心电诊断
    isSupportECGDiagnosis = map["isSupportECGDiagnosis"];

    /// 明日天气
    isSupportTomorrowWeather = map["isSupportTomorrowWeather"];

    /// 今日天气
    isSupportTodayWeather = map["isSupportTodayWeather"];

    /// 搜周边
    isSupportSearchAround = map["isSupportSearchAround"];

    /// 微信运动
    isSupportWeChatSports = map["isSupportWeChatSports"];

    /// 肤色设置
    isSupportSkinColorSettings = map["isSupportSkinColorSettings"];

    // MARK: - === 其它功能3 ===

    /// 温度
    isSupportTemperature = map["isSupportTemperature"];

    ///压力
    isSupportPressure = map["isSupportPressure"];

    ///最大摄氧量
    isSupportVo2max = map["isSupportVo2max"];

    /// 音乐控制
    isSupportMusicControl = map["isSupportMusicControl"];

    /// 主题
    isSupportTheme = map["isSupportTheme"];

    /// 电极位置
    isSupportElectrodePosition = map["isSupportElectrodePosition"];

    /// 血压校准
    isSupportBloodPressureCalibration =
        map["isSupportBloodPressureCalibration"];

    /// CVRR
    isSupportCVRR = map["isSupportCVRR"];

    /// 腋温测量
    isSupportAxillaryTemperatureMeasurement =
        map["isSupportAxillaryTemperatureMeasurement"];

    /// 温度预警
    isSupportTemperatureAlarm = map["isSupportTemperatureAlarm"];

    // MARK: - === 其它功能4 ===

    /// 温度校准
    isSupportTemperatureCalibration = map["isSupportTemperatureCalibration"];

    /// 机主信息编辑
    isSupportHostInfomationEdit = map["isSupportHostInfomationEdit"];

    /// 手动拍照
    isSupportManualPhotographing = map["isSupportManualPhotographing"];

    /// 摇一摇拍照
    isSupportShakePhotographing = map["isSupportShakePhotographing"];

    /// 女性生理周期
    isSupportFemalePhysiologicalCycle =
        map["isSupportFemalePhysiologicalCycle"];

    /// 表盘功能
    isSupportWatchFace = map["isSupportWatchFace"];

    /// 通讯录
    isSupportAddressBook = map["isSupportAddressBook"];

    /// ECG结果精准
    isECGResultsAccurate = map["isECGResultsAccurate"];

    // MARK: - 运动模式

    /// 登山
    isSupportMountaineering = map["isSupportMountaineering"];

    /// 足球
    isSupportFootball = map["isSupportFootball"];

    /// 乒乓球
    isSupportPingPang = map["isSupportPingPang"];

    /// 户外跑步
    isSupportOutdoorRunning = map["isSupportOutdoorRunning"];

    /// 室内跑步
    isSupportIndoorRunning = map["isSupportIndoorRunning"];

    /// 户外步行
    isSupportOutdoorWalking = map["isSupportOutdoorWalking"];

    /// 室内步行
    isSupportIndoorWalking = map["isSupportIndoorWalking"];

    /// 实时监护模式
    isSupportRealTimeMonitoring = map["isSupportRealTimeMonitoring"];

    /// 羽毛球
    isSupportBadminton = map["isSupportBadminton"];

    /// 健走
    isSupportWalk = map["isSupportWalk"];

    /// 游泳
    isSupportSwimming = map["isSupportSwimming"];

    /// 篮球
    isSupportPlayBall = map["isSupportPlayBall"];

    /// 跳绳
    isSupportRopeSkipping = map["isSupportRopeSkipping"];

    /// 骑行
    isSupportRiding = map["isSupportRiding"];

    /// 健身
    isSupportFitness = map["isSupportFitness"];

    /// 跑步
    isSupportRun = map["isSupportRun"];

    /// 室内骑行
    isSupportIndoorRiding = map["isSupportIndoorRiding"];

    /// 踏步机
    isSupportStepper = map["isSupportStepper"];

    /// 划船机
    isSupportRowingMachine = map["isSupportRowingMachine"];

    /// 仰卧起坐
    isSupportSitUps = map["isSupportSitUps"];

    /// 跳跃运动
    isSupportJumping = map["isSupportJumping"];

    /// 重量训练
    isSupportWeightTraining = map["isSupportWeightTraining"];

    /// 瑜伽
    isSupportYoga = map["isSupportYoga"];

    /// 徒步
    isSupportOnFoot = map["isSupportOnFoot"];

    // MARK: - === 扩充功能

    /// 同步运动实时数据
    isSupportSyncRealSportData = map["isSupportSyncRealSportData"];

    /// 启动心率测量
    isSupportStartHeartRateMeasurement =
        map["isSupportStartHeartRateMeasurement"];

    /// 启动血压测量
    isSupportStartBloodPressureMeasurement =
        map["isSupportStartBloodPressureMeasurement"];

    /// 启动血氧测量
    isSupportStartBloodOxygenMeasurement =
        map["isSupportStartBloodOxygenMeasurement"];

    /// 启动体温测量
    isSupportStartBodyTemperatureMeasurement =
        map["isSupportStartBodyTemperatureMeasurement"];

    /// 启动压力测量
    isSupportStartPressureMeasurement =
        map["isSupportStartPressureMeasurement"];

    /// 启动呼吸率测量
    isSupportStartRespirationRateMeasurement =
        map["isSupportStartRespirationRateMeasurement"];

    /// 启动血糖测量
    isSupportStartBloodGlucoseMeasurement =
        map["isSupportStartBloodGlucoseMeasurement"];

    /// 启动HRV测量
    isSupportStartHRVMeasurement = map["isSupportStartHRVMeasurement"];

    /// 自定义表盘
    isSupportCustomWatchface = map["isSupportCustomWatchface"];

    // =========

    /// 精准血压测量
    isSupportAccurateBloodPressureMeasurement =
        map["isSupportAccurateBloodPressureMeasurement"];

    /// SOS开关
    isSupportSOS = map["isSupportSOS"];

    /// 血氧报警
    isSupportBloodOxygenAlarm = map["isSupportBloodOxygenAlarm"];

    /// 精准血压实时数据上传
    isSupportAccurateBloodPressureRealTimeDataUpload =
        map["isSupportAccurateBloodPressureRealTimeDataUpload"];

    /// Viber消息推送
    isSupportInformationTypeViber = map["isSupportInformationTypeViber"];

    /// 其它消息推送
    isSupportInformationTypeOther = map["isSupportInformationTypeOther"];

    /// 自定义表盘颜色翻转
    isFlipCustomDialColor = map["isFlipCustomDialColor"];

    /// 手表亮度调节五档
    isSupportFiveSpeedBrightness = map["isSupportFiveSpeedBrightness"];

    // =============

    /// 震动强度设置
    isSupportVibrationIntensitySetting =
        map["isSupportVibrationIntensitySetting"];

    /// 亮屏时间设置
    isSupportScreenTimeSetting = map["isSupportScreenTimeSetting"];

    /// 亮屏亮度调节
    isSupportScreenBrightnessAdjust = map["isSupportScreenBrightnessAdjust"];

    /// 血糖测量
    isSupportBloodGlucose = map["isSupportBloodGlucose"];

    /// 运动暂停
    isSupportSportPause = map["isSupportSportPause"];

    /// 是否支持运动断开延迟
    isSupportMotionDelayDisconnect = map["isSupportMotionDelayDisconnect"];

    /// 喝水提醒
    isSupportDrinkWaterReminder = map["isSupportDrinkWaterReminder"];

    /// 发送名片
    isSupportBusinessCard = map["isSupportBusinessCard"];

    /// 尿酸测量
    isSupportUricAcid = map["isSupportUricAcid"];

    // MARK: - 运动模式4

    /// 网球
    isSupportVolleyball = map["isSupportVolleyball"];

    /// 皮划艇
    isSupportKayak = map["isSupportKayak"];

    /// 轮滑
    isSupportRollerSkating = map["isSupportRollerSkating"];

    /// 网球
    isSupportTennis = map["isSupportTennis"];

    /// 高尔夫
    isSupportGolf = map["isSupportGolf"];

    /// 椭圆机
    isSupportEllipticalMachine = map["isSupportEllipticalMachine"];

    /// 舞蹈
    isSupportDance = map["isSupportDance"];

    /// 攀岩
    isSupportRockClimbing = map["isSupportRockClimbing"];

    /// 健身操
    isSupportAerobics = map["isSupportAerobics"];

    /// 其它运动
    isSupportOtherSports = map["isSupportOtherSports"];

    /// 血酮测量
    isSupportBloodKetone = map["isSupportBloodKetone"];

    /// 支持支付宝
    isSupportAliPay = map["isSupportAliPay"];

    /// 安卓绑定
    isSupportAndroidBind = map["isSupportAndroidBind"];

    /// 呼吸率告警
    isSupportRespirationRateAlarm = map["isSupportRespirationRateAlarm"];

    /// 血脂测量
    isSupportBloodFat = map["isSupportBloodFat"];

    /// 独立监测时间(E200测量)
    isSupportIndependentMonitoringTime =
        map["isSupportIndependentMonitoringTime"];

    /// 本地录音上传
    isSupportLocalRecordingFileUpload =
        map["isSupportLocalRecordingFileUpload"];

    /// 理疗记录
    isSupportPhysiotherapyRecords = map["isSupportPhysiotherapyRecords"];

    /// 是否支持消息推送 Zoom
    isSupportInformationTypeZoom = map["isSupportInformationTypeZoom"];

    /// 是否支持消息推送 TikTok
    isSupportInformationTypeTikTok = map["isSupportInformationTypeTikTok"];

    /// 是否支持消息推送 KakaoTalk
    isSupportInformationTypeKaKaoTalk =
        map["isSupportInformationTypeKaKaoTalk"];

    // MARK: -

    /// 是否支持睡眠提醒
    isSupportSleepReminder = map["isSupportSleepReminder"];

    /// 是否支持设备规格设置
    isSupportDeviceSpecificationsSetting =
        map["isSupportDeviceSpecificationsSetting"];

    /// 是否支持设备本地运动上传
    isSupportLocalSportDataUpload = map["isSupportLocalSportDataUpload"];
  }
}

// MARK: ===========  健康数据  ===========

/// 健康数据类型
class HealthDataType {
  static const step = 0; // 步数(步数、距离、卡咱里)
  static const sleep = 1; // 睡眠
  static const heartRate = 2; // 心率
  static const bloodPressure = 3; // 血压
  static const combinedData = 4; // 组合数据(体温、血氧、呼吸率、血糖等)
  static const invasiveComprehensiveData = 5; // 有创数据 (血脂和尿酸)
  static const sportHistoryData = 6;
  static const bodyIndexData = 7; // 运动历史记录
  static const historyWearData = 8; // 设备佩戴历史记录
}

/// 佩戴装袋
class HistoryWearInfo {
  int startTimeStamp = 0;
  int wearType = 0;

  /// 0: 放置, 1: 充电, 2: 佩戴
  HistoryWearInfo.fromJson(Map map) {
    if (map == null) return;

    // 处理 startTimeStamp（可能是 String 或 int）
    dynamic timeValue = map["startTimeStamp"];
    if (timeValue is String) {
      // 尝试将字符串转为整数（如 "1620000000" -> 1620000000）
      startTimeStamp = int.tryParse(timeValue) ?? 0;
    } else if (timeValue is int) {
      startTimeStamp = timeValue;
    } else {
      startTimeStamp = 0; // 无效类型时默认值
    }

    // 处理 wearType（可能是 String 或 int）
    dynamic typeValue = map["YCWearingType"];
    print("map: $map");
    if (typeValue is String) {
      wearType = int.tryParse(typeValue) ?? 0;
    } else if (typeValue is int) {
      wearType = typeValue;
    } else {
      wearType = 0; // 无效类型时默认值
    }
  }

  @override
  String toString() {
    return "\nstartTimeStamp: $startTimeStamp, \wearType: $wearType";
  }
}

/// 步数
class StepDataInfo {
  int startTimeStamp = 0;
  int endTimeStamp = 0;

  int step = 0;
  int distance = 0;
  int calories = 0;

  StepDataInfo.fromJson(Map map) {
    if (map != null) {
      startTimeStamp = map["startTimeStamp"];
      endTimeStamp = map["endTimeStamp"];

      step = map["step"];
      distance = map["distance"];
      calories = map["calories"];
    }
  }

  @override
  String toString() {
    return "\nstartTimeStamp: $startTimeStamp, \nendTimeStamp: $endTimeStamp, \n step:$step, \n distance: $distance, \ncalories= $calories";
  }
}

/// 睡眠状态
class SleepType {
  static const int deepSleep = 0xF1;
  static const int lightSleep = 0xF2;
  static const int rem = 0xF3;
  static const int awake = 0xF4;
}

/// 睡眠的详细状态
class SleepDetailDataInfo {
  /// 开始时间
  int startTimeStamp = 0;

  /// 时长
  int duration = 0;

  /// 类型 使用 SleepType 判断
  int sleepType = 0;

  SleepDetailDataInfo.fromJson(Map map) {
    if (map != null) {
      startTimeStamp = map["startTimeStamp"];
      duration = map["duration"];
      sleepType = map["sleepType"];
    }
  }

  @override
  String toString() {
    return "\nstartTimeStamp: $startTimeStamp, duration: $duration, sleepType: $sleepType\n";
  }
}

/// 睡眠信息
class SleepDataInfo {
  /// 新旧睡眠区分标记
  bool isNewSleepProtocol = false;

  /// 开始时间
  int startTimeStamp = 0;

  /// 结束时间
  int endTimeStamp = 0;

  /// 深睡
  int deepSleepSeconds = 0;

  /// 浅睡
  int lightSleepSeconds = 0;

  /// rem
  int remSleepSeconds = 0;

  /// 详细数据
  List<SleepDetailDataInfo> list = [];

  SleepDataInfo.fromJson(Map map) {
    if (map != null) {
      isNewSleepProtocol = map["isNewSleepProtocol"];

      startTimeStamp = map["startTimeStamp"];
      endTimeStamp = map["endTimeStamp"];

      deepSleepSeconds = map["deepSleepSeconds"];
      lightSleepSeconds = map["lightSleepSeconds"];
      remSleepSeconds = map["remSleepSeconds"];

      final detail = map["detail"];
      if (detail is List) {
        final listInfo = detail;
        for (var element in listInfo) {
          final detailInfo = SleepDetailDataInfo.fromJson(element);
          list.add(detailInfo);
        }
      }
    }
  }

  @override
  String toString() {
    var detail = "[ ";
    for (var element in list) {
      detail += element.toString();
    }
    detail += "]";
    return "\n isNewSleep: $isNewSleepProtocol, \nstartTimeStamp: $startTimeStamp, \nendTimeStamp: $endTimeStamp, \ndeepSleepSeconds: $deepSleepSeconds, \nlightSleepSeconds: $lightSleepSeconds, \nremSleepSeconds:$remSleepSeconds, \ndetail: $detail";
  }
}

/// 心率数据
class HeartRateDataInfo {
  int startTimeStamp = 0;
  int heartRate = 0;

  HeartRateDataInfo.fromJson(Map map) {
    if (map != null) {
      startTimeStamp = map["startTimeStamp"];
      heartRate = map["heartRate"];
    }
  }

  @override
  String toString() {
    return "\n startTimeStamp: $startTimeStamp, \n heartRate:$heartRate \n";
  }
}

/// 健康数据测量模式
class HealthDataMeasureMode {
  /// 单次测量
  static const int single = 0;

  /// 自动监测
  static const int monitor = 1;

  /// 外接模块测量
  static const int inflated = 2;
}

/// 血压数据
class BloodPressureDataInfo {
  /// 开始时间(秒)
  int startTimeStamp = 0;

  /// 收缩压
  int systolicBloodPressure = 0;

  /// 舒张压
  int diastolicBloodPressure = 0;

  /// HealthDataMeasureMode 等价
  int mode = 0;

  BloodPressureDataInfo.fromJson(Map map) {
    if (map != null) {
      startTimeStamp = map["startTimeStamp"];
      systolicBloodPressure = map["systolicBloodPressure"];
      diastolicBloodPressure = map["diastolicBloodPressure"];
      mode = map["mode"];
    }
  }

  @override
  String toString() {
    return "\n startTimeStamp: $startTimeStamp, \n systolicBloodPressure:$systolicBloodPressure\n diastolicBloodPressure: $diastolicBloodPressure \n mode: $mode";
  }
}

/// 组合数据
class CombinedDataDataInfo {
  int startTimeStamp = 0;
  int step = 0;
  int heartRate = 0;
  int systolicBloodPressure = 0;
  int diastolicBloodPressure = 0;

  int bloodOxygen = 0;
  int respirationRate = 0;
  int hrv = 0;
  int cvrr = 0;

  double bloodGlucose = 0;
  double fat = 0;
  double temperature = 0;

  CombinedDataDataInfo.fromJson(Map map) {
    if (map != null) {
      startTimeStamp = map["startTimeStamp"];

      // 这个参数用不上，先注释
      // step = map["step"];
      // heartRate = map["heartRate"];
      // systolicBloodPressure = map["systolicBloodPressure"];
      // diastolicBloodPressure = map["diastolicBloodPressure"];

      bloodOxygen = map["bloodOxygen"];
      respirationRate = map["respirationRate"];
      hrv = map["hrv"];
      cvrr = map["cvrr"];

      final bloodGlucoseValue = map["bloodGlucose"];
      final fatValue = map["fat"];
      final temperatureValue = map["temperature"];

      if (bloodGlucoseValue is String) {
        bloodGlucose = double.parse(bloodGlucoseValue);
      }

      if (fatValue is String) {
        fat = double.parse(fatValue);
      }

      if (temperatureValue is String) {
        temperature = double.parse(temperatureValue);
      }
    }
  }

  @override
  String toString() {
    return "\n startTimeStamp: $startTimeStamp\n bloodOxygen: $bloodOxygen\n respirationRate:$respirationRate\n bloodGlucose: $bloodGlucose\n fat: $fat\n temperature: $temperature\n hrv: $hrv\n cvrr:$cvrr";
  }
}

/// 身体恢复指数数据
class BodyIndexDataInfo {
  String? startTimeStamp;
  String? endTimeStamp;
  String? loadIndex;
  String? hrvIndex;
  String? bodyIndex;
  String? sympatheticActivityIndex;
  String? sdnHrv;
  String? pressureIndex;
  String? vo2Max;

  BodyIndexDataInfo({
    this.startTimeStamp,
    this.endTimeStamp,
    this.loadIndex,
    this.hrvIndex,
    this.bodyIndex,
    this.sympatheticActivityIndex,
    this.sdnHrv,
    this.pressureIndex,
    this.vo2Max,
  });

  factory BodyIndexDataInfo.fromJson(Map<Object?, Object?> json) =>
      BodyIndexDataInfo(
        startTimeStamp: json["startTimeStamp"].toString(),
        endTimeStamp: json["endTimeStamp"].toString(),
        loadIndex: json["loadIndex"].toString(),
        hrvIndex: json["hrvIndex"].toString(),
        bodyIndex: json["bodyIndex"].toString(),
        sympatheticActivityIndex: json["sympatheticActivityIndex"].toString(),
        sdnHrv: json["sdnHRV"].toString(),
        pressureIndex: json["pressureIndex"].toString(),
        vo2Max: json["vo2max"].toString(),
      );

  Map<String, dynamic> toJson() => {
        "startTimeStamp": startTimeStamp,
        "endTimeStamp": endTimeStamp,
        "loadIndex": loadIndex,
        "hrvIndex": hrvIndex,
        "bodyIndex": bodyIndex,
        "sympatheticActivityIndex": sympatheticActivityIndex,
        "sdnHRV": sdnHrv,
        "pressureIndex": pressureIndex,
        "vo2max": vo2Max,
      };

  @override
  String toString() {
    return "\n startTimeStamp: $startTimeStamp\n endTimeStamp: $endTimeStamp\n loadIndex:$loadIndex\n hrvIndex: $hrvIndex\n bodyIndex: $bodyIndex\n sympatheticActivityIndex: $sympatheticActivityIndex\n sdnHrv: $sdnHrv\n pressureIndex:$pressureIndex\n vo2max:$vo2Max";
  }
}

/// 有创组合数据
class InvasiveComprehensiveDataInfo {
  /// 时间戳
  int startTimeStamp = 0;

  /// 血糖测量模式 HealthDataMeasureMode
  int bloodGlucoseMode = 0;

  /// 血糖值
  double bloodGlucose = 0.0;

  /// 尿酸模式 HealthDataMeasureMode
  int uricAcidMode = 0;

  /// 尿酸
  int uricAcid = 0;

  /// 血酮模式 HealthDataMeasureMode
  int bloodKetoneMode = 0;

  /// 血酮
  double bloodKetone = 0.0;

  /// 血酯模式 HealthDataMeasureMode
  int bloodFatMode = 0;

  /// 总胆固醇
  double totalCholesterol = 0.0;

  /// 高密度脂蛋白胆固醇
  double hdlCholesterol = 0.0;

  /// 低密度脂蛋白胆固醇
  double ldlCholesterol = 0.0;

  /// 甘油三酯
  double triglycerides = 0.0;

  /// 构造函数
  InvasiveComprehensiveDataInfo.fromJson(Map map) {
    if (map != null) {
      startTimeStamp = map["startTimeStamp"];

      bloodGlucoseMode = map["bloodGlucoseMode"];
      bloodGlucose = double.parse(map["bloodGlucose"]);

      uricAcidMode = map["uricAcidMode"];
      uricAcid = map["uricAcid"];

      bloodKetoneMode = map["bloodKetoneMode"];
      bloodKetone = double.parse(map["bloodKetone"]);

      bloodFatMode = map["bloodFatMode"];
      totalCholesterol = double.parse(map["totalCholesterol"]);
      hdlCholesterol = double.parse(map["hdlCholesterol"]);
      ldlCholesterol = double.parse(map["ldlCholesterol"]);
      triglycerides = double.parse(map["triglycerides"]);
    }
  }

  @override
  String toString() {
    return "\nstartTimeStamp: $startTimeStamp\nbloodGlucoseMode: $bloodGlucoseMode\nbloodGlucose: $bloodGlucose\nuricAcidMode: $uricAcidMode\nuricAcid: $uricAcid\nbloodKetoneMode: $bloodKetoneMode,\nbloodKetone: $bloodKetone,\nbloodFatMode: $bloodFatMode,\ntotalCholesterol: $totalCholesterol,\nhdlCholesterol: $hdlCholesterol,\nldlCholesterol: $ldlCholesterol,\ntriglycerides: $triglycerides";
  }
}

/// 运动类型定义
class DeviceSportType {
  static const int none = 0; // 保留
  static const int run = 0x01; // 跑步 (户外)
  static const int swimming = 0x02; // 游泳
  static const int riding = 0x03; // 户外骑行
  static const int fitness = 0x04; // 健身

  static const int ropeskipping = 0x06; // 跳绳
  static const int playball = 0x07; // 篮球(打球)
  static const int walk = 0x08; // 健走
  static const int badminton = 0x09; // 羽毛球

  static const int football = 0x0A; // 足球
  static const int mountaineering = 0x0B; // 登山
  static const int pingPang = 0x0C; // 乒乓球
  static const int freeMode = 0x0D; // 自由模式
  static const int indoorRunning = 0x0E; // 室内跑步
  static const int outdoorRunning = 0x0F; // 户外跑步
  static const int outdoorWalking = 0x10; // 户外步行
  static const int indoorWalking = 0x11; // 室内步行
  static const int runMode = 0x12; // 走跑模式
  static const int indoorRiding = 0x13; // 室内骑行
  static const int stepper = 0x14; // 踏步机
  static const int rowingMachine = 0x15; // 划船机
  static const int realTimeMonitoring = 0x16; // 实时监护
  static const int situps = 0x17; // 仰卧起坐
  static const int jumping = 0x18; // 跳跃运动
  static const int weightTraining = 0x19; // 重量训练
  static const int yoga = 0x1A; // 瑜伽

  static const int onfoot = 0x1B; // 徒步
  static const int volleyball = 0x1C; // 排球
  static const int kayak = 0x1D; // 皮划艇
  static const int rollerSkating = 0x1E; // 轮滑
  static const int tennis = 0x1F; // 网球
  static const int golf = 0x20; // 高尔夫
  static const int ellipticalMachine = 0x21; // 椭圆机
  static const int dance = 0x22; // 舞蹈
  static const int rockClimbing = 0x23; // 攀岩
  static const int aerobics = 0x24; // 健身操
  static const int otherSports = 0x25; // 其它运动
}

/// 运动启动方式
class DeviceSportModeStartMethod {
  static const int app = 0;
  static const int device = 1;
}

/// 运动状态
enum DeviceSportState {
  stop, // 停止
  start, // 开始
  pause, // 暂停
  continueSport, // 继续
}

/// 运动信息
class SportModeDataInfo {
  /// 开始时间戳(秒)
  int startTimeStamp = 0;

  /// 结束时间戳(秒)
  int endTimeStamp = 0;

  /// 运动启动方式 DeviceSportModeStartMethod
  int flag = 0;

  /// 运动方式 DeviceSportType 类型
  int sportType = 0;

  /// 运动时间
  int sportTime = 0;

  /// 步数 (步)
  int step = 0;

  /// 距离 (米)
  int distance = 0;

  /// 卡路里(千卡)
  int calories = 0;

  /// 心率
  int heartRate = 0;

  /// 最小心率
  int minimumHeartRate = 0;

  /// 最大心率
  int maximumHeartRate = 0;

  SportModeDataInfo.fromJson(Map map) {
    if (map != null) {
      startTimeStamp = map["startTimeStamp"];
      endTimeStamp = map["endTimeStamp"];
      flag = map["flag"];
      sportType = map["sportType"];
      sportTime = map["sportTime"];
      step = map["step"];
      distance = map["distance"];
      calories = map["calories"];
      heartRate = map["heartRate"];
      minimumHeartRate = map["minimumHeartRate"];
      maximumHeartRate = map["maximumHeartRate"];
    }
  }

  @override
  String toString() {
    return "startTimeStamp: $startTimeStamp, \nendTimeStamp: $endTimeStamp, \nstep: $step, \ndistance: $distance, \ncalories: $calories, \nsport: $sportType, \nflag: $flag, \nheartRate: $heartRate, \nsportTime: $sportTime, \nminimumHeartRate: $minimumHeartRate, \nmaximumHeartRate: $maximumHeartRate";
  }
}

// ================  查询设备信息 ================

/// 设备种类
enum DeviceType { watch, ring, touchRing, bodyTemperatureSticker, ecgStickers }

/// 设备电量状态
enum DeviceBatteryState {
  normal,
  low,
  charging,
  full,
}

class DeviceBasicInfo {
  /// 设备id
  int deviceID = 0;

  /// 设备类别
  DeviceType deviceType = DeviceType.watch;

  /// 电池状态
  DeviceBatteryState batteryStatus = DeviceBatteryState.normal;

  /// 电量
  int batteryPower = 0;

  /// 固件主版本
  int firmwareMajorVersion = 0;

  /// 固件子版本
  int firmwareSubVersion = 0;

  /// 显示固件版本
  String get firmwareVersion {
    return "$firmwareMajorVersion.${firmwareSubVersion.toString().padLeft(2, '0')}";
  }

  /// 构造
  DeviceBasicInfo.fromJson(Map map) {
    if (map != null && map.isNotEmpty) {
      deviceID = map["deviceID"];
      int deviceTypeValue = map["deviceType"];
      deviceType = DeviceType.values[deviceTypeValue];

      // 充电状态
      int batteryStatusValue = map["batteryStatus"];
      batteryStatus = DeviceBatteryState.values[batteryStatusValue];

      batteryPower = map["batteryPower"];
      firmwareMajorVersion = map["firmwareMajorVersion"];
      firmwareSubVersion = map["firmwareSubVersion"];
    }
  }

  @override
  String toString() {
    return "deviceID: $deviceID, \ndeviceType:$deviceType, \nbatteryStatus: $batteryStatus, \nbatteryPower: $batteryPower, \nfirmwareVersion:$firmwareVersion\n";
  }
}

/// 用户性别
enum DeviceUserGender { male, female }

/// 皮肤颜色
enum DeviceSkinColorLevel {
  white,
  whiteYellow,
  yellow,
  brown,
  darkBrown,
  black,
  other
}

/// 距离单位
enum DeviceDistanceUnit { km, mile }

/// 体重单位
enum DeviceWeightUnit { kg, lb }

/// 温度单位
enum DeviceTemperatureUnit { celsius, fahrenheit }

/// 时间格式
enum DeviceTimeFormat { h24, h12 }

/// 血糖或血脂单位
enum DeviceBloodGlucoseOrBloodFatUnit {
  millimolePerLiter,
  milligramsPerDeciliter
}

/// 尿酸单位 umol/l mg/dl
enum DeviceUricAcidUnit { microMolePerLiter, milligramsPerDeciliter }

/// 语言类型
class DeviceLanguageType {
  static const int english = 0x00;
  static const int chineseSimplified = 0x01;
  static const int russian = 0x02;
  static const int german = 0x03;
  static const int french = 0x04;
  static const int japanese = 0x05;
  static const int spanish = 0x06;
  static const int italian = 0x07;
  static const int portuguese = 0x08;
  static const int korean = 0x09;
  static const int poland = 0x0A;
  static const int malay = 0x0B;
  static const int chineseTradition = 0x0C;
  static const int thai = 0x0D;
  static const int vietnamese = 0x0F;
  static const int hungarian = 0x10;
  static const int arabic = 0x1A;
  static const int greek = 0x1B;
  static const int malaysian = 0x1C;
  static const int hebrew = 0x1D;
  static const int finnish = 0x1E;
  static const int czech = 0x1F;

  static const int croatian = 0x20;

  static const int persian = 0x24;

  static const int ukrainian = 0x27;
  static const int turkish = 0x28;

  static const int danish = 0x2B;
  static const int swedish = 0x2C;
  static const int norwegian = 0x2D;

  static const int romanian = 0x32;

  static const int slovak = 0x34;
}

/// 星期重复
class DeviceWeekDay {
  static const int monday = 1 << 0;
  static const int tuesday = 1 << 1;
  static const int wednesday = 1 << 2;
  static const int thursday = 1 << 3;
  static const int friday = 1 << 4;
  static const int saturday = 1 << 5;
  static const int sunday = 1 << 6;
}

/// 左右手
enum DeviceWearingPositionType { left, right }

/// 表盘信息
class DeviceThemeInfo {
  /// 总数
  int count = 0;

  /// 索引
  int index = 0;

  DeviceThemeInfo(this.count, this.index);

  DeviceThemeInfo.fromJson(Map map) {
    index = map["index"];
    count = map["count"];
  }

  @override
  String toString() {
    return "DeviceThemeInfo - count: $count, index: $index";
  }
}

/// 消息推送类型
enum DeviceInfoPushType {
  // 第一组
  call,
  sms,
  email,
  wechat,
  qq,
  weibo,
  facebook,
  twitter,

  // 第二组
  messenger,
  whatsAPP,
  linkedIn,
  instagram,
  skype,
  line,
  snapchat,
  telegram,

  // 第三组
  other,
  viber,
  zoom,
  tiktok,
  kaKaoTalk,
}

/// 通知类型
enum AndroidDevicePushNotificationType {
  call,
  sms,
  email,
  app, // 注意与 other 有相关的功能，取决于手表支持的固件。
  qq,
  wechat,
  weibo,
  twitter,
  facebook,
  messenger,
  whatsAPP,
  linkedIn,
  instagram,
  skype,
  line,
  snapchat,
  declineCall,
  missedCall,
  telegram,
  viber,
  other
}

/// 设备操作
enum DeviceSystemOperator {
  shutDown,
  transportation,
  resetRestart,
}

/// 血糖标定模式
enum DeviceBloodGlucoseCalibrationaMode { beforeMeal, afterMeal }

/// 天气
enum DeviceWeatherDay {
  today,
  tomorrow,
}

/// 天气类型
enum DeviceWeatherType {
  unKnow,
  sunny,
  cloudy,
  wind,
  rain,
  snow,
  foggy,
}

/// 波形上传控制
enum YCWaveUploadState { off, uploadWithOutSerialnumber, uploadSerialnumber }

enum YCWaveDataType {
  ppg,
  ecg,
  multiAxisSensor,
  ambientLight,
  multiChannelPPG, // 多通道PPG

  hengAiBPData, //恒爱高科血压透传数据
  hengAiPressure, //恒爱高科情绪压力透传数据
  hengAiMultiBOData //多通道光电波形（血氧）
}

extension rawValue on DeviceWeatherType {
  int getRawValue(DeviceWeatherType type) {
    switch (type) {
      case DeviceWeatherType.unKnow:
        return 0;

      default:
        return 0;
    }
  }
}

/// 名片类型
class DeviceBusinessCardType {
  static const int wechat = 0;
  static const int qq = 1;
  static const int facebook = 2;
  static const int twitter = 3;
  static const int whatsApp = 4;
  static const int instagram = 5;

  static const int snCode = 0xF0;
  static const int staticCode = 0xF1;
  static const int dynamicCode = 0xF2;
}

/// 拍照状态变化
enum DeviceControlPhotoState {
  exit, // 退出拍照
  enter, // 进入拍照
  photo, // 执行拍照
}

/// 设备控制状态
enum DeviceControlState {
  stop,
  start,
}

/// 一键测量类型
enum DeviceAppControlMeasureHealthDataType {
  heartRate, // 心率
  bloodPressure, // 血压
  bloodOxygen, // 血氧
  respirationRate, // 呼吸率
  bodyTemperature, // 体温
  bloodGlucose, // 血糖
  uricAcid, // 尿酸
  bloodKetone, // 血酮
  eda,
  bloodFat,
  hrv,
  ppg,
  pressure, //压力
  vo2max, //最大摄氧量
}

/// 设备实时数据类型 (除了step，其它类型一般不需要使用)
enum DeviceRealTimeDataType {
  step,
  heartRate,
  bloodOxygen,
  bloodPressure,
  hrv,
  respirationRate,
  sportMode,
  combinedData,
}

/// ECG诊断结果
class DeviceECGResult {
  int hearRate = 0;
  int qrsType = 0;
  bool afFlag = false;

  double? heavyLoad;
  double? pressure;
  double? body;
  double? hrvNorm;
  double? sympatheticActivityIndex;
  int? respiratoryRate;

  DeviceECGResult();

  /// 转换值
  DeviceECGResult.fromMap(Map map) {
    hearRate = map["hearRate"];
    qrsType = map["qrsType"];
    afFlag = map["afflag"];

    if (map.keys.contains("heavyLoad")) {
      heavyLoad = double.parse(map["heavyLoad"].toString());
      pressure = double.parse(map["pressure"].toString());
      body = double.parse(map["body"].toString());
      hrvNorm = double.parse(map["hrvNorm"].toString());
      sympatheticActivityIndex =
          double.parse(map["sympatheticActivityIndex"].toString());
      respiratoryRate = int.parse(map["respiratoryRate"].toString());
    }
  }

  @override
  String toString() {
    return "hearRate: $hearRate, \nafFlag: $afFlag, \nqrsType: $qrsType, \nheavyLoad: $heavyLoad, \npressure: $pressure, \nbody: $body, \nhrvNorm: $hrvNorm, \nsympatheticActivityIndex: $sympatheticActivityIndex, \nrespiratoryRate: $respiratoryRate";
  }
}

/// 历史数据
enum DeviceCollectDataType {
  ecg,
  ppg,
}

/// 表盘信息
class DeviceWatchInfo {
  /// 表盘id
  int dialID = 0;

  /// 版本，保留参数
  int version = 0;

  /// 表盘包数
  int blockCount = 0;

  /// 是否可以删除(非预置表盘)
  bool isSupportDelete = false;

  /// 是否为自定义表盘
  bool get isCustomDial => ((dialID >> 8) & 0x7FFFFF) == 0x7FFFFF;

  /// 是否为当前表盘
  bool get isCurrentDial => blockCount == 0xFFFF;

  /// 最大允许表盘数
  int limitCount = 0;

  /// 当前已安装数
  int localCount = 0;

  /// 构造
  DeviceWatchInfo.fromMap(Map map) {
    dialID = map["dialID"];
    version = map["version"];
    blockCount = map["blockCount"];
    isSupportDelete = map["isSupportDelete"];

    limitCount = map["limitCount"];
    localCount = map["localCount"];
  }

  @override
  String toString() {
    return "dialID: $dialID, blockCount: $blockCount,  isSupportDelete: $isSupportDelete, isCurrentDial: $isCurrentDial, isCustomDial: $isCustomDial, limitCount: $limitCount, localCount: $localCount";
  }
}

/// 自定义表盘的缩略图信息
class DeviceCustomWatchFaceDataInfo {
  /// 表盘宽度 (像素)
  int width = 0;

  /// 表盘高度 (像素)
  int height = 0;

  /// 表盘大小 (字节数)
  int size = 0;

  /// 表盘圆角半径 (像素)
  int radius = 0;

  /// 表盘缩略图宽度 (像素)
  int thumbnailWidth = 0;

  /// 表盘缩略图高度 (像素)
  int thumbnailHeight = 0;

  /// 表盘缩略大小 (字节数)
  int thumbnailSize = 0;

  /// 表盘缩略图半径 (像素)
  int thumbnailRadius = 0;

  DeviceCustomWatchFaceDataInfo.fromMap(Map map) {
    size = map["size"];
    width = map["width"];
    height = map["height"];
    radius = map["radius"];

    thumbnailSize = map["thumbnailSize"];
    thumbnailWidth = map["thumbnailWidth"];
    thumbnailHeight = map["thumbnailHeight"];
    thumbnailRadius = map["thumbnailRadius"];
  }

  @override
  String toString() {
    return "size: $size, width: $width, height: $height, radius: $radius, \nthumbnailSize: $thumbnailSize, thumbnailWidth: $thumbnailWidth, thumbnailHeight: $thumbnailWidth, thumbnailRadius: $thumbnailRadius";
  }
}

/// 屏幕类型
enum DeviceScreenType {
  round, //  圆形
  square // 方法
}

/// 设备显示信息
class DeviceDisplayParametersInfo {
  /// 屏幕类型
  DeviceScreenType screenType = DeviceScreenType.round;

  /// 宽度（像素）
  int widthPixels = 0;

  /// 高度（像素）
  int heightPixels = 0;

  /// 圆角半径 (像素)
  int filletRadiusPixels = 0;

  /// 缩略图宽度 (像素)
  int thumbnailWidthPixels = 0;

  /// 缩略图高度 (像素)
  int thumbnailHeightPixels = 0;

  /// 缩略图半径 (像素)
  int thumbnailRadiusPixels = 0;

  /// 构造
  DeviceDisplayParametersInfo.fromMap(Map map) {
    int screenKind = map["screenType"];
    screenType = DeviceScreenType.values[screenKind];

    widthPixels = map["widthPixels"];
    heightPixels = map["heightPixels"];
    filletRadiusPixels = map["filletRadiusPixels"];

    thumbnailWidthPixels = map["thumbnailWidthPixels"];
    thumbnailHeightPixels = map["thumbnailHeightPixels"];
    thumbnailRadiusPixels = map["thumbnailRadiusPixels"];
  }

  @override
  String toString() {
    return "screenType: ${screenType.toString()}, widthPixels: $widthPixels, heightPixels: $heightPixels, filletRadiusPixels: $filletRadiusPixels, \nthumbnailWidthPixels: $thumbnailWidthPixels, thumbnailHeightPixels: $thumbnailHeightPixels, thumbnailRadiusPixels: $thumbnailRadiusPixels";
  }
}

/// 时间位置
enum DeviceWatchFaceTimePosition {
  top,
  bottom,
  left,
  right,
  leftTop,
  rightTop,
  leftBottom,
  rightBottom,
  center,
}

/// 通讯录信息
class DeviceContactInfo {
  /// 名称 (不超过六个中文)
  String name = "";

  /// 电话
  String phone = "";

  DeviceContactInfo(this.name, this.phone);

  /// 转换为字典
  Map toJson() {
    return {
      "name": name,
      "phone": phone,
    };
  }

  @override
  String toString() {
    return "name: $name, phone: $phone";
  }
}

class AlarmClockInfo {
  int alarmHour = 0;
  int alarmType = 0;
  int alarmMin = 0;
  int alarmRepeat = 0;
  int alarmDelayTime = 0;

  AlarmClockInfo.fromJson(Map map) {
    if (map != null) {
      alarmHour = map["alarmHour"];
      alarmType = map["alarmType"];
      alarmMin = map["alarmMin"];
      alarmRepeat = map["alarmRepeat"];
      alarmDelayTime = map["alarmDelayTime"];
    }
  }

  @override
  String toString() {
    return "\nalarmHour: $alarmHour, \n";
  }
}

/// 亮度设置
enum DeviceDisplayBrightnessLevel {
  low,
  middle,
  high,
  automatic,
  lower,
  higher,
}

/// 定时提醒任务
enum DevicePeriodicReminderType {
  drinkWater, // 喝水
  takeMedicine // 提醒
}

/// 日志类型
enum LoggerType {
  appSdkLog, // sdk日志
  jlDeviceLog, // 杰理日志
  deviceLog //设备日志
}
