package com.example.yc_product_plugin;

import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleDeviceToAppDataResponse;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class YcProductPluginDeviceControl {

    /**
     * 监听设备操作
     *
     * @param handler
     * @param eventSink
     */
    public static void setupDeviceControlObserver(
            Handler handler,
            EventChannel.EventSink eventSink) {


        YCBTClient.deviceToApp(new BleDeviceToAppDataResponse() {
            @Override
            public void onDataResponse(int i, HashMap hashMap) {

                Log.e("deviceToApp", "onDataResponse: " + hashMap);

                if (hashMap != null) {

                    if (0 == i) {
                        int dataType = (int) hashMap.get("dataType");
                        switch (dataType) {
                            case Constants.DATATYPE.DeviceTakePhoto://相机拍照控制

                                int photoCode = (int) hashMap.get("data");
                                HashMap photoMap = new HashMap();
                                photoMap.put(YcProductPluginFlutterType.NativeEventType.deviceControlPhotoStateChange, photoCode);

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        eventSink.success(photoMap);
                                    }
                                });

                                break;

                            case Constants.DATATYPE.DeviceFindMobile: // 找手机
                                int findCode = (int) hashMap.get("data");
                                HashMap findMap = new HashMap();
                                findMap.put(YcProductPluginFlutterType.NativeEventType.deviceControlFindPhoneStateChange, findCode);

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        eventSink.success(findMap);
                                    }
                                });

                                break;

                            // 测量状态
                            case Constants.DATATYPE.DeviceMeasurementResult:
                                byte[] data = (byte[]) hashMap.get("datas");
                                int state = data[1] & 0xFF;
                                int healthDataType = data[0] & 0xFF;

                                HashMap stateInfo = new HashMap();
                                stateInfo.put("state", state);
                                stateInfo.put("healthDataType", healthDataType);
                                
                                java.util.ArrayList<Integer> rawValues = new java.util.ArrayList<>();
                                if (data != null && data.length > 2) {
                                    for(int j = 2; j < data.length; j++) {
                                        rawValues.add(data[j] & 0xFF);
                                    }
                                }
                                stateInfo.put("values", rawValues);

                                HashMap measureMap = new HashMap();
                                measureMap.put(
                                        YcProductPluginFlutterType.NativeEventType.deviceHealthDataMeasureStateChange,
                                        stateInfo
                                );

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        eventSink.success(measureMap);
                                    }
                                });
                                break;

                            // 运动状态
                            case Constants.DATATYPE.DeviceSportModeControl:

                                byte[] datas = (byte[]) hashMap.get("datas");

                                int sportState = datas[0];
                                int sportType = datas[1];

                                HashMap sporttControlInfo = new HashMap();
                                sporttControlInfo.put("state", sportState);
                                sporttControlInfo.put("sportType", sportType);

                                HashMap sportMap = new HashMap();
                                sportMap.put(
                                        YcProductPluginFlutterType.NativeEventType.deviceSportStateChange,
                                        sporttControlInfo
                                );
                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        eventSink.success(sportMap);
                                    }
                                });
                                break;

                            case Constants.DATATYPE.DeviceSwitchDial:

                                if (YCBTClient.getChipScheme() == Constants.Platform.JieLi) {

                                    String deviceName = hashMap.get("datas").toString();
                                    Log.d("WATCH", "onDataResponse: " + deviceName);

                                    if (deviceName.isEmpty() == false) {
                                        deviceName = deviceName.substring(1);
                                    }

                                    HashMap dialMap = new HashMap();
                                    dialMap.put(YcProductPluginFlutterType.NativeEventType.deviceJieLiWatchFaceChange, deviceName);
                                    handler.post(new Runnable() {
                                        @Override
                                        public void run() {
                                            eventSink.success(dialMap);
                                        }
                                    });

                                } else {

                                    byte[] ids = (byte[]) hashMap.get("datas");
                                    int dialID = (ids[0] & 0xff) + ((ids[1] & 0xff) << 8) + ((ids[2] & 0xff) << 16) + ((ids[3] & 0xff) << 24);

                                    HashMap dialMap = new HashMap();
                                    dialMap.put(YcProductPluginFlutterType.NativeEventType.deviceWatchFaceChange, dialID);
                                    handler.post(new Runnable() {
                                        @Override
                                        public void run() {
                                            eventSink.success(dialMap);
                                        }
                                    });
                                }

                                break;
                            case Constants.DATATYPE.DeviceEndECG:
                                Log.d("DeviceEndECG",hashMap.toString());

                                    HashMap hashMap1 = new HashMap();
                                    hashMap1.put(YcProductPluginFlutterType.NativeEventType.deviceEndECG, 0);

                                    handler.post(new Runnable() {
                                        @Override
                                        public void run() {
                                            eventSink.success(hashMap1);
                                        }
                                    });
                                break;

                            default:
                                break;
                        }
                    }
                }
            }
        });
    }

    /**
     * 控制拍照
     *
     * @param arguments
     * @param result
     */
    public static void appControlTakePhoto(Object arguments, @NonNull MethodChannel.Result result) {

        Boolean isEnable = (Boolean) arguments;

        YCBTClient.appControlTakePhoto(isEnable ? 1 : 0, new BleDataResponse() {
            private boolean isReplied = false;
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (isReplied) return;
                isReplied = true;
                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                new Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        result.success(map);
                    }
                });
            }
        });
    }

    /**
     * 运动控制
     *
     * @param arguments
     * @param result
     */
    public static void appControlSport(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int state = (int) list.get(0);
        int sportType = (int) list.get(1);

        YCBTClient.appRunMode(state, sportType, new BleDataResponse() {
            private boolean isReplied = false;
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (isReplied) return;
                isReplied = true;
                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                new Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        result.success(map);
                    }
                });
            }
        });
    }


    /**
     * 一键测量
     *
     * @param arguments
     * @param result
     */
    public static void appControlMeasureHealthData(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int state = (int) list.get(0);
        int dataType = (int) list.get(1);

        YCBTClient.appStartMeasurement(state, dataType, new BleDataResponse() {
            private boolean isReplied = false;
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                System.out.println("LHY-MEASURE: appStartMeasurement fired! i=" + i + ", v=" + v + ", hashMap=" + hashMap);
                if (isReplied) return;
                isReplied = true;
                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                new Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        result.success(map);
                    }
                });
            }
        });

    }



    public static void realTimeDataUpload(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }
        boolean state = (boolean) list.get(0);
        int dataTypeIndex = (int) list.get(1);
        
        // Map Flutter DeviceRealTimeDataType to Android SDK Types:
        int sdkDataType = 0x09; // Default to comprehensive
        switch (dataTypeIndex) {
            case 0: sdkDataType = 0x01; break; // step
            case 1: sdkDataType = 0x02; break; // heartRate
            case 2: sdkDataType = 0x03; break; // bloodOxygen
            case 3: sdkDataType = 0x04; break; // bloodPressure
            case 7: sdkDataType = 0x09; break; // combinedData
        }

        Log.d("LHY", "realTimeDataUpload: state=" + state + " dartEnumIndex=" + dataTypeIndex + " sdkDataType=" + sdkDataType);

        YCBTClient.appRealDataFromDevice(state ? 1 : 0, sdkDataType, new BleDataResponse() {
            private boolean isReplied = false;
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                System.out.println("LHY-MEASURE: appRealDataFromDevice fired! i=" + i + ", v=" + v + ", hashMap=" + hashMap);
                if (isReplied) return;
                isReplied = true;
                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                new Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        result.success(map);
                    }
                });
            }
        });
    }



}
