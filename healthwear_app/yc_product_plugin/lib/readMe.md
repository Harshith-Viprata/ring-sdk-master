# 1. 插件集成

## 1.1 代码集成

```yaml
  yc_product_plugin:
    git:
      url: https://gitee.com/yucheng_3/yc_product_plugin.git
      path: code/
```

## 1.2 平台配置
AndroidManifest.xml增加dfu服务

```xml
 <service android:name="com.realsil.sdk.dfu.DfuService"
        android:exported="false" />
```



# 2. 插件初始化
* 方法
```dart
/// 插件初始化
/// isReconnectEnable 是否设置回连
/// isLogEnable 是否开启回连
Future<void> initPlugin({bool isReconnectEnable = true, bool isLogEnable = false};


/// 插件结果
class PluginResponse<T> {
  /// 结果状态  PluginState
  final int statusCode;
  
  /// 结果列表
  final T data;
}
 
/// 插件API的状态
class PluginState {
  static const int succeed = 0; // 执行成功
  static const int failed = 1; // 执行失败
  static const int unavailable = 2; // 设备不支持
}
```

* 说明
  * 初始化只要在程序启动时，执行一次。
  
* 示例
```dart
// init plugin
YcProductPlugin().initPlugin(isReconnectEnable: false, isLogEnable: true);
```

# 3. 设备连接与断开

## 3.1 搜索设备

* 方法
```dart
 /// 扫描设备
Future<List<BluetoothDevice>?> scanDevice({int time = 6})
```

* 说明
  * 通过指定不同的搜索时间来搜索设备

* 示例
```dart
// 搜索设备
YcProductPlugin().scanDevice(time: 3).then((devices) {
  
  debugPrint("=== 设备 $devices");
  
  //  devices?.sort((a, b) =>  (b?.rssiValue.toInt() ?? 0) - (a?.rssiValue.toInt() ?? 0));
  //  _devices = devices ?? [];
    
});
```

## 3.2 连接设备

* 方法
```dart
Future<bool?> connectDevice(BluetoothDevice device);
```
* 说明

* 示例
```dart
YcProductPlugin().connectDevice(item).then((value) {
  if (value == true) {
    debugPrint("Connected");
  } else {
    debugPrint("Connect failed");
  }
});
```

## 3.3 断开设备
* 方法
```dart
Future<bool?> disconnectDevice();
```

* 说明
  * 要以通过结果来判断是否断开成功

* 示例
```dart
YcProductPlugin().disconnectDevice();
```

## 3.4 获取当前连接状态
* 方法
```dart
Future<int?> getBluetoothState();
```
* 说明
  * 获取当前蓝牙状态，返回值 BluetoothState。

* 示例
```dart
YcProductPlugin().getBluetoothState().then((value) {
  if (value == BluetoothState.connected) {
    
  }
}
```

## 3.5 监听蓝牙状态变化
* 方法
```dart

/// 开启监听
void onListening(void Function(dynamic event) onData);

/// 原生传递事件类型
class NativeEventType {

  /// 蓝牙状态变化
  static const String bluetoothStateChange;

  /// 设备拍照状态变化
  static const String deviceControlPhotoStateChange;

  /// 设备找手机状态变化
  static const String deviceControlFindPhoneStateChange;

  /// 设备一键测量状态变化
  static const String deviceHealthDataMeasureStateChange;

  /// 设备运动状态变化
  static const String deviceSportStateChange;

  /// 设备表盘切换变更
  static const String deviceWatchFaceChange;

  /// 杰理表盘切换变更
  static const String deviceJieLiWatchFaceChange;

  // MARK: - 实时数据

  /// 计步
  static const String deviceRealStep;

  /// 运动
  static const String deviceRealSport;

  /// 心率
  static const String deviceRealHeartRate;

  /// 血压
  static const String deviceRealBloodPressure;

  /// 血氧
  static const String deviceRealBloodOxygen;

  /// 温度
  static const String deviceRealTemperature;

  /// 实时ECG数据
  static const String deviceRealECGData;

  /// 实时ECG数据滤波数据
  static const String deviceRealECGFilteredData;

  /// 实时PPG数据
  static const String deviceRealPPGData;

  /// 实时RR数据
  static const String  deviceRealECGAlgorithmRR;

  /// 实时HRV数据
  static const String  deviceRealECGAlgorithmHRV;
  
}
```

* 说明
  * 蓝牙状态发送变化，插件会主动将状态广播出来。
  * 监听设备会返回一个Map, Map中的信息类型在 NativeEventType 有定义说明。

* 示例
```dart
YcProductPlugin().onListening((event) {
  if (event.keys.contains(NativeEventType.bluetoothStateChange)) {
    final int st = event[NativeEventType.bluetoothStateChange];
    debugPrint('蓝牙状态变化 $st');
    setState(() {
      // ....
    });
  }   
});
```

# 4. 健康历史数据

* 可以获操作的数据类型如下
```dart
/// 健康数据类型
class HealthDataType {
  static const step = 0; // 步数(步数、距离、卡咱里)
  static const sleep = 1; // 睡眠
  static const heartRate = 2; // 心率
  static const bloodPressure = 3; // 血压
  static const combinedData = 4; // 组合数据(体温、血氧、呼吸率、血糖等)
  static const invasiveComprehensiveData = 5; // 血脂和尿酸
  static const sportHistoryData = 6; // 运动历史记录
}
```

* 步数数据
  * 这是历史步数，每半小时产生一条记录，与表盘上显示的实时步数会存在半小时的差异。
```dart
/// 步数
class StepDataInfo {
  
  // 开始时间
  int startTimeStamp = 0;
  
  // 结束时间
  int endTimeStamp = 0;

  // 步数
  int step = 0;
  
  // 距离 (米)
  int distance = 0;
  
  // 卡路里 (千卡)
  int calories = 0;
  
  @override
  String toString();
}

```

* 睡眠数据
  * 睡眠数据会跨天存储，设备是从晚上的20:00开始监测，直到第二天的12：00结束，如果中途产生了一条或多条睡眠记录也是正常的。
  * 睡眠数据中如果`isNewSleepProtocol`是true则使用的新格式，包含四种睡眠状态，反之只有深睡和浅睡两种状态。
