//
//  YcProductPlugin + Query.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/8.
//

import UIKit
import Flutter
import YCProductSDK

// MARK: - 查询
extension YcProductPlugin {
    
    
    /// 查询基本信息
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceBasicInfo(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.queryDeviceBasicInfo { state, response in
            
            let code = self.convertFlutterState(state)
            
            
            guard state == YCProductState.succeed,
                  let info = response as? YCDeviceBasicInfo else {
                
                result(["code": code, "data": [:]])
                return
            }
            
            let data = [
                "deviceID": info.deviceID,
                "deviceType": info.deviceType.rawValue,
                "batteryStatus": info.batterystatus.rawValue,
                "batteryPower": info.batteryPower,
                "firmwareMajorVersion": info.mcuFirmware.majorVersion,
                "firmwareSubVersion": info.mcuFirmware.subVersion
            ]
            
            result(["code": code, "data": data])
            
        }
    }
    
    /// 查询mac地址
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceMacAddress(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.queryDeviceMacAddress { state, response in
            
            let code = self.convertFlutterState(state)
            
            guard state == YCProductState.succeed,
                  let macaddress = response as? String else {
                
                result(["code": code, "data": ""])
                return
            }
            
            result(["code": code, "data": macaddress])
        }
    }
    
    /// 查询设备型号
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceModel(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.queryDeviceModel { state, response in
            
            let code = self.convertFlutterState(state)
            
            guard state == YCProductState.succeed,
                  let name = response as? String else {
                
                result(["code": code, "data": ""])
                return
            }
            
            result(["code": code, "data": name])
        }
    }
    
