import Flutter
import UIKit
import YCProductSDK
import JL_BLEKit
import JLDialUnit
import RTKLEFoundation
import RTKOTASDK
import iOSDFULibrary



public class YcProductPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    /// ecg算法工具类
    public var ecgAlgorithmManager = YCECGManager()
    
    /// 当前ECG数据的前一个
    public var previousData: Float = 0
    
    /// 当前ECG数据的上一个的上一个
    public var previousPreviousData: Float = 0
    
    /// ECG数量
    public var ecgDataCount: Int = 0
    
    public override init() {
        super.init()
        
      // 只监听一次
      setupDeviceObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
//    static var eventChannel: FlutterEventChannel?
    var eventSink: FlutterEventSink?
    
    public static var methodChannel: FlutterMethodChannel? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = YcProductPlugin()
        
        // methodChannel
        let methodChannel = FlutterMethodChannel(name: "ycaviation.com/yc_product_plugin_method_channel", binaryMessenger: registrar.messenger())
         
        registrar.addMethodCallDelegate(
            instance,
            channel: methodChannel
        )
        
        // eventChannel
        let eventChannel = FlutterEventChannel(
            name: "ycaviation.com/yc_product_plugin_event_channel",
            binaryMessenger: registrar.messenger()
        )
        
        eventChannel.setStreamHandler(instance)
        
        self.methodChannel = methodChannel
    }
    
    // 方法调用
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        matchMethodCall(call, result: result)
    }
    
    // MARK: - 监听
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        eventSink = events
        
//        setupDeviceObserver()
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        
        eventSink = nil
        return nil
    }
}


// MARK: - eventChannel 通道
extension YcProductPlugin {
    
    /// 设置监听
    private func setupDeviceObserver() {
        
        NotificationCenter.default.removeObserver(self)
        
        // 监听蓝牙状态
        setupDeviceStateObserver()
        
        // 监听设备操作状态
        setupDeviceControlObserver()
        
        // 监听实时数据
        setupDeviceRealDataObserver()
        
        // 监听杰理语音识别数据
        setupJLAudioDataObserver()
    }
    
    /// 转换状态码
    /// - Parameter state: <#state description#>
    /// - Returns: <#description#>
    public func convertFlutterState(_ state: YCProductState) -> Int {
         
        if state == .noRecord ||
            state == .succeed {
            
            return PluginState.succeed
            
        } else if state == .unavailable {
            
            return PluginState.unavailable
            
        } else {
            
            return PluginState.failed
        }
        
    }
}

// MARK: - methodChannel 通信
extension YcProductPlugin {
    
    /// 处理不同的方法
    /// - Parameters:
    ///   - call: <#call description#>
    ///   - result: <#result description#>
    private func matchMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
            
            // MARK: - 初始化
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "initPlugin":
            initSDK(call.arguments, result: result)
            
        case "setReconnectEnabled":
            setReconnectEnabled(call.arguments, result: result)
            
        case "clearQueue":
            clearQueue(result: result)
            
        case "getBluetoothState":
            getBluetoothState(result: result)
            
        case "scanDevice":
            scanDevice(call.arguments, result: result)
            
        case "stopScanDevice":
            stopScanDevice(result: result)
            
        case "connectDevice":
            connectDevice(call.arguments, result: result)
            
        case "disconnectDevice":
            disConnectDevice(call.arguments, result: result)
            
        case "getDeviceFeature":
            getDeviceFeature(call.arguments, result: result)
            
            // MARK: - 查询与删除健康历数据
            
        case "queryDeviceHealthData":
            queryDeviceHealthData(call.arguments, result: result)
            
        case "deleteDeviceHealthData":
            deleteDeviceHealthData(call.arguments, result: result)
            
            // MARK: - 查询部分
            
        case "queryDeviceBasicInfo":
            queryDeviceBasicInfo(call.arguments, result: result)
            
        case "queryDeviceMacAddress":
            queryDeviceMacAddress(call.arguments, result: result)
            
        case "queryDeviceModel":
            queryDeviceModel(call.arguments, result: result)
            
        case "queryDeviceMCU":
            queryDeviceMCU(call.arguments, result: result)
            
            // MARK: - 设置部分
        case "setDeviceSyncPhoneTime":
            setDeviceSyncPhoneTime(call.arguments, result: result)
            
        case "setDeviceStepGoal":
            setDeviceStepGoal(call.arguments, result: result)
            
        case "setDeviceSleepGoal":
            setDeviceSleepGoal(call.arguments, result: result)
            
        case "setDeviceUserInfo":
            setDeviceUserInfo(call.arguments, result: result)
            
        case "setDeviceSkinColor":
            setDeviceSkinColor(call.arguments, result: result)
            
        case "setDeviceUnit":
            setDeviceUnit(call.arguments, result: result)
            
        case "setDeviceAntiLost":
            setDeviceAntiLost(call.arguments, result: result)
            
        case "setDeviceNotDisturb":
            setDeviceNotDisturb(call.arguments, result: result)
            
        case "setDeviceLanguage":
            setDeviceLanguage(call.arguments, result: result)
            
        case "setDeviceSedentary":
            setDeviceSedentary(call.arguments, result: result)
            
        case "setDeviceWearingPosition":
            setDeviceWearingPosition(call.arguments, result: result)
            
        case "setPhoneSystemInfo":
            setPhoneSystemInfo(call.arguments, result: result)
            
        case "restoreFactorySettings":
            restoreFactorySettings(call.arguments, result: result)

        case "settingGetAllAlarm":
            settingGetAllAlarm(call.arguments,result:result)

        case "settingAddAlarm":
            settingAddAlarm(call.arguments,result:result)

        case "settingModfiyAlarm":
            settingModfiyAlarm(call.arguments,result:result)        

            
        case "setDeviceWristBrightScreen":
            setDeviceWristBrightScreen(call.arguments, result: result)
            
        case "setDeviceDisplayBrightness":
            setDeviceDisplayBrightness(call.arguments, result: result)
            
        case "setDeviceHealthMonitoringMode":
            setDeviceHealthMonitoringMode(call.arguments, result: result)
            
        case "setDeviceTemperatureMonitoringMode":
            setDeviceTemperatureMonitoringMode(call.arguments, result: result)
            
        case "setDeviceHeartRateAlarm":
            setDeviceHeartRateAlarm(call.arguments, result: result)
            
        case "setDeviceBloodPressureAlarm":
            setDeviceBloodPressureAlarm(call.arguments, result: result)
            
        case "setDeviceBloodOxygenAlarm":
            setDeviceBloodOxygenAlarm(call.arguments, result: result)
            
        case "setDeviceRespirationRateAlarm":
            setDeviceRespirationRateAlarm(call.arguments, result: result)
            
        case "setDeviceTemperatureAlarm":
            setDeviceTemperatureAlarm(call.arguments, result: result)
            
        case "queryDeviceTheme":
            queryDeviceTheme(call.arguments, result: result)
            
        case "setDeviceTheme":
            setDeviceTheme(call.arguments, result: result)
            
        case "setDeviceSleepReminder":
            setDeviceSleepReminder(call.arguments, result: result)
            
        case "setDeviceInfoPush":
            setDeviceInfoPush(call.arguments, result: result)
            
        case "setDevicePeriodicReminderTask":
            setDevicePeriodicReminderTask(
                call.arguments,
                result: result
            )
            
            // MARK: - App Control
            
        case "sendPhoneUUIDToDevice":
            sendPhoneUUIDToDevice(call.arguments, result: result)
            
        case "sendDeviceMenstrualCycle":
            sendDeviceMenstrualCycle(
                call.arguments,
                result: result
            )
            
        case "findDevice":
            findDevice(call.arguments, result: result)
            
        case "deviceSystemOperator":
            deviceSystemOperator(call.arguments, result: result)
            
        case "bloodPressureCalibration":
            bloodPressureCalibration(call.arguments, result: result)
            
        case "temperatureCalibration":
            temperatureCalibration(call.arguments, result: result)
            
        case "bloodGlucoseCalibration":
            bloodGlucoseCalibration(call.arguments, result: result)
            
        case "sendTodayWeather":
            sendTodayWeather(call.arguments, result: result)

        case "waveDataUpload":
            waveDataUpload(call.arguments, result: result)

            
        case "sendTomorrowWeather":
            sendTomorrowWeather(call.arguments, result: result)
            
        case "uricAcidCalibration":
            uricAcidCalibration(call.arguments, result: result)
            
        case "bloodFatCalibration":
            bloodFatCalibration(call.arguments, result: result)
            
        case "sendBusinessCard":
            sendBusinessCard(call.arguments, result: result)
            
        case "queryBusinessCard":
            queryBusinessCard(call.arguments, result: result)
            
        case "appControlTakePhoto":
            appControlTakePhoto(call.arguments, result: result)
            
        case "appControlSport":
            appControlSport(call.arguments, result: result)
            
        case "appControlMeasureHealthData":
            appControlMeasureHealthData(call.arguments, result: result)
            
        case "realTimeDataUpload":
            realTimeDataUpload(call.arguments, result: result)
            
        case "startECGMeasurement":
            startECGMeasurement(call.arguments, result: result)
            
        case "stopECGMeasurement":
            stopECGMeasurement(call.arguments, result: result)
            
        case "getECGResult":
            getECGResult(call.arguments, result: result)
            
        case "queryCollectDataBasicInfo":
            queryCollectDataBasicInfo(call.arguments, result: result)
            
        case "queryCollectDataInfo":
            queryCollectDataInfo(call.arguments, result: result)
            
        case "deleteCollectData":
            deleteCollectData(call.arguments, result: result)
            
            
            // MARK: - Ota
        case "deviceUpgrade":
            deviceUpgrade(call.arguments, result: result)
            
            // MARK: - 表盘操作
        case "queryWatchFaceInfo":
            queryWatchFaceInfo(call.arguments, result: result)
            
        case "changeWatchFace":
            changeWatchFace(call.arguments, result: result)
            
        case "deleteWatchFace":
            deleteWatchFace(call.arguments, result: result)
            
        case "installWatchFace":
            installWatchFace(call.arguments, result: result)
            
        case "queryDeviceCustomWatchFaceInfo":
            queryDeviceCustomWatchFaceInfo(call.arguments, result: result)
            
        case "installCustomWatchFace":
            installCustomWatchFace(call.arguments, result: result)
            
        case "changeJieLiWatchFace":
            changeJieLiWatchFace(call.arguments, result: result)
            
        case "deleteJieLiWatchFace":
            deleteJieLiWatchFace(call.arguments, result: result)
            
        case "installJieLiWatchFace":
            installJieLiWatchFace(call.arguments, result: result)
            
            
        case "queryDeviceDisplayParametersInfo":
            queryDeviceDisplayParametersInfo(
                call.arguments,
                result: result
            )
            
        case "installJieLiCustomWatchFace":
            installJieLiCustomWatchFace(
                call.arguments,
                result: result
            )
            
        case "queryJieLiDeviceContacts":
            queryJieLiDeviceContacts(
                call.arguments,
                result: result
            )
            
        case "updateJieLiDeviceContacts":
            updateJieLiDeviceContacts(
                call.arguments,
                result: result
            )
            
        case "updateDeviceContacts":
            updateDeviceContacts(
                call.arguments,
                result: result
            )

        case "getLogFilePath":
            getLogFilePath(call.arguments,
                result: result)    

        case "getJLDeviceLogFilePath":
            getJLDeviceLogFilePath(call.arguments,
                result: result)
                
        case "getDeviceLogFilePath":
            getDeviceLogFilePath(call.arguments,
                result: result)

         case "clearSDKLog":
                    clearSDKLog(call.arguments,
                        result: result)
            
        case "sendDeviceQuiteSleep":
            sendDeviceQuiteSleep(result: result)
            
            

        // MARK: - 语音识别
        case "startSpeechRecognition":
            startSpeechRecognition(result: result)
            
        case "stopSpeechRecognition":
            stopSpeechRecognition(result: result)
            
            
        default:
            result(FlutterMethodNotImplemented)
        }
         
    }
}
 

// MARK: - 工具代码
extension YcProductPlugin {
    
    /// 圆角图片
    public static func circleImage(
        _ srcImage: UIImage,
        borderColor: UIColor,
        borderWidth: CGFloat,
        corner: CGFloat,
        finalSize: CGSize
    ) -> UIImage? {
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(finalSize, false, scale)
        
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: finalSize), cornerRadius: corner)
        
        path.lineWidth = borderWidth
        borderColor.set()
        path.addClip()
        path.fill()
        
        let clicPath =
            UIBezierPath(
                roundedRect:
                    CGRect(x: borderWidth, y: borderWidth, width: finalSize.width - 2 * borderWidth, height: finalSize.height - 2 * borderWidth),
                cornerRadius: corner
            )
        
        clicPath.addClip()
        
        srcImage.draw(in: CGRect(x: borderWidth, y: borderWidth, width: finalSize.width - 2 * borderWidth, height: finalSize.height - 2 * borderWidth))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
