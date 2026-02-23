//
//  YcProductPlugin + Device.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/4.
//

import Flutter
import UIKit
import YCProductSDK
import JL_BLEKit
import JLDialUnit
import RTKLEFoundation
import RTKOTASDK
import iOSDFULibrary

extension YcProductPlugin {
    
    /// 连接设备
    /// - Parameters:
    ///   - arguments: 参数
    ///   - result: 连接结果
    public func connectDevice(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let uuidString = arguments as? String,
              let device = YCProduct.getDeviceByUUID(uuidString) else {
            result(false)
            return
        }
        
        YCProduct.connectDevice(device) { state, error in
            result(state == .connected)
        }
    }
    
    /// 断开连接
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func disConnectDevice(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let uuidString = arguments as? String else {
            
            result(false)
            return
        }
        
        let device =
        uuidString.isEmpty ?
        YCProduct.shared.currentPeripheral :
        YCProduct.getDeviceByUUID(uuidString)
        
        YCProduct.disconnectDevice(device) { state, error in
            result(state == .disconnected)
        }
    }
    
    /// 搜索设备
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func scanDevice(_ arguments: Any?, result: @escaping FlutterResult) {
        
        // 搜索时长
        var delayTime: TimeInterval = 3.0
        if let time = arguments as? Int {
            delayTime = TimeInterval(time)
        }
        

        var items = [[String: Any]]()
        YCProduct.scanningDevice(delayTime: delayTime) { devices, error in
            
            items.removeAll()
            devices.forEach { device in
           
                // 逐个转换为字典
                var deviceInfo = [String: Any]()
                deviceInfo["name"] = device.name
                deviceInfo["rssiValue"] = device.rssiValue
                deviceInfo["macAddress"] =  device.macAddress
                deviceInfo["deviceIdentifier"] = device.identifier.uuidString
                
                deviceInfo["firmwareVersion"] = device.firmwareVersion
                deviceInfo["deviceSize"] = device.deviceSize
                deviceInfo["deviceColor"] = device.deviceColor
                deviceInfo["imageIndex"] = device.imageIndex
                
                items.append(deviceInfo)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayTime, execute: {
 
            result(items)
        })
    }
    
 
    
    /// 停止搜索设备
    /// - Parameter result: <#result description#>
    public func stopScanDevice(result: @escaping FlutterResult) {
        YCProduct.stopSearchDevice()
        result(nil)
    }
    
}



// MARK: - 蓝牙监听状态
extension YcProductPlugin {
    
    /// 获取蓝牙的状态
    /// - Parameter result: <#result description#>
    public func getBluetoothState(result: @escaping FlutterResult) {
    
        let state = YCProduct.shared.centralManagerState
        let bleState = setupBlutetoothState(state)
        
        result(bleState)
    }
    
    /// 蓝牙状态
    public func setupDeviceStateObserver() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(bleDeviceStateChange(_:)),
            name: YCProduct.deviceStateNotification,
            object: nil
        )
    }
    
    /// 蓝牙状态
    /// - Parameter notification: <#notification description#>
    @objc private func bleDeviceStateChange(_ notification: Notification) {

        //佩带状态
        //如果包含了[YCProduct.ecgElectrodesStateKey]，则拿出state值
        if let info = notification.userInfo as? [String: Any],
           let ecgState = info[YCProduct.ecgElectrodesStateKey] as? YCDeviceRealState,
           let ppgState = info[YCProduct.photoelectricSensorStateKey] as? YCDeviceRealState {
            
    
            var ecgStatusInfo = [String: Any]()
            ecgStatusInfo["EcgStatus"] = ecgState.rawValue
            ecgStatusInfo["PPGStatus"] = ppgState.rawValue
            
            // 返回携带信息
            eventSink?(
                [
                    NativeEventType.appECGPPGStatus : ecgStatusInfo 
                ]
            )

            return
        } 
          


        
        guard let info = notification.userInfo as? [String: Any],
              let state = info[YCProduct.connecteStateKey] as? YCProductState else {

            return
        }
        
         
        // 适配Flutter BluetoothState
        let bleState = setupBlutetoothState(state)
        
        // 如果已经连接了
        if state == YCProductState.connected,
           let device = YCProduct.shared.currentPeripheral {
            
            // 设备信息
            var deviceInfo = [String: Any]()
            deviceInfo["name"] = device.name
            deviceInfo["rssiValue"] = device.rssiValue
            deviceInfo["macAddress"] =  device.macAddress
            deviceInfo["deviceIdentifier"] = device.identifier.uuidString
            
            // 返回携带信息
            eventSink?(
                [
                    NativeEventType.deviceInfo: deviceInfo,
                    NativeEventType.bluetoothStateChange: bleState
                ]
            )
             
            return
        }
 
        eventSink?([NativeEventType.bluetoothStateChange: bleState])
    }
    
    
    /// 适配状态
    /// - Parameter state: <#state description#>
    /// - Returns: <#description#>
    private func setupBlutetoothState(_ state: YCProductState) -> Int {
        
        var bleState = BluetoothState.off
        
        if state == .unauthorized ||
            state == .unknow ||
            state == .unsupported
        {
          
            bleState = BluetoothState.off
            
        } else if state == .poweredOff {
            
            bleState = BluetoothState.off
            
        } else if state == .poweredOn {
            
            bleState = BluetoothState.on
            
        } else if state == .connected {
            
            bleState = BluetoothState.connected
            
        } else if state == .connectedFailed {
            
            bleState = BluetoothState.connectFailed
            
        } else if state == .disconnected {
            
            bleState = BluetoothState.disconnected
            
        } else {
            
            bleState = BluetoothState.on
        }
        
        return bleState
    }
}