```dart

/// 睡眠状态
class SleepType {
  
  /// 深睡状态
  static const int deepSleep = 0xF1;
  
  /// 浅睡状态
  static const int lightSleep = 0xF2;
  
  /// 快速眼动
  static const int rem = 0xF3;
  
  /// 清醒状态
  static const int awake = 0xF4;
}

/// 睡眠的详细状态
class SleepDetailDataInfo {
  
  /// 开始时间 (秒)
  int startTimeStamp = 0;

  /// 时长 (秒)
  int duration = 0;

  /// 类型 使用 SleepType 判断
  int sleepType = 0;
  
  @override
  String toString();
}

/// 睡眠信息
class SleepDataInfo {

  /// 新旧睡眠区分标记
  bool isNewSleepProtocol = false;

  /// 开始时间 (秒)
  int startTimeStamp = 0;

  /// 结束时间 (秒)
  int endTimeStamp = 0;

  /// 深睡 (秒)
  int deepSleepSeconds = 0;

  /// 浅睡 (秒)
  int lightSleepSeconds = 0;

  /// rem (秒)
  int remSleepSeconds = 0;

  /// 详细数据
  List<SleepDetailDataInfo> list = [];
  
  @override
  String toString();
}
```

* 心率数据 
```dart
/// 心率数据
class HeartRateDataInfo {
  
  /// 测量时间 (秒)
  int startTimeStamp = 0;
  
  /// 心率值
  int heartRate = 0;

  @override
  String toString();
}
```

* 血压数据
  * 光电血压，可以通过API进行校准，校准指令可以通过文档中血压校准API来实现。
```dart
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

  @override
  String toString();
}
```

* 组合数据 (血压、呼吸率、温度、血糖)
  * 其它参数如步数、心率、血压不要使用。
  * 温度的单位使用的是摄氏度，如果小数部分出现`15`，表示此温度值无效。
  * 血糖的单位使用的是 mmol/L，与血压一样，血糖也可以通过血糖标定API来进行标定。
```dart
/// 组合数据
class CombinedDataDataInfo {
  
  /// 测量时间 (秒)
  int startTimeStamp = 0;
  int step = 0;
  int heartRate = 0;
  int systolicBloodPressure = 0;
  int diastolicBloodPressure = 0;

  /// 血氧
  int bloodOxygen = 0;
  
  /// 呼吸率
  int respirationRate = 0;
  int hrv = 0;
  int cvrr = 0;

  /// 血糖 mmol/L
  double bloodGlucose = 0;
  
  /// 体脂
  double fat = 0;
  
  /// 温度 C
  double temperature = 0;
  
  @override
  String toString();
}
```

* 血脂和尿酸
  * 血脂和尿酸也可以通过对应的API来标定。
  * 目前用到的只有尿酸（uricAcid）和总胆固醇(totalCholesterol)两个参数。

```dart
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
  
  @override
  String toString();
}
```

* 运动历史数据
  * 如果按每10秒一条的格式返回
  * 调用都可以按照时间的升序，相邻运动时间、相同运动类型的条件进行合并。

```dart
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
  stop,
  start,
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

  /// 运动时间 (保留参数)
  int sportTime = 0;

  /// 步数 (步)
  int step = 0;

  /// 距离 (米)
  int distance = 0;

  /// 卡路里(千卡)
  int calories = 0;

  /// 心率
  int heartRate = 0;

  /// 最小心率 (保留参数)
  int minimumHeartRate = 0;

  /// 最大心率 (保留参数)
  int maximumHeartRate = 0;
  
  @override
  String toString();
}
```

## 4.1 查询数据
* 方法 
```dart
Future<PluginResponse<List>?> queryDeviceHealthData(int healthDataType);
```
* 说明
  * 依据不同的类型来获取设备上产生的历史数据。

* 示例

```dart
YcProductPlugin().queryDeviceHealthData(HealthDataType.heartRate).then((result) {
    if (result?.statusCode == PluginState.succeed) {
      final list = result?.data ?? [];
      for (var item in list) {
        debugPrint(item.toString());
      }
    } else {
      debugPrint("failed");
    }
});
```

## 4.2 删除数据
* 方法
```dart
Future<PluginResponse?> deleteDeviceHealthData(int healthDataType);
```
* 说明
  * 依据不同的数据类型删除不同的数据，执行了删除指令后，再次获取将获取不到执行删除指令前的数据，但不影响手表上的数据显示。
  * 参数类型与查询是相同的类型。

* 示例
```dart
YcProductPlugin().deleteDeviceHealthData(HealthDataType.heartRate).then((value) {
    if (value?.statusCode == PluginState.succeed) {
      debugPrint("succeed");
    } else if (value?.statusCode == PluginState.failed) {
      debugPrint("failed");
    } else if (value?.statusCode == PluginState.unavailable) {
      debugPrint("unavailable");
    }
  }, 
);
```

# 5. 获取信息

## 5.1 基本信息

* 方法
```dart

/// 设备种类
enum DeviceType { watch, ring, touchRing, bodyTemperatureSticker, ecgStickers }

/// 设备电量状态
enum DeviceBatteryState { normal, low, charging, full, }

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
  String get firmwareVersion;

  @override
  String toString();
}

/// 查询设备的基本信息
Future<PluginResponse<DeviceBasicInfo>?> queryDeviceBasicInfo();

```

## 5.2 功能支持列表
* 方法
```dart
/// 获取设备功能列表
Future<DeviceFeature?>getDeviceFeature();

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

  // 最大摄氧量
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
}
```
* 说明
  * 此方法不需要调用，在设备连接后，在当前连接设备的属性中就可以直接获取。

* 示例 
```dart
final feature = await getDeviceFeature();
```

## 5.3 Mac地址
* 方法
```dart
/// 查询设备mac地址
Future<PluginResponse<String>?> queryDeviceMacAddress();
```
* 说明
  * 此方法获取的是当前连接的设备Mac地址

* 示例
```dart

YcProductPlugin().queryDeviceMacAddress().then((value) {
  if (value?.statusCode == PluginState.succeed) {
    final macAddress = value?.data ?? "";
  } else {
    
  }
});
```


## 5.4 设备型号

* 方法
```dart
/// 查询设备型号
Future<PluginResponse<String>?> queryDeviceModel();
```
* 说明
  * 设备型号是用于区分手表的种类。

* 示例
```dart
YcProductPlugin().queryDeviceModel().then((value) {
  if (value?.statusCode == PluginState.succeed) {
    final model = value?.data ?? "";
  }
});
```

## 5.5 设备平台
* 方法
```dart
/// 查询设备平台
Future<PluginResponse<DeviceMcuPlatform>?> queryDeviceMCU();
```

* 说明
  * 用于查询设备的主控使用是哪一种平台，一般会影响到Ota功能。对于具体的定制项目则不需要考虑。

* 示例

```dart
YcProductPlugin().queryDeviceMCU().then((value) {
  if (value?.statusCode == PluginState.succeed) {
    final mcu = value?.data ?? DeviceMcuPlatform.nrf52832;
  }    
});
```


