//
//  YcProductPlugin + AppControl.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/14.
//

import UIKit
import Flutter
import YCProductSDK

// MARK: - AppControl
extension YcProductPlugin {

    
    /// 发送手机的UUID
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func sendPhoneUUIDToDevice(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let content = arguments as? String else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        
        YCProduct.sendPhoneUUIDToDevice(content: content) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 发送生理周期
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func sendDeviceMenstrualCycle(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [Int],
              list.count >= 3
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let time = list[0]
        let duration = list[1]
        let cycle = list[2]
        
        YCProduct.sendMenstrualCycle(
            time: time,
            duration: UInt8(duration),
            cycle: UInt8(cycle)
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 找设备
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func findDevice(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let remindCount = list.first,
              let remindInterval = list.last
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.findDevice(
            remindCount: UInt8(remindCount),
            remindInterval: UInt8(remindInterval)
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
 
    
    /// 关机操作
    /// - Parameters:
    ///   - call.arguments: <#call.arguments description#>
    ///   - result: <#result description#>
    public func deviceSystemOperator(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let value = arguments as? Int,
              let mode = YCDeviceSystemOperator(rawValue: UInt8(value)) else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.deviceSystemOperator(mode: mode) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 血压校准
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func bloodPressureCalibration(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let sbp = list.first,
              let dbp = list.last
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.deviceBloodPressureCalibration(systolicBloodPressure: UInt8(sbp), diastolicBloodPressure: UInt8(dbp)) { state, response in
         
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 温度校准
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func temperatureCalibration(_ arguments: Any?, result: @escaping FlutterResult) {
     
        YCProduct.deviceTemperatureCalibration { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 血糖标定
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func bloodGlucoseCalibration(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 3
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let mode =
            YCBloodGlucoseCalibrationaMode(
                rawValue: UInt8(list[0])
            ) ?? .fasting
        
        let bloodGlucoseInteger = Int8(list[1])
        let bloodGlucoseDecimal = Int8(list[2])
        
        YCProduct.bloodGlucoseCalibration(
            bloodGlucoseInteger: bloodGlucoseInteger,
            bloodGlucoseDecimal: bloodGlucoseDecimal,
            mode: mode
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
            
        }
    }
    
    
    /// 发送今天天气
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func sendTodayWeather(_ arguments: Any?, result: @escaping FlutterResult) {
     
        guard let list = arguments as? [Int],
              list.count >= 4
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let type = YCWeatherCodeType(rawValue: UInt8(list[0])) ?? .unknow
        let lowestTemperature = Int8(list[1])
        let highestTemperature = Int8(list[2])
        let realTimeTemperature = Int8(list[3])
        
        YCProduct.sendWeatherData(
            isTomorrow: false,
            lowestTemperature: lowestTemperature,
            highestTemperature: highestTemperature,
            realTimeTemperature: realTimeTemperature,
            weatherType: type
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 发送明天天气
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func sendTomorrowWeather(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 4
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let type = YCWeatherCodeType(rawValue: UInt8(list[0])) ?? .unknow
        let lowestTemperature = Int8(list[1])
        let highestTemperature = Int8(list[2])
        let realTimeTemperature = Int8(list[3])
        
        YCProduct.sendWeatherData(
            isTomorrow: true,
            lowestTemperature: lowestTemperature,
            highestTemperature: highestTemperature,
            realTimeTemperature: realTimeTemperature,
            weatherType: type
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 波形上传控制
    /// - Parameters:
    ///   - state: 是否开关
    ///   - dataType: 波形类型
    ///   - result: <#result description#>
    public func waveDataUpload(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              list.count >= 2
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        let state = YCWaveUploadState(rawValue: UInt8(list[0])) ?? .uploadWithOutSerialnumber
        let dataType = YCWaveDataType(rawValue: UInt8(list[1])) ?? .ecg
        
//        YCProduct.waveDataUpload(state: state, dataType: dataType) { state, response in
//            result(["code": self.convertFlutterState(state),
//                    "data": ""]
//        }
                   YCProduct.waveDataUpload(state: state, dataType: dataType) { state, response in
                       result(["code": self.convertFlutterState(state),
                               "data": ""]
                       )
                   }
    }
    
    
    /// 尿酸标定
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func uricAcidCalibration(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let uricAcid = arguments as? Int else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.uricAcidCalibration(value: UInt16(uricAcid)) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    
    /// 血酯标定
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func bloodFatCalibration(_ arguments: Any?, result: @escaping FlutterResult) {
     
        guard let cholesterolString = arguments as? String,
         let value = Double(cholesterolString) else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.bloodFatCalibration(cholesterol: value) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 发送名片
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func sendBusinessCard(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Any],
              let typeValue = list.first as? Int,
              let cardType = YCBusinessCardType(rawValue: UInt8(typeValue)),
              let contents = list.last as? String
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
            
        }
        
        YCProduct.sendBusinessCard(businessCardType: cardType, content: contents) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 查询名片
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryBusinessCard(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let value = arguments as? Int,
              let cardType = YCBusinessCardType(rawValue: UInt8(value)) else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.queryBusinessCardContent(businessCardType: cardType) { state, response in
            
            var data = ""
            
            if state == .succeed,
               let contents = response as? String {
                
               data = contents
            }
            
            result(["code": self.convertFlutterState(state),
                    "data": data]
            )
            
        }
        
    }
    
    /// APP通知手表/戒指退出睡眠
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func sendDeviceQuiteSleep(result: @escaping FlutterResult) {
        
        
        YCProduct.sendDeviceQuiteSleep { state, response in
            
            let code = self.convertFlutterState(state)
            
            guard state == YCProductState.succeed,
                  let name = response as? String else {
                
                result(["code": code, "data": ""])
                return
            }
            
            result(["code": code, "data": ""])
        }
    }
}
