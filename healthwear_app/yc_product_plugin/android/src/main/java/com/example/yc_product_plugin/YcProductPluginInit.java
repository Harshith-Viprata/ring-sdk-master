package com.example.yc_product_plugin;

import android.content.Context;

import androidx.annotation.NonNull;

import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechUtility;
import com.yucheng.ycbtsdk.YCBTClient;

import java.util.ArrayList;

import io.flutter.plugin.common.MethodChannel;
import com.yucheng.ycbtsdk.gatt.BleHelper;
import com.yucheng.ycbtsdk.gatt.Reconnect;
import com.yucheng.ycbtsdk.response.BleConnectResponse;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleScanResponse;

public class YcProductPluginInit {

    // MARK: - 初始化方法
    public static void initPlugin(Context context, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList<Boolean> list = (ArrayList<Boolean>) arguments;
        Boolean isReconnectEnable = list.get(0);
        Boolean isLogEnable = list.get(1);

        SpeechUtility.createUtility(context, SpeechConstant.APPID + "=eac7ae72");

        // 调用SDK
        YCBTClient.initClient(context, isReconnectEnable, isLogEnable);
        result.success(null);
    }

    /**
     * 清除队列
     * @param result
     */
    public static void clearQueue(@NonNull MethodChannel.Result result) {
        YCBTClient.resetQueue();
        result.success(null);
    }


    // 设置回连
    public static void setReconnectEnabled(Object arguments, @NonNull MethodChannel.Result result) {
        Boolean isReconnectEnable = (Boolean)arguments;
        // 暂时没有实现
        Reconnect.getInstance().setReconnect(isReconnectEnable);
        result.success(null);
    }

    //重置配对过程
    public static void resetBond(Object arguments, @NonNull MethodChannel.Result result) {
        YCBTClient.resetBond();
        result.success(null);
    }

    public static void exitScanDevice(Object arguments, @NonNull MethodChannel.Result result) {
        YCBTClient.exitScanDevice();
        result.success(null);
    }
}