    /// 查询芯片型号
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceMCU(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.queryDeviceMCU { state, response in
            
            let code = self.convertFlutterState(state)
            
            guard state == .succeed,
                  let mcu = response as? YCDeviceMCUType else {
                
                result(["code": code, "data": 0])
                return
            }
            
            result(["code": code, "data": mcu.rawValue])
        }
    }
    
    
    /// 获取设备的功能列表
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func getDeviceFeature(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let items = YCProduct.shared.currentPeripheral?.supportItems else {
            
            result(["code": PluginState.failed, "data": [:]])
            return
        }
        
        let deviceFeature =
        [
            /// 血压
            "isSupportBloodPressure": items.isSupportBloodPressure,
            
            /// 语言设置
            "isSupportLanguageSettings": items.isSupportLanguageSettings,
            
            /// 消息推送 (总开关)
            "isSupportInformationPush": items.isSupportInformationPush,
            
            /// 心率
            "isSupportHeartRate": items.isSupportHeartRate,
            
            /// OTA升级
            "isSupportOta": items.isSupportOta,
            
            /// 实时数据上传
            "isSupportRealTimeDataUpload": items.isSupportRealTimeDataUpload,
            
            /// 睡眠
            "isSupportSleep": items.isSupportSleep,
            
            /// 计步
            "isSupportStep": items.isSupportStep,
            
            // MARK: - === 主要功能2 ===
            
            /// 多运动
            "isSupportSport": items.isSupportSport,
            
            /// HRV
            "isSupportHRV": items.isSupportHRV,
            
            /// 呼吸率
            "isSupportRespirationRate": items.isSupportRespirationRate,
            
            /// 血氧
            "isSupportBloodOxygen": items.isSupportBloodOxygen,
            
            /// 历史ECG
            "isSupportHistoricalECG": items.isSupportHistoricalECG,
            
            /// 实时ECG
            "isSupportRealTimeECG": items.isSupportRealTimeECG,
            
            /// 血压告警
            "isSupportBloodPressureAlarm": items.isSupportBloodPressureAlarm,
            
            /// 心率告警
            "isSupportHeartRateAlarm": items.isSupportHeartRateAlarm,
            
            
            // MARK: - === 闹钟类型 ====
            
            /// 闹钟数量( alarmClockCount 0表示不支持闹钟)
            "isSupportAlarm": items.alarmClockCount > 0,
            
            /// 闹钟类型 起床
            "isSupportAlarmTypeWakeUp": items.isSupportAlarmTypeWakeUp,
            
            /// 闹钟类型 起床
            "isSupportAlarmTypeSleep": items.isSupportAlarmTypeSleep,
            
            /// 闹钟类型 锻炼
            "isSupportAlarmTypeExercise": items.isSupportAlarmTypeExercise,
            
            /// 闹钟类型 吃药
            "isSupportAlarmTypeMedicine": items.isSupportAlarmTypeMedicine,
            
            /// 闹钟类型 约会
            "isSupportAlarmTypeAppointment": items.isSupportAlarmTypeAppointment,
            
            /// 闹钟类型 聚会
            "isSupportAlarmTypeParty": items.isSupportAlarmTypeParty,
            
            /// 闹钟类型 会议
            "isSupportAlarmTypeMeeting": items.isSupportAlarmTypeMeeting,
            
            /// 闹钟类型 自定义
            "isSupportAlarmTypeCustom": items.isSupportAlarmTypeCustom,
            
            
            // MARK: - === 消息推送 ===
            
            // 第一组
            "isSupportInformationTypeTwitter": items.isSupportInformationTypeTwitter,
            "isSupportInformationTypeFacebook": items.isSupportInformationTypeFacebook,
            "isSupportInformationTypeWeiBo": items.isSupportInformationTypeWeiBo,
            "isSupportInformationTypeQQ": items.isSupportInformationTypeQQ,
            "isSupportInformationTypeWeChat": items.isSupportInformationTypeWeChat,
            "isSupportInformationTypeEmail": items.isSupportInformationTypeEmail,
            "isSupportInformationTypeSMS": items.isSupportInformationTypeSMS,
            "isSupportInformationTypeCall": items.isSupportInformationTypeCall,
            
            // 第二组
            "isSupportInformationTypeTelegram": items.isSupportInformationTypeTelegram,
            "isSupportInformationTypeSkype": items.isSupportInformationTypeSkype,
            "isSupportInformationTypeSnapchat": items.isSupportInformationTypeSnapchat,
            "isSupportInformationTypeLine": items.isSupportInformationTypeLine,
            "isSupportInformationTypeLinkedIn": items.isSupportInformationTypeLinkedIn,
            "isSupportInformationTypeInstagram": items.isSupportInformationTypeInstagram,
            "isSupportInformationTypeMessenger": items.isSupportInformationTypeMessenger,
            "isSupportInformationTypeWhatsApp": items.isSupportInformationTypeWhatsApp,
            
            // MARK: - === 其它功能1 ===
            
            /// 翻腕亮屏
            "isSupportWristBrightScreen": items.isSupportWristBrightScreen,
            
            /// 勿扰模式
            "isSupportDoNotDisturbMode": items.isSupportDoNotDisturbMode,
            
            /// 血压水平设置
            "isSupportBloodPressureLevelSetting": items.isSupportBloodPressureLevelSetting,
            
            /// 出厂设置
            "isSupportFactorySettings": items.isSupportFactorySettings,
            
            /// 找设备
            "isSupportFindDevice": items.isSupportFindDevice,
            
            /// 找手机
            "isSupportFindPhone": items.isSupportFindPhone,
            
            /// 防丢提醒
            "isSupportAntiLostReminder": items.isSupportAntiLostReminder,
            
            /// 久坐提醒
            "isSupportSedentaryReminder": items.isSupportSedentaryReminder,
            
            // MARK: - === 其它功能2 ===
            
            /// 上传数据 加密
            "isSupportUploadDataEncryption": items.isSupportUploadDataEncryption,
            
            /// 通话
            "isSupportCall": items.isSupportCall,
            
            /// 心电诊断
            "isSupportECGDiagnosis": items.isSupportECGDiagnosis,
            
            /// 明日天气
            "isSupportTomorrowWeather": items.isSupportTomorrowWeather,
            
            /// 今日天气
            "isSupportTodayWeather": items.isSupportTodayWeather,
            
            /// 搜周边
            "isSupportSearchAround": items.isSupportSearchAround,
            
            /// 微信运动
            "isSupportWeChatSports": items.isSupportWeChatSports,
            
            /// 肤色设置
            "isSupportSkinColorSettings": items.isSupportSkinColorSettings,
            
            
            // MARK: - === 其它功能3 ===
            
            /// 温度
            "isSupportTemperature": items.isSupportTemperature,
            
            /// 压力
            "isSupportPressure": items.isSupportPressure,

            /// 最大摄氧量
            "isSupportVo2max": items.isSupportVo2max,
   
            /// 音乐控制
            "isSupportMusicControl": items.isSupportMusicControl,
            
            /// 主题
            "isSupportTheme": items.isSupportTheme,
            
            /// 电极位置
            "isSupportElectrodePosition": items.isSupportElectrodePosition,
            
            /// 血压校准
            "isSupportBloodPressureCalibration": items.isSupportBloodPressureCalibration,
            
            /// CVRR
            "isSupportCVRR": items.isSupportCVRR,
            
            /// 腋温测量
            "isSupportAxillaryTemperatureMeasurement": items.isSupportAxillaryTemperatureMeasurement,
            
            /// 温度预警
            "isSupportTemperatureAlarm": items.isSupportTemperatureAlarm,
            
            // MARK: - === 其它功能4 ===
            
            /// 温度校准
            "isSupportTemperatureCalibration": items.isSupportTemperatureCalibration,
            
            /// 机主信息编辑
            "isSupportHostInfomationEdit": items.isSupportHostInfomationEdit,
            
            /// 手动拍照
            "isSupportManualPhotographing": items.isSupportManualPhotographing,
            
            /// 摇一摇拍照
            "isSupportShakePhotographing": items.isSupportShakePhotographing,
            
            /// 女性生理周期
            "isSupportFemalePhysiologicalCycle": items.isSupportFemalePhysiologicalCycle,
            
            /// 表盘功能
            "isSupportWatchFace": items.isSupportWatchFace,
            
            /// 通讯录
            "isSupportAddressBook": items.isSupportAddressBook,
            
            /// ECG结果精准
            "isECGResultsAccurate": items.isECGResultsAccurate,
            
            
            // MARK: - 运动模式
            
            /// 登山
            "isSupportMountaineering": items.isSupportMountaineering,
            
            /// 足球
            "isSupportFootball": items.isSupportFootball,
            
            /// 乒乓球
            "isSupportPingPang": items.isSupportPingPang,
            
            /// 户外跑步
            "isSupportOutdoorRunning": items.isSupportOutdoorRunning,
            
            /// 室内跑步
            "isSupportIndoorRunning": items.isSupportIndoorRunning,
            
            /// 户外步行
            "isSupportOutdoorWalking": items.isSupportOutdoorWalking,
            
            /// 室内步行
            "isSupportIndoorWalking": items.isSupportIndoorWalking,
            
            /// 实时监护模式
            "isSupportRealTimeMonitoring": items.isSupportRealTimeMonitoring,
            
            /// 羽毛球
            "isSupportBadminton": items.isSupportBadminton,
            
            /// 健走
            "isSupportWalk": items.isSupportWalk,
            
            /// 游泳
            "isSupportSwimming": items.isSupportSwimming,
            
            /// 篮球
            "isSupportPlayBall": items.isSupportPlayball,
            
            /// 跳绳
            "isSupportRopeSkipping": items.isSupportRopeskipping,
            
            /// 骑行
            "isSupportRiding": items.isSupportRiding,
            
            /// 健身
            "isSupportFitness": items.isSupportFitness,
            
            /// 跑步
            "isSupportRun": items.isSupportRun,
            
            /// 室内骑行
            "isSupportIndoorRiding": items.isSupportIndoorRiding,
            
            /// 踏步机
            "isSupportStepper": items.isSupportStepper,
            
            /// 划船机
            "isSupportRowingMachine": items.isSupportRowingMachine,
            
            /// 仰卧起坐
            "isSupportSitUps": items.isSupportSitups,
            
            /// 跳跃运动
            "isSupportJumping": items.isSupportJumping,
            
            /// 重量训练
            "isSupportWeightTraining": items.isSupportWeightTraining,
            
            /// 瑜伽
            "isSupportYoga": items.isSupportYoga,
            
            /// 徒步
            "isSupportOnFoot": items.isSupportOnfoot,
            
            // MARK: - === 扩充功能
            
            /// 同步运动实时数据
            "isSupportSyncRealSportData": items.isSupportSyncRealSportData,
            
            /// 启动心率测量
            "isSupportStartHeartRateMeasurement": items.isSupportStartHeartRateMeasurement,
            
            /// 启动血压测量
            "isSupportStartBloodPressureMeasurement": items.isSupportStartBloodPressureMeasurement,
            
            /// 启动血氧测量
            "isSupportStartBloodOxygenMeasurement": items.isSupportStartBloodOxygenMeasurement,
            
            /// 启动体温测量
            "isSupportStartBodyTemperatureMeasurement": items.isSupportStartBodyTemperatureMeasurement,

            /// 启动压力测量
            "isSupportStartPressureMeasurement": items.isSupportStartPressureMeasurement,
            
            /// 启动呼吸率测量
            "isSupportStartRespirationRateMeasurement": items.isSupportStartRespirationRateMeasurement,

            /// 启动血糖测量
            "isSupportStartBloodGlucoseMeasurement": items.isSupportStartBloodGlucoseMeasurement,

            /// 启动HRV测量
            "isSupportStartHRVMeasurement": items.isSupportStartHRVMeasurement,
            
            /// 自定义表盘
            "isSupportCustomWatchface": items.isSupportCustomWatchface,
            
            // =========
            
            /// 精准血压测量
            "isSupportAccurateBloodPressureMeasurement": items.isSupportAccurateBloodPressureMeasurement,
            
            /// SOS开关
            "isSupportSOS": items.isSupportSOS,
            
            /// 血氧报警
            "isSupportBloodOxygenAlarm": items.isSupportBloodOxygenAlarm,
            
            /// 精准血压实时数据上传
            "isSupportAccurateBloodPressureRealTimeDataUpload": items.isSupportAccurateBloodPressureRealTimeDataUpload,
            
            /// Viber消息推送
            "isSupportInformationTypeViber": items.isSupportInformationTypeViber,
            
            /// 其它消息推送
            "isSupportInformationTypeOther": items.isSupportInformationTypeOther,
            
            /// 自定义表盘颜色翻转
            "isFlipCustomDialColor": items.isFlipCustomDialColor,
            
            /// 手表亮度调节五档
            "isSupportFiveSpeedBrightness": items.isSupportFiveSpeedBrightness,
            
            
            // =============
            
            /// 震动强度设置
            "isSupportVibrationIntensitySetting": items.isSupportVibrationIntensitySetting,
            
            /// 亮屏时间设置
            "isSupportScreenTimeSetting": items.isSupportScreenTimeSetting,
            
            /// 亮屏亮度调节
            "isSupportScreenBrightnessAdjust": items.isSupportScreenBrightnessAdjust,
            
            /// 血糖测量
            "isSupportBloodGlucose": items.isSupportBloodGlucose,
            
            /// 运动暂停
            "isSupportSportPause": items.isSupportSportPause,

            ///是否支持运动断开延迟
            "isSupportMotionDelayDisconnect": items.isSupportMotionDelayDisconnect,
            
            /// 喝水提醒
            "isSupportDrinkWaterReminder": items.isSupportDrinkWaterReminder,
            
            /// 发送名片
            "isSupportBusinessCard": items.isSupportBusinessCard,
            
            /// 尿酸测量
            "isSupportUricAcid": items.isSupportUricAcid,
            
            
            // MARK: - 运动模式4
            
            /// 网球
            "isSupportVolleyball": items.isSupportVolleyball,
            
            /// 皮划艇
            "isSupportKayak": items.isSupportKayak,
            
            /// 轮滑
            "isSupportRollerSkating": items.isSupportRollerSkating,
            
            /// 网球
            "isSupportTennis": items.isSupportTennis,
            
            /// 高尔夫
            "isSupportGolf": items.isSupportGolf,
            
            /// 椭圆机
            "isSupportEllipticalMachine": items.isSupportEllipticalMachine,
            
            /// 舞蹈
            "isSupportDance": items.isSupportDance,
            
            /// 攀岩
            "isSupportRockClimbing": items.isSupportRockClimbing,
            
            
            /// 健身操
            "isSupportAerobics": items.isSupportAerobics,
            
            /// 其它运动
            "isSupportOtherSports": items.isSupportOtherSports,
            
            /// 血酮测量
            "isSupportBloodKetone": items.isSupportBloodKetone,
            
            /// 支持支付宝
            "isSupportAliPay": items.isSupportAliPay,
            
            /// 安卓绑定
            "isSupportAndroidBind": items.isSupportAndroidBind,
            
            /// 呼吸率告警
            "isSupportRespirationRateAlarm": items.isSupportRespirationRateAlarm,
            
            /// 血脂测量
            "isSupportBloodFat": items.isSupportBloodFat,
            
            /// 独立监测时间(E200测量)
            "isSupportIndependentMonitoringTime": items.isSupportIndependentMonitoringTime,
            
            /// 本地录音上传
            "isSupportLocalRecordingFileUpload": items.isSupportLocalRecordingFileUpload,
            
            /// 理疗记录
            "isSupportPhysiotherapyRecords": items.isSupportPhysiotherapyRecords,
            
            /// 是否支持消息推送 Zoom
            "isSupportInformationTypeZoom": items.isSupportInformationTypeZoom,
            
            /// 是否支持消息推送 TikTok
            "isSupportInformationTypeTikTok": items.isSupportInformationTypeTikTok,
            
            /// 是否支持消息推送 KakaoTalk
            "isSupportInformationTypeKaKaoTalk": items.isSupportInformationTypeKakaoTalk,
            
            
            // MARK: -
            
            /// 是否支持睡眠提醒
            "isSupportSleepReminder": items.isSupportSleepRemider,
            
            /// 是否支持设备规格设置
            "isSupportDeviceSpecificationsSetting": items.isSupportDeviceSpecificationsSetting,
            
            /// 是否支持设备本地运动上传
            "isSupportLocalSportDataUpload": items.isSupportLocalSportDataUpload,
            
            /// 是否支持零星小睡
            "isSupportFewSleep": items.isSupportFewSleep,
            
        ]
        
        result(["code": PluginState.succeed, "data": deviceFeature])
    }
}
