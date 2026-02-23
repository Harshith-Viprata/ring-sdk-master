//
//  YcProductPlugin + DeviceControl.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/16.
//

import Flutter
import UIKit
import YCProductSDK

// MARK: - 设备控制
extension YcProductPlugin {
    
    
    /// 设置设备监听
    public func setupDeviceControlObserver() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reciveDeviceReportData(_:)),
            name: YCProduct.deviceControlNotification,
            object: nil
        )
        
        // 杰理手表切换
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveJLWatchFaceChange(_:)),
            name: YCProduct.jlDeviceWachFaceChangeNotification,
            object: nil
        )
    }
    
    /// 接收表盘改变
    /// - Parameter ntf: ntf description
    @objc private func receiveJLWatchFaceChange(_ ntf: Notification) {
        
        guard let info = ntf.object as? [String: Any],
              let name = info[YCProduct.jlDeviceWatcFaceChangeKey] as? String else {
            return
        }
        
        let currentWatchName =
            name.replacingOccurrences(of: "/", with: "")
        
        eventSink?(
            [
                NativeEventType.deviceJieLiWatchFaceChange: currentWatchName
            ]
        )
    }
    
    /// 收到找手机
    @objc private func reciveDeviceReportData(_ notification: Notification) {
        
        guard let info = notification.userInfo as? [String: Any],
              let currentDevice = YCProduct.shared.currentPeripheral else {
            return
        }
        
        // 找手机
        if  currentDevice.supportItems.isSupportFindPhone,
            let response = info[YCDeviceControlType.findPhone.toString] as?
                YCReceivedDeviceReportInfo,
            let device = response.device,
            currentDevice.identifier.uuidString == device.identifier.uuidString,
            let state = response.data as? YCDeviceControlState {
            
            //
            eventSink?([NativeEventType.deviceControlPhotoStateChange: state.rawValue])
        }
        
        // 拍照
        else if (currentDevice.supportItems.isSupportManualPhotographing ||
                 currentDevice.supportItems.isSupportShakePhotographing),
                let response = info[YCDeviceControlType.photo.toString] as?
                    YCReceivedDeviceReportInfo,
                let device = response.device,
                currentDevice.identifier.uuidString == device.identifier.uuidString,
                let state = response.data as? YCDeviceControlPhotoState {
            
            // 设备拍照状态
            eventSink?([NativeEventType.deviceControlPhotoStateChange: state.rawValue])
            
        }
        
        // 一键测量
        else if let result =
                    ((info[YCDeviceControlType.healthDataMeasurementResult.toString]) as?
                     YCReceivedDeviceReportInfo)?.data as?
                    YCDeviceControlMeasureHealthDataResultInfo {
            
            // 测量状态
            let state = result.state.rawValue
            
            // 测量类型
            let healthDataType = result.dataType.rawValue
            
            eventSink?(
                [
                    NativeEventType.deviceHealthDataMeasureStateChange: [
                        "state": state,
                        "healthDataType": healthDataType
                    ]
                ]
            )
            
        }
        
        // 运动状态
        else if let info = notification.userInfo as? [String: Any],
                let response = info[YCDeviceControlType.sportModeControl.toString] as?
                    YCReceivedDeviceReportInfo,
                let result = response.data as? YCDeviceControlSportModeControlInfo {
            
            // 运动状态
            let state = result.state.rawValue
            
            // 运动类型
            let sportType = result.sportType.rawValue
            
            eventSink?(
                [
                    NativeEventType.deviceSportStateChange: [
                        "state": state,
                        "sportType": sportType
                    ],
                ]
            )
        }
        
        // 表盘切换
        else if let info = notification.userInfo as? [String: Any],
                 let dialID = ((info[YCDeviceControlType.switchWatchFace.toString]) as?
                               YCReceivedDeviceReportInfo)?.data as? UInt32 {
            
            // 表盘切换
            eventSink?([
                NativeEventType.deviceWatchFaceChange: dialID]
            )
            
        }
        
        // ecg测量结束
        else if let info = notification.userInfo as? [String: Any],
                    let _ = info[YCDeviceControlType.stopRealTimeECGMeasurement.toString] as?
                        YCReceivedDeviceReportInfo  {
            // 表盘切换
            eventSink?([
                NativeEventType.deviceEndECG: 0]
            )
        }
        
    }
    
    
    /// App控制拍照
    public func appControlTakePhoto(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let isEnable = arguments as? Bool else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.takephotoByPhone(isEnable: isEnable) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 控制运动
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func appControlSport(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let stateValue = list.first,
              let state = YCDeviceSportState(rawValue: UInt8(stateValue)),
              let sportTypeValue = list.last,
              let sportType = YCDeviceSportType(rawValue: UInt8(sportTypeValue))
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        
        YCProduct.controlSport(state: state, sportType: sportType) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 控制App测量
    /// - Parameters:
    ///   - call.arguments: <#call.arguments description#>
    ///   - result: <#result description#>
    public func appControlMeasureHealthData(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Int],
              let measureTypeValue = list.first,
              let measureType = YCAppControlHealthDataMeasureType(rawValue: UInt8(measureTypeValue)),
              let dataTypeValue = list.last,
              let dataType = YCAppControlMeasureHealthDataType(rawValue: UInt8(dataTypeValue))
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.controlMeasureHealthData(
            measureType: measureType,
            dataType: dataType
        ) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
            
        }
    }
    
    
    /// 实时数据上传
    public func realTimeDataUpload(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let list = arguments as? [Any],
              let isEnable = list.first as? Bool,
              let dataTypeValue = list.last as? Int,
              let dataType = YCRealTimeDataType(rawValue: UInt8(truncatingIfNeeded: dataTypeValue))
              
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.realTimeDataUplod(isEnable: isEnable, dataType: dataType) { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
}
