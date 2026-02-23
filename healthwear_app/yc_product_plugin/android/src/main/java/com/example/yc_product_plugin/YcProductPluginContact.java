package com.example.yc_product_plugin;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.MethodChannel;

import com.jieli.jl_rcsp.task.SimpleTaskListener;
import com.jieli.jl_rcsp.task.contacts.DeviceContacts;
import com.jieli.jl_rcsp.task.contacts.UpdateContactsTask;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.ContactsBean;
import com.yucheng.ycbtsdk.jl.WatchManager;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.utils.ByteUtil;

import java.util.ArrayList;
import java.util.HashMap;

public class YcProductPluginContact {

    /**
     * 更新通讯录
     *
     * @param arguments
     * @param result
     */
    public static void updateDeviceContacts(Context context, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList datas = (ArrayList) arguments;

        if (datas.size() == 0) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        ArrayList<ContactsBean> items = new ArrayList<ContactsBean>();

        // 准备同步
        for (int j = 0; j < datas.size(); j++) {
            HashMap info = (HashMap) datas.get(j);
            ContactsBean bean = new ContactsBean((short) j, (String) info.get("name"), (String) info.get("phone"));
            items.add(bean);
        }

        // 开启
        YCBTClient.appPushContactsSwitch(2, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                if (0 != i) {
//                    int state = YcProductPlugin.convertPluginState(i);
                    HashMap map = new HashMap();
                    map.put("code", YcProductPluginFlutterType.PluginState.failed);
                    map.put("data", "");
                    result.success(map);
                    return;
                }


                YCBTClient.appNewPushContacts(context, items, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                        if (0 != i) {
//                            int state = YcProductPlugin.convertPluginState(i);
                            HashMap map = new HashMap();
                            map.put("code", YcProductPluginFlutterType.PluginState.failed);
                            map.put("data", "");
                            result.success(map);
                            return;
                        }

                        YCBTClient.appPushContactsSwitch(0, new BleDataResponse() {
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
                });

            }
        });
    }

    /**
     * 更新杰理通讯录
     *
     * @param arguments
     * @param result
     */
    public static void updateJieLiDeviceContacts(Context context, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList datas = (ArrayList) arguments;

        if (datas.size() == 0) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        ArrayList<DeviceContacts> items = new ArrayList<DeviceContacts>();

        // 准备同步
        for (int j = 0; j < datas.size(); j++) {
            HashMap info = (HashMap) datas.get(j);
            String name = (String) info.get("name");
            String phone = (String) info.get("phone");

            if (name != null) {
                name = ByteUtil.getData(name, 20);
            }

            if (phone != null) {
                phone = ByteUtil.getData(phone, 20);
            }

            DeviceContacts bean = new DeviceContacts((short) j, name, phone);
            items.add(bean);
        }

        // 同步通讯录
        UpdateContactsTask task = new UpdateContactsTask(WatchManager.getInstance(), context, items);
        task.setListener(new SimpleTaskListener() {
            @Override
            public void onBegin() {

            }

            @Override
            public void onError(int code, String msg) {

                HashMap map = new HashMap();
                map.put("code", YcProductPluginFlutterType.PluginState.failed);
                map.put("data", "");
                result.success(map);
            }

            @Override
            public void onFinish() {

                HashMap map = new HashMap();
                map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                map.put("data", "");
                result.success(map);
            }
        });

        task.start();

    }


    /**
     * 查询杰理通讯录
     *
     * @param arguments
     * @param result
     */
    public static void queryJieLiDeviceContacts(Context context, Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.getDeviceContacts(context, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                ArrayList items = new ArrayList();

                if (hashMap != null && hashMap.get("data") != null) {
                    ArrayList<ContactsBean> beans = (ArrayList) hashMap.get("data");

                    for (ContactsBean bean : beans) {

                        HashMap info = new HashMap();
                        info.put("name", bean.name);
                        info.put("phone", bean.number);
                        items.add(info);
                    }
                }

                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", items);
                result.success(map);
            }
        });
    }
}
