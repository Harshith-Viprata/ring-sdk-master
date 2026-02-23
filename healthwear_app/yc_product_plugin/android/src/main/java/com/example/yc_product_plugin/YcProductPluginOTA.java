package com.example.yc_product_plugin;

import android.content.Context;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.upgrade.DfuCallBack;

import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;
import com.yucheng.ycbtsdk.response.BleConnectResponse;

public class YcProductPluginOTA {


    /**
     * 固件升级
     *
     * @param context
     * @param arguments
     * @param result
     */
    public static void deviceUpgrade(MethodChannel methodChannel, Handler handler, Context context, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            result.success(null);
            return;
        }

        int mcu = (int) list.get(0);
        String filePath = (String) list.get(1);

        String macAddress = YCBTClient.getBindDeviceMac();
        String deviceName = YCBTClient.getBindDeviceName();

        result.success(null);

        HashMap info = new HashMap();
        info.clear();


        info.put("code", YcProductPluginFlutterType.DeviceUpdateState.start);
        info.put("progress", "0.0");
        info.put("error", "");

        methodChannel.invokeMethod("upgradeState", info);
        Log.d("startBleStateChange","startBleStateChange111");
        handler.post(new Runnable() {
            @Override
            public void run() {

                YCBTClient.setOta(true);
                // YCBTClient.registerBleStateChange(null);

                Log.d("registerBleStateChange","onConnectResponse");

               DfuCallBack dfuCallBack = new DfuCallBack() {

                   @Override
                   public void progress(int i) {
//                        Log.d("")
Log.d("startBleStateProgress","startBleStateProgress:"+i);
                       info.clear();

                       info.put("code", YcProductPluginFlutterType.DeviceUpdateState.upgradingFirmware);
                       info.put("progress", String.format("%.2f", i * 0.01));
                       info.put("error", "");

                       methodChannel.invokeMethod("upgradeState", info);
                   }

                   @Override
                   public void success() {
                       Log.d("startBleStateSuccess","startBleStateSuccess:"+"success");
                       YCBTClient.setOta(false);
                       info.clear();

                       info.put("code", YcProductPluginFlutterType.DeviceUpdateState.succeed);
                       info.put("progress", "1.0");
                       info.put("error", "");

                       methodChannel.invokeMethod("upgradeState", info);


                   }

                   @Override
                   public void failed(String s) {
                       Log.d("startBleStateFail","startBleStateFail:"+s);
                       YCBTClient.setOta(false);
                       info.clear();

                       info.put("code", YcProductPluginFlutterType.DeviceUpdateState.failed);
                       info.put("progress", "0.0");
                       info.put("error", s);

                       handler.post(new Runnable() {
                           @Override
                           public void run() {
                               methodChannel.invokeMethod("upgradeState", info);
                           }
                       });
                       // methodChannel.invokeMethod("upgradeState", info);
                   }

                   @Override
                   public void disconnect() {
                       Log.e("MARK", "disconnect: ");
                   }

                   @Override
                   public void onNeedReconnect(String s, boolean b) {

                   }

                   @Override
                   public void connecting() {
                       Log.e("MARK", "connecting: ");
                   }

                   @Override
                   public void connected() {
                       Log.e("MARK", "connected: ");
                   }

                   @Override
                   public void latest() {
                       Log.e("MARK", "latest: ");
                   }

                   @Override
                   public void error(String s) {
                       Log.d("失败","失败原因:"+s);
                       YCBTClient.setOta(false);
                       info.clear();

                       info.put("code", YcProductPluginFlutterType.DeviceUpdateState.failed);
                       info.put("progress", "0.0");
                       info.put("error", s);

                       methodChannel.invokeMethod("upgradeState", info);
                   }
               };

               YCBTClient.registerBleStateChange(new BleConnectResponse() {
                   @Override
                   public void onConnectResponse(int code) {
                       Log.d("registerBleStateChange","code="+code);
                       // if (code == com.yucheng.ycbtsdk.Constants.BLEState.ReadWriteOK){
                            if (code == 0x0a && YCBTClient.isOta()){
                               YCBTClient.upgradeFirmware(context, null, null, filePath,dfuCallBack);
                            }

                   }
               });

               // YCBTClient.resetQueue();
               Log.d("开始升级","开始升级:"+macAddress+","+"deviceName"+deviceName+",filePath"+filePath);

               // 开始升级
               YCBTClient.upgradeFirmware(context, macAddress, deviceName, filePath, dfuCallBack
               );

            }
        });


    }


}
