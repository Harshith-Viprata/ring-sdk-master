//
//  YcProductPlugin + HealthData.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/6.
//

import Flutter
import UIKit
import YCProductSDK
import JL_BLEKit
import JLDialUnit
import RTKLEFoundation
import RTKOTASDK
import iOSDFULibrary


// MARK: - 健康数据
extension YcProductPlugin {
    
    /// 删除健康数据
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func deleteDeviceHealthData(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        
        guard let dataType = arguments as? Int else {
            result(["code": PluginState.unavailable, "data": ""])
            return
        }
        
        switch dataType {
        case HealthDataType.step:
            
            YCProduct.deleteHealthData(dataType: .step) { state, response in
                
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
            
        case HealthDataType.sleep:
            YCProduct.deleteHealthData(dataType: .sleep) { state, response in
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
            
        case HealthDataType.heartRate:
            YCProduct.deleteHealthData(dataType: .heartRate) { state, response in
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
            
        case HealthDataType.bloodPressure:
            YCProduct.deleteHealthData(dataType: .bloodPressure) { state, response in
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
            
        case HealthDataType.combinedData:
            YCProduct.deleteHealthData(dataType: .combinedData) { state, response in
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
            
        case HealthDataType.invasiveComprehensiveData:
            YCProduct.deleteHealthData(dataType: .invasiveComprehensiveData) { state, response in
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
            
        case HealthDataType.sportHistoryData:
            YCProduct.deleteHealthData(dataType: .sportModeHistoryData) { state, response in
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
        case HealthDataType.bodyIndexData:
            YCProduct.deleteHealthData(dataType: .bodyIndexData) { state, response in
                result(["code": self.convertFlutterState(state),
                        "data": ""]
                )
            }
       case HealthDataType.historyWearData:
           YCProduct.deleteHealthData(dataType: .historyWearData) { state, response in
               result(["code": self.convertFlutterState(state),
                       "data": ""]
                      )
           }
        default:
            result(["code": PluginState.unavailable,
                    "data": ""]
            )
        }
        
    }
    
    
    /// 查询健康数据类型
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceHealthData(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let dataType = arguments as? Int else {
            result(["code": PluginState.unavailable, "data": [[:]]])
            return
        }
        
        var datas = [[String: Any]]()
        
        switch dataType {
        case HealthDataType.step:
            YCProduct.queryHealthData(dataType: .step) { state, response in
                
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataStep] {
                    
                    for item in items {
                        datas.append(
                            [
                                "startTimeStamp": item.startTimeStamp,
                                "endTimeStamp": item.endTimeStamp,
                                "step": item.step,
                                "distance": item.distance,
                                "calories": item.calories,
                            ]
                        )
                    }
                }
                
                result(["code": code, "data": datas])
            }
             
            
        case HealthDataType.sleep:
            YCProduct.queryHealthData(dataType: .sleep) { state, response in
                
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataSleep] {
                    
                    for item in items {
                        
                        // 详细数据
                        var detailInfo = [[String: Any]]()
                        for detailItem in item.sleepDetailDatas {
                             
                            detailInfo.append(
                                [
                                    "startTimeStamp": detailItem.startTimeStamp,
                                    "sleepType": detailItem.sleepType.rawValue,
                                    "duration": detailItem.duration
                                ]
                            )
                        }
                        
                        let isNewSleep = item.deepSleepCount == 0xFFFF
                        let deepSleepSeconds =
                            isNewSleep ? item.deepSleepSeconds :
                            item.deepSleepMinutes * 60
                        
                        let lightSleepSeconds =
                            isNewSleep ? item.lightSleepSeconds :
                            item.lightSleepMinutes * 60
                        
                        let remSleepSeconds =
                            isNewSleep ? item.remSleepSeconds :
                            item.remSleepMinutes * 60
                        
                        datas.append(
                            [
                                "startTimeStamp": item.startTimeStamp,
                                "endTimeStamp": item.endTimeStamp,
                                "isNewSleepProtocol": isNewSleep,
                                "deepSleepSeconds": deepSleepSeconds,
                                "lightSleepSeconds": lightSleepSeconds,
                                "remSleepSeconds": remSleepSeconds,
                                "detail": detailInfo
                            ]
                        )
                        
                    }
                }
                
                result(["code": code, "data": datas])
            }
            
        case HealthDataType.heartRate:
            YCProduct.queryHealthData(dataType: .heartRate) { state, response in
                
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataHeartRate] {
                    
                    for item in items {
                        datas.append(
                            [
                                "startTimeStamp": item.startTimeStamp,
                                "heartRate": item.heartRate
                            ]
                        )
                    }
                }
                
                result(["code": code, "data": datas])
            }
            
        case HealthDataType.bloodPressure:
            YCProduct.queryHealthData(dataType: .bloodPressure) { state, response in
                
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataBloodPressure] {
                    
                    for item in items {
                        datas.append(
                            [
                                "startTimeStamp": item.startTimeStamp,
                                "systolicBloodPressure": item.systolicBloodPressure,
                                "diastolicBloodPressure": item.diastolicBloodPressure,
                                "mode": item.mode.rawValue
                            ]
                        )
                    }
                }
                
                result(["code": code, "data": datas])
            }
            
        case HealthDataType.combinedData:
            YCProduct.queryHealthData(dataType: .combinedData) { state, response in
                
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataCombinedData] {
                    
                    for item in items {
                        datas.append(
                            [
                                "startTimeStamp": item.startTimeStamp,
                                "step": item.step,
                                "heartRate": item.heartRate,
                                "systolicBloodPressure": item.systolicBloodPressure,
                                "diastolicBloodPressure": item.diastolicBloodPressure,
                                "bloodOxygen": item.bloodOxygen,
                                "respirationRate": item.respirationRate,
                                "hrv": item.hrv,
                                "cvrr": item.cvrr,
                                "bloodGlucose": "\(item.bloodGlucose)",
                                "fat": "\(item.fat)",
                                "temperature": "\(item.temperature)"
                            ]
                        )
                    }
                }
                
                result(["code": code, "data": datas])
            }
            
        case HealthDataType.invasiveComprehensiveData:
            YCProduct.queryHealthData(dataType: .invasiveComprehensiveData) { state, response in
                
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataInvasiveComprehensiveData] {
                    
                    for item in items {
                        
                        datas.append([
                            "startTimeStamp": item.startTimeStamp,
                            
                            "bloodGlucoseMode": item.bloodGlucoseMode.rawValue,
                            "bloodGlucose": "\(item.bloodGlucose)",
                            
                            "uricAcidMode": item.uricAcidMode.rawValue,
                            "uricAcid": item.uricAcid,
                            
                            "bloodKetoneMode": item.bloodGlucoseMode.rawValue,
                            "bloodKetone": "\(item.bloodKetone)",
                            
                            "bloodFatMode": item.bloodFatMode.rawValue,
                            "totalCholesterol": "\(item.totalCholesterol)",
                            "hdlCholesterol": "\(item.hdlCholesterol)",
                            "ldlCholesterol": "\(item.ldlCholesterol)",
                            "triglycerides": "\(item.triglycerides)",
                            
                        ])
                    }
                }
                
                result(["code": code, "data": datas])
            }
            
        case HealthDataType.sportHistoryData:
            YCProduct.queryHealthData(dataType: .sportModeHistoryData) { state, response in
             
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataSportModeHistory] {
                    
                    for item in items {
                        datas.append(
                            [
                                "startTimeStamp": item.startTimeStamp,
                                "endTimeStamp": item.endTimeStamp,
                                
                                "flag": item.flag.rawValue,
                                "sportTime": item.sportTime,
                                "sportType": item.sport.rawValue,
                                
                                "step": item.step,
                                "distance": item.distance,
                                "calories": item.calories,
                                
                                "heartRate": item.heartRate,
                                "minimumHeartRate": item.minimumHeartRate,
                                "maximumHeartRate": item.maximumHeartRate
                            ]
                        )
                    }
                }
                
                result(["code": code, "data": datas])
            }
        case HealthDataType.bodyIndexData:
            YCProduct.queryHealthData(dataType: .bodyIndexData) { state, response in
                debugPrint(" === 加载状态指数数据 state=>\(state) type=>\(HealthDataType.bodyIndexData) response=>\(String(describing: response)) ")
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let items = response as? [YCHealthDataBodyIndexData] {
                    
                    for item in items {
                        datas.append(
                            [
                                "startTimeStamp": item.startTimeStamp,
                                "endTimeStamp": item.startTimeStamp,
                                "loadIndex": item.loadIndex,
                                "hrvIndex": item.hrvIndex,
                                "bodyIndex": item.bodyIndex,
                                "sympatheticActivityIndex": item.sympatheticActivityIndex,
                                "sdnHRV": item.sdnnHRV,
                                "pressureIndex": item.pressureIndex,
                                "vo2max": item.vo2max
                            ]
                        )
                    }
                }
                debugPrint(" === 加载状态指数返回的数据 code=>\(code) datas=>\(datas.count) ")
                result(["code": code, "data": datas])
            }
       case HealthDataType.historyWearData:
            YCProduct.queryHealthData(dataType: .historyWearData) { state, response in
                   let code = self.convertFlutterState(state)
                   var datas = [[String: Any]]()
                   
                   // 检查状态和数据类型是否有效
                   if state == .succeed, let items = response as? [YCReceivedWearingStatusDataInfo] {
                       for item in items {
                           datas.append([
                               "startTimeStamp": "\(item.startTimeStamp)", // 确保字符串格式
                               "YCWearingType": item.wearType.rawValue
                           ])
                       }
                   }
                   
                   debugPrint(" === 加载佩戴状态返回的数据 code=>\(code) datas=>\(datas.count) ")
                   result(["code": code, "data": datas])
               }
        default:
            result(PluginState.unavailable)
        }
        
    }
    
     
    
}
