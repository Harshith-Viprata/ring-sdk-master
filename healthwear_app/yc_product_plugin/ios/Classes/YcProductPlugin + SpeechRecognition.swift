//
//  YcProductPlugin + SpeechRecognition.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/6.
//

import UIKit
import Flutter
import YCProductSDK
import AVFoundation
import Speech
import JL_BLEKit
import JLAudioUnitKit

/**
 语音识别的几个信息
    1. 状态变化： 准备、识别中、识别完成、结束、出错
                        进度条，出错信息
    2. 不同语言支持
*/

/// 语音识别管理器
private var speechRecognizer: SFSpeechRecognizer?
private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
private var recognitionTask: SFSpeechRecognitionTask?
private var audioEngine: AVAudioEngine?

// MARK: - 语音识别
extension YcProductPlugin {
    
    
    /// 设置设备监听
    public func setupJLAudioDataObserver() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reciveJLAudioStateData(_:)),
            name: YCProduct.jlAudioRecordStateDidChangeNotification,
            object: nil
        )
        
        // 杰理手表切换
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveJLAudioCompleteData(_:)),
            name: YCProduct.jlAudioRecordResultDidCompleteNotification,
            object: nil
        )
    }
    
    
    public func startSpeechRecognition(
        result: @escaping FlutterResult
    ) {
        YCProduct.startRecord()
        result(["code": PluginState.succeed,
                "data": ""]
        )
        
    }
    
    public func stopSpeechRecognition(
        result: @escaping FlutterResult
    ) {
        
        YCProduct.stopRecord()
        result(["code": PluginState.succeed,
                "data": ""]
        )
    }
       
    
    @objc private func reciveJLAudioStateData(_ notification: Notification) {
        // 1. 校验必要数据（设备存在 + 通知有userInfo）
        guard let info = notification.userInfo as? [String: Any],
              let currentDevice = YCProduct.shared.currentPeripheral else {
            print("杰理音频状态事件：设备未连接或通知数据为空")
            return
        }
        
        // 2. 从通知中解析录音状态
        let stateString = info["state"] as? String ?? "未知"
        eventSink?([
            NativeEventType.deviceJLAudioState: [
                "state" : stateString
            ],
        ])
    }

    // MARK: - 杰理音频结果完成监听方法
    @objc private func receiveJLAudioCompleteData(_ notification: Notification) {
        // 1. 校验必要数据
        guard let info = notification.userInfo as? [String: Any],
              let currentDevice = YCProduct.shared.currentPeripheral else {
            print("杰理音频结果事件：设备未连接或通知数据为空")
            return
        }
        
        // 2. 解析录音结果的所有字段
        let text = info["text"] as? String ?? "无识别结果"
        let wavFilePath = info["wavFilePath"] as? String ?? "无WAV路径"
        let opusFilePath = info["opusFilePath"] as? String ?? "无OPUS路径"
        let isDeviceInitiated = info["isDeviceInitiated"] as? Bool ?? false
        let error = info["error"] as? String ?? ""
        
        // 3. 构造事件字典（和状态事件格式对齐，便于Flutter统一解析）
        let resultDict: [String: Any] = [
            "text": text,                  // 识别文本
            "wavFilePath": wavFilePath,    // WAV文件路径
            "opusFilePath": opusFilePath,  // OPUS文件路径
            "isDeviceInitiated": isDeviceInitiated, // 是否设备触发
            "error": error,                // 错误信息（空则无错误）
        ]
        
        // 4. 发送结果事件到Flutter
        eventSink?([
            NativeEventType.deviceJLAudioComplete: [
                "resultDict" : resultDict
            ],
        ]
        )
    }
}
