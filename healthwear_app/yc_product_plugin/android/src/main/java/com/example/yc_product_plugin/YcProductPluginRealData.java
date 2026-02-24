package com.example.yc_product_plugin;

import android.os.Handler;
import android.util.Log;

import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleRealDataResponse;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class YcProductPluginRealData {

    private static java.util.concurrent.ConcurrentHashMap<Integer, Long> lastEmitTimes = new java.util.concurrent.ConcurrentHashMap<>();

    /**
     * 监听实时数据
     *
     * @param handler
     * @param eventSink
     */
    public static void setupDeviceRealDataObserver(
            Handler handler,
            EventChannel.EventSink eventSink) {

        YCBTClient.appRegisterRealDataCallBack(new BleRealDataResponse() {
            @Override
            public void onRealDataResponse(int i, HashMap hashMap) {
                System.out.println("LHY-REALDATA-RAW: dataType=" + i + " map=" + hashMap);
                // --- BUG 2: Throttling Check (Max 1 event per 1000ms per characteristic) ---
                long now = System.currentTimeMillis();
                Long lastTime = lastEmitTimes.get(i);
                if (lastTime != null && (now - lastTime) < 1000) {
                    return; // Drop packet to prevent BLASTBufferQueue exhaustion over EventChannel
                }
                lastEmitTimes.put(i, now);
                // --------------------------------------------------------------------------

                Log.d("LHY", "RealData: dataType=" + i + " data=" + hashMap);
                int dataType_val = i; 
                switch (dataType_val) {

                    case Constants.DATATYPE.Real_UploadSport: // 实时计步
                        if (hashMap != null) {

                            Integer step = (Integer) hashMap.get("sportStep");
                            Integer distance = (Integer)hashMap.get("sportDistance");
                            Integer calories = (Integer)hashMap.get("sportCalorie");

                            HashMap stepInfo = new HashMap();
                            stepInfo.put("step", step);
                            stepInfo.put("distance", distance);
                            stepInfo.put("calories", calories);

                            HashMap stepMap = new HashMap();
                            stepMap.put(
                                    YcProductPluginFlutterType.NativeEventType.deviceRealStep,
                                    stepInfo
                            );

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    if (!YcProductPlugin.isAppInBackground) eventSink.success(stepMap);
                                }
                            });
                        }
                        break;
                    case Constants.DATATYPE.Real_UploadHeart: // 实时心率
                        if (hashMap != null) {
                            Integer heartValue = (Integer) hashMap.get("heartValue");

                            HashMap heartMap = new HashMap();
                            heartMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealHeartRate, heartValue);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    if (!YcProductPlugin.isAppInBackground) eventSink.success(heartMap);
                                }
                            });
                        }

                        break;

                    case Constants.DATATYPE.Real_UploadBloodOxygen:
                        if (hashMap != null) {

                            Integer bloodOxygenValue = (Integer) hashMap.get("bloodOxygenValue");

                            HashMap bloodOxygenMap = new HashMap();
                            bloodOxygenMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealBloodOxygen, bloodOxygenValue);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    if (!YcProductPlugin.isAppInBackground) eventSink.success(bloodOxygenMap);
                                }
                            });
                        }
                        break;

                    case Constants.DATATYPE.Real_UploadBlood:
                        if (hashMap != null) {

//                            Log.e("TAG", "onRealDataResponse: + " + hashMap );

                            Integer sbp = (Integer) hashMap.get("bloodSBP");
                            Integer dbp = (Integer) hashMap.get("bloodDBP");

                            if (sbp != null && dbp != null) {
                                HashMap bpInfo = new HashMap();
                                bpInfo.put("systolicBloodPressure", sbp);
                                bpInfo.put("diastolicBloodPressure", dbp);

                                HashMap bloodPressureMap = new HashMap();
                                bloodPressureMap.put(
                                        YcProductPluginFlutterType.NativeEventType.deviceRealBloodPressure,
                                        bpInfo
                                );

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(bloodPressureMap);
                                    }
                                });
                            }

                            Integer hrv = (Integer) hashMap.get("hrv");
                            if(hrv != null && hrv != 0x0F && hrv > 0){
                                HashMap hrvMap = new HashMap();
                                hrvMap.put(
                                    YcProductPluginFlutterType.NativeEventType.deviceRealHRV,
                                    hrv
                                );

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(hrvMap);
                                    }
                                });
                            }
                        }
                        break;

                    case Constants.DATATYPE.Real_UploadComprehensive:

                        if (hashMap != null) {
                            Integer tempFloat = (Integer) hashMap.get("tempFloat");
                            Integer tempInteger = (Integer) hashMap.get("tempInteger");

                            Integer bloodSugar = (Integer) hashMap.get("bloodSugar");
                            if(bloodSugar != null && bloodSugar != 0x0F && bloodSugar != 0){
                                String bloodGlucose = (bloodSugar / 10) + "." + (bloodSugar % 10);
                                HashMap bloodGlucoseMap = new HashMap();
                                bloodGlucoseMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealBloodGlucose, bloodGlucose);
    
                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(bloodGlucoseMap);
                                    }
                                });
                            }

                            if (tempFloat != null && tempInteger != null && tempFloat != 0x0F) {
                                String temperature = tempInteger + "." + tempFloat;
                                HashMap temperatureMap = new HashMap();
                                temperatureMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealTemperature, temperature);

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(temperatureMap);
                                    }
                                });
                            }

                            Integer heartRate = (Integer) hashMap.get("heartRate");
                            if (heartRate != null && heartRate > 0) {
                                HashMap heartMap = new HashMap();
                                heartMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealHeartRate, heartRate);
                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(heartMap);
                                    }
                                });
                            }

                            Integer bloodOxygen = (Integer) hashMap.get("bloodOxygen");
                            if (bloodOxygen != null && bloodOxygen > 0) {
                                HashMap bloodOxygenMap = new HashMap();
                                bloodOxygenMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealBloodOxygen, bloodOxygen);
                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(bloodOxygenMap);
                                    }
                                });
                            }

                            Integer sbp = (Integer) hashMap.get("SBP");
                            Integer dbp = (Integer) hashMap.get("DBP");
                            if (sbp != null && dbp != null && sbp > 0 && dbp > 0) {
                                HashMap bpInfo = new HashMap();
                                bpInfo.put("systolicBloodPressure", sbp);
                                bpInfo.put("diastolicBloodPressure", dbp);
                                HashMap bloodPressureMap = new HashMap();
                                bloodPressureMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealBloodPressure, bpInfo);
                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(bloodPressureMap);
                                    }
                                });
                            }

                            Integer step = (Integer) hashMap.get("step");
                            if (step != null && step > 0) {
                                HashMap stepInfo = new HashMap();
                                stepInfo.put("step", step);
                                stepInfo.put("distance", hashMap.get("dis") != null ? hashMap.get("dis") : 0);
                                stepInfo.put("calories", hashMap.get("kcal") != null ? hashMap.get("kcal") : 0);
                                HashMap stepMap = new HashMap();
                                stepMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealStep, stepInfo);
                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(stepMap);
                                    }
                                });
                            }
                        }
                        break;
                    
                        // 压力
                    case Constants.DATATYPE.Real_UploadBodyData:
                        if(hashMap != null){
                            Integer pressureInteger = (Integer) hashMap.get("pressureInteger");
                            Integer pressureFloat = (Integer) hashMap.get("pressureFloat");

                            if (pressureInteger != null && pressureFloat != null && pressureFloat != 0x0F) {
                                String pressure = pressureInteger + "." + pressureFloat;
                                HashMap pressureMap = new HashMap();
                                pressureMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealPressure, pressure);

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (!YcProductPlugin.isAppInBackground) eventSink.success(pressureMap);
                                    }
                                });
                            }
                        }

                        
                        break;

                        // 运动模式
                    case Constants.DATATYPE.Real_UploadOGA:
                    Log.d("LHY","sportMap2:"+hashMap);
                        if (hashMap != null) {
                           Log.d("LHY","sportMap3:"+hashMap);
                            Integer time = (Integer)hashMap.get("recordTime");
                            Integer heartRate = (Integer)hashMap.get("heartRate");
                            Integer step = (Integer)hashMap.get("sportsRealSteps");
                            Integer distance = (Integer)hashMap.get("sportsRealDistance");
                            Integer calories = (Integer)hashMap.get("sportsRealCalories");
                            //最大摄氧量
                            Integer maximalOxygenIntake = (Integer) hashMap.get("maximalOxygenIntake");

                            HashMap sportInfo = new HashMap();
                            sportInfo.put("time", time);
                            sportInfo.put("heartRate", heartRate);
                            sportInfo.put("step", step);
                            sportInfo.put("distance", distance);
                            sportInfo.put("calories", calories);

                            if (maximalOxygenIntake != null) {
                                sportInfo.put("vo2max", maximalOxygenIntake);
                            }

                            HashMap sportMap = new HashMap();
                            sportMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealSport, sportInfo);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    if (!YcProductPlugin.isAppInBackground) eventSink.success(sportMap);
                                }
                            });
                        }
                        break;
                    case Constants.DATATYPE.Real_UploadSensor:
                        if(hashMap != null){
                            int type = (int) hashMap.get("type");
                            List<Map<String,String>> data = (List<Map<String,String>>) hashMap.get("data");

                            HashMap hashMap1 = new HashMap();
                            hashMap1.put("type", type);
                            hashMap1.put("data", data);

                            HashMap map = new HashMap();
                            map.put(YcProductPluginFlutterType.NativeEventType.deviceRealACCData, hashMap1);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    if (!YcProductPlugin.isAppInBackground) eventSink.success(map);
                                }
                            });
                        }


                        break;
                    case Constants.DATATYPE.Real_UploadMulPhotoelectricWaveform:
                        if(hashMap != null){



                            List<Integer> red = (List<Integer>) hashMap.get("red");
                            List<Integer> green = (List<Integer>) hashMap.get("green");
                            List<Integer> typeList = (List<Integer>) hashMap.get("typeList");
                            List<Integer> data = (List<Integer>) hashMap.get("data");

                            int dataType1 = (int) hashMap.get("dataType");
                            List<Integer> ir = (List<Integer>) hashMap.get("ir");
                            int sampleType = (int) hashMap.get("sampleType");

                            HashMap hashMap1 = new HashMap();
                            hashMap1.put("red", red);
                            hashMap1.put("green", green);
                            hashMap1.put("typeList", typeList);
                            hashMap1.put("data", data);
                            hashMap1.put("dataType", dataType1);
                            hashMap1.put("ir", ir);
                            hashMap1.put("sampleType", sampleType);


                            HashMap map = new HashMap();
                            map.put(YcProductPluginFlutterType.NativeEventType.deviceMultiChannelPPGData, hashMap1);

                            handler.post(new Runnable() {
                                @Override
                                public void run() {
                                    if (!YcProductPlugin.isAppInBackground) eventSink.success(map);
                                }
                            });
                        }


                        break;

                    default:
                        break;
                }

                Log.e("Flutter", "onRealDataResponse: " + hashMap + "," + i);
            }
        });
    }
}
