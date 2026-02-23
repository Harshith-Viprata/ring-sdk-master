//
//  YcProductPlugin + Setting.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/13.
//

import UIKit
import Flutter
import YCProductSDK

// MARK: - 设置
extension YcProductPlugin {
    
    
    /// 设置时间
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceSyncPhoneTime(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.setDeviceSyncPhoneTime { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置运动步数目标
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceStepGoal(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let step = arguments as? Int,
              step > 0 else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceStepGoal(step: UInt32(step)) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置睡眠目标
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceSleepGoal(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let hour = list.first,
              let min = list.last
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceSleepGoal(hour: UInt8(hour), minute: UInt8(min)) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置用户信息
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceUserInfo(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 4
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let height = list[0] < 0 ? 0 : list[0]
        let weight = list[1] < 0 ? 0 : list[1]
        let gender: YCDeviceGender = list[2] <= 0 ? .male : .female
        let age = list[3] < 0 ? 0 : list[3]
        
        guard  height < 255, weight < 255,gender.rawValue < 255,age < 255
        else{
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        
        YCProduct.setDeviceUserInfo(height: UInt8(height), weight: UInt8(weight), gender: gender, age: UInt8(age)) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置肤色
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceSkinColor(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let level = arguments as? Int,
              let skiniColor = YCDeviceSkinColorLevel(rawValue: UInt8(level)) else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceSkinColor(level: skiniColor) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置单位
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceUnit(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 6
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        
        let distance: YCDeviceDistanceType =
        list[0] == 0 ? .km : .mile
        
        let weight: YCDeviceWeightType =
        list[1] == 0 ? .kg : .lb
        
        let temperature: YCDeviceTemperatureType =
        list[2] == 0 ? .celsius : .fahrenheit
        
        let timeFormat: YCDeviceTimeType =
        list[3] == 0 ? .hour24 : .hour12
        
        let bloodGlucoseOrBloodFat: YCDeviceBloodGlucoseType =
        list[4] == 0 ? .millimolePerLiter : .milligramsPerDeciliter
        
        let uricAcid: YCDeviceUricAcidType =
        list[5] == 0 ? .micromolePerLiter : .milligramsPerDeciliter
        
        YCProduct.setDeviceUnit(
            distance: distance,
            weight: weight,
            temperature: temperature,
            timeFormat: timeFormat,
            bloodGlucoseOrBloodFat: bloodGlucoseOrBloodFat,
            uricAcid: uricAcid) { state, response in
                
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
    }
    
    /// 设置防丢
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceAntiLost(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let isEnable = arguments as? Bool else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceAntiLost(antiLostType: isEnable ? .middleDistance : .off) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置勿扰
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceNotDisturb(_ arguments: Any?, result: @escaping FlutterResult) {
        
        
        guard let list = arguments as? [Int],
              list.count >= 5
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let isEnable = list[0] != 0
        let startHour = list[1]
        let startMinute = list[2]
        let endHour = list[3]
        let endMinute = list[4]
        
        YCProduct.setDeviceNotDisturb(
            isEnable: isEnable,
            startHour: UInt8(startHour),
            startMinute: UInt8(startMinute),
            endHour: UInt8(endHour),
            endMinute: UInt8(endMinute)
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
        
    }
    
    /// 设置语言
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceLanguage(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let type = arguments as? Int,
              let language = YCDeviceLanguageType(rawValue: UInt8(type)) else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceLanguage(language: language) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 久坐提醒
    public func setDeviceSedentary(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 10 else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let startHour1 = list[0]
        let startMinute1 = list[1]
        let endHour1 = list[2]
        let endMinute1 = list[3]
        
        let startHour2 = list[4]
        let startMinute2 = list[5]
        let endHour2 = list[6]
        let endMinute2 = list[7]
        
        let interval = list[8]
        let repeatValue: UInt8 = UInt8(list[9] & 0xFF)
        
        var values = Set<YCDeviceWeekRepeat>()
        
        for index in 0 ..< 8 {
            
            let bitValue: UInt8 = 1 << index
            
            if repeatValue & bitValue > 0,
            let item = YCDeviceWeekRepeat(rawValue: bitValue) {
                
                values.insert(item)
            }
        }
        
        YCProduct.setDeviceSedentary(
            startHour1: UInt8(startHour1),
            startMinute1: UInt8(startMinute1),
            endHour1: UInt8(endHour1),
            endMinute1: UInt8(endMinute1),
            startHour2: UInt8(startHour2),
            startMinute2: UInt8(startMinute2),
            endHour2: UInt8(endHour2),
            endMinute2: UInt8(endMinute2),
            interval: UInt8(interval),
            repeat: values
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 左右手佩戴设置
    public func setDeviceWearingPosition(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let position = arguments as? Int,
              let wearingPosition = YCDeviceWearingPositionType(rawValue: UInt8(position))
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceWearingPosition(wearingPosition: wearingPosition) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置手机系统
    public func setPhoneSystemInfo(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.setPhoneSystemInfo() { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
        
    }
    
    
    /// 抬腕亮屏
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceWristBrightScreen(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let isEnable = arguments as? Bool  else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceWristBrightScreen(isEnable: isEnable) { state, response in
         
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 亮度设置
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceDisplayBrightness(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let levelValue = arguments as? Int,
        let level =
                YCDeviceDisplayBrightnessLevel(rawValue: UInt8(levelValue)) else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        YCProduct.setDeviceDisplayBrightness(level: level) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 健康监测
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceHealthMonitoringMode(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let flag = list.first,
              let interval = list.last
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceHealthMonitoringMode(
            isEnable: flag != 0,
            interval: UInt8(interval)
        ) { state, response in
                
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 温度监测
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceTemperatureMonitoringMode(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let flag = list.first,
              let interval = list.last
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceTemperatureMonitoringMode(
            isEnable: flag != 0,
            interval: UInt8(interval)
        ) { state, response in
                
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 心率报警
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceHeartRateAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 3
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let isEnable = list[0] != 0
        let maxHeartRate = list[1]
        let minHeartRate = list[2]
        
        YCProduct.setDeviceHeartRateAlarm(
            isEnable: isEnable,
            maxHeartRate: UInt8(maxHeartRate),
            minHeartRate: UInt8(minHeartRate)
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 血压报警
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceBloodPressureAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 5
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let isEnable = list[0] != 0
        let maxSBP = list[1]
        let maxDBP = list[2]
        let minSBP = list[3]
        let minDBP = list[4]
        
        YCProduct.setDeviceBloodPressureAlarm(
            isEnable: isEnable,
            maximumSystolicBloodPressure: UInt8(maxSBP),
            maximumDiastolicBloodPressure: UInt8(maxDBP),
            minimumSystolicBloodPressure: UInt8(minSBP),
            minimumDiastolicBloodPressure: UInt8(minDBP)
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 血氧报警
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceBloodOxygenAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let flag = list.first,
              let value = list.last
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.setDeviceBloodOxygenAlarm(
            isEnable: flag != 0,
            minimum: UInt8(value)
        ) { state, response in
              
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 呼吸率报警
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceRespirationRateAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 3
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let isEnable = list[0] != 0
        let maximum = list[1]
        let minimum = list[2]
        
        YCProduct.setDeviceRespirationRateAlarm(
            isEnable: isEnable,
            maximum: UInt8(maximum),
            minimum: UInt8(minimum)
        ) { state, response in
                
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 温度报警
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceTemperatureAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 5
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let isEnable = list[0] != 0
        let highTemperatureIntegerValue = list[1]
        let highTemperatureDecimalValue = list[2]
        let lowTemperatureIntegerValue = list[3]
        let lowTemperatureDecimalValue = list[4]
        
        YCProduct.setDeviceTemperatureAlarm(
            isEnable: isEnable,
            highTemperatureIntegerValue:
                UInt8(highTemperatureIntegerValue),
            highTemperatureDecimalValue:
                UInt8(highTemperatureDecimalValue),
            lowTemperatureIntegerValue:
                Int8(lowTemperatureIntegerValue),
            lowTemperatureDecimalValue:
                UInt8(lowTemperatureDecimalValue)
        ) { state, response in
        
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 获取主题
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceTheme(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.queryDeviceTheme { state, response in
            
            guard state == .succeed,
                  let info = response as? YCDeviceTheme else {
                
                result(["code": PluginState.failed,
                        "data": ""]
                )
                
                return
            }
            
            result(["code": self.convertFlutterState(state),
                    "data": [
                        "index": info.themeIndex,
                        "count": info.themeCount]
                   ]
            )
            
        }
    }
    
    /// 设置主题
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceTheme(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let index = arguments as? Int else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        YCProduct.setDeviceTheme(index: UInt8(index)) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 设置睡眠提醒时间
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceSleepReminder(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 3
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let hour = list[0]
        let minute = list[1]
        let repeatValue: UInt8 = UInt8(list[2] & 0xFF)
        
        var values = Set<YCDeviceWeekRepeat>()
        
        for index in 0 ..< 8 {
            
            let bitValue: UInt8 = 1 << index
            
            if repeatValue & bitValue > 0,
            let item = YCDeviceWeekRepeat(rawValue: bitValue) {
                
                values.insert(item)
            }
        }
        
        YCProduct.setDeviceSleepReminder(
            hour: UInt8(hour),
            minute: UInt8(minute),
            repeat: values
        ) { state, response in
                
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 设置消息推送
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDeviceInfoPush(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 4
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let isEnable = list[0] != 0
        let item1 = list[1]
        let item2 = list[2]
        let item3 = list[3]
        
        var repeatValue = Set<YCDeviceInfoPushType>()
        
        let bit0 = 1 << 0
        let bit1 = 1 << 1
        let bit2 = 1 << 2
        let bit3 = 1 << 3
        let bit4 = 1 << 4
        let bit5 = 1 << 5
        let bit6 = 1 << 6
        let bit7 = 1 << 7
        
        if (item1 & bit0) > 0 {
            repeatValue.insert(.twitter)
        }
        
        if (item1 & bit1) > 0 {
            repeatValue.insert(.facebook)
        }
        
        if (item1 & bit2) > 0 {
            repeatValue.insert(.weibo)
        }
        
        if (item1 & bit3) > 0 {
            repeatValue.insert(.qq)
        }
        
        if (item1 & bit4) > 0 {
            repeatValue.insert(.wechat)
        }
        
        if (item1 & bit5) > 0 {
            repeatValue.insert(.email)
        }
        
        if (item1 & bit6) > 0 {
            repeatValue.insert(.sms)
        }
        
        if (item1 & bit7) > 0 {
            repeatValue.insert(.call)
        }
        
        if (item2 & bit0) > 0 {
            repeatValue.insert(.telegram)
        }
        
        if (item2 & bit1) > 0 {
            repeatValue.insert(.snapchat)
        }
        
        if (item2 & bit2) > 0 {
            repeatValue.insert(.line)
        }
        
        if (item2 & bit3) > 0 {
            repeatValue.insert(.skype)
        }
        
        if (item2 & bit4) > 0 {
            repeatValue.insert(.instagram)
        }
        
        if (item2 & bit5) > 0 {
            repeatValue.insert(.linkedIn)
        }
        
        if (item2 & bit6) > 0 {
            repeatValue.insert(.whatsAPP)
        }
        
        if (item2 & bit7) > 0 {
            repeatValue.insert(.messenger)
        }
         
        if (item3 & bit0) > 0 {
            repeatValue.insert(.other)
        }
        
        if (item3 & bit1) > 0 {
            repeatValue.insert(.viber)
        }
        
        if (item3 & bit2) > 0 {
            repeatValue.insert(.zoom)
        }
        
        if (item3 & bit3) > 0 {
            repeatValue.insert(.tiktok)
        }
        
        if item3 & (1 << 4) > 0 {
            repeatValue.insert(.kakaoTalk)
        }
        
        YCProduct.setDeviceInfoPush(
            isEnable: isEnable,
            infoPushType: repeatValue
        ) { state, response in
                
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    
    
    /// 设置定时任务(喝水等)
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setDevicePeriodicReminderTask(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Any],
              list.count >= 8,
        let reminderTypeRawValue = list[0] as? Int,
        let reminderType = YCPeriodicReminderType(rawValue: UInt8(reminderTypeRawValue)),
        
        let startHour = list[1] as? Int,
        let startMinute = list[2] as? Int,
        let endHour = list[3] as? Int,
        let endMinute = list[4] as? Int,
        let interval = list[5] as? Int,
        let week = list[6] as? Int,
        let contnet = list[7] as? String
                
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        
        let repeatValue: UInt8 = UInt8(week & 0xFF)
        
        var values = Set<YCDeviceWeekRepeat>()
        
        for index in 0 ..< 8 {
            
            let bitValue: UInt8 = 1 << index
            
            if repeatValue & bitValue > 0,
            let item = YCDeviceWeekRepeat(rawValue: bitValue) {
                
                values.insert(item)
            }
        }
        
        YCProduct.setDevicePeriodicReminderTask(
            periodicReminderType: reminderType,
            startHour: UInt8(startHour),
            startMinute: UInt8(startMinute),
            endHour: UInt8(endHour),
            endMinute: UInt8(endMinute),
            repeat: values,
            interval: UInt8(interval),
            content: contnet
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
            
        }
        
    }
    
    /// 恢复出厂设置
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func restoreFactorySettings(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.setDeviceReset { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }

    /// 查询闹钟
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func settingGetAllAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
         YCProduct.queryDeviceAlarmInfo { state, response in

            if state == .succeed,
                let datas = response as? [YCDeviceAlarmInfo] {
                var array = []
                
                for item in datas {
                    var repeatValue = 0
                    for week in item.repeat {
                        print("\(week.rawValue)")
                        repeatValue = repeatValue + Int(week.rawValue)
                    }
                    
                    let dicionary = ["alarmHour":item.hour,"alarmType":item.alarmType.rawValue,"alarmMin":item.minute,"alarmRepeat":UInt8(repeatValue),"alarmDelayTime":item.snoozeTime]
                    array.append(dicionary)
                }
              result(["code": self.convertFlutterState(state),"data": array])
 
                } else {
                    result(["code": self.convertFlutterState(state),"data": []])
                }
        }
    }

    /// 添加闹钟
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func settingAddAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Any],
              list.count >= 5,
        let typeRawValue = list[0] as? Int,
        let type = YCDeviceAlarmType(rawValue: UInt8(typeRawValue)),
        
        let startHour = list[1] as? Int,
        let startMinute = list[2] as? Int,
        let weekRepeat = list[3] as? String,
        let delayTime = list[4] as? Int,
        
                let repeatValue = UInt8(weekRepeat, radix: 2)
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
//        let week = Int(weekRepeat) ?? 0
//        
//        let repeatValue: UInt8 = UInt8(week & 0xFF)
        
        var values = Set<YCDeviceWeekRepeat>()
        
        for index in 0 ..< 8 {
            
            let bitValue: UInt8 = 1 << index
            
            if repeatValue & bitValue > 0,
            let item = YCDeviceWeekRepeat(rawValue: bitValue) {
                
                values.insert(item)
            }
        }

        YCProduct.addDeviceAlarm(alarmType: type, hour: UInt8(startHour), minute: UInt8(startMinute), repeat: values, snoozeTime: UInt8(delayTime)) { state, response in
             result(["code": self.convertFlutterState(state),
                    "data": ""])
        }
    }

    /// 修改闹钟
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func settingModfiyAlarm(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Any],
              list.count >= 7,
        let typeRawValue = list[2] as? Int,
        let type = YCDeviceAlarmType(rawValue: UInt8(typeRawValue)),
        
        let oldHour = list[0] as? Int,
        let oldMinute = list[1] as? Int,
        
        let newHour = list[3] as? Int,
        let newMinute = list[4] as? Int,
        let weekRepeat =  list[5] as? String,
        let delayTime = list[6] as? Int,
              let repeatValue = UInt8(weekRepeat, radix: 2)
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
//        let week = Int(weekRepeat) ?? 0
//        
//        let repeatValue: UInt8 = UInt8(week & 0xFF)
//        guard let repeatValue = UInt8(weekRepeat, radix: 2) else { }
        
//        if let repeatValue = Int(weekRepeat, radix: 2) {
//            print("二进制 \(weekRepeat) 转换成十进制是: \(repeatValue)")
//        } else {
//            print("转换失败")
//        }
        
        var values = Set<YCDeviceWeekRepeat>()
        
        for index in 0 ..< 8 {
            
            let bitValue: UInt8 = 1 << index
            
            if repeatValue & bitValue > 0,
            let item = YCDeviceWeekRepeat(rawValue: bitValue) {
                
                values.insert(item)
            }
        }
        
         YCProduct.modifyDeviceAlarm(oldHour: UInt8(oldHour), oldMinute: UInt8(oldMinute), hour: UInt8(newHour), minute: UInt8(newMinute), alarmType: type, repeat: values, snoozeTime: UInt8(delayTime)) { state, response in
             result(["code": self.convertFlutterState(state),
                    "data": ""])
        }
    }
}