# 6. 设置信息

## 6.1 设置时间
* 方法
```dart
/// 设置时间(同步手机时间)
Future<PluginResponse?> setDeviceSyncPhoneTime();
```

* 说明
  * 插件在连接设备后，会主动更新时间，一般不需要调用此方法。
  * 更新的时间以当前连接手机的时间为准。

* 示例
```dart
YcProductPlugin().setDeviceSyncPhoneTime();
```

## 6.2 设置目标

* 方法
```dart
/// 设置运动步数目标
Future<PluginResponse?> setDeviceStepGoal(int step);

/// 设置睡眠目标
Future<PluginResponse?> setDeviceSleepGoal(int hour, int minute);
```
* 说明
  * 设备普通支持运动目标和睡眠目标
  * 如果是手表达到运动目标后，会出现奖杯，睡眠目标则不会有任何提示。
  
* 示例
```dart

// 运动目标 10000 步
YcProductPlugin().setDeviceStepGoal(10000).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }                        
});

// 睡眠目标 8小时 30分钟
YcProductPlugin().setDeviceSleepGoal(8, 30).then((value) {
  if (value?.statusCode == PluginState.succeed) {

  } else {
 
  }
});
```

## 6.3 设置用户信息
* 方法
```dart

/// 用户性别
enum DeviceUserGender { male, female }

/// 设置用户信息
Future<PluginResponse?> setDeviceUserInfo(int height, int weight, int age, DeviceUserGender gender);
```
* 说明
  * 用户信息会影响到用户的计量数据

* 示例
```dart
YcProductPlugin().setDeviceUserInfo(170, 65, 18, DeviceUserGender.male).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }                    
});
```

## 6.4 肤色设置
* 方法
```dart
/// 皮肤颜色
enum DeviceSkinColorLevel {
  white, whiteYellow, yellow, brown, darkBrown, black, other
}

/// 肤色设置
Future<PluginResponse?> setDeviceSkinColor({DeviceSkinColorLevel level = DeviceSkinColorLevel.yellow});
```
* 说明
  * 不同的肤色会影响到设备采集测量数据的工作状态，如测量心率、睡眠等。
  * 默认是黄色

* 示例
```dart
YcProductPlugin().setDeviceSkinColor().then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }                     
});
```

## 6.5 单位设置
* 方法

```dart

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

/// 设置单位
Future<PluginResponse?> setDeviceUnit({DeviceDistanceUnit distance = DeviceDistanceUnit.km,
      DeviceWeightUnit weight = DeviceWeightUnit.kg,
      DeviceTemperatureUnit temperature = DeviceTemperatureUnit.celsius,
      DeviceTimeFormat timeFormat = DeviceTimeFormat.h24,
      DeviceBloodGlucoseOrBloodFatUnit bloodGlucoseOrBloodFat =
          DeviceBloodGlucoseOrBloodFatUnit.millimolePerLiter,
      DeviceUricAcidUnit uricAcid = DeviceUricAcidUnit.microMolePerLiter});
```
* 说明
  * 单位设置，只是影响到手表的数值和单位显示。
  * 默认是公制单位

* 示例
```dart
YcProductPlugin().setDeviceUnit(distance: DeviceDistanceUnit.km).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});
```

## 6.6 语言设置
* 方法
```dart

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

/// 设置语言
/// language - DeviceLanguageType
Future<PluginResponse?> setDeviceLanguage(int language);
```
* 说明
  * 设置不同的语言可以使用手表显示不同的语言。
  * 如果设置的语言不支持，则显示为英语。

* 示例
```dart
YcProductPlugin().setDeviceLanguage(DeviceLanguageType.english).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
    
  }
});
```

## 6.7 防丢设置
* 方法
```dart
/// 防丢设置
Future<PluginResponse?> setDeviceAntiLost(bool isEnable);
```
* 说明
  * 设置防丢开启后，手表与应用连接断开后，手表会震动提示。

* 示例
```dart
YcProductPlugin().setDeviceAntiLost(true).then((value) {
  if (value?.statusCode == PluginState.succeed) {

  } else {

  }
});
```

## 6.8 勿扰设置
* 方法
```dart
/// 设置勿扰
Future<PluginResponse?> setDeviceNotDisturb(bool isEnable, int startHour, int startMinute, int endHour, int endMinute);
```
* 说明
  * 设置勿扰后，手表上的久坐提醒、消息提醒、抬腕亮屏将关闭。
  * 方法中的参数分别是使能开关、开始时间和结束时间。
  
* 示例
```dart
YcProductPlugin().setDeviceNotDisturb(true, 9, 30, 12, 0).then((value) {
  if (value?.statusCode == PluginState.succeed) {

  } else {

  }
});
```

## 6.9 久坐提醒

* 方法
```dart

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

/// 久坐提醒
/// isEnable 是否开启
/// startXXX 开始时间
/// endXXX  结束时间
/// interval 15 ~ 60 分钟，其它值不可以使用
/// repeat 重复，星期设置 DeviceWeekDay
Future<PluginResponse?> setDeviceSedentary(
      bool isEnable, 
        int startHour1, int startMinute1, int endHour1, int endMinute1, 
        int startHour2, int startMinute2, int endHour2, int endMinute2,
      int interval,
      Set<int> repeat);
```

* 说明
  * 方法中有两组参数，如果设置不同的时间，第一组的时间应该早于第二组。如果只想设置一组时间，则两组的时间应该相同。
  * 提醒间隔只能是15~45分钟这个范围，超出这个范围的值是无效的。

* 示例
```dart
  final Set<int> week = <int>{};
  week.add(DeviceWeekDay.monday);
  week.add(DeviceWeekDay.tuesday);
  week.add(DeviceWeekDay.wednesday);
  week.add(DeviceWeekDay.thursday);
  week.add(DeviceWeekDay.friday);
  week.add(DeviceWeekDay.saturday);
  week.add(DeviceWeekDay.sunday);
                          
  YcProductPlugin().setDeviceSedentary(true, 9, 30, 12, 0, 14, 0, 18, 30, 30, week).then((value) {
    if (value?.statusCode == PluginState.succeed) {
                          
    } else {
                           
    }
  });
```

## 6.10 手机系统设置
* 方法
```dart
/// 手机系统设置
Future<PluginResponse?> setPhoneSystemInfo();
```
* 说明
  * 用于设置设备，当前连接的手机是什么操作系统和版本。
  * 一般情况下，不需要使用此方法，此功能是用于触摸戒指时用于配置智趣功能。
* 示例
```dart
YcProductPlugin().setPhoneSystemInfo().then((value) {
  if (value?.statusCode == PluginState.succeed) {

  } else {

  }                     
});
```

