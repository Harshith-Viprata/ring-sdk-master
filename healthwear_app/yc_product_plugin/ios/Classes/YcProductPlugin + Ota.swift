//
//  YcProductPlugin + Ota.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/20.
//

import UIKit
import Flutter
import YCProductSDK
import iOSDFULibrary
import RTKOTASDK
import JLDialUnit
import JL_BLEKit
import ZIPFoundation

/**
 OTA的几个信息
    1. 状态变化： 准备、升级中、升级完成、结束、出错
                        进度条，出错信息
    2. 杰理不同点
        
 
 */

/// 升级文件
private var upgradeFilePath: String = ""

// MARK: - NRF

/// NRF升级控制
private var dfuController: DFUServiceController?

// MARK: - RTK

/// RTK的升级管理器
private var rtkDFUUpgrade: RTKDFUUpgrade?

/// RTL升级的固件镜像
private var rtkImages: [RTKOTAUpgradeBin]?


// MARK: - JL

/// 重复扫描次数
private let REPEAT_SCAN_JL_FORCE_OTA_COUNT = 5

/// 重复扫描次数
private var repeatScanJLCount: Int = 0

/// 回连地址
private var reconnectJLMacAddress: String = ""

/// 设备列表
private var jlForceOtaDevices = [CBPeripheral]()

 


// MARK: - OTA
extension YcProductPlugin {
    
    public func deviceUpgrade(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        // 获取参数
        guard let list = arguments as? [Any],
        let mcuValue = list.first as? Int,
        let mcu = YCDeviceMCUType(rawValue: UInt8(mcuValue)),
        let filePath: String = list.last as? String,
        let device = YCProduct.shared.currentPeripheral
        else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        // 匹配升级固件
        switch mcu {
        case .rtk8762c, .rtk8762d:
            
            startRTKFirmwareUpgrade(
                filePath,
                device: device
            )
            
            result(nil)
            
        case .nrf52832:
            startNRFFirmwareUpgrade(filePath, device: device)
            result(nil)
            
        case .jl632n, .jl701n:
            startJLFirmwareUpgrade(filePath, device: device)
            result(nil)
            
        default:
            result(nil)
        }
        
    }
    
}

// MARK: - 杰理OTA
extension YcProductPlugin {
    
    /// 固件升级
    /// - Parameters:
    ///   - filePath: 文件
    ///   - device: 设备
    func startJLFirmwareUpgrade(_ filePath: String,
                                device: CBPeripheral) {
        
        
        upgradeFilePath = filePath
        reconnectJLMacAddress = device.macAddress
        
        jlDeviceOTA(device, filePath: filePath)
        
//        if YCProduct.isJLDeviceForceOTA() ||
//            device.mcu == .jl632n ||
//            device.basicInfo.deviceType == .bodyTemperatureSticker ||
//            device.basicInfo.deviceType == .ecgStickers {
//            jlDeviceOTA(device, filePath: filePath)
//            return
//        }
//
//        // 普通杰理手表
//        YCProduct.openJLDialFileSystem { [weak self] isSuccess in
//
//            self?.jlDeviceOTA(device, filePath: filePath)
//        }
        
    }
    
    /// 杰理OTA
    /// - Parameters:
    ///   - device: <#device description#>
    ///   - filePath: <#filePath description#>
    private func jlDeviceOTA(
        _ device: CBPeripheral,
        filePath: String
    ) {
        
        YCProduct.jlDeviceUpgradeFirmware(device, filePath: filePath) { [weak self] state, progress, didSend in
            
            switch state {
                
            case .start:
                let info = [
                    "code": DeviceUpdateState.start.rawValue,
                    "progress": "0.0",
                    "error": "",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: info
                )
                
            case .success:
                let info = [
                    "code": DeviceUpdateState.succeed.rawValue,
                    "progress": "1.0",
                    "error": "",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: info
                )
                
            case .failed:
                let info = [
                    "code": DeviceUpdateState.failed.rawValue,
                    "progress": "0.0",
                    "error": "failed",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: info
                )
                
            case .uiUpdating:
                let info = [
                    "code": DeviceUpdateState.upgradingResources.rawValue,
                    "progress": String(format: "%.2f", progress),
                    "error": "",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: info
                )
                
            case .upgrading:
                let info = [
                    "code": DeviceUpdateState.upgradingFirmware.rawValue,
                    "progress": String(format: "%.2f", progress),
                    "error": "",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: info
                )
                
            case .updateUIFinished:
                
                let info = [
                    "code": DeviceUpdateState.upgradeResourcesFinished.rawValue,
                    "progress": String(format: "%.2f", progress),
                    "error": "",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: info
                )
                
                self?.reconnectJLDeviceWithMacAddr()
                
            default:
                break
            }
        }
    }
    
    /// 时间到了
    @objc private func scanJLForceOtaDevice() {
        
        repeatScanJLCount += 1
        
        if repeatScanJLCount >= REPEAT_SCAN_JL_FORCE_OTA_COUNT {
            
            YCProductLogManager.write(
                message: "回连次数达到限制，回连失败。"
            )
             
            let info = [
                "code": DeviceUpdateState.failed.rawValue,
                "progress": "0.0",
                "error": "reconnected failed",
            ] as [String : Any]
            
            YcProductPlugin.methodChannel?.invokeMethod(
                "upgradeState",
                arguments: info
            )
            
            return
        }
        
        YCProductLogManager.write(
            message: "重新搜索需要回连的设备: \(repeatScanJLCount)"
        )
        
        
        // 搜索设备
        jlForceOtaDevices.removeAll() // 清除设备
        YCProduct.scanningDevice(delayTime: 3.0 ) { devices, error in
            
            for device in devices where jlForceOtaDevices.contains(device) == false  {
                jlForceOtaDevices.append(device)
//                if device.name?.hasPrefix("ET310") ?? false {
//                    print("++== \(device.name ?? "" )")
//                }
            }
        }
        
        // 搜索结束 准备连接
        perform(
            #selector(connectJLForceOtaDevice),
            with: nil,
            afterDelay: 3.5
        )
    }
    
    /// OTA回连设备
    @objc func reconnectJLDeviceWithMacAddr() {
        
        // 需要等设备重启
        usleep(2500_000)
        
        repeatScanJLCount = 0
        
        YCProductLogManager.write(message: "获取到设备状态，准备回连。\(repeatScanJLCount)")
        
        scanJLForceOtaDevice()
    }
    
    /// 重新设备
    @objc private func connectJLForceOtaDevice() {
        
        YCProductLogManager.write(message: "JLOTA搜索结束，开始查找二次升级设备。")
 
        // 查找设备
        for device in jlForceOtaDevices {
            
            if device.macAddress.uppercased() == reconnectJLMacAddress.uppercased() {
                
                YCProductLogManager.write(
                    message: "找到设备 开始回连: \(device.name ?? "")"
                )
                
                YCProduct.connectDevice(device) { [weak self] state, error in
                    
                    if state == .connected {
                        
                        YCProductLogManager.write(
                            message: "回连成功 进行固件升级: \(device.name ?? "" )"
                        )
                         
                        
                        self?.startJLFirmwareUpgrade(
                            upgradeFilePath,
                            device: device
                        )
                        
                    } else {
                        
                        YCProductLogManager.write(
                            message: "JL OTA 回连失败: \(device.name ?? ""), \(repeatScanJLCount)"
                        )
                        
                        self?.scanJLForceOtaDevice()
                         
                    }
                }
                
                return
            }
        }
        
        // 没有找到
        YCProductLogManager.write(
            message: "没有搜索到任何设备: \(repeatScanJLCount)"
        )
        
        scanJLForceOtaDevice()
    }
}

// MARK: - RTK 升级
extension YcProductPlugin: RTKDFUUpgradeDelegate {
    
    
    /// 升级RTK
    func startRTKFirmwareUpgrade(_ filePath: String, device: CBPeripheral) {
         
        // 初始化
        #if DEBUG
        RTKLog.setLogLevel(.warning)
        #else
        RTKLog.setLogLevel(.off)
        #endif
        
        rtkDFUUpgrade = RTKDFUUpgrade(peripheral: device)
        rtkDFUUpgrade?.delegate = self
        
        // 严格检查版本
        rtkDFUUpgrade?.usingStrictImageCheckMechanism = true
        
        // 电量检查
        rtkDFUUpgrade?.batteryLevelLimit = RTKDFUBatteryLevel.zero

        
        // 加载文件
        guard let zipFile = try? RTKOTAUpgradeBin.imagesExtracted(fromMPPackFilePath: filePath),
           zipFile.count == 1,
              zipFile.last?.icDetermined == false else {
        
            debugPrint(" === 提示 OA 无法升级 加载文件失败 ")
            
            let info = [
                "code": DeviceUpdateState.failed.rawValue,
                "progress": "0.0",
                "error": "load file failed",
            ] as [String : Any]
            
            YcProductPlugin.methodChannel?.invokeMethod(
                "upgradeState",
                arguments: info
            )
            
            return
        }
        
        rtkImages = zipFile
        
        // 开始升级
        // 我们采用静默升级，无需设置
//        (rtkDFUUpgrade as? RTKDFUUpgradeGATT)?.prefersUpgradeUsingOTAMode = false
        rtkDFUUpgrade?.prepareForUpgrade()
        
    }
    
    
    /// 无法升级(准备升级)
    /// - Parameters:
    ///   - task: <#task description#>
    ///   - error: <#error description#>
    public func dfuUpgrade(_ task: RTKDFUUpgrade, couldNotUpgradeWithError error: Error) {
        
        debugPrint(" === 提示 OA 无法升级 couldNotUpgradeWithError ")
        
        let info = [
            "code": DeviceUpdateState.failed.rawValue,
            "progress": "0.0",
            "error": error.localizedDescription,
        ] as [String : Any]
        
        YcProductPlugin.methodChannel?.invokeMethod(
            "upgradeState",
            arguments: info
        )
    }
    
    /// 准备升级
    public func dfuUpgradeDidReady(for task: RTKDFUUpgrade) {
        
        guard let deviceInfo = task.deviceInfo,
           let upgradeBins = rtkImages else {
             
            debugPrint(" === 提示 OA 升级失败 dfuUpgradeDidReady")
            
            let info = [
                "code": DeviceUpdateState.failed.rawValue,
                "progress": "0.0",
                "error": "dfuUpgradeDidReady failed",
            ] as [String : Any]
            
            YcProductPlugin.methodChannel?.invokeMethod(
                "upgradeState",
                arguments: info
            )
            
            return
        }
        
        upgradeBins.last?.assertAvailable(forPeripheralInfo: deviceInfo)
        rtkDFUUpgrade?.upgrade(withImages: upgradeBins)
        
        // 准备升级
        debugPrint("=== 提示用户准备升级 dfuUpgradeDidReady ")
        
        let info = [
            "code": DeviceUpdateState.start.rawValue,
            "progress": "0.0",
            "error": "",
        ] as [String : Any]
        
        YcProductPlugin.methodChannel?.invokeMethod(
            "upgradeState",
            arguments: info
        )
    }
    
    /// 正在升级
    public func dfuUpgrade(_ task: RTKDFUUpgrade, withDevice connection: RTKProfileConnection, didSendBytesCount length: UInt, ofImage image: RTKOTAUpgradeBin) {
        
        let progress = task.progress.fractionCompleted
        
//        debugPrint("=== 正在升级中 didSendBytesCount \(progress)")
        
        let info = [
            "code": DeviceUpdateState.upgradingFirmware.rawValue,
            "progress": String(format: "%.2f", progress),
            "error": "",
        ] as [String : Any]
        
        YcProductPlugin.methodChannel?.invokeMethod(
            "upgradeState",
            arguments: info
        )
        
    }
    
    /// 升级完成
    public func dfuUpgrade(_ task: RTKDFUUpgrade, withDevice connection: RTKProfileConnection, didCompleteSendImage image: RTKOTAUpgradeBin) {
        
//        debugPrint("=== 升级完成 \(task.progress.fractionCompleted)")
         
    }
    
