//
//  YcProductPlugin + ECG.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/17.
//

import Flutter
import UIKit
import YCProductSDK

// MARK: - ECG
extension YcProductPlugin {
    
    
    
    /// 开启ECG测量
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func startECGMeasurement(_ arguments: Any?, result: @escaping FlutterResult) {
        
        ecgAlgorithmManager = YCECGManager()
        previousData = 0
        previousPreviousData = 0
        ecgDataCount = 0
        
        ecgAlgorithmManager.setupManagerInfo { [weak self] rr, heartRate in
            
            self?.eventSink?(
                [
                    NativeEventType.deviceRealECGAlgorithmRR: "\(rr)",
                ]
            )
            
        } hrv: { [weak self] hrv in
            
            self?.eventSink?(
                [
                    NativeEventType.deviceRealECGAlgorithmHRV: hrv,
                ]
            )
        } 
        
        YCProduct.startECGMeasurement { state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    
    /// 结束ECG测量
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func stopECGMeasurement(_ arguments: Any?, result: @escaping FlutterResult) {
        
        YCProduct.stopECGMeasurement{ state, response in
            
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
    }
    
    /// 获取ECG的结果
    public func getECGResult(_ arguments: Any?, result: @escaping FlutterResult) {
        
        ecgAlgorithmManager.getECGMeasurementResult(deviceHeartRate: 0, deviceHRV: 0) { ecgResult in
            
            var info = [String: Any]()
            
            // 心率
            let hearRate = ecgResult.hearRate
            let hrv = ecgResult.hrv
            let qrsType = ecgResult.qrsType
            let afflag = ecgResult.afflag
            
            info["hearRate"] = hearRate
//            info["hrv"] = hrv
            info["qrsType"] = qrsType
            info["afflag"] = afflag
            
            let bodyInfo =
            self.ecgAlgorithmManager.getPhysicalIndexParameters()
            
            if bodyInfo.isAvailable, qrsType != 14 {
                
                let heavyLoad = bodyInfo.heavyLoad
                let pressure = bodyInfo.pressure
                let body = bodyInfo.body
                let hrvNorm = bodyInfo.hrvNorm
                let sympatheticActivityIndex = bodyInfo.sympatheticActivityIndex
                
                let respiratoryRate = bodyInfo.respiratoryRate
                
                info["heavyLoad"] = String(format: "%.1f", heavyLoad)
                info["pressure"] = String(format: "%.1f", pressure)
                info["body"] = String(format: "%.1f", body)
                info["hrvNorm"] = String(format: "%.1f", hrvNorm)
                info["sympatheticActivityIndex"] = String(format: "%.1f", sympatheticActivityIndex)
                info["respiratoryRate"] = respiratoryRate
            }
            
            result(["code": PluginState.succeed,
                    "data": info]
            )
            
            
        }
    }
}
