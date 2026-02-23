package com.example.yc_product_plugin;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.provider.CalendarContract;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.iflytek.cloud.ErrorCode;
import com.iflytek.cloud.InitListener;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechRecognizer;

import com.wevey.selector.dialog.DialogInterface;
import com.wevey.selector.dialog.MDAlertDialog;
import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.ScanDeviceBean;
import com.yucheng.ycbtsdk.response.BleConnectResponse;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleScanListResponse;
import com.yucheng.ycbtsdk.response.BleScanResponse;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

public class YcProductPluginDevice {

    static boolean isNeedReplay = true;

    static ArrayList<Map<String, Object>> list = new ArrayList<Map<String, Object>>();


    static ArrayList<Map<String, BluetoothDevice>> deviceList = new ArrayList<Map<String, BluetoothDevice>>();

    private static SpeechRecognizer mIat;

    private static HashMap<String, String> mIatResults = new LinkedHashMap<>();

    private Toast mToast;


    private static int ret = 0;

    private static InitListener mInitListener = new InitListener() {

        @Override
        public void onInit(int code) {
            Log.d("test onInit", "SpeechRecognizer init() code = " + code);
            if (code != ErrorCode.SUCCESS) {
                Log.d("test onInit","初始化失败，错误码：" + code);
            }
        }
    };

    /**
     * 连接设备
     *
     * @param arguments
     * @param result
     */
    public static void connectDevice(Object arguments, @NonNull MethodChannel.Result result) {

        Log.d("MARK-", "发起设备连接 Android connectDevice : ");
        isNeedReplay = true;
        String macAddress = (String) arguments;
        BluetoothDevice device = null;
        for (int i = 0; i < deviceList.size(); i++) {
            if (deviceList.get(i).containsKey(macAddress)) {
                device = deviceList.get(i).get(macAddress);
            }
//            if(deviceList.get(i).get("macAddress")!=null) {
//                if (deviceList.get(i).get("macAddress").equals(macAddress)) {
//                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR) {
//                       device=(BluetoothDevice)deviceList.get(i).get("device");
//                    }
//                    break;
//                }
//            }
        }
        if (device != null) {
            YCBTClient.connectBleDevice(device, new BleConnectResponse() {
                @Override
                public void onConnectResponse(int i) {

                    if (isNeedReplay == false) {
                        return;
                    }

                    Log.d("MARK-", "设备连接 onConnectResponse: " + i);

                    isNeedReplay = false;
                    result.success(0 == i ||
                            YCBTClient.connectState() == Constants.BLEState.ReadWriteOK);
                }
            });
        }
    }

    /**
     * 断开设备连接
     *
     * @param arguments
     * @param result
     */
    public static void disConnectDevice(Object arguments, @NonNull MethodChannel.Result result) {
        String macAddress = (String) arguments;
        YCBTClient.disconnectBle();
        result.success(true);
    }


    /**
     * 停止扫描
     *
     * @param result
     */
    public static void stopScanDevice(@NonNull MethodChannel.Result result) {

        YCBTClient.stopScanBle();
        result.success(null);
    }