## 6.11 抬腕亮屏
* 方法
```dart
/// 抬腕亮屏
Future<PluginResponse?> setDeviceWristBrightScreen(bool isEnable);
```
* 说明
  * 用设置手表抬起时会自动亮屏，一般不建议设置，此功能可以在手表上自行设置。
* 示例
```dart
YcProductPlugin().setDeviceWristBrightScreen(true).then((value) {
  if (value?.statusCode == PluginState.succeed) {
   
  } else {
   
  }                           
});
```

## 6.12 恢复出厂设置
* 方法
```dart
/// 恢复出厂设置
Future<PluginResponse?> restoreFactorySettings();
```
* 说明
  * 调用此方法，手表会将数据全部清除后，自动重启。
* 示例
```dart
YcProductPlugin().restoreFactorySettings().then((value) {
  if (value?.statusCode == PluginState.succeed) {
   
  } else {
   
  }                           
});
```

## 6.13 主题功能
* 方法
```dart

  /// 表盘信息
  class DeviceThemeInfo {
    /// 总数
    int count = 0;
  
    /// 索引
    int index = 0;
    
    @override
    String toString();
  }
  /// 获取主题
  Future<PluginResponse<DeviceThemeInfo>?> queryDeviceTheme();

  /// 设置主题
  Future<PluginResponse?> setDeviceTheme(int index);
```
* 说明
  * 主题功能是指获取手表有哪几种显示的表盘样式、可以通过索引来设置，索引从0开始。
  * 需要注意的是现在手表普遍使用的是表盘功能，使用此方法的场景很少。
* 示例 
```dart
YcProductPlugin().queryDeviceTheme().then((value) {
  if (value?.statusCode == PluginState.succeed) {
    final info = value?.data as DeviceThemeInfo;
  
    YcProductPlugin().setDeviceTheme(info.count - 1).then((value) {
      
      if (value?.statusCode == PluginState.succeed) {
  
      } else {
  
      }
    });
    
  } else {
  
  }                         
                          
});
```

## 6.14 健康监测 

* 方法
```dart
  /// 健康监测(心率监测)
  /// isEnable - 开关
  /// interval - 1 ~ 60 min
  Future<PluginResponse?> setDeviceHealthMonitoringMode({bool isEnable = true, int interval = 60});

  @Deprecated("Use setDeviceHealthMonitoringMode")
  /// 温度监测
  Future<PluginResponse?> setDeviceTemperatureMonitoringMode({bool isEnable = true, int interval = 60});
```
* 说明
  * 健康监测只需要使用第一个方法，只有极个别设置会使用到第二个方法。
  
* 示例
```dart
YcProductPlugin().setDeviceHealthMonitoringMode().then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});
```


## 6.15 报警设置

### 6.15.1 心率报警

* 方法
```dart
/// 心率报警
Future<PluginResponse?>setDeviceHeartRateAlarm({bool isEnable = true, int maxHeartRate = 100, int minHeartRate = 30});
```
* 说明
  * 最高心率报警范围是 100 ~ 240
  * 最低心率报警直接指定 30 ~ 60

* 示例
```dart
YcProductPlugin().setDeviceHeartRateAlarm().then((value) {

  if (value?.statusCode == PluginState.succeed) {
    
  } else {

  }
});
```

### 6.15.2 温度报警

* 方法
```dart
/// 温度报警
Future<PluginResponse?> setDeviceTemperatureAlarm(bool isEnable, String maximumTemperature, String minimumTemperature);
```

* 说明
  * 温度参数是浮点数的字符串，小数只支持0~9， 高度报警的范围是 36~100。
  * 低温报警目前不支持。
  * 设备功能标志 `isSupportTemperatureAlarm` 为true时，此功能才有效。

* 示例
```dart
YcProductPlugin().setDeviceTemperatureAlarm(true, "37.3", "33").then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});
```

### 6.15.3 血氧报警

* 方法
```dart
/// 血氧报警
Future<PluginResponse?> setDeviceBloodOxygenAlarm({bool isEnable = true, int minimum = 90});
```

* 说明
  * 当设备检查到血氧值低于设置的报警值时，设备会报警。
  * 设备功能标志 `isSupportBloodOxygenAlarm` 为true时，此功能才有效。

* 示例
```dart
YcProductPlugin().setDeviceBloodOxygenAlarm().then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {

  }
});
```

### 6.15.4 呼吸率报警

* 方法
```dart
/// 呼吸率报警
Future<PluginResponse?> setDeviceRespirationRateAlarm(bool isEnable, int maximum, int minimum);
```
* 说明
  * 当设备检查到呼吸率没有超过这个范围时，设备会报警。
  * 设备功能标志 `isSupportRespirationRateAlarm` 为true时，此功能才有效。


### 6.15.5 血压报警

* 方法
```dart
/// 血压报警
Future<PluginResponse?> setDeviceBloodPressureAlarm(
      bool isEnable, 
        int maximumSystolicBloodPressure, int maximumDiastolicBloodPressure,
        int minimumSystolicBloodPressure, int minimumDiastolicBloodPressure);
```
* 说明
  * 血压报警需要设置一具范围，当设备检查到的血压值不在设置的范围内时，设备将报警。
  * 设备功能标志 `isSupportBloodPressureAlarm` 为true时，此功能才有效。

* 示例
```dart
// sbp 80 ~ 160, dbp: 60 ~ 120
YcProductPlugin().setDeviceBloodPressureAlarm(true, 160, 120, 80, 60).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});
```

## 6.16 睡眠提醒时间
* 方法
```dart
/// 设置睡眠提醒时间
Future<PluginResponse?> setDeviceSleepReminder(bool isEnable, int hour, int minute, Set<int>repeat);
```

* 说明
  * 设置睡前提醒，repeat表示周一到周日中哪天要提醒， 使用DeviceWeekDay成员。
  * 设备功能标志 `isSupportSleepReminder` 为true时，此功能才有效。 

* 示例
```dart
  final Set<int> week = <int>{};
  week.add(DeviceWeekDay.monday);
  week.add(DeviceWeekDay.tuesday);
  week.add(DeviceWeekDay.wednesday);
  week.add(DeviceWeekDay.thursday);
  week.add(DeviceWeekDay.friday);
  week.add(DeviceWeekDay.saturday);
  week.add(DeviceWeekDay.sunday);

  YcProductPlugin().setDeviceSleepReminder(true, 22, 30, week).then((value) {
    if value?.statusCode == PluginState.succeed) {
      
    } else { 
    
    }
  });
                          
```

