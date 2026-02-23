package com.example.yc_product_plugin;

import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.AITools;
import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.AIDataBean;
import com.yucheng.ycbtsdk.bean.HealthNormBean;
import com.yucheng.ycbtsdk.response.BleAIDiagnosisResponse;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleRealDataResponse;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class YcProductPluginECG {

    /**
     * 开启ECG测量
     *
     * @param arguments
     * @param result
     */
    public static void startECGMeasurement(
            Object arguments,
            @NonNull MethodChannel.Result result,
                    Handler handler,
            EventChannel.EventSink eventSink
    ) {

        // 算法初始化
        AITools.getInstance().init();

        YCBTClient.appEcgTestStart(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                result.success(map);
            }
        }, new BleRealDataResponse() {
            @Override
            public void onRealDataResponse(int i, HashMap hashMap) {

//                Log.e("ECG测量", "onRealDataResponse: " + hashMap + ',' + i );

                // ECG 数据
                if (i == Constants.DATATYPE.Real_UploadECG && hashMap != null) {
                    ArrayList ecgData = (ArrayList) hashMap.get("originalData");
                    ArrayList mvData = (ArrayList) hashMap.get("data");
//                    Log.e("ECG测量 mvData", "onRealDataResponse: " + mvData );

                    HashMap ecgMap = new HashMap();
                    ecgMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealECGData, ecgData);
                    ecgMap.put(YcProductPluginFlutterType.NativeEventType.deviceRealECGFilteredData, mvData);
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            eventSink.success(ecgMap);
                        }
                    });
                }

                // PPG 数据
                else if (i == Constants.DATATYPE.Real_UploadPPG && hashMap != null) {
                    ArrayList ppgData = (ArrayList) hashMap.get("data");
//                    Log.e("ECG测量", "onRealDataResponse: " + ppgData );

                    HashMap ppgMap = new HashMap();
                    ppgMap.put(YcProductPluginFlutterType.NativeEventType.deviceMultiChannelPPGData, ppgData);
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            eventSink.success(ppgMap);
                        }
                    });
                }

                // 血压数据
                else if (i == Constants.DATATYPE.Real_UploadBlood && hashMap != null) {

                    int heartValue = (int) hashMap.get("heartValue");
                    int bloodSBP = (int) hashMap.get("bloodSBP");
                    int bloodDBP = (int) hashMap.get("bloodDBP");

                    if (heartValue > 0 &&
                            bloodDBP > 0 &&
                            bloodSBP > 0 &&
                            bloodSBP > bloodDBP
                    ) {

                        HashMap bloodPressureMap = new HashMap();
                        bloodPressureMap.put("heartRate", heartValue);
                        bloodPressureMap.put("systolicBloodPressure", bloodSBP);
                        bloodPressureMap.put("diastolicBloodPressure", bloodDBP);

                        if (hashMap.containsKey("hrv")) {
                            int hrv = (int) hashMap.get("hrv");
                            if (hrv > 0 && hrv < 150) {
                                bloodPressureMap.put("hrv", hrv);
                            }
                        }


                        HashMap bloodPressureInfo = new HashMap();

                        bloodPressureInfo.put(
                                YcProductPluginFlutterType.NativeEventType.deviceRealBloodPressure,
                                bloodPressureMap
                        );

//                        Log.e("ECG测量 心率血压", "" + bloodPressureInfo);

                        handler.post(new Runnable() {
                            @Override
                            public void run() {
                                   eventSink.success(bloodPressureInfo);
                            }
                        });
                    }
                }

                // RR间隔数据
                else if (i == Constants.DATATYPE.Real_UploadECGRR && hashMap != null) {
//                    Log.e("ECG测量 RR", "onRealDataResponse: " + hashMap);
                    float rr = (float) hashMap.get("data");

                    HashMap rrInfo = new HashMap();
                    rrInfo.put(YcProductPluginFlutterType.NativeEventType.deviceRealECGAlgorithmRR, String.format("%.2f", rr));

                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            eventSink.success(rrInfo);
                        }
                    });
                }

                // HRV
                else if (i == Constants.DATATYPE.Real_UploadECGHrv && hashMap != null) {

                    int hrv = (int)(float)hashMap.get("data");
//                    Log.e("ECG测量 HRV", "" + hrv);

                    HashMap hrvInfo = new HashMap();
                    hrvInfo.put(YcProductPluginFlutterType.NativeEventType.deviceRealECGAlgorithmHRV, hrv);
                    handler.post(new Runnable() {
                        @Override
                        public void run() {

                            eventSink.success(hrvInfo);
                        }
                    });
                }

                else if (i == Constants.DATATYPE.AppECGPPGStatus&& hashMap != null) {
                    Log.d("AppECGPPGStatus",hashMap.toString());
                    int EcgStatus = (int) hashMap.get("EcgStatus");
                    int PPGStatus = (int) hashMap.get("PPGStatus");

                    HashMap hashMap1 = new HashMap();
                    hashMap1.put("EcgStatus", EcgStatus);
                    hashMap1.put("PPGStatus", PPGStatus);


                    HashMap appECGPPGStatusMap = new HashMap();
                    appECGPPGStatusMap.put(YcProductPluginFlutterType.NativeEventType.appECGPPGStatus, hashMap1);
                    handler.post(new Runnable() {
                        @Override
                        public void run() {

                            eventSink.success(appECGPPGStatusMap);
                        }
                    });

                }
                }
        });
    }

    /**
     * 结束ECG测量
     *
     * @param arguments
     * @param result
     */
    public static void stopECGMeasurement(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.appEcgTestEnd(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                result.success(map);
            }
        });
    }


    /**
     * 获取ECG诊断结果
     * @param arguments
     * @param result
     */
    public static void getECGResult(Object arguments, @NonNull MethodChannel.Result result) {


        AITools.getInstance().getAIDiagnosisResult(new BleAIDiagnosisResponse() {
            @Override
            public void onAIDiagnosisResponse(AIDataBean aiDataBean) {

                HashMap map = new HashMap();

                if (aiDataBean != null) {

                   int heart = AITools.getInstance().getHeart();
                //    short heart = aiDataBean.heart;//心率
                    // 诊断类型  1正常  4 ,5 ,9异常
                    int qrstype = aiDataBean.qrstype;//类型 1正常心拍 5室早心拍 9房早心拍  14噪声
                    // 是否房颤
                    Boolean afflag = aiDataBean.is_atrial_fibrillation;//是否心房颤动

                    map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                    HashMap ecgInfo = new HashMap();
                    ecgInfo.put("hearRate", heart);
                    ecgInfo.put("qrsType", qrstype);
                    ecgInfo.put("afflag", afflag);

                    HealthNormBean bodyInfo = AITools.getInstance().getHealthNorm();

                    Log.e("LHY", "ECG诊断: " + qrstype );

                    if (bodyInfo.flag != -1  && qrstype != 14) {

                        float heavyLoad = bodyInfo.heavyLoad;
                        float pressure = bodyInfo.pressure;
                        float body = bodyInfo.body;
                        float hrvNorm = bodyInfo.hrvNorm;
                        float sympatheticActivityIndex = bodyInfo.sympatheticParasympathetic;

                        int respiratoryRate = bodyInfo.respiratoryRate;

                        ecgInfo.put("heavyLoad", "" +  String.format("%.1f", heavyLoad));
                        ecgInfo.put("pressure", "" +  String.format("%.1f", pressure));
                        ecgInfo.put("body", "" +  String.format("%.1f", body));
                        ecgInfo.put("hrvNorm", "" +  String.format("%.1f", hrvNorm));
                        ecgInfo.put("sympatheticActivityIndex", "" +  String.format("%.1f", sympatheticActivityIndex));
                        ecgInfo.put("respiratoryRate", respiratoryRate);

                        Log.i("LHY", "onAIDiagnosisResponse: " + ecgInfo);
                    }

                    map.put("data", ecgInfo);

                } else  {

                    map.put("code", YcProductPluginFlutterType.PluginState.failed);
                    map.put("data", "");
                }

                result.success(map);
            }
        });
    }
}