    /**
     * 搜索设备
     *
     * @param result
     */
    public static void scanDevice(Context context, Object arguments, @NonNull MethodChannel.Result result) {


        if (!hasPermission(context)) {
            return;
        }
        YCBTClient.stopScanBle();
        int time = (int) arguments; // 这里是秒

        list.clear();

//        YCBTClient.startScanBle(new BleScanResponse() {
//            @Override
//            public void onScanResponse(int i, ScanDeviceBean scanDeviceBean) {
//                Log.d("LHY", "获取设备: onScanResponse");
//                if (scanDeviceBean != null) {
//
//                    Log.d("LHY", "获取设备: " + scanDeviceBean.getDeviceName() + ", " +
//                            scanDeviceBean.getDeviceMac() + "," + scanDeviceBean.getDeviceRssi());
//
//                    Map<String, Object> deviceInfo =
//                            new HashMap<String, Object>();
//                    if(TextUtils.isEmpty(scanDeviceBean.getDeviceName())){
//                        String name = SharedPrefesHelper.getSharedPreferences(context,"flutter").getString(scanDeviceBean.getDeviceMac(),"");
//                        deviceInfo.put("name", name);
//                    }else{
//                        deviceInfo.put("name", scanDeviceBean.getDeviceName());
//                        SharedPrefesHelper.getSharedPreferences(context,"flutter").edit().putString(scanDeviceBean.getDeviceMac(),scanDeviceBean.getDeviceName());
//                    }
//
//                    deviceInfo.put("macAddress", scanDeviceBean.getDeviceMac());
//                    deviceInfo.put("deviceIdentifier", scanDeviceBean.getDeviceMac());
//                    deviceInfo.put("rssiValue", scanDeviceBean.getDeviceRssi());
//
//                    deviceInfo.put("deviceColor", scanDeviceBean.ringColor);
//                    deviceInfo.put("deviceIndex", scanDeviceBean.ringNumber);
//                    deviceInfo.put("imageIndex", scanDeviceBean.imageId);
//
//                    boolean isHasDevice = false;
//                     for (int j = 0; j < list.size(); j++) {
//                         if (scanDeviceBean.getDeviceMac().equals(list.get(j).get("macAddress"))) {
////                             isHasDevice = true;
////                             break;
//                             list.remove(j);
//                             j--;
//                         }
//                     }
//                //    if (!isHasDevice) {
//                        list.add(deviceInfo);
//                  //  }
//
//                } else {
//                    Log.d("LHY", "获取设备: null");
//                }
//            }
//        }, time);

        int productId = 0x7810;

        int timeOut = time;
        YCBTClient.startScanBle( new BleScanResponse() {
            @Override
            public void onScanResponse(int code, ScanDeviceBean scanDeviceBean) {

                Log.d("LHY", "获取设备: onScanResponse");
                if (scanDeviceBean != null) {

                    Log.d("LHY", "获取设备: " + scanDeviceBean.getDeviceName() + ", " +
                            scanDeviceBean.getDeviceMac() + "," + scanDeviceBean.getDeviceRssi());

                    Map<String, Object> deviceInfo =
                            new HashMap<String, Object>();
                    if (TextUtils.isEmpty(scanDeviceBean.getDeviceName())) {
                        deviceInfo.put("name", scanDeviceBean.getDeviceMac());
                    } else {
                        deviceInfo.put("name", scanDeviceBean.getDeviceName());
                    }

                    deviceInfo.put("macAddress", scanDeviceBean.getDeviceMac());
                    deviceInfo.put("deviceIdentifier", scanDeviceBean.getDeviceMac());
                    deviceInfo.put("rssiValue", scanDeviceBean.getDeviceRssi());

                    deviceInfo.put("deviceColor", scanDeviceBean.ringColor);
                    deviceInfo.put("deviceIndex", scanDeviceBean.ringNumber);
                    deviceInfo.put("imageIndex", scanDeviceBean.imageId);


                    Map<String, BluetoothDevice> deviceInfo2 =
                            new HashMap<String, BluetoothDevice>();
                    deviceInfo2.put(scanDeviceBean.getDeviceMac(), scanDeviceBean.device);

                    boolean isHasDevice = false;
                    for (int j = 0; j < list.size(); j++) {
                        if (scanDeviceBean.getDeviceMac().equals(list.get(j).get("macAddress"))) {
//                             isHasDevice = true;
//                             break;
                            list.remove(j);
                            j--;
                        }
                    }
                    //    if (!isHasDevice) {
                    list.add(deviceInfo);
                    deviceList.add(deviceInfo2);
                    //  }

                } else {
                    Log.d("LHY", "获取设备: null");
                }
            }

            @NonNull
            private List<ScanDeviceBean> getScanDeviceBeanList(List<ScanDeviceBean> scanBean, String etText) {
                String lowerCase = etText.toLowerCase();
                List<ScanDeviceBean> scanBeanTemp = new ArrayList<>();
                for (int i = 0; i < scanBean.size(); i++) {
                    ScanDeviceBean scanDeviceBean1 = scanBean.get(i);
                    if (scanDeviceBean1.getDeviceName().toLowerCase().contains(lowerCase)) {
                        scanBeanTemp.add(scanDeviceBean1);
                    }
                }
                return scanBeanTemp;
            }
        }, timeOut, 0);//0x7810

        // 定时任务
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                result.success(list);
            }
        }, time * 1000);
    }


    /**
     * 设置蓝牙状态监听
     */
    public static void setupDeviceStateObserver(
            Handler handler,
            EventChannel.EventSink eventSink) {

        YCBTClient.registerBleStateChange(code -> {
            int state = setupBlutetoothState(code);
            Log.d("LHY", "setupDeviceStateObserver: 蓝牙状态" + state);

            Map map = new HashMap();
            map.put(YcProductPluginFlutterType.NativeEventType.bluetoothStateChange, state);

            // 如果是DFU怎么办
            if (code == Constants.BLEState.ReadWriteOK) {

                Map<String, Object> deviceInfo =
                        new HashMap<String, Object>();

                deviceInfo.put("name", YCBTClient.getBindDeviceName());
                deviceInfo.put("macAddress", YCBTClient.getBindDeviceMac());
                deviceInfo.put("deviceIdentifier", YCBTClient.getBindDeviceMac());
                deviceInfo.put("rssiValue", 0);

                map.put(YcProductPluginFlutterType.NativeEventType.deviceInfo, deviceInfo);
            }

            handler.post(new Runnable() {
                @Override
                public void run() {
                    eventSink.success(map);
                }
            });


        });
    }

    public static boolean hasPermission(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED
                    || ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {

                return false;
            }
        }
        return true;
    }

    /**
     * 获取当前状态
     *
     * @param result
     */
    public static void getBluetoothState(@NonNull MethodChannel.Result result) {
        int state = setupBlutetoothState(YCBTClient.connectState());
        result.success(state);
    }

    /**
     * 关机
     */

    public static void shutdown(@NonNull MethodChannel.Result result) {
        YCBTClient.appShutDown(1, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

            }
        });
        result.success(0);
    }

    /**
     * 适配蓝牙状态
     *
     * @param getState
     * @return
     */
    private static int setupBlutetoothState(int getState) {

        int state =
                YcProductPluginFlutterType.BluetoothState.off;

        if (getState == Constants.BLEState.ReadWriteOK) {
            state = YcProductPluginFlutterType.BluetoothState.connected;
        } else if (getState == Constants.BLEState.TimeOut) {
            state = YcProductPluginFlutterType.BluetoothState.connectFailed;
        } else if (getState == Constants.BLEState.Disconnect) {
            state = YcProductPluginFlutterType.BluetoothState.disconnected;
        } else if (getState == Constants.BLEState.NotOpen) {
            state = YcProductPluginFlutterType.BluetoothState.off;
        } else {
            state = YcProductPluginFlutterType.BluetoothState.on;
        }

        return state;
    }

    public static void startListening(ActivityPluginBinding activityPluginBinding,Context context,@NonNull MethodChannel.Result result) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            // 请求权限
            ActivityCompat.requestPermissions(activityPluginBinding.getActivity(), new String[]{Manifest.permission.RECORD_AUDIO}, 1);
        } else {
            setParam(context);
            ret = mIat.startListening(new RecognizerListener() {

                @Override
                public void onBeginOfSpeech() {

                }

                @Override
                public void onError(SpeechError error) {
                    Log.d("test", "onError " + error.getPlainDescription(true));
                }

                @Override
                public void onEndOfSpeech() {

                }

                @Override
                public void onResult(RecognizerResult results, boolean isLast) {
                    Log.d("test", results.getResultString());
                    if (isLast) {
                        Log.d("test", "onResult 结束");
                    }
                  //  result.success(results.getResultString());
                     printResult(results,result);
                }

                @Override
                public void onVolumeChanged(int volume, byte[] data) {

                }

                @Override
                public void onEvent(int eventType, int arg1, int arg2, Bundle obj) {

                }
            });
            Log.d("test", ret + "");
        }
    }


    /**
     * 显示结果
     */
    private static void printResult(RecognizerResult results,@NonNull MethodChannel.Result result) {
        String text = JsonParser.parseIatResult(results.getResultString());
        String sn = null;
        // 读取json结果中的sn字段
        try {
            JSONObject resultJson = new JSONObject(results.getResultString());
            sn = resultJson.optString("sn");
        } catch (JSONException e) {
            e.printStackTrace();
        }

        mIatResults.put(sn, text);

        StringBuffer resultBuffer = new StringBuffer();
        for (String key : mIatResults.keySet()) {
            resultBuffer.append(mIatResults.get(key));
        }
        HashMap map = new HashMap();
        map.put("code", YcProductPluginFlutterType.PluginState.succeed);
        map.put("data", resultBuffer.toString());
        result.success(map);
    }


    /**
     * 听写UI监听器
     */