## 6.17 消息提醒开关

* 方法
```dart
/// 通知开关(ANCS)
/// items - DeviceInfoPushType 成员
Future<PluginResponse?> setDeviceInfoPush(bool isEnable, Set<DeviceInfoPushType>items);

/// 通知类型
enum AndroidDevicePushNotificationType {
  call,
  sms,
  email,
  app, // 注意与 other 有相关的功能，取决于手表支持的固件。如果支持 other，则不使用此参数
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
/// 消息推送 Android
Future<PluginResponse?> appPushNotifications(AndroidDevicePushNotificationType type, String title, String contents);
```
* 说明
  * 通过不同的类型来设置手表可以显示接收到来自手机的来电、短信、微信、facebook等消息。
  * 需要注意的是，这个功能在不同的平台是不一样的，在iOS端，需要将手表与系统蓝牙配对同时要允许通知。这是由于在iOS端消息推送是由ANCS服务实现的。
  * 对于Android端，没有类似的服务，是要由App自行获取到通知道然后通过API下发到手表中。


* 示例
```dart
final Set<DeviceInfoPushType> items = <DeviceInfoPushType>{};
items.add(DeviceInfoPushType.call);
items.add(DeviceInfoPushType.sms);
items.add(DeviceInfoPushType.wechat);
items.add(DeviceInfoPushType.qq);

YcProductPlugin().setDeviceInfoPush(true, items).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});

// Android
YcProductPlugin().appPushNotifications(AndroidDevicePushNotificationType.wechat, "你好", "吃了吗？").then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
 
  }
});
```



# 7. 控制设备

## 7.1 找设备
* 方法
```dart
/// 找设备
Future<PluginResponse?> findDevice({int remindCount = 5, int remindInterval = 1});
```
* 说明
  * 调用方法后，设备会有震动提示。
  * 建议使用默认参数，不作修改。

* 示例
```dart
YcProductPlugin().findDevice().then((value) {
  if (value?.statusCode == PluginState.succeed) {

  } else {

  }                          
});
```

## 7.2 关机、重启 
* 方法
```dart

/// 设备操作
enum DeviceSystemOperator {
  shutDown,
  transportation,
  resetRestart,
}

/// 关机、复位、重启
Future<PluginResponse?> deviceSystemOperator(DeviceSystemOperator operator);
```
* 说明
  * 如果使用了复位，设备中的数据将会被清除。
  * 如果进入了运输模式，则只以使用充电激活，手表键是没有反应的。

* 示例
```dart
YcProductPlugin().deviceSystemOperator(DeviceSystemOperator.shutDown).then((value) {
  if (value?.statusCode == PluginState.succeed) {
 
  } else {
 
  }
});
```

## 7.3 血压校准 

* 方法
```dart
/// 血压校准
Future<PluginResponse?> bloodPressureCalibration(int systolicBloodPressure, int diastolicBloodPressure);
```
* 说明
  * 对于光电血压测量出现偏差时，可以使用此方法进行校准。

* 示例
```dart
YcProductPlugin().bloodPressureCalibration(120, 80).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }                           
});
```

## 7.4 温度校准
* 方法
```dart
/// 温度校准
Future<PluginResponse?> temperatureCalibration();
```

* 说明
  * 此功能只对于有两组温度传感器的精准体温功能才有效，其它产品则不起作用。该方法在开发中不常见。

* 示例
```dart
YcProductPlugin().temperatureCalibration().then((value) {
  if (value?.statusCode == PluginState.succeed) {

  } else {

  } 
});
```

## 7.5 血糖标定
* 方法
```dart

/// 血糖标定模式
enum DeviceBloodGlucoseCalibrationaMode { beforeMeal, afterMeal }
/// 血糖标定
Future<PluginResponse?> bloodGlucoseCalibration(DeviceBloodGlucoseCalibrationaMode mode, String value);
```

*  方法
  * 血糖标定是用于校准血糖测量的数据。
  * 血糖单位是 mmol/L

* 示例
```dart
YcProductPlugin().bloodGlucoseCalibration(DeviceBloodGlucoseCalibrationaMode.afterMeal, "7.2").then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});
```

## 7.6 尿酸标定

* 方法
```dart
/// 尿酸标定
/// uricAcid - umol/L
Future<PluginResponse?> uricAcidCalibration(int uricAcid);
```
* 说明
  * 尿酸标定是用于校准尿酸测量的数据。
  * 尿酸单位是 umol/L

* 示例
```dart
YcProductPlugin().uricAcidCalibration(800).then((value) {
  if (value?.statusCode == PluginState.succeed) {

  } else {

  }                         
});
```

## 7.7 血脂标定

* 方法
```dart
/// 血脂校准
/// cholesterol 胆固醇 - mmol/L
Future<PluginResponse?> bloodFatCalibration(String cholesterol);
```

* 说明
  * 血脂标定是用于校准尿酸测量的数据。
  * 血脂单位是 mmol/L

* 示例
```dart
YcProductPlugin().bloodFatCalibration("5.6").then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }                          
});
```

## 7.8 天气

* 方法
```dart

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

/// 发送天气
Future<PluginResponse?> sendTodayWeather(DeviceWeatherType weatherType, int lowestTemperature, int highestTemperature, int realTimeTemperature);

/// 发送明日天气
Future<PluginResponse?> sendTomorrowWeather(DeviceWeatherType weatherType, int lowestTemperature, int highestTemperature, int realTimeTemperature);
```
* 说明
  * 天气有今天气和明天天气，参数是相同，天气数据来源于天气服务商。
  * 温度单位是摄氏温度。
  * 明日天气的实时温度是不显示的，可以给任何值，建议给0或当天的实时温度。

* 示例
```dart
// 今天 下雪 -20 ~ 18 当前 12
YcProductPlugin().sendTodayWeather(DeviceWeatherType.snow, -20, 18, 12).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});

// 明天 16 ~ 33 
YcProductPlugin().sendTomorrowWeather(DeviceWeatherType.sunny, 16, 33, 0).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});
```

## 7.9 名片

* 方法
```dart

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

/// 名片下发
/// type - DeviceBusinessCardType
Future<PluginResponse?> sendBusinessCard(int type, String contents);

/// 查询名片
/// type - DeviceBusinessCardType
Future<PluginResponse?> queryBusinessCard(int type);
```

* 说明
  * 目前只有杰理平台的设备支持此功能。
  * 只有部分设置支持查询名片，对于类型中的snCode、staticCode、dynamicCode三种类型，只有个别定制设备才支持。

