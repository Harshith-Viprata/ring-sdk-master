package com.example.yc_product_plugin;

/**
 * Flutter端定义的数据类型
 */
public class YcProductPluginFlutterType {

    // 代码对齐 opt + cmd + L

    /// 升级状态
    class DeviceUpdateState {
        static final int start = 0; // 开始
        static final int upgradingResources = 1; // 升级资源
        static final int upgradeResourcesFinished = 2; // 升级资源结束
        static final int upgradingFirmware = 3; // 升级固件
        static final int succeed = 4;
        static final int failed = 5;

        static final int installingWatchFace = 6;  // 安装表盘
    }

    /// 插件API的状态
    class PluginState {
        static final int succeed          = 0;    // 执行成功
        static final int failed           = 1;    // 执行失败
        static final int unavailable      = 2;    // 设备不支持
    }



    /// 原生传递事件类型
    class NativeEventType {

        // 设备信息
        static final String deviceInfo = "deviceInfo";

        // 蓝牙状态变化
        static final String bluetoothStateChange = "bluetoothStateChange";

        // 设备拍照状态变化
        static final String deviceControlPhotoStateChange = "deviceControlPhotoStateChange";

        /// 设备找手机状态变化
        static final String deviceControlFindPhoneStateChange = "deviceControlFindPhoneStateChange";

        /// 设备一键测量状态变化
        static final String deviceHealthDataMeasureStateChange =
                "deviceHealthDataMeasureStateChange";

        /// 设备运动状态变化
        static final String deviceSportStateChange = "deviceSportStateChange";

        /// 表盘变化
        static final String deviceWatchFaceChange = "deviceWatchFaceChange";

        /// 杰理表盘变更
        static final String deviceJieLiWatchFaceChange =
                "deviceJieLiWatchFaceChange";

        // MARK: - 实时数据

        /// 计步
        static final String deviceRealStep = "deviceRealStep";

        /// 运动
        static final String deviceRealSport = "deviceRealSport";

        /// 心率
        static final String deviceRealHeartRate = "deviceRealHeartRate";

        /// 血压
        static final String deviceRealBloodPressure = "deviceRealBloodPressure";

        /// 血氧
        static final String deviceRealBloodOxygen = "deviceRealBloodOxygen";

        /// 温度
        static final String deviceRealTemperature = "deviceRealTemperature";

        /// 压力
        static final String deviceRealPressure = "deviceRealPressure";

        /// 最大摄氧量
        static final String deviceRealVo2max = "deviceRealVo2max";
   
        /// 血糖
        static final String deviceRealBloodGlucose = "deviceRealBloodGlucose";

        /// HRV
        static final String deviceRealHRV = "deviceRealHRV";

        /// 实时ECG数据
        static final String deviceRealECGData = "deviceRealECGData";

        /// 实时ECG数据滤波数据
        static final String deviceRealECGFilteredData = "deviceRealECGFilteredData";

        /// 实时PPG数据
        static final String deviceRealPPGData = "deviceRealPPGData";

        /// 实时RR数据
        static final String deviceRealECGAlgorithmRR = "deviceRealECGAlgorithmRR";

        /// 实时HRV数据
        static final String deviceRealECGAlgorithmHRV = "deviceRealECGAlgorithmHRV";

        static final String deviceEndECG = "deviceEndECG";

        static final String appECGPPGStatus = "appECGPPGStatus";

        static final String deviceRealACCData = "deviceRealACCData";

        static final String deviceMultiChannelPPGData = "deviceMultiChannelPPGData";
    }

    /// 蓝牙状态
    class BluetoothState {
        static final int off = 0;                   // 蓝牙关闭
        static final int on = 1;                    // 蓝牙开启
        static final int connected = 2;             // 连接
        static final int connectFailed = 3;         // 连接失败
        static final int disconnected = 4;          // 断开连接
    }

    /// 健康数据类型
    class HealthDataType {
        static final int step = 0;                          // 步数(步数、距离、卡咱里)
        static final int sleep = 1;                         // 睡眠
        static final int heartRate = 2;                     // 心率
        static final int bloodPressure = 3;                 // 血压
        static final int combinedData = 4;                  // 组合数据(体温、血氧、呼吸率、血糖等)
        static final int invasiveComprehensiveData = 5;     // 有创数据 (血脂和尿酸)
        static final int sportHistoryData        = 6;       // 运动历史记录

        static final int bodyIndexData = 7;                      // 压力，最大报氧量

        static final int WearingStatus = 8;
    }
}