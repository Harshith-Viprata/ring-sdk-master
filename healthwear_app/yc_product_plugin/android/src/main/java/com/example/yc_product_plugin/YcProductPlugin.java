package com.example.yc_product_plugin;

import android.content.Context;
import android.app.Activity;
import android.content.Intent;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


/** YcProductPlugin */
public class YcProductPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {

  public static boolean isAppInBackground = false;

  private MethodChannel methodChannel;
  private EventChannel eventChannel;

  // 定义一个上下文
  private Context context;
  private Handler handler;
  private EventChannel.EventSink eventSink;

  private ActivityPluginBinding activityPluginBinding;


  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityPluginBinding = binding;
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

    // 初始化
    context = flutterPluginBinding.getApplicationContext();
    handler = new Handler(android.os.Looper.getMainLooper());


    // methodChannel
    methodChannel =
            new MethodChannel(
                    flutterPluginBinding.getBinaryMessenger(),
                    "ycaviation.com/yc_product_plugin_method_channel"
            );
    methodChannel.setMethodCallHandler(this);

    // eventChannel
    eventChannel =
            new EventChannel(
                    flutterPluginBinding.getBinaryMessenger(),
                    "ycaviation.com/yc_product_plugin_event_channel"
            );


    eventChannel.setStreamHandler(new EventChannel.StreamHandler() {

      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {

        eventSink = events;
        setupObserver(handler, eventSink);

      }

      @Override
      public void onCancel(Object arguments) {

      }
    });
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    matchMethodCall(call, result);
  }


  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    // 销毁通道
    methodChannel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
  }


  /**
   * 适配MethodChannel
   *
   * @param call
   * @param result
   */
  private void matchMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    String method = call.method;
    Object arguments = call.arguments;


    switch (method) {
      case "pauseEventChannel":
        isAppInBackground = true;
        result.success(null);
        break;

      case "resumeEventChannel":
        isAppInBackground = false;
        result.success(null);
        break;

      case "shutdownBle":
        Log.d("MARK-", "App closing, shutting down BLE gracefully.");
        com.yucheng.ycbtsdk.YCBTClient.disconnectBle();
        try {
            android.bluetooth.BluetoothManager manager = (android.bluetooth.BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
            if (manager != null) {
                java.util.List<android.bluetooth.BluetoothDevice> connectedOSDevices = manager.getConnectedDevices(android.bluetooth.BluetoothProfile.GATT);
                for (android.bluetooth.BluetoothDevice osDevice : connectedOSDevices) {
                    android.bluetooth.BluetoothGatt tempGatt = osDevice.connectGatt(context, false, new android.bluetooth.BluetoothGattCallback() {});
                    if (tempGatt != null) {
                        tempGatt.disconnect();
                        tempGatt.close();
                    }
                }
            }
        } catch (Exception e) {
            Log.e("MARK-", "GATT force close error: " + e.getMessage());
        }
        result.success(null);
        break;

      // MARK: - SDK 初始化
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;

      case "initPlugin":
        YcProductPluginInit.initPlugin(context, arguments, result);
        break;

      case "setReconnectEnabled":
        YcProductPluginInit.setReconnectEnabled(arguments, result);
        break;

      case "clearQueue":
        YcProductPluginInit.clearQueue(result);
        break;

      case "resetBond":
        YcProductPluginInit.resetBond(arguments,result);
        break;

      case "exitScanDevice":
        YcProductPluginInit.exitScanDevice(arguments,result);
        break;

      // MARK: - 蓝牙相关

      case "getBluetoothState":
        YcProductPluginDevice.getBluetoothState(result);
        break;

      case "scanDevice":
        YcProductPluginDevice.scanDevice(context,arguments, result);
        break;

      case "stopScanDevice":
        YcProductPluginDevice.stopScanDevice(result);
        break;

      case "connectDevice":
        YcProductPluginDevice.connectDevice(context, arguments, result);
        break;

      case "disconnectDevice":
        YcProductPluginDevice.disConnectDevice(arguments, result);
        break;

      case "getDeviceFeature":
        YcProductPluginQuery.getDeviceFeature(arguments, result);
        break;


      // MARK: - 同步数据
      case "queryDeviceHealthData":
        YcProductPluginHealthData.queryDeviceHealthData(arguments, result);
      break;

      case "deleteDeviceHealthData":
        YcProductPluginHealthData.deleteDeviceHealthData(arguments, result);
      break;

      // MARK: - 查询
      case "queryDeviceBasicInfo":
        YcProductPluginQuery.queryDeviceBasicInfo(arguments, result);
        break;

      case "queryDeviceMacAddress":
        YcProductPluginQuery.queryDeviceMacAddress(arguments, result);
        break;

      case "queryDeviceModel":
        YcProductPluginQuery.queryDeviceModel(arguments, result);
        break;

      case "queryDeviceMCU":
        YcProductPluginQuery.queryDeviceMCU(arguments, result);
        break;

        // MARK: - 设置部分
      case "setDeviceSyncPhoneTime":
        YcProductPluginSetting.setDeviceSyncPhoneTime(arguments, result);
        break;

      case "setDeviceStepGoal":
        YcProductPluginSetting.setDeviceStepGoal(arguments, result);
        break;

      case "setDeviceSleepGoal":
        YcProductPluginSetting.setDeviceSleepGoal(arguments, result);
        break;

      case "setDeviceUserInfo":
        YcProductPluginSetting.setDeviceUserInfo(arguments, result);
        break;

      case "setDeviceSkinColor":
        YcProductPluginSetting.setDeviceSkinColor(arguments, result);
        break;

      case "setDeviceUnit":
        YcProductPluginSetting.setDeviceUnit(arguments, result);
        break;

      case "setDeviceAntiLost":
        YcProductPluginSetting.setDeviceAntiLost(arguments, result);
        break;

      case "setDeviceNotDisturb":
        YcProductPluginSetting.setDeviceNotDisturb(arguments, result);
        break;

      case "setDeviceLanguage":
        YcProductPluginSetting.setDeviceLanguage(arguments, result);
        break;

      case "setDeviceSedentary":
        YcProductPluginSetting.setDeviceSedentary(arguments, result);
        break;

      case "setDeviceWearingPosition":
        YcProductPluginSetting.setDeviceWearingPosition(arguments, result);

      case "setPhoneSystemInfo":
        YcProductPluginSetting.setPhoneSystemInfo(arguments, result);
        break;

      case "restoreFactorySettings":
        YcProductPluginSetting.restoreFactorySettings(arguments, result);
        break;

      case "setDeviceWristBrightScreen":
        YcProductPluginSetting.setDeviceWristBrightScreen(arguments, result);
        break;

      case "setDeviceDisplayBrightness":
        YcProductPluginSetting.setDeviceDisplayBrightness(arguments, result);
        break;

      case "setDeviceHealthMonitoringMode":
        YcProductPluginSetting.setDeviceHealthMonitoringMode(arguments, result);
        break;

      case "setDeviceTemperatureMonitoringMode":
        YcProductPluginSetting.setDeviceTemperatureMonitoringMode(arguments, result);
        break;

      case "setDeviceHeartRateAlarm":
        YcProductPluginSetting.setDeviceHeartRateAlarm(arguments, result);
        break;

      case "setDeviceBloodPressureAlarm":
        YcProductPluginSetting.setDeviceBloodPressureAlarm(arguments, result);
        break;

      case "setDeviceBloodOxygenAlarm":
        YcProductPluginSetting.setDeviceBloodOxygenAlarm(arguments, result);
        break;

      case "setDeviceRespirationRateAlarm":
        YcProductPluginSetting.setDeviceRespirationRateAlarm(arguments, result);
        break;

      case "setDeviceTemperatureAlarm":
        YcProductPluginSetting.setDeviceTemperatureAlarm(arguments, result);
        break;

      case "queryDeviceTheme":
        YcProductPluginSetting.queryDeviceTheme(arguments, result);
        break;

      case "setDeviceTheme":
        YcProductPluginSetting.setDeviceTheme(arguments, result);
        break;

      case "setDeviceSleepReminder":
        YcProductPluginSetting.setDeviceSleepReminder(arguments, result);
        break;

      case "setDevicePeriodicReminderTask":
        YcProductPluginSetting.setDevicePeriodicReminderTask(arguments, result);
        break;

      case "setDeviceInfoPush":
        YcProductPluginSetting.setDeviceInfoPush(arguments, result);
        break;


      // MARK: - App Control部分

      case "sendPhoneUUIDToDevice":
        YcProductPluginAppControl.sendPhoneUUIDToDevice(arguments, result);
        break;

      case "sendDeviceMenstrualCycle":
        YcProductPluginAppControl.sendDeviceMenstrualCycle(arguments, result);
        break;

      case "findDevice":
        YcProductPluginAppControl.findDevice(arguments, result);
        break;

      case "deviceSystemOperator":
        YcProductPluginAppControl.deviceSystemOperator(arguments, result);
        break;

      case "bloodPressureCalibration":
        YcProductPluginAppControl.bloodPressureCalibration(arguments, result);
        break;

      case "temperatureCalibration":
        YcProductPluginAppControl.temperatureCalibration(arguments, result);
        break;

      case "bloodGlucoseCalibration":
        YcProductPluginAppControl.bloodGlucoseCalibration(arguments, result);
        break;

      case "sendTodayWeather":
        YcProductPluginAppControl.sendTodayWeather(arguments, result);
        break;
      case"waveDataUpload":
        YcProductPluginAppControl.waveDataUpload(arguments, result);
      break;
      case "sendTomorrowWeather":
        YcProductPluginAppControl.sendTomorrowWeather(arguments, result);
        break;

      case "uricAcidCalibration":
        YcProductPluginAppControl.uricAcidCalibration(arguments, result);
        break;

      case "bloodFatCalibration":
        YcProductPluginAppControl.bloodFatCalibration(arguments, result);
        break;

      case "appPushNotifications":
        YcProductPluginAppControl.appPushNotifications(arguments, result);
        break;

      case "sendBusinessCard":
        YcProductPluginAppControl.sendBusinessCard(arguments, result);
        break;

      case "queryBusinessCard":
        YcProductPluginAppControl.queryBusinessCard(arguments, result);
        break;

      case "appControlTakePhoto":
        YcProductPluginDeviceControl.appControlTakePhoto(arguments, result);
        break;

      case "appControlSport":
        YcProductPluginDeviceControl.appControlSport(arguments, result);
        break;

      case "appControlMeasureHealthData":
        YcProductPluginDeviceControl.appControlMeasureHealthData(arguments, result);
        break;

      case "realTimeDataUpload":
        YcProductPluginDeviceControl.realTimeDataUpload(arguments, result);
        break;

      case "startECGMeasurement":
        YcProductPluginECG.startECGMeasurement(arguments, result, handler, eventSink);
        break;

      case "stopECGMeasurement":
        YcProductPluginECG.stopECGMeasurement(arguments, result);
        break;

      case "getECGResult":
        YcProductPluginECG.getECGResult(arguments, result);
        break;

      case "queryCollectDataBasicInfo":
        YcProductPluginCollectData.queryCollectDataBasicInfo(arguments, result);
        break;

      case "queryCollectDataInfo":
        YcProductPluginCollectData.queryCollectDataInfo(arguments, result);
        break;

      case "deleteCollectData":
        YcProductPluginCollectData.deleteCollectData(arguments, result);
        break;

        // Ota升级 context
      case "deviceUpgrade":
        YcProductPluginOTA.deviceUpgrade(methodChannel, handler, activityPluginBinding.getActivity(), arguments, result);
        break;

        // MARK: - 表盘
      case "queryWatchFaceInfo":
        YcProductPluginWatchFace.queryWatchFaceInfo(arguments, result);
        break;

      case "changeWatchFace":
        YcProductPluginWatchFace.changeWatchFace(arguments, result);
        break;

      case "deleteWatchFace":
        YcProductPluginWatchFace.deleteWatchFace(arguments, result);
        break;

      case "installWatchFace":
        YcProductPluginWatchFace.installWatchFace(methodChannel, handler, arguments, result);
        break;

      case "queryDeviceCustomWatchFaceInfo":
        YcProductPluginWatchFace.queryDeviceCustomWatchFaceInfo(arguments, result);
        break;

      case "installCustomWatchFace":
        YcProductPluginWatchFace.installCustomWatchFace(context, methodChannel, handler, arguments, result);
        break;

      case "changeJieLiWatchFace":
        YcProductPluginWatchFace.changeJieLiWatchFace(arguments, result);
        break;

      case "deleteJieLiWatchFace":
        YcProductPluginWatchFace.deleteJieLiWatchFace(arguments, result);
        break;

      case "installJieLiWatchFace":
        YcProductPluginWatchFace.installJieLiWatchFace(methodChannel, handler, arguments, result);
        break;

      case "queryDeviceDisplayParametersInfo":
        YcProductPluginWatchFace.queryDeviceDisplayParametersInfo(arguments, result);
        break;

      case "installJieLiCustomWatchFace":
        YcProductPluginWatchFace.installJieLiCustomWatchFace(context, methodChannel, handler, arguments, result);
        break;

      case "updateJieLiDeviceContacts":
        YcProductPluginContact.updateJieLiDeviceContacts(context, arguments, result);
        break;

      case "queryJieLiDeviceContacts":
        YcProductPluginContact.queryJieLiDeviceContacts(context, arguments, result);
        break;

      case "updateDeviceContacts":
        YcProductPluginContact.updateDeviceContacts(context, arguments, result);
        break;
      
      case "getLogFilePath":
        YcProductPluginLogger.getLogFilePath(context, arguments, result);
        break;

      case "shareLogFile":
        YcProductPluginLogger.shareLogFile(context,activityPluginBinding, arguments, result);
        break;

      case "getJLDeviceLogFilePath":
        YcProductPluginLogger.getJLDeviceLogFilePath(context, arguments, result);
        break;
              
      case "getDeviceLogFilePath":
        YcProductPluginLogger.getDeviceLogFilePath(context, arguments, result);
        break;

      case "clearSDKLog":
        YcProductPluginLogger.clearSDKLog(context, arguments, result);
        break;

        //闹钟
      case "settingGetAllAlarm":
        YcProductPluginSetting.settingGetAllAlarm(arguments, result);
        break;
      case "settingAddAlarm":
        YcProductPluginSetting.settingAddAlarm(arguments, result);
        break;
      case "settingModfiyAlarm":
        YcProductPluginSetting.settingModfiyAlarm(arguments, result);
        break;
      case "updateCallAlerts":
        YcProductPluginSetting.updateCallAlerts(arguments, result);
        break;
      case "shutdown":
        YcProductPluginDevice.shutdown(result);
        break;
      case "startListening":
        YcProductPluginDevice.startListening(activityPluginBinding,context,result);
        break;
      case "appQuerySampleRate":
        YcProductPluginSetting.appQuerySampleRate(arguments,result);
        break;
      case "appConfigureSampleRate":
        YcProductPluginSetting.appConfigureSampleRate(arguments,result);
        break;
      case "appConfigureRealTimePpg":
        YcProductPluginSetting.appConfigureRealTimePpg(arguments,result);
        break;
      case "appQueryMems":
        YcProductPluginSetting.appQueryMems(arguments,result);
        break;
      case "appMemsSwitch":
        YcProductPluginSetting.appMemsSwitch(arguments,result);
        break;
      case "settingVibrationIntensity":
        YcProductPluginSetting.settingVibrationIntensity(arguments,result);
        break;
      default:
        result.notImplemented();

    }
  }


  /**
   * 设置监听
   */
  private void setupObserver(Handler handler, EventChannel.EventSink eventSink) {

    // 蓝牙状态
    YcProductPluginDevice.setupDeviceStateObserver(handler, eventSink);

    // 设备操作
    YcProductPluginDeviceControl.setupDeviceControlObserver(handler, eventSink);

    // 实时数据
    YcProductPluginRealData.setupDeviceRealDataObserver(handler, eventSink);
  }


  /**
   * 转换Flutter插件的状态码
   *
   * @param code
   * @return
   */
  public static int convertPluginState(int code) {

    if (0xFC == (code & 0xFF) || 0xFD == (code & 0xFF)) {

      return YcProductPluginFlutterType.PluginState.unavailable;

    } else if (0 == code) {

      return YcProductPluginFlutterType.PluginState.succeed;

    } else {

      return YcProductPluginFlutterType.PluginState.failed;

    }
  }

}