```dart

// 查询名片
YcProductPlugin().queryBusinessCard(DeviceBusinessCardType.wechat).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  final info = value?.data ;
  
  } else {
  
  }                           
});


// 设置名片
YcProductPlugin().sendBusinessCard(DeviceBusinessCardType.wechat, "https://me.wechat/xxxx").then((value) {
  if (value?.statusCode == PluginState.succeed) {
   
  } else {
   
  }
});

```


## 7.10 拍照
* 方法
```dart
/// 控制设备进入或退出拍照
Future<PluginResponse?> appControlTakePhoto(bool isEnable);

/// 拍照状态变化
enum DeviceControlPhotoState {
  exit,  // 设备退出拍照
  enter, // 设备进入拍照
  photo, // 设备执行拍照
}

/// 拍照状态变化
NativeEventType.deviceControlPhotoStateChange
```
* 说明
  * 拍照有两种模式，一种是由手机启动或退出，一种是由设备本身启动或退出。
  * 执行拍照动作也有两种方式，一种是手机执行拍照，不需要做任何的蓝牙指令操作，另一个种是在设备上操作，由手机来响应这个指令。

* 举例
```dart
YcProductPlugin().onListening((event) {
  if (event.keys.contains(NativeEventType.deviceControlPhotoStateChange)) {
    final int index = event[NativeEventType.deviceControlPhotoStateChange];
    final state = DeviceControlPhotoState.values[index];
    debugPrint("Device photo ${state.toString()}");
  }
});


/// 手机启动拍照
YcProductPlugin().appControlTakePhoto(true). then((value) {
  if (value?.statusCode == PluginState.succeed) {
   
  } else {
   
  }
});

/// 手机退出拍照
YcProductPlugin().appControlTakePhoto(false). then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});

```

## 7.11 运动

* 方法
```dart

/// 控制运动
Future<PluginResponse?> appControlSport(DeviceSportState state, int sportType);

/// 运动状变化 
NativeEventType.deviceSportStateChange;

/// 运动状态
enum DeviceSportState {
  stop,             // 停止 
  start,            // 开始
  pause,            // 暂停
  continueSport,    // 继续
}

/// 运动数据
NativeEventType.deviceRealSport;

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

```
* 运动
  * 这里的运动指的是由App启动设备进入实时运动状态。手表会将产生的数据返回，手表不会存储运动记录。
  * 一般的设备只有开始和结束，只有`isSupportSportPause`为true时，才支持暂停与继续运动。

* 举例
```dart

YcProductPlugin().onListening((event) {

  // 实时运动
  final Map? sportInfo = event[NativeEventType.deviceRealSport];
  if (sportInfo != null) {
    
    // time 运动时间
    // heartRate 运动心率
    // distance 距离
    // step 步数
    // calories 千卡
  }

  final Map? sportStateInfo = event[NativeEventType.deviceSportStateChange];
    if (sportStateInfo != null) {
      
      // state 运动状态
      // sportType 运动类型
    }
  });

)}

// 开始跑步
YcProductPlugin().appControlSport(DeviceSportState.start, DeviceSportType.run).then((value) {
  if (value?.statusCode == PluginState.succeed) {
   
  } else {
   
  }
});

// 结束跑步
YcProductPlugin().appControlSport(DeviceSportState., DeviceSportType.run).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
  
  }
});

```

## 7.12 ECG

### 7.12.1 启动与停止ECG
* 方法
```dart
/// 开启ECG测量
Future<PluginResponse?> startECGMeasurement();

/// 结束ECG测量
Future<PluginResponse?> stopECGMeasurement();
```
* 说明
  * 建议测量时长为60秒

* 示例
```dart
YcProductPlugin().startECGMeasurement().then((value) {
  if (value?.statusCode == PluginState.succeed) {
   
  } else {
  
  }
});

// 停止测量
YcProductPlugin().stopECGMeasurement().then((value) {
  
});
```

### 7.12.2 获取ECG实时数据

* 方法
```dart

/// 实时ECG 
NativeEventType.deviceRealECGData;

/// 实时血压(包含心率和HRV)
NativeEventType.deviceRealBloodPressure;

```
* 说明
  * 测量过程中会产生实时的ECG数据、心率、血压和HRV，部分设备可能会携带PPG数据。
  * 实时ECG数据可以用来绘制ECG图形。

* 示例
```dart
YcProductPlugin().onListening((event) {
  final ecgData = event[NativeEventType.deviceRealECGData];
  if (ecgData != null) {
    // debugPrint("实时ECG: ${ecgData.toString()}");
  }
  
  // final ppgData = event[NativeEventType.deviceRealECGData];
  // if (ppgData != null) {
  //   debugPrint("实时PPG: ${ppgData.toString()}");
  // }
  
  final bloodMap = event[NativeEventType.deviceRealBloodPressure];
  if (bloodMap != null) {
    debugPrint("实时血压: ${bloodMap.toString()}");
  }    
});
```

### 7.12.3 获取ECG诊断结果

* 方法
```dart

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
  
  @override
  String toString();
}

/// 获取ECG的结果
Future<PluginResponse<DeviceECGResult>?> getECGResult();
```

* 说明
  * 诊断结果中的三个参数用于判断心电的诊断结果。
  * 对于诊断结果中用到的心率和HRV，如果设备主动上报了，则优先使用设备上报的数据，否则通过结果获取。
  * 诊断结果可遵循如下原则：
    * 1. 优先判断 afFlag, 如果 afFlag 为 true， 则表示为心房颤动，其它参数不需要判断。
    * 2. 如果 afFlag 为 false则判断 qrsType的类型，qrsType的类型。如下:
      * qrsType == 14，测量失败
      * qrsType == 5, 室性早搏
      * qrsType == 9, 房性早搏
      * qrsType == 1，需要判断心率和hrv
        * hearRate <= 50, 疑似心动过缓
        * hearRate >= 120, 疑似心动过速
        * hrv >= 125, 疑似窦性心律不齐
        * 以上条件都不成立，则为正常心电图。
* 示例
```dart
YcProductPlugin().getECGResult().then((value) {
  
  PluginResponse info = value as PluginResponse;
  
  // 依据

});
```

## 7.13 实时数据上传

* 方法
```dart
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

/// 控制实时数据上传
Future<PluginResponse?> realTimeDataUpload(bool isEnable, {DeviceRealTimeDataType dataType = DeviceRealTimeDataType.step});
```

* 说明
  * 参数类型中，除了step，其它参数一般不使用，step参数主要是用于直接获取手表上的当天实时计步信息。