//    private val mRecognizerDialogListener: RecognizerDialogListener =
//        object : RecognizerDialogListener {
//
//            override fun onResult(p0: RecognizerResult?, p1: Boolean) {
//
//            }
//
//            override fun onError(error: SpeechError) {
//                showTip(error.getPlainDescription(true))
//            }
//        }

    /**
     * 参数设置
     *
     * @return
     */
    public static void setParam(Context context) {
        mIat = SpeechRecognizer.createRecognizer(context, mInitListener);
        // 清空参数
        mIat.setParameter(SpeechConstant.PARAMS, null);
        // 设置听写引擎
        mIat.setParameter(SpeechConstant.ENGINE_TYPE, SpeechConstant.TYPE_CLOUD);
        // 设置返回结果格式
        mIat.setParameter(SpeechConstant.RESULT_TYPE, "json");

        mIat.setParameter(SpeechConstant.LANGUAGE, "zh_cn");
        mIat.setParameter(SpeechConstant.ACCENT, "mandarin");

        //此处用于设置dialog中不显示错误码信息
        //mIat.setParameter("view_tips_plain","false");

        // 设置语音前端点:静音超时时间，即用户多长时间不说话则当做超时处理
        mIat.setParameter(SpeechConstant.VAD_BOS, "4000");

        // 设置语音后端点:后端点静音检测时间，即用户停止说话多长时间内即认为不再输入， 自动停止录音
        mIat.setParameter(SpeechConstant.VAD_EOS, "1000");

        // 设置标点符号,设置为"0"返回结果无标点,设置为"1"返回结果有标点
        mIat.setParameter(SpeechConstant.ASR_PTT, "1");
    }


}
