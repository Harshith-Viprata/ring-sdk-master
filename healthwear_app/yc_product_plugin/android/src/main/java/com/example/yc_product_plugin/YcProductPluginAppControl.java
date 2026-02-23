package com.example.yc_product_plugin;

import android.util.Log;

import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;

import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;

public class YcProductPluginAppControl {

    /**
     * 发送手机唯一识别码给设备
     * @param arguments
     * @param result
     */
    public static void sendPhoneUUIDToDevice(Object arguments, @NonNull MethodChannel.Result result) {

        String content = (String) arguments;

        YCBTClient.appSendUUID(content, new BleDataResponse() {
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
         * 发送生理周期
         * @param arguments
         * @param result
         */
    public static void sendDeviceMenstrualCycle(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 3) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int time = (int) list.get(0);
        int duration = (int) list.get(1);
        int cycle = (int) list.get(2);

        YCBTClient.appPushFemalePhysiological(time, duration, cycle, new BleDataResponse() {
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
     *
     * @param arguments
     * @param result
     */
    public static void findDevice(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int remindNum = (int) list.get(0);
        int remindInterval = (int) list.get(1);

        YCBTClient.appFindDevice(1, remindNum, remindInterval, new BleDataResponse() {
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
     *
     * @param arguments
     * @param result
     */
    public static void deviceSystemOperator(Object arguments, @NonNull MethodChannel.Result result) {

        int mode = (int) arguments;

        YCBTClient.appShutDown(mode, new BleDataResponse() {
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
     *
     * @param arguments
     * @param result
     */
    public static void bloodPressureCalibration(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int sbp = (int) list.get(0);
        int dbp = (int) list.get(1);

        YCBTClient.appBloodCalibration(sbp, dbp, new BleDataResponse() {
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
     *
     * @param arguments
     * @param result
     */
    public static void temperatureCalibration(Object arguments, @NonNull MethodChannel.Result result) {
        YCBTClient.appTemperatureCorrect(0, 0, new BleDataResponse() {
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
     *
     * @param arguments
     * @param result
     */
    public static void bloodGlucoseCalibration(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 3) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int type = (int) list.get(0);
        int intValue = (int) list.get(1);
        int floatValue = (int) list.get(2);

        YCBTClient.appBloodSugarCalibration(intValue, floatValue, type, new BleDataResponse() {
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
     * 今日天气
     * @param arguments
     * @param result
     */
    public static void waveDataUpload(Object arguments, @NonNull MethodChannel.Result result) {

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

        YCBTClient.appControlWave(state, dataType,  new BleDataResponse() {
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
     * 今日天气
     * @param arguments
     * @param result
     */
    public static void sendTodayWeather(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 4) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int type = (int) list.get(0);
        int lowestTemperature = (int) list.get(1);
        int highestTemperature = (int) list.get(2);
        int realTimeTemperature = (int) list.get(3);

        YCBTClient.appTodayWeather(lowestTemperature + "", highestTemperature + "", realTimeTemperature + "", type, new BleDataResponse() {
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
     * 明日天气
     * @param arguments
     * @param result
     */
    public static void sendTomorrowWeather(Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList list = (ArrayList) arguments;

        if (list.size() < 4) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int type = (int) list.get(0);
        int lowestTemperature = (int) list.get(1);
        int highestTemperature = (int) list.get(2);
        int realTimeTemperature = (int) list.get(3);

        YCBTClient.appTomorrowWeather(lowestTemperature + "", highestTemperature + "", realTimeTemperature + "", type, new BleDataResponse() {
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
     * 尿酸标定
     * @param arguments
     * @param result
     */
    public static void uricAcidCalibration(Object arguments, @NonNull MethodChannel.Result result) {

        int uricAcid = (int) arguments;

        YCBTClient.appUricAcidCalibration(0, uricAcid, new BleDataResponse() {
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
     * 血脂标定
     * @param arguments
     * @param result
     */
    public static void bloodFatCalibration(Object arguments, @NonNull MethodChannel.Result result) {
        String value = (String) arguments;

        int intValue = (int)Double.parseDouble(value);
        int value1 = (int) (Double.parseDouble(value) * 100);

        YCBTClient.appLipidCalibration(0, value1 / 100, value1 % 100, new BleDataResponse() {
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
     * 消息推送
     * @param arguments
     * @param result
     */
    public static void appPushNotifications(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 3) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int type = (int) list.get(0);
        String title = (String) list.get(1);
        String contents = (String) list.get(2);

        YCBTClient.appSengMessageToDevice(type, title, contents, new BleDataResponse() {
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
     * 查询名片
     * @param arguments
     * @param result
     */
    public static void queryBusinessCard(Object arguments, @NonNull MethodChannel.Result result) {
        int cardType = (int) arguments;

        YCBTClient.getCardInfo(cardType, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);
                String data = "";

                if (i == 0 && hashMap != null) {
                  data = (String) hashMap.get("data");
                }

                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", data);
                result.success(map);

            }
        });
    }

    /**
     * 设置名片
     * @param arguments
     * @param result
     */
    public static void sendBusinessCard(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int type = (int)list.get(0);
        String content = (String)list.get(1);

        YCBTClient.appSendCardNumber(type, content, new BleDataResponse() {
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


}