* 示例
```dart
YcProductPlugin().onListening((event) {
      if (event.keys.contains(NativeEventType.deviceRealStep)) {
        final stepInfo = event[NativeEventType.deviceRealStep];
        debugPrint('步数变化: $stepInfo');
      }
});

YcProductPlugin().realTimeDataUpload(true).then((value) {
  if (value?.statusCode == PluginState.succeed) {
  
  } else {
    
  }
});

```

# 8. 表盘操作

> 如果固件使用的是52832或8762d平台，则使用的玉成表盘，如果使用的是杰理平台则为杰理表盘。

## 8.1 玉成表盘

### 8.1.1 查询表盘信息

* 方法

```dart
/// 查询信息
Future<PluginResponse<List<DeviceWatchInfo>>?> queryWatchFaceInfo();

/// 表盘信息
class DeviceWatchInfo {

  /// 表盘id
  int dialID;

  /// 版本，保留参数
  int version;

  /// 表盘包数
  int blockCount;

  /// 是否可以删除(非预置表盘)
  bool isSupportDelete;

  /// 是否为自定义表盘
  bool get isCustomDial;

  /// 是否为当前表盘
  bool get isCurrentDial;
  
  /// 最大允许表盘数 (包含可以下载的表盘和自定义表盘，不包含预置表盘。)
  int limitCount = 0;

  /// 当前已安装数 (包含可以下载的表盘和自定义表盘，不包含预置表盘。)
  int localCount = 0;

  @override
  String toString();
}
```

* 说明
    * 使用此方法，可以查询当前手表中存储的表盘信息。
    * 如果表盘中的`isCurrentDial`为 `true`说明此表盘是当前正在显示的表盘。
    * 如果表盘中的`isSupportDelete为`true`说明此表盘可以删除，可以重新安装，否则不能删除。
    * 如果表盘中的`isCustomDial`为`true`说明此表盘允许用户修改时间位置、颜色、背景图片。
    * 可以通过`limitCount`的数量来判断手表允许安装几个表盘，`localCount`则表示当前已经安装且可以删除的表盘数量。

* 示例

```dart

YcProductPlugin().queryWatchFaceInfo().then((result) {
  if (result?.statusCode == PluginState.succeed) {

    final list = result?.data ?? [];
    
    for (var item in list) {
      debugPrint(item.toString());
    }

  } else {
    debugPrint("Not support");
  }
});

```

### 8.1.2 设置表盘

* 方法

```dart
Future<PluginResponse?>changeWatchFace(int dialID);
```
* 说明
  * 通过dialID可以直接切换表盘，但这个表盘必须已经存在于手表，否则会失败。

* 示例

```dart
YcProductPlugin().changeWatchFace(185).then((result) {
  if (result?.statusCode == PluginState.succeed) {
      debugPrint("succeed");
  } else {
     debugPrint("failed");
  }
});

```

### 8.1.3 删除表盘

* 方法

```dart
Future<PluginResponse?>deleteWatchFace(int dialID);
```
* 说明
  * 通过dialID可以直接删除表盘，但这个表盘必须已经存在于手表，否则会失败。
  * 此方法只对可以删除的表盘有效，对于预置表盘无效。

* 示例

```dart
YcProductPlugin().deleteWatchFace(306).then((result) {
  if (result?.statusCode == PluginState.succeed) {
      debugPrint("succeed");
  } else {
     debugPrint("failed");
  }
});

```

### 8.1.4 下载表盘

* 方法

```dart
/// 下载表盘
Future<PluginResponse?>installWatchFace(bool isEnable, int dialID, int blockCount, int dialVersion, String filePath, ProcessCallback processCallback);

```

* 说明
  * isEnable 为`true`则表示启动下载, 否则表示停止下载。
  * dialID 为 表盘的编号
  * blockCount 为表盘已下载的包数，可以通过查询表盘信息获得，建议使用0，表示从头开始下载。
  * dialVersion 是表盘版本，暂时没有，可以给任意数字。
  * filePath 表盘文件的绝对路径
  * processCallback 表盘的下载路径。

* 示例

```dart
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final documentsPath = documentsDirectory.path;
   
    String filePath = "assets/files/E300H1.bin";
    String destinationPath = '$documentsPath/E300H1.bin';
    
    ByteData data = await rootBundle.load(filePath);
    List<int> bytes = data.buffer.asUint8List();
    
    // 写入到App目录下
    File(destinationPath).writeAsBytes(bytes).then((value) {
      
      // 下载表盘
      YcProductPlugin().installWatchFace(true, 306, 0, 0, destinationPath,
          (code, process, errorString) {
        debugPrint("Upgrading ${(process * 100).toInt()}%");
      }).then((result) {
        if (result?.statusCode == PluginState.succeed) {
          debugPrint("succeed");
        } else {
          debugPrint("failed");
        }
      });
    });
```

### 8.1.5 自定义表盘
* 方法
```dart

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

  DeviceCustomWatchFaceDataInfo.fromMap(Map map);

  @override
  String toString();
}

/// 获取自定义表盘的参数
Future<PluginResponse<DeviceCustomWatchFaceDataInfo>?>queryDeviceCustomWatchFaceInfo(String filePath);

/// 下载自定义表盘
Future<PluginResponse>? installCustomWatchFace(int dialID, String filePath, String backgroundImage, String thumbnail, int timeX, int timeY, int redColor, int greenColor, int blueColor, ProcessCallback processCallback);
```
* 说明
  * 要先查询到对应的参数，进行图片转换后，再下载到手中。

* 示例
```dart
final documentsDirectory = await getApplicationDocumentsDirectory();
    final documentsPath = documentsDirectory.path;
    // debugPrint("目标地址: $documentsPath");

    // 表盘文件
    String filePath = "assets/files/customE88E.bin";
    ByteData data = await rootBundle.load(filePath);
    List<int> bytes = data.buffer.asUint8List();

    // 目标路径
    String destinationPath = '$documentsPath/customE88E.bin';

    File(destinationPath).writeAsBytes(bytes).then((value) {
      debugPrint("写入成功 ${value.toString()}");

      // 查询表盘信息
      YcProductPlugin()
          .queryDeviceCustomWatchFaceInfo(destinationPath)
          .then((result) async {
        if (result?.statusCode == PluginState.succeed) {
           
          final dialInfo = result?.data;
          
          // 写入图片 由尺寸大小压缩得到
          String bgPath = "assets/images/2147483615.png";
          ByteData bgImageData = await rootBundle.load(bgPath);
          List<int> bgImageBytes = bgImageData.buffer.asUint8List();
          String bgImageDestinationPath = "$documentsPath/2147483615.png";

          File(bgImageDestinationPath).writeAsBytes(bgImageBytes).then((value) async {
 
            String thumbnailPath = "assets/images/2147483615_thumbnail.png";
            ByteData thumbnailImageData = await rootBundle.load(thumbnailPath);
            List<int> thumbnailImageBytes = thumbnailImageData.buffer.asUint8List();
            String thumbnailImageDestinationPath = "$documentsPath/thumbnail.png";

            File(thumbnailImageDestinationPath).writeAsBytes(thumbnailImageBytes).then((value) {
 
              int dialID = 2147483615;

              int timeX = (dialInfo?.width ?? 0) ~/ 4;
              int timeY = (dialInfo?.height ?? 0) ~/ 2;

              YcProductPlugin().installCustomWatchFace(dialID, destinationPath, bgImageDestinationPath, thumbnailImageDestinationPath, timeX, timeY, 255, 0, 0, (code, process, errorString) {
                  debugPrint("Upgrading ${(process * 100).toInt()}%");
              })?.then((result) {
                  if (result?.statusCode == PluginState.succeed) {
                   debugPrint("succeed");
                  } else {
                    debugPrint("failed");
                  }
              });

            });

          });
        } else {
          debugPrint("Not support");
        }
      });
    });

