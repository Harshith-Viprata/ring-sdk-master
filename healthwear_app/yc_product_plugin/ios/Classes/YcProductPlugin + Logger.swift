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
    
    
    /// 获取log日志文件
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func getLogFilePath(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {

        //获取日志文件
        let filePath = YCProductLogManager.shared.logFilePath
        result(["code": PluginState.succeed, "data": filePath])
    }

    /// 获取杰理设备log日志文件
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func getJLDeviceLogFilePath(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {

        YCProduct.shared.jlAssist.mCmdManager.mDeviceLogs.deviceLogDownload { [weak self] logType, progress, savePath in
            /**
             LogTypeDownloading = 0x00,
             LogTypeFailed = 0x01,
             LogTypeSucceed = 0x02,
             LogTypeNoLog = 0x03
             */
            if logType.rawValue == 0x02 ||
                logType.rawValue == 0x03 {
                if(progress == 1){
                    guard let filePath = savePath else{
                        result(["code": PluginState.failed, "data": ""])
                        return;
                    }
                    result(["code": PluginState.succeed, "data": filePath])
                }
            }else{
                result(["code": PluginState.failed, "data": ""])
            }
                
        }
    }
      
    
    /// 获取设备log日志文件
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func getDeviceLogFilePath(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        

        //获取设备日志文件
        YCProduct.queryDeviceLog {state,response in
            guard state == YCProductState.succeed,let data = response as? String else {
                print("日志:\(response)")
                result(["code": PluginState.failed, "data": ""])
                return
            }
            result(["code": PluginState.succeed, "data": data])
        }
    }


        /// 清除log日志文件
        /// - Parameters:
        ///   - arguments: <#arguments description#>
        ///   - result: <#result description#>
        public func clearSDKLog(
            _ arguments: Any?,
            result: @escaping FlutterResult
        ) {
            YCProductLogManager.clear();
            result(["code": PluginState.succeed, "data": ""])
        }
   
}
