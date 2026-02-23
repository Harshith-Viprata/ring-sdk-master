//
//  YcProductPlugin + RealData.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/11/17.
//

import Flutter
import UIKit
import YCProductSDK

// MARK: - 设备控制
extension YcProductPlugin {
    
    
    /// 设置设备监听
    public func setupDeviceRealDataObserver() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveRealTimeData(_ :)),
            name: YCProduct.receivedRealTimeNotification,
            object: nil
        )
        
    }
    
    /// 接收到实时数据
    @objc private func receiveRealTimeData( _ notification: Notification
    ) {
        
        guard let info = notification.userInfo as? [String: Any] else {
            return
        }
        
        // 实时心率
        if let response = info[YCReceivedRealTimeDataType.heartRate.toString]
            as? YCReceivedDeviceReportInfo,
           //                       let device = response.device,
           let heartRate = response.data as? UInt8,
           heartRate > 0 {
            
            eventSink?(
                [NativeEventType.deviceRealHeartRate: heartRate]
            )
        }
        
        // 血压
        else if let response =
                    info[YCReceivedRealTimeDataType.bloodPressure.toString] as?
                    YCReceivedDeviceReportInfo,
                //           let device = response.device,
                let bloodPressureInfo = response.data as?
                    YCReceivedRealTimeBloodPressureInfo ,
                bloodPressureInfo.heartRate >= 0,
                bloodPressureInfo.systolicBloodPressure >= 0,
                bloodPressureInfo.diastolicBloodPressure >= 0,
                bloodPressureInfo.systolicBloodPressure >=
                    bloodPressureInfo.diastolicBloodPressure {
            
            var info = [
                "heartRate": bloodPressureInfo.heartRate,
                "systolicBloodPressure": bloodPressureInfo.systolicBloodPressure,
                "diastolicBloodPressure":
                    bloodPressureInfo.diastolicBloodPressure,
            ]
            
            // 有 HRV 就传 HRV
            if bloodPressureInfo.hrv > 0,
               bloodPressureInfo.hrv <= 150 {
                info["hrv"] = bloodPressureInfo.hrv
                eventSink?(
                    [
                        NativeEventType.deviceRealHRV: "\(bloodPressureInfo.hrv)"
                    ]
                )
                return
            }
            
            eventSink?(
                [
                    NativeEventType.deviceRealBloodPressure: info
                ]
            )
        }
        
        
        // 血氧
        else if let response = info[YCReceivedRealTimeDataType.bloodOxygen.toString]
                    as? YCReceivedDeviceReportInfo,
                //                    let device = response.device,
                let bloodOxygen = response.data as? UInt8,
                bloodOxygen > 0 {
            
            eventSink?([NativeEventType.deviceRealBloodOxygen: bloodOxygen])
        }
        
        // 温度
        else if let response = info[YCReceivedRealTimeDataType.comprehensiveData.toString] as? YCReceivedDeviceReportInfo,
                let info = response.data as? YCReceivedComprehensiveDataModeInfo  {
            
            let temperature = "\(info.temperature)"
            
            let bloodGlucose = "\(info.bloodGlucose)"
            if( !bloodGlucose.isEmpty && info.bloodGlucose != 0 && info.bloodGlucose != 0x0F){
                eventSink?([NativeEventType.deviceRealBloodGlucose: bloodGlucose])
                return
            }
            
            guard let temperatureString = String(format: "%.1f", temperature).components(separatedBy: ".").last,
                  let temperatureDecimal = Int(temperatureString),
                  temperatureDecimal != 0x0F else {
                
                return
            }
            
            eventSink?([NativeEventType.deviceRealTemperature: temperature])
        }

        // 压力
        else if let response = info[YCReceivedRealTimeDataType.bodyIndexData.toString] as? YCReceivedDeviceReportInfo,
                let info = response.data as? YCReceivedBodyIndexInfo,
                let pressure: Double? = info.pressureIndex,
                pressure ?? 0>0{
           
                eventSink?([NativeEventType.deviceRealPressure: pressure])
           
        }
        
        // 实时步数
        else if let response = notification.userInfo as? [String: Any],
                let info = response[YCReceivedRealTimeDataType.step.toString] as?
                    YCReceivedDeviceReportInfo,
                //           let device = response.device,
                let sportInfo = info.data as? YCReceivedRealTimeStepInfo {
            
            let distance = sportInfo.distance
            let step = sportInfo.step
            let calories = sportInfo.calories
            
            eventSink?(
                [
                    NativeEventType.deviceRealStep: [
                        "distance": distance,
                        "step": step,
                        "calories": calories
                    ]
                ]
            )
        }
        
        /// 实时运动状态
        else if let response =
                    info[YCReceivedRealTimeDataType.realTimeMonitoringMode.toString] as?
                    YCReceivedDeviceReportInfo,
                //              let device = response.device,
                let data = response.data as? YCReceivedMonitoringModeInfo {
            
            
            let sportTime = data.startTimeStamp
            let sportHearRate = data.heartRate
            let sportStep = Int(data.modeStep)
            let sportCalories = Int(data.modeCalories)
            let sportDistance = Int(data.modeDistance)

            let ppi = Int(data.ppi)
            let vo2max = Int(data.vo2max)

            // if(sportTime == 0 && vo2max != 0){
            //     eventSink?(
            //     [
            //         NativeEventType.deviceRealVo2max: [
            //             "vo2max": vo2max
            //         ]
            //     ]
            // )
            // return
            // }
            
            eventSink?(
                [
                    NativeEventType.deviceRealSport: [
                        "time": sportTime,
                        "heartRate": sportHearRate,
                        "distance": sportDistance,
                        "step": sportStep,
                        "calories": sportCalories,
                        "ppi": ppi,
                        "vo2max": vo2max
                    ]
                ]
            )
        }
        
        // 实时PPG
        else if let response =
                    info[YCReceivedRealTimeDataType.ppg.toString] as?
                    YCReceivedDeviceReportInfo,
                //              let device = response.device,
                let ppgData = response.data as? [Int32] {
            
            //            print("++== ecg的数据: \(ppgData)")
            eventSink?([NativeEventType.deviceRealPPGData: ppgData])
        }
        
        // 实时ECG
        else if let response =
                    info[YCReceivedRealTimeDataType.ecg.toString] as?
                    YCReceivedDeviceReportInfo,
                //              let device = response.device,
                let ecgDatas = response.data as? [Int32] {
            
            // 进行滤波操作
            let mvDatas = parseECGdata(ecgDatas)
            
            eventSink?(
                [
                    NativeEventType.deviceRealECGData: ecgDatas,
                    NativeEventType.deviceRealECGFilteredData: mvDatas
                ]
            )
        }
         // 实时ACC
        else if let response =
                    info[YCReceivedRealTimeDataType.nAxisSensor.toString] as?
                    YCReceivedDeviceReportInfo,
                //              let device = response.device,
                let accDatas = response.data as? [Int32] {
            
            // 进行滤波操作
            let mvDatas = parseRealACCData(accDatas)
            // 0 代表三轴 目前只有三轴情况
            let data: [String: Any] = ["data" : mvDatas,"type" : 0]
            eventSink?(
                [
                    NativeEventType.deviceRealACCData: data,
                    NativeEventType.deviceRealACCFilteredData: data
                ]
            )
        }
        // 多通道PPG
        else if let response =
                    info[YCReceivedRealTimeDataType.multiChannelPPG.toString] as?
                    YCReceivedDeviceReportInfo,
                //              let device = response.device,
                let multiChannelPPGData = response.data as? YCReceivedMultiChannelPPGInfo {
            
            let data: [String: Any] = [
                       "data": multiChannelPPGData.compositeData,
                       "green": multiChannelPPGData.greenData,
                       "ir": multiChannelPPGData.irData,
                       "red": multiChannelPPGData.redData,
                       "sampleType":multiChannelPPGData.compositeType.rawValue
                   ]
            eventSink?([NativeEventType.deviceMultiChannelPPGData: data])
        }
    }
    /// 处理ACC数据
    private func parseRealACCData(_ datas: [Int32]) -> [[String: Float]] {
        var result = [[String: Float]]()
        
        // 按每3个元素一组解析为(x, y, z)
        for i in stride(from: 0, to: datas.count, by: 3) {
            guard i + 2 < datas.count else { break }
            
            let x = Float(datas[i])
            let y = Float(datas[i + 1])
            let z = Float(datas[i + 2])
            
            // 转为字典并添加到结果数组
            result.append(["x": x, "y": y, "z": z])
        }
        return result
//    }
        // 将[Int32]转换为UInt8数组（按字节处理）
//        let byteData = datas.withUnsafeBytes { Data($0) }.map { $0 }
//        
//        // 至少需要包含类型字节
//        guard byteData.count >= 1 else {
//            return .threeAxes([]) // 数据不足时返回空的三轴数据（可根据需求调整）
//        }
//        
//        // 第一个字节：数据类型（00=三轴，01=六轴，02=九轴）
//        let dataType = byteData[0]
//        
//        // 根据数据类型确定每个样本包含的轴数
//        let axesCount: Int
//        switch dataType {
//        case 0x00:
//            axesCount = 3  // 三轴：每个样本3个轴值
//        case 0x01:
//            axesCount = 6  // 六轴：每个样本6个轴值
//        case 0x02:
//            axesCount = 9  // 九轴：每个样本9个轴值
//        default:
//            return .threeAxes([]) // 未知类型返回空数据
//        }
//        
//        // 计算每个样本的总字节数（每个轴2字节）
//        let bytesPerSample = axesCount * 2
//        var offset = 1  // 从第二个字节开始是样本数据
//        var rawValues = [Float]()  // 存储解析出的所有轴值
//        
//        // 循环解析所有完整的样本
//        while offset + bytesPerSample <= byteData.count {
//            // 解析当前样本的所有轴值
//            for _ in 0..<axesCount {
//                // 每个轴值由2字节组成（低字节在前）
//                let lowByte = byteData[offset]
//                let highByte = byteData[offset + 1]
//                
//                // 组合为16位有符号整数
//                let uint16Value = UInt16(highByte) << 8 | UInt16(lowByte)
//                let int16Value = Int16(bitPattern: uint16Value)
//                
//                // 转换为Float并添加到原始值数组
//                rawValues.append(Float(int16Value))
//                
//                // 移动到下一个轴值的起始位置
//                offset += 2
//            }
//        }
//        
//        // 根据轴数分组为对应的元组数组
//        switch axesCount {
//        case 3:
//            var result = [(x: Float, y: Float, z: Float)]()
//            // 每3个值组成一个三轴元组
//            for i in stride(from: 0, to: rawValues.count, by: 3) {
//                guard i + 2 < rawValues.count else { break }
//                result.append((
//                    x: rawValues[i],
//                    y: rawValues[i+1],
//                    z: rawValues[i+2]
//                ))
//            }
//            return .threeAxes(result)
//            
//        case 6:
//            var result = [(x: Float, y: Float, z: Float, a: Float, b: Float, c: Float)]()
//            // 每6个值组成一个六轴元组
//            for i in stride(from: 0, to: rawValues.count, by: 6) {
//                guard i + 5 < rawValues.count else { break }
//                result.append((
//                    x: rawValues[i],
//                    y: rawValues[i+1],
//                    z: rawValues[i+2],
//                    a: rawValues[i+3],
//                    b: rawValues[i+4],
//                    c: rawValues[i+5]
//                ))
//            }
//            return .sixAxes(result)
//            
//        case 9:
//            var result = [(x: Float, y: Float, z: Float, a: Float, b: Float, c: Float, d: Float, e: Float, f: Float)]()
//            // 每9个值组成一个九轴元组
//            for i in stride(from: 0, to: rawValues.count, by: 9) {
//                guard i + 8 < rawValues.count else { break }
//                result.append((
//                    x: rawValues[i],
//                    y: rawValues[i+1],
//                    z: rawValues[i+2],
//                    a: rawValues[i+3],
//                    b: rawValues[i+4],
//                    c: rawValues[i+5],
//                    d: rawValues[i+6],
//                    e: rawValues[i+7],
//                    f: rawValues[i+8]
//                ))
//            }
//            return .nineAxes(result)
//            
//        default:
//            return .threeAxes([])
//        }
        
    }
    
    /// 解析ECG数据
    /// - Parameter datas: <#datas description#>
    private func parseECGdata(_ datas: [Int32]) -> [Float] {
        
        var mvDatas = [Float]()
        for data in datas {
            
            var ecgValue: Float = 0
            ecgValue = ecgAlgorithmManager.processECGData(Int(data))
            
            if (ecgDataCount % 3 == 0) {
                
                let tmpEcgData =
                (ecgValue + previousData + previousPreviousData) / 3.0
                
                // 转换为 mv => / 40 / 1000
                let realValue = tmpEcgData / 40.0 / 1000.0
                
                //                if realValue >= 500 {
                //                    mvDatas.append(500)
                //                } else if realValue <= -500 {
                //                    mvDatas.append(-500)
                //                } else {
                //                    mvDatas.append(realValue)
                //                }
                
                mvDatas.append(realValue)
            }
            
            ecgDataCount += 1
            previousPreviousData = previousData
            previousData = ecgValue
        }
        
        return mvDatas
    }
}