```


### 8.1.6 表盘切换

* 方法
```dart
NativeEventType.deviceWatchFaceChange;
```
* 说明
  * 通过全局监听，可以获取手表切换的表盘id。

* 示例 
```dart
YcProductPlugin().onListening((event) {
      if (event.keys.contains(NativeEventType.deviceWatchFaceChange)) {
        int dialId = event[NativeEventType.deviceWatchFaceChange];
      }
});
```

## 8.2 杰理表盘 


### 8.2.1 查询表盘
 * 和玉成表盘是相同的，手表的名称在服务器端与杰理工具配置相同。表盘名称与设置表盘相同。


### 8.2.2 设置表盘
* 方法
```dart
Future<PluginResponse?>changeJieLiWatchFace(String watchName);
```
* 说明
  * 通过指定手表名称来进行切换表盘。如果该表盘不存在，则会出错。
* 示例
```dart
YcProductPlugin().changeJieLiWatchFace("WATCH1").then((result) {
  if (result?.statusCode == PluginState.succeed) {
    debugPrint("succeed");
  } else {
    debugPrint("failed");
  }  
});
```

### 8.2.3 删除表盘

* 方法
```dart
Future<PluginResponse?>deleteJieLiWatchFace(String watchName);
```

* 说明
  * 通过指定手表名称来删除表盘。如果该表盘不存在，则会出错。

* 示例
```dart
YcProductPlugin().deleteJieLiWatchFace("watch28").then((result) {
  if (result?.statusCode == PluginState.succeed) {
    debugPrint("succeed");
  } else {
   debugPrint("failed");
  }
});
```

### 8.2.4 下载表盘

* 方法
```dart
Future<PluginResponse?>installJieLiWatchFace(String watchName, String filePath, ProcessCallback processCallback);
```
* 说明
  * watchName 是表盘名称
  * filePath 表盘文件在手机中的存储绝对路径
  * processCallback 安装进度。

* 示例
```dart
YcProductPlugin().installJieLiWatchFace(watchName, destinationPath, (code, process, errorString) {
        EasyLoading.showProgress(process,
       
            debugPrint("Upgrading ${(process * 100).toInt()}%");
      }).then((result) {

        if (result?.statusCode == PluginState.succeed) {
          debugPrint("succeed");
        } else {
          debugPrint("failed");
        }
      });
```

### 8.2.5 下载自定义表盘

* 方法
```dart

/// 屏幕类型
enum DeviceScreenType {
  round,    //  圆形
  square    // 方法
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
  DeviceDisplayParametersInfo.fromMap(Map map);

  @override
  String toString();
}

Future<PluginResponse<DeviceDisplayParametersInfo>?>queryDeviceDisplayParametersInfo();


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
  ProcessCallback processCallback);
```

* 说明
  * queryDeviceDisplayParametersInfo 可以查询手表的显示屏参数，用于背景图和缩略图片的大小设置。
  * 切换好图片后，通过installJieLiCustomWatchFace方法下载到手表中，颜色参数注意是RGB565, 转换方法在工具类中已提供。

* 示例
```dart
YcProductPlugin().queryDeviceDisplayParametersInfo().then((result) async {
      if (result?.statusCode != PluginState.succeed) {
        
        return;
      }

      final parametersInfo = result?.data;
 

      // 依据  parametersInfo 的图片，进行将图片进行转换为相应尺寸、圆角的两张图片，这里不演示直接得到对应的。

      // 写入图片
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final documentsPath = documentsDirectory.path;

      String bgPath = "assets/images/2147483615.png";
      ByteData bgImageData = await rootBundle.load(bgPath);
      List<int> bgImageBytes = bgImageData.buffer.asUint8List();
      String bgImageDestinationPath = "$documentsPath/background.png";

      // 写入手表
      File(bgImageDestinationPath)
          .writeAsBytes(bgImageBytes)
          .then((value) async {
        String thumbnailPath = "assets/images/2147483615_thumbnail.png";
        ByteData thumbnailImageData = await rootBundle.load(thumbnailPath);
        List<int> thumbnailImageBytes = thumbnailImageData.buffer.asUint8List();
        String thumbnailImageDestinationPath = "$documentsPath/thumbnail.png";

        File(thumbnailImageDestinationPath)
            .writeAsBytes(thumbnailImageBytes)
            .then((value) {
          // 准备转换图片 // BGP_W900
          YcProductPlugin().installJieLiCustomWatchFace(
              "watch900",
              bgImageDestinationPath,
              thumbnailImageDestinationPath,
              DeviceWatchFaceTimePosition.bottom,
              YcProductPluginTools.colorToRGB565(
                  const Color.fromARGB(255, 255, 255, 255)),
              parametersInfo!, (code, process, errorString) {
            EasyLoading.showProgress(process,
                status: "Upgrading ${(process * 100).toInt()}%");
          }).then((value) {
  
            if (result?.statusCode == PluginState.succeed) {
              debugPrint("succeed");
            } else {
             debugPrint("failed");
            }
          });
        });
      });
    });
```

### 8.2.6 表盘切换
* 方法
```dart
NativeEventType.deviceJieLiWatchFaceChange;
```
* 说明
  * 手表切换表盘后，手表的名称返回。

* *示例
```dart
YcProductPlugin().onListening((event) {

      if (event.keys.contains(NativeEventType.deviceJieLiWatchFaceChange)) {

        String watchName = event[NativeEventType.deviceJieLiWatchFaceChange];

        setState(() {
          _displayedText = "Watch face change: $watchName";
        });
      }

});
```


# 9. OTA

# 10. 其它 