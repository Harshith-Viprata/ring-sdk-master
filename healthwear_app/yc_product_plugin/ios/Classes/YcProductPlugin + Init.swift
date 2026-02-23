//
//  YcProductPlugin + Init.swift
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

// MARK: - 初始化相关
extension YcProductPlugin {
    
    
    /// 初始化SDK
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func initSDK(_ arguments: Any?, result: @escaping FlutterResult) {
        
        _ = YCProduct.shared
        
        // 获取参数
        if let args = arguments as? [Bool],
           let isReconnectEnable = args.first,
           let isLogEnable = args.last {
            
            YCProduct.shared.isReconnectEnable = isReconnectEnable
            
            if isLogEnable {
                YCProduct.setLogLevel(.normal, saveLevel: .normal)
            } else {
                YCProduct.setLogLevel(.off, saveLevel: .off)
            }
        }
        
        result(nil)
    }
    
    
    /// 设置回连是否有效
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func setReconnectEnabled(_ arguments: Any?, result: @escaping FlutterResult) {
        
        if let isReconnectEnable = arguments as? Bool {
            YCProduct.shared.isReconnectEnable = isReconnectEnable
        }
        
        result(nil)
    }
    
    /// 清除队列
    /// - Parameter result: <#result description#>
    public func clearQueue(result: @escaping FlutterResult) {
        YCProduct.shared.clearQueue()
        result(nil)
    }
      
   
}