    /// 升级结束
    public func dfuUpgrade(_ task: RTKDFUUpgrade, didFinishUpgradeWithError error: Error?
    ) {
     
        if error == nil {
//            debugPrint(" === 提示 OA 升级成功 didFinishUpgradeWithError === ")
            
            let info = [
                "code": DeviceUpdateState.succeed.rawValue,
                "progress": "1.0",
                "error": "",
            ] as [String : Any]
            
            YcProductPlugin.methodChannel?.invokeMethod(
                "upgradeState",
                arguments: info
            )
            
            return
        }
        
//        debugPrint(" === 提示 OA 升级失败 didFinishUpgradeWithError ")
        
        let info = [
            "code": DeviceUpdateState.failed.rawValue,
            "progress": "0.0",
            "error": error?.localizedDescription ?? "",
        ] as [String : Any]
        
        YcProductPlugin.methodChannel?.invokeMethod(
            "upgradeState",
            arguments: info
        )
    }
    
    
}

// MARK: - NRF 升级
extension YcProductPlugin: DFUServiceDelegate, DFUProgressDelegate {
    
    /// 固件升级
    /// - Parameters:
    ///   - filePath: 文件
    ///   - device: 设备
    func startNRFFirmwareUpgrade(
        _ filePath: String,
        device: CBPeripheral
    ) {
        
        let url = URL(fileURLWithPath: filePath)
        
        guard let dfuFirmware = try? DFUFirmware(urlToZipFile: url) else {
    
            debugPrint(" === 提示 OA 无法升级 加载文件失败 ")
            
            let info = [
                "code": DeviceUpdateState.failed.rawValue,
                "progress": "0.0",
                "error": "load file failed",
            ] as [String : Any]
            
            YcProductPlugin.methodChannel?.invokeMethod(
                "upgradeState",
                arguments: info
            )
            
            return
        }
        
        let initiator =
            DFUServiceInitiator(queue: DispatchQueue.main,
                                delegateQueue: DispatchQueue.main,
                                progressQueue: DispatchQueue.main,
                                loggerQueue: DispatchQueue.main
            )
        
        initiator.delegate = self
        initiator.progressDelegate = self
        
        initiator.forceDfu = false
        initiator.alternativeAdvertisingNameEnabled = false
        initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        
        _ = initiator.with(firmware: dfuFirmware)
        dfuController = initiator.start(target: device)
    }
    
    // 状态变化
    public func dfuStateDidChange(to state: DFUState) {
        
//        debugPrint(" === OTA状态变化 : \(state.rawValue) ")
        
        switch state {
        
        case .disconnecting:
            break
            
        case .connecting:
            break
            
        case .starting:
            break
            
        case .enablingDfuMode:
            break
        
        case .uploading: // DFU
            let info = [
                "code": DeviceUpdateState.start.rawValue,
                "progress": "0.0",
                "error": "",
            ] as [String : Any]
            
            YcProductPlugin.methodChannel?.invokeMethod(
                "upgradeState",
                arguments: info
            )
            
        case .validating:
            break
            
        case .completed:
            
            let info = [
                "code": DeviceUpdateState.succeed.rawValue,
                "progress": "1.0",
                "error": "",
            ] as [String : Any]
            
            YcProductPlugin.methodChannel?.invokeMethod(
                "upgradeState",
                arguments: info
            )
            
        case .aborted:
            break
        }
        
    }
    
    // 升级出错
    public func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        
//        debugPrint(" === 升级出错 didOccurWithMessage ")
        let info = [
            "code": DeviceUpdateState.failed.rawValue,
            "progress": "0.0",
            "error": "error code: \(error.rawValue)",
        ] as [String : Any]
        
        YcProductPlugin.methodChannel?.invokeMethod(
            "upgradeState",
            arguments: info
        )
    }
    
    // 升级进度
    public func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        
//        debugPrint(" === 升级进度 \(Float(progress) * 0.01)  ")
        
        let upgradeProgress = Float(progress) * 0.01
        
        let info = [
            "code": DeviceUpdateState.upgradingFirmware.rawValue,
            "progress": String(format: "%.2f", upgradeProgress),
            "error": "",
        ] as [String : Any]
        
        YcProductPlugin.methodChannel?.invokeMethod(
            "upgradeState",
            arguments: info
        )
        
    }
}
