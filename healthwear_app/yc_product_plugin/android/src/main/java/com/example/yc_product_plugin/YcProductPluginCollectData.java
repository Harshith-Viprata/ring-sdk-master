package com.example.yc_product_plugin;

import android.util.Log;

import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class YcProductPluginCollectData {

    /**
     * 查询基本信息
     *
     * @param arguments
     * @param result
     */
    public static void queryCollectDataBasicInfo(Object arguments, @NonNull MethodChannel.Result result) {

        int dataType = (int) arguments;
        ArrayList items = new ArrayList();

        YCBTClient.collectHistoryListData(dataType, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                if (i == 0 && hashMap != null) {

                    ArrayList datas = (ArrayList) hashMap.get("data");



                    for (int i1 = 0; i1 < datas.size(); i1++) {

                        Map item = (Map) datas.get(i1);


                        int index = (int) item.get("collectSN");
                        int timeStamp = (int) ((long) item.get("collectStartTime") / 1000);
                        int packages = (int) item.get("collectBlockNum");
                        int totalBytes = (int) item.get("collectTotalLen");
                        int samplesCount = (int) item.get("collectDigits");

                        HashMap info = new HashMap();

                        info.put("dataType", dataType);
                        info.put("index", index);
                        info.put("timeStamp", timeStamp);
                        info.put("packages", packages);
                        info.put("totalBytes", totalBytes);
//                        info.put("samplesCount", samplesCount);

                        items.add(info);

                    }
                }

                HashMap map = new HashMap();
                map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                map.put("data", items);
                result.success(map);
            }
        });
    }

    /***
     * 查询数据
     * @param arguments
     * @param result
     */
    public static void queryCollectDataInfo(Object arguments, @NonNull MethodChannel.Result result) {


        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int dataType = (int) list.get(0);
        int index = (int) list.get(1);

        YCBTClient.collectHistoryDataWithIndex(dataType, index, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                Log.i("LHY", "collectHistoryDataWithIndex: " + hashMap);
            }
        });
    }

    /**
     * 删除采集数据
     */
    public static void deleteCollectData(Object arguments, @NonNull MethodChannel.Result result) {

        Log.i("LHY", "deleteCollectData: 123");
        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int dataType = (int) list.get(0);
        int index = (int) list.get(1);

        YCBTClient.deleteHistoryListData(dataType, index, new BleDataResponse() {
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
