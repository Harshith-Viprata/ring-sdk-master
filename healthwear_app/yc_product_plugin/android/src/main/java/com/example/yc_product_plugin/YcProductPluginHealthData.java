package com.example.yc_product_plugin;

import android.util.Log;
import android.webkit.WebSettings;

import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.BlockingDeque;

import io.flutter.plugin.common.MethodChannel;

public class YcProductPluginHealthData {


    /**
     * 查询健康历史数据
     *
     * @param arguments YcProductPluginFlutterType.HealthDataType 类型
     * @param result
     */
    public static void queryDeviceHealthData(Object arguments, @NonNull MethodChannel.Result result) {

        int dataType = (int) arguments;

        switch (dataType) {
            case YcProductPluginFlutterType.HealthDataType.step:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistorySport, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {
                                    HashMap obj = (HashMap) list.get(index);

                                    long startTimeStamp = (long) obj.get("sportStartTime") / 1000;
                                    long endTimeStamp = (long) obj.get("sportEndTime") / 1000;
                                    int step = (int) obj.get("sportStep");
                                    int distance = (int) obj.get("sportDistance");
                                    int calories = (int) obj.get("sportCalorie");


                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", startTimeStamp);
                                    info.put("endTimeStamp", endTimeStamp);
                                    info.put("step", step);
                                    info.put("distance", distance);
                                    info.put("calories", calories);

                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                // 返回空值, 什么都不处理

                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.sleep:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistorySleep, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long startTimeStamp = (long) obj.get("startTime") / 1000;
                                    long endTimeStamp = (long) obj.get("endTime") / 1000;
                                    boolean isNewSleepProtocol = ((int) obj.get("deepSleepCount") & 0xFFFF) == 0xFFFF;

                                    int deepSleepSeconds = (int) obj.get("deepSleepTotal");
                                    int lightSleepSeconds = (int) obj.get("lightSleepTotal");

                                    int remSleepSeconds = (int) obj.get("rapidEyeMovementTotal");


                                    // 详细数据
                                    ArrayList detailList = (ArrayList) obj.get("sleepData");
                                    ArrayList allData = new ArrayList();
                                    for (int j = 0; j < detailList.size(); j++) {
                                        HashMap sleepData = (HashMap) detailList.get(j);

                                        HashMap detailInfo = new HashMap();
                                        long detailStartTimeStamp = (long) sleepData.get("sleepStartTime") / 1000;
                                        int duration = (int) sleepData.get("sleepLen");
                                        int sleepType = (int) sleepData.get("sleepType");

                                        detailInfo.put("startTimeStamp", detailStartTimeStamp);
                                        detailInfo.put("duration", duration);
                                        detailInfo.put("sleepType", sleepType);

                                        allData.add(detailInfo);
                                    }

                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", startTimeStamp);
                                    info.put("endTimeStamp", endTimeStamp);

                                    info.put("isNewSleepProtocol", isNewSleepProtocol);
                                    info.put("deepSleepSeconds", deepSleepSeconds);
                                    info.put("lightSleepSeconds", lightSleepSeconds);
                                    info.put("remSleepSeconds", remSleepSeconds);

                                    info.put("detail", allData);

                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                // 返回空值, 什么都不处理
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.heartRate:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistoryHeart, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long time = (long) obj.get("heartStartTime") / 1000;
                                    int heartRate = (int) obj.get("heartValue");

                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", time);
                                    info.put("heartRate", heartRate);

                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                // 返回空值, 什么都不处理
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.bloodPressure:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistoryBlood, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long time = (long) obj.get("bloodStartTime") / 1000;
                                    int systolicBloodPressure = (int) obj.get("bloodSBP");
                                    int diastolicBloodPressure = (int) obj.get("bloodDBP");
                                    int mode = (int) obj.get("isInflated");

                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", time);
                                    info.put("systolicBloodPressure", systolicBloodPressure);
                                    info.put("diastolicBloodPressure", diastolicBloodPressure);
                                    info.put("mode", mode);

                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                // 返回空值, 什么都不处理
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.combinedData:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistoryAll, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long time = (long) obj.get("startTime") / 1000;
                                    int step = (int) obj.get("stepValue");
                                    int heartRate = (int) obj.get("heartValue");
                                    int systolicBloodPressure = (int) obj.get("SBPValue");
                                    int diastolicBloodPressure = (int) obj.get("DBPValue");
                                    int bloodOxygen = (int) obj.get("OOValue");
                                    int respirationRate = (int) obj.get("respiratoryRateValue");
                                    int hrv = (int) obj.get("hrvValue");
                                    int cvrr = (int) obj.get("cvrrValue");

                                    int tempInt = (int) obj.get("tempIntValue");
                                    int tempFloat = (int) obj.get("tempFloatValue");

                                    String temperature = tempInt + "." + tempFloat;

                                    int fatInt = (int) obj.get("bodyFatIntValue");
                                    int fatFloat = (int) obj.get("bodyFatFloatValue");

                                    String fat = fatInt + "." + fatFloat;

                                    int bloodSugarValue = (int) obj.get("bloodSugarValue");

                                    String bloodGlucose = (bloodSugarValue / 10) + "." + (bloodSugarValue % 10);

                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", time);
                                    info.put("step", step);
                                    info.put("heartRate", heartRate);
                                    info.put("systolicBloodPressure", systolicBloodPressure);
                                    info.put("diastolicBloodPressure", diastolicBloodPressure);
                                    info.put("bloodOxygen", bloodOxygen);
                                    info.put("respirationRate", respirationRate);
                                    info.put("hrv", hrv);
                                    info.put("cvrr", cvrr);

                                    info.put("temperature", temperature);
                                    info.put("fat", fat);
                                    info.put("bloodGlucose", bloodGlucose);


                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                // 返回空值, 什么都不处理
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.invasiveComprehensiveData:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistoryComprehensiveMeasureData, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long startTimeStamp = (long) obj.get("time") / 1000;

                                    // 血糖
                                    int bloodGlucoseMode = (int) obj.get("bloodSugarModel");
                                    int bloodSugarInteger = (int) obj.get("bloodSugarInteger");
                                    int bloodSugarFloat = (int) obj.get("bloodSugarFloat");
                                    String bloodGlucose = bloodSugarInteger + "." + bloodSugarFloat;

                                    // 尿酸
                                    int uricAcidMode = (int) obj.get("uricAcidModel");
                                    int uricAcid = (int) obj.get("uricAcid");

                                    // 血酮
                                    int bloodKetoneMode = (int) obj.get("bloodKetoneModel");
                                    int bloodKetoneInteger = (int) obj.get("bloodKetoneInteger");
                                    int bloodKetoneFloat = (int) obj.get("bloodKetoneFloat");
                                    String bloodKetone = bloodKetoneInteger + "." + bloodKetoneFloat;

                                    // 血脂
                                    int bloodFatMode = (int) obj.get("bloodFatModel");

                                    int totalCholesterolInt = (int) obj.get("cholesterolInteger");
                                    int totalCholesterolFloat = (int) obj.get("cholesterolFloat");

                                    String delimiter = totalCholesterolFloat >= 10 ? "" : "0";

                                    String totalCholesterol = totalCholesterolInt + "." + delimiter + totalCholesterolFloat;

                                    int hdlCholesterolInt = (int) obj.get("highLipoproteinCholesterolInteger");
                                    int hdlCholesterolFloat = (int) obj.get("highLipoproteinCholesterolFloat");
                                    delimiter = hdlCholesterolFloat >= 10 ? "" : "0";

                                    String hdlCholesterol = hdlCholesterolInt + "." + delimiter + hdlCholesterolFloat;

                                    int lowLipoproteinCholesterolInteger = (int) obj.get("lowLipoproteinCholesterolInteger");
                                    int lowLipoproteinCholesterolFloat = (int) obj.get("lowLipoproteinCholesterolFloat");
                                    delimiter = lowLipoproteinCholesterolFloat >= 10 ? "" : "0";
                                    String ldlCholesterol = lowLipoproteinCholesterolInteger + "." + delimiter + lowLipoproteinCholesterolFloat;

                                    int triglycerideCholesterolInteger = (int) obj.get("triglycerideCholesterolInteger");
                                    int triglycerideCholesterolFloat = (int) obj.get("triglycerideCholesterolFloat");
                                    delimiter = triglycerideCholesterolFloat >= 10 ? "" : "0";
                                    String triglycerides = triglycerideCholesterolInteger + "." + delimiter + triglycerideCholesterolFloat;


                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", startTimeStamp);

                                    info.put("bloodGlucoseMode", bloodGlucoseMode);
                                    info.put("bloodGlucose", bloodGlucose);

                                    info.put("uricAcidMode", uricAcidMode);
                                    info.put("uricAcid", uricAcid);

                                    info.put("bloodKetoneMode", bloodKetoneMode);
                                    info.put("bloodKetone", bloodKetone);

                                    info.put("bloodFatMode", bloodFatMode);
                                    info.put("totalCholesterol", totalCholesterol);
                                    info.put("hdlCholesterol", hdlCholesterol);
                                    info.put("ldlCholesterol", ldlCholesterol);
                                    info.put("triglycerides", triglycerides);

                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                // 返回空值, 什么都不处理
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.sportHistoryData:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistorySportMode, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long startTimeStamp = (long) obj.get("startTime") / 1000;
                                    long endTimeStamp = (long) obj.get("endTime") / 1000;

                                    int flag = (int) obj.get("startMethod");
                                    long sportTime = (long) obj.get("sportTime");
                                    int sportType = (int) obj.get("sportMode");

                                    long step = (long) obj.get("sportSteps");
                                    int distance = (int) obj.get("sportDistances");
                                    int calories = (int) obj.get("sportCalories");

                                    int heartRate = (int) obj.get("sportHeartRate");
                                    int minimumHeartRate = (int) obj.get("minHeartRate");
                                    int maximumHeartRate = (int) obj.get("maxHeartRate");

                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", startTimeStamp);
                                    info.put("endTimeStamp", endTimeStamp);

                                    info.put("step", step);
                                    info.put("distance", distance);
                                    info.put("calories", calories);

                                    info.put("heartRate", heartRate);
                                    info.put("minimumHeartRate", minimumHeartRate);
                                    info.put("maximumHeartRate", maximumHeartRate);

                                    info.put("flag", flag);
                                    info.put("sportTime", sportTime);
                                    info.put("sportType", sportType);

                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                // 返回空值, 什么都不处理
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;
            case YcProductPluginFlutterType.HealthDataType.bodyIndexData:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_History_Body_Data, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();

                        if (0 == i && hashMap != null) {

                            try {

                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long startTimeStamp = (long) obj.get("time") / 1000;
                                    long endTimeStamp = (long) obj.get("time") / 1000;

                                    int loadIndexInteger = (int) obj.get("loadIndexInteger");
                                    int loadIndexFloat = (int) obj.get("loadIndexFloat");
                                    int hrvInteger = (int) obj.get("hrvInteger");
                                    int hrvFloat = (int) obj.get("hrvFloat");
                                    int bodyInteger = (int) obj.get("bodyInteger");
                                    int bodyFloat = (int) obj.get("bodyFloat");

                                    int sympatheticInteger = (int) obj.get("sympatheticInteger");
                                    int sympatheticFloat = (int) obj.get("sympatheticFloat");
                                    int sdn = (int)obj.get("sdn");


                                    int pressureInteger = (int) obj.get("pressureInteger");
                                    int pressureFloat = (int) obj.get("pressureFloat");
                                    int maximalOxygenIntake=0;
                                    if(hashMap.get("maximalOxygenIntake")!=null) {
                                         maximalOxygenIntake = (int) hashMap.get("maximalOxygenIntake");
                                    }

                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", startTimeStamp);
                                    info.put("endTimeStamp", endTimeStamp);

                                    info.put("loadIndex",loadIndexInteger+"."+loadIndexFloat);
                                    info.put("hrvIndex",hrvInteger+"."+hrvFloat);

                                    info.put("bodyIndex",bodyInteger+"."+bodyFloat);
                                    info.put("sympatheticActivityIndex",sympatheticInteger+"."+sympatheticFloat);

                                    info.put("sdnHRV",sdn);

                                    info.put("pressureIndex", pressureInteger+"."+pressureFloat);
                                    info.put("vo2max", maximalOxygenIntake);

                                    datas.add(info);
                                }

                            } catch (Exception e) {

                                e.printStackTrace();
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;
            case YcProductPluginFlutterType.HealthDataType.WearingStatus:
                YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistoryWearingStatus, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        Log.d("WearingStatus","hashMap:"+hashMap);
                        int state = YcProductPlugin.convertPluginState(i);
                        ArrayList datas = new ArrayList();


                        if (0 == i && hashMap != null) {
                            try {

                                int dataType = (int) hashMap.get("dataType");
                                ArrayList list = (ArrayList) hashMap.get("data");

                                for (int index = 0; index < list.size(); index++) {

                                    HashMap obj = (HashMap) list.get(index);

                                    long time = (long) obj.get("time") / 1000;
                                    int status= (int)obj.get("status");


                                    HashMap info = new HashMap();
                                    info.put("startTimeStamp", time+"");
                                    info.put("YCWearingType", status+"");


                                    datas.add(info);
                                }
                            } catch (Exception e) {

                                e.printStackTrace();
                            }
                        }

                        HashMap map = new HashMap();
                        map.put("code", state);
                        map.put("data", datas);
                        result.success(map);
                    }
                });
                break;
            default:
                break;
        }
    }


    /**
     * 删除历史健康数据
     *
     * @param arguments YcProductPluginFlutterType.HealthDataType 类型
     * @param result
     */
    public static void deleteDeviceHealthData(Object arguments, @NonNull MethodChannel.Result result) {

        int dataType = (int) arguments;

        switch (dataType) {
            case YcProductPluginFlutterType.HealthDataType.step:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteSport, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);

                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.sleep:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteSleep, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.heartRate:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteHeart, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.bloodPressure:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteBlood, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.combinedData:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteAll, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.invasiveComprehensiveData:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteComprehensiveMeasureData, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.sportHistoryData:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteSportMode, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;

            case YcProductPluginFlutterType.HealthDataType.bodyIndexData:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteBodyData, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;
            case YcProductPluginFlutterType.HealthDataType.WearingStatus:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteHistoryWearingStatus, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        HashMap map = new HashMap();
                        map.put("code", YcProductPlugin.convertPluginState(i));
                        map.put("data", "");
                        result.success(map);
                    }
                });
                break;
            default:
                break;
        }
    }


}
