//
//  YcProductPlugin + Common.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/4.
//

import Foundation


// MARK: - Dart对应的类型

/// 原生传递事件类型
public struct NativeEventType {
    
    /// 设备信息
    static let deviceInfo = "deviceInfo"
    
    /// 设备蓝牙状态变化
    static let bluetoothStateChange = "bluetoothStateChange"
    
    /// 设备拍照状态变化
    static let deviceControlPhotoStateChange = "deviceControlPhotoStateChange"
    
    /// 设备找手机状态变化
    static let deviceControlFindPhoneStateChange = "deviceControlFindPhoneStateChange"
    
    /// 设备一键测量状态变化
    static let deviceHealthDataMeasureStateChange =
        "deviceHealthDataMeasureStateChange"
    
    /// 设备运动状态变化
    static let deviceSportStateChange =
        "deviceSportStateChange"

    /// 表盘切换变更
    static let deviceWatchFaceChange =
        "deviceWatchFaceChange"
    
    /// 杰理表盘变更
    static let deviceJieLiWatchFaceChange =
        "deviceJieLiWatchFaceChange"
    
    /// 杰理语音识别状态
     static let deviceJLAudioState = "deviceJLAudioState"

     /// 杰理语音识别完成
     static let deviceJLAudioComplete = "deviceJLAudioComplete"
    
    // MARK: - 实时数据
    
    /// 计步
    static let deviceRealStep = "deviceRealStep"
    
    /// 运动
    static let deviceRealSport = "deviceRealSport"
    
    /// 心率
    static let deviceRealHeartRate = "deviceRealHeartRate"
    
    /// 血压
    static let deviceRealBloodPressure = "deviceRealBloodPressure"
    
    /// 血氧
    static let deviceRealBloodOxygen = "deviceRealBloodOxygen"
    
    /// 温度
    static let deviceRealTemperature = "deviceRealTemperature"

    /// 压力
    static let deviceRealPressure = "deviceRealPressure"

    /// 最大摄氧量
    static let deviceRealVo2max = "deviceRealVo2max"

    /// 血糖
    static let deviceRealBloodGlucose: String = "deviceRealBloodGlucose"

    /// HRV
    static let deviceRealHRV: String = "deviceRealHRV"
    
    /// 实时ECG数据
    static let deviceRealECGData = "deviceRealECGData"
    
    /// 实时ACC数据
    static let deviceRealACCData = "deviceRealACCData"
    
    /// 实时ECG数据滤波数据
    static let deviceRealECGFilteredData = "deviceRealECGFilteredData"
    
    /// 实时ACC数据滤波数据
    static let deviceRealACCFilteredData = "deviceRealACCFilteredData"

    /// 实时PPG数据
    static let deviceRealPPGData = "deviceRealPPGData"
    
    /// 多通道PPG数据
    static let deviceMultiChannelPPGData = "deviceMultiChannelPPGData"
    
    /// 实时RR数据
    static let deviceRealECGAlgorithmRR = "deviceRealECGAlgorithmRR"
    
    /// 实时HRV数据
    static let deviceRealECGAlgorithmHRV = "deviceRealECGAlgorithmHRV"
    
    static let deviceEndECG = "deviceEndECG"
    
    static let  appECGPPGStatus = "appECGPPGStatus"
}

/// 蓝牙状态
public class BluetoothState {
    static let off = 0                       // 蓝牙关闭
    static let on = 1                    // 蓝牙开启
    static let connected = 2             // 连接
    static let connectFailed = 3         // 连接失败
    static let disconnected = 4          // 断开连接
}

/// 插件API的状态
class PluginState {
    static let succeed          = 0    // 执行成功
    static let failed           = 1    // 执行失败
    static let unavailable      = 2    // 设备不支持
}

/// 健康数据类型
class HealthDataType {
    static let step = 0                       // 步数(步数、距离、卡咱里)
    static let sleep = 1                      // 睡眠
    static let heartRate = 2                  // 心率
    static let bloodPressure = 3              // 血压
    static let combinedData = 4               // 组合数据(体温、血氧、呼吸率、血糖等)
    static let invasiveComprehensiveData = 5  // 有创数据 (血脂和尿酸)
    static let sportHistoryData        = 6    // 运动历史记录
    static let bodyIndexData = 7              // 压力、最大摄氧量
    static let historyWearData = 8            // 历史佩戴数据
}


/// 升级状态
public enum DeviceUpdateState: Int {
    case start                          // 开始升级
    case upgradingResources             // 升级资源
    case upgradeResourcesFinished       // 升级资源结束
    case upgradingFirmware              // 升级固件
    case succeed                        // 升级完成
    case failed                         // 升级失败
    
    case installingWatchFace            // 正在安装盘
}
