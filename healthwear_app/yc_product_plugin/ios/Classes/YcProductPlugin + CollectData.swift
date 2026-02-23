//
//  YcProductPlugin + CollectData.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/23.
//

import UIKit
import Flutter
import YCProductSDK

// MARK: - 数据
extension YcProductPlugin {
    
    
    /// 查询基本信息
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryCollectDataBasicInfo(_ arguments: Any?, result: @escaping FlutterResult) {
        
        guard let typeValue = arguments as? Int,
              let dataType = YCCollectDataType(rawValue: UInt8(typeValue))
        else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        YCProduct.queryCollectDataBasicinfo(dataType: dataType) { state, response in
            
            guard state == .succeed,
                  let list = response as? [YCCollectDataBasicInfo] else {

                result(["code": PluginState.failed,
                        "data": ""]
                )

                return
            }
            
            var datas = [[String: Any]]()
            
            for info in list {
                 
                datas.append([
                    
                    "dataType": info.dataType.rawValue,
                    "index": info.index,
                    "timeStamp": info.timeStamp,
                    "totalBytes": info.totalBytes,
                    "packages": info.packages,
//                    "sampleRate": info.sampleRate,
//                    "samplesCount": info.samplesCount,
                ])
            }
            
            result(["code": PluginState.succeed,
                    "data": datas]
            )
            
        }
         
    }
     
    
    
    /// 查询数据
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryCollectDataInfo(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [Int],
              let typeValue = list.first,
              let dataType = YCCollectDataType(rawValue: UInt8(typeValue)),
              let index = list.last
        else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        YCProduct.queryCollectDataInfo(
            dataType: dataType,
            index: UInt16(index),
            uploadEnable: true
        ) { state, response in
            
            guard state == .succeed,
                  let info = response as? YCCollectDataInfo else {
                
                result(["code": PluginState.failed,
                        "data": ""]
                )
                
                return
            }
            
            
        }
        
    }
    
    /// 删除数据
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func deleteCollectData(
        _ arguments: Any?, result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [Int],
              let typeValue = list.first,
              let dataType = YCCollectDataType(rawValue: UInt8(typeValue)),
              let index = list.last
        else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        YCProduct.deleteCollectData(dataType: dataType, index: UInt16(index)
        ) { state, response in
            result(["code": self.convertFlutterState(state),
                    "data": ""]
            )
        }
        
        
    }
    
    
}
