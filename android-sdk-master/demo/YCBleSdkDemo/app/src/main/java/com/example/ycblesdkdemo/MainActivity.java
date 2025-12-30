package com.example.ycblesdkdemo;

import android.app.ProgressDialog;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.adapter.DeviceAdapter;
import com.example.ycblesdkdemo.model.ConnectEvent;
import com.example.ycblesdkdemo.upgrade.FirmwareRecoveryActivity;
import com.example.ycblesdkdemo.upgrade.auto.AutoFactoryActivity;
import com.example.ycblesdkdemo.upgrade.auto.AutoFirmwareUpgradeActivity;
import com.example.ycblesdkdemo.upgrade.auto.AutoUiUpgradeActivity;
import com.yucheng.ycbtsdk.AITools;
import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.AIDataBean;
import com.yucheng.ycbtsdk.bean.HealthNormBean;
import com.yucheng.ycbtsdk.bean.ScanDeviceBean;
import com.yucheng.ycbtsdk.response.BleAIDiagnosisHRVNormResponse;
import com.yucheng.ycbtsdk.response.BleAIDiagnosisResponse;
import com.yucheng.ycbtsdk.response.BleConnectResponse;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleDeviceToAppDataResponse;
import com.yucheng.ycbtsdk.response.BleRealDataResponse;
import com.yucheng.ycbtsdk.response.BleScanResponse;
import com.yucheng.ycbtsdk.utils.ByteUtil;
import com.yucheng.ycbtsdk.utils.YCBTLog;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.TimeZone;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;

import static com.yucheng.ycbtsdk.Constants.BLEState.ReadWriteOK;

public class MainActivity extends AppCompatActivity implements View.OnClickListener {
    private final static String TAG = MainActivity.class.getSimpleName();
    private int invertTime = 10;
    private ProgressDialog progressDialog;
    private ListView listView;

    private List<ScanDeviceBean> listModel = new ArrayList<>();
    private List<String> listVal = new ArrayList<>();
    DeviceAdapter deviceAdapter = new DeviceAdapter(MainActivity.this, listModel);

    private AITools aiTools;

    private TextView dfuUpdateView;

    private String macVal;

    private String realData = "";
    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            if (msg.what == 0) {
                handler.sendEmptyMessageDelayed(0, 1000);
                YCBTClient.getAllRealDataFromDevice(new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        if (hashMap != null) {
                            MainActivity.this.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    ((TextView) findViewById(R.id.tv_get_real)).setText(hashMap.toString());
                                }
                            });
                        }
                    }
                });
            } else if (msg.what == 1) {
                showDialog();
            } else if (msg.what == 2) {
                dissmissDialog();
                Toast.makeText(MainActivity.this, "没有历史数据", Toast.LENGTH_LONG).show();
            } else if (msg.what == 3) {
                Toast.makeText(MainActivity.this, "同步失败", Toast.LENGTH_LONG).show();
                dissmissDialog();
            } else if (msg.what == 4) {
                Toast.makeText(MainActivity.this, "同步成功", Toast.LENGTH_LONG).show();
                dissmissDialog();
            } else if (msg.what == 5) {
                Toast.makeText(MainActivity.this, "升级成功", Toast.LENGTH_LONG).show();
                dissmissDialog();
            } else if (msg.what == 6) {
                Toast.makeText(MainActivity.this, "升级失败", Toast.LENGTH_LONG).show();
                dissmissDialog();
            } else if (msg.what == 10) {
                Toast.makeText(MainActivity.this, "完成", Toast.LENGTH_LONG).show();
                dissmissDialog();
            }
            return false;
        }
    });

    private void showDialog() {
        if (!MainActivity.this.isFinishing() && progressDialog != null && !progressDialog.isShowing()) {
            progressDialog.show();
        }
    }

    private void dissmissDialog() {
        if (!MainActivity.this.isFinishing() && progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        EventBus.getDefault().register(this);

        startService(new Intent(this, MyBleService.class));
//        startService(new Intent(this, BackService.class));


        listView = findViewById(R.id.device_list_view);
        listView.setAdapter(deviceAdapter);

        findViewById(R.id.ed_mac_start).setOnClickListener(this);
        findViewById(R.id.auto_set_product_view).setOnClickListener(this);
        findViewById(R.id.bt_start_scan).setOnClickListener(this);
        findViewById(R.id.bt_stop_scan).setOnClickListener(this);
        findViewById(R.id.bt_connect_dev).setOnClickListener(this);
        findViewById(R.id.bt_write_test).setOnClickListener(this);
        findViewById(R.id.bt_write_stop).setOnClickListener(this);
        findViewById(R.id.bt_write_real).setOnClickListener(this);
        findViewById(R.id.bt_ui_getinfo).setOnClickListener(this);
        findViewById(R.id.bt_get_history_data).setOnClickListener(this);
        findViewById(R.id.bt_delete_history_data).setOnClickListener(this);
        findViewById(R.id.open_real_temp).setOnClickListener(this);
        findViewById(R.id.read_real_temp).setOnClickListener(this);
        findViewById(R.id.close_real_temp).setOnClickListener(this);
        findViewById(R.id.bt_disconnect_dev).setOnClickListener(this);
        findViewById(R.id.send_message).setOnClickListener(this);
        findViewById(R.id.send_model).setOnClickListener(this);
        findViewById(R.id.send_reset_order).setOnClickListener(this);
        findViewById(R.id.start_sport).setOnClickListener(this);
        findViewById(R.id.end_sport).setOnClickListener(this);
        findViewById(R.id.get_real).setOnClickListener(this);
        findViewById(R.id.watchDialDownload).setOnClickListener(this);
        findViewById(R.id.history_data_view).setOnClickListener(this);
        findViewById(R.id.history_ecg_data_index).setOnClickListener(this);
        findViewById(R.id.history_ecg_data_timestamp).setOnClickListener(this);
        findViewById(R.id.history_blood_data_view).setOnClickListener(this);
        findViewById(R.id.delete_history_data_view).setOnClickListener(this);
        findViewById(R.id.delete_history_blood_data_view).setOnClickListener(this);
        findViewById(R.id.start_test_blood_view).setOnClickListener(this);
        findViewById(R.id.history_data_light).setOnClickListener(this);
        findViewById(R.id.history_ppg_data_view).setOnClickListener(this);
        findViewById(R.id.delete_history_ppg_data_view).setOnClickListener(this);
        //findViewById(R.id.delete_history_data_light).setOnClickListener(this);
        findViewById(R.id.set_history_data_invert_time).setOnClickListener(this);
        findViewById(R.id.get_ppi).setOnClickListener(this);
        findViewById(R.id.history_ppi_data_view).setOnClickListener(this);
        findViewById(R.id.delete_history_ppi_data_view).setOnClickListener(this);
        findViewById(R.id.auto_ui_upgrade).setOnClickListener(this);
        findViewById(R.id.auto_firmware_upgrade).setOnClickListener(this);
        findViewById(R.id.firmware_recovery).setOnClickListener(this);
        ((RadioGroup) findViewById(R.id.radio_group)).setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                switch (checkedId) {
                    case R.id.radio_button1:
                        invertTime = 10;
                        break;
                    case R.id.radio_button2:
                        invertTime = 20;
                        break;
                    case R.id.radio_button3:
                        invertTime = 30;
                        break;
                    case R.id.radio_button4:
                        invertTime = 40;
                        break;
                    case R.id.radio_button5:
                        invertTime = 50;
                        break;
                    case R.id.radio_button6:
                        invertTime = 60;
                        break;
                }
            }
        });


//        String defaultMac = (String) SPHelper.get(MainActivity.this, "key", "no");
//
//        if (!defaultMac.equals("no")) {
//
//            Log.e("device", "default=" + defaultMac);
//
//
//            YCBTClient.connectBle(defaultMac, new BleConnectResponse() {
//                @Override
//                public void onConnectResponse(final int i) {
//
//                    runOnUiThread(new Runnable() {
//                        @Override
//                        public void run() {
////                            Toast.makeText(MainActivity.this, "main=" + i, Toast.LENGTH_SHORT).show();
//                            baseOrderSet();
//                        }
//                    });
//                }
//            });
//        }


        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {

                YCBTClient.stopScanBle();

                ScanDeviceBean scanDeviceBean = (ScanDeviceBean) parent.getItemAtPosition(position);

                SPHelper.setParam(MainActivity.this, "key", scanDeviceBean.getDeviceMac());

                macVal = scanDeviceBean.getDeviceMac();

                YCBTClient.connectBle(scanDeviceBean.getDeviceMac(), new BleConnectResponse() {
                    @Override
                    public void onConnectResponse(final int i) {

                        runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
//                                    baseOrderSet();
                            }
                        });
                    }
                });
            }
        });
    }


    private synchronized void createMac(String mac, int number) {
        showDialog();
        String start = mac.replace(":", "");
        new Thread(new Runnable() {
            @Override
            public void run() {
                String macs = "";
                for (int i = 0; i < number; i++) {
                    long end = 0;
                    try {
                        end = Long.parseLong(start, 16) + i;
                    } catch (NumberFormatException e) {
                        e.printStackTrace();
                        Toast.makeText(MainActivity.this, "输入有误，请重新输入", Toast.LENGTH_LONG).show();
                        dissmissDialog();
                        return;
                    }
                    String forMac = String.format("%012X", end).replaceAll("(.{2})", "$1" + ":").substring(0, 17);
                    macs += (forMac + "\n");
                    if (i == 0) {
                        YCBTLog.saveFile("mac地址.txt", macs, false);
                    } else if (i % 3000 == 0 || i == number - 1) {
                        YCBTLog.saveFile("mac地址.txt", macs, true);
                        macs = "";
                    }
                }
                handler.sendEmptyMessage(10);
            }
        }).start();
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.ed_mac_start:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在生成mac地址", true, false);
                }
                try {
                    createMac(((TextView) findViewById(R.id.ed_mac_initial)).getText().toString().trim(), Integer.parseInt(((TextView) findViewById(R.id.ed_mac_number)).getText().toString().trim()));
                } catch (NumberFormatException e) {
                    e.printStackTrace();
                    Toast.makeText(MainActivity.this, "输入有误，请重新输入", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.get_real:
                realData = "";
                handler.removeMessages(0);
                handler.sendEmptyMessage(0);
                break;
            case R.id.bt_disconnect_dev:
                YCBTClient.disconnectBle();
                break;
            case R.id.auto_set_product_view:
                startActivity(new Intent(MainActivity.this, AutoFactoryActivity.class));
                break;
            case R.id.bt_start_scan: {
                //YCBTClient.connectBle("DA:18:56:2C:3C:D0", null);
                YCBTClient.startScanBle(new BleScanResponse() {
                    @Override
                    public void onScanResponse(int i, ScanDeviceBean scanDeviceBean) {
                        if (scanDeviceBean != null) {
                            if (!listVal.contains(scanDeviceBean.getDeviceMac())) {
                                listVal.add(scanDeviceBean.getDeviceMac());
                                deviceAdapter.addModel(scanDeviceBean);
                            }
                            Log.e("device", "mac=" + scanDeviceBean.getDeviceMac() + ";name=" + scanDeviceBean.getDeviceName() + "rssi=" + scanDeviceBean.getDeviceRssi());
                        }
                    }
                }, 6);//0x7810
                break;
            }
            case R.id.bt_stop_scan: {
                YCBTClient.stopScanBle();
                break;
            }
            case R.id.watchDialDownload:
                try {
                    /*InputStream is = getResources().openRawResource(R.raw.night_15689745621);
                    byte[] buffer = new byte[1024];
                    int len = 0;
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    while ((len = is.read(buffer)) != -1) {
                        bos.write(buffer, 0, len);
                    }
                    bos.flush();*/
                   /* YCBTClient.watchDialDownload(bos.toByteArray(), new BleDataResponse() {
                        @Override
                        public void onDataResponse(int i, float v, HashMap hashMap) {
                            System.out.println("chong---------i==" + i);
                        }
                    });*/
                } catch (Exception e) {
                    e.printStackTrace();
                }
                break;
            case R.id.bt_connect_dev: {
                //p3plus D8:D3:F7:1F:22:69
                //v5 F3:E8:04:E8:73:68
//                YCBTClient.connectBle("", new BleConnectResponse() {
//                    @Override
//                    public void onConnectResponse(int i) {
//
//                    }
//                });
                break;
            }
            case R.id.bt_write_test: {
                //0x0200080047436FEC
                AITools.getInstance().setAIDiagnosisHRVNormResponse(new BleAIDiagnosisHRVNormResponse() {
                    @Override
                    public void onAIDiagnosisResponse(HealthNormBean hrvNormBean) {
                        /* float heavy_load;//负荷指数 （越大越不好 传出）
                         float pressure;//压力指数 （越大越不好 传出）
                         float HRV_norm;//HRV指数 （越大越好 传出）
                         float body;//身体指数 （越大越好 传出）
                         int flag = -1;//0正常 -1错误*/
                        //System.out.println("chong--------AIDiagnosis");
                    }
                });
                YCBTClient.appEcgTestStart(new BleDataResponse() {
                    @Override


                    public void onDataResponse(int i, float v, HashMap hashMap) {

                    }
                }, new BleRealDataResponse() {
                    @Override
                    public void onRealDataResponse(int i, HashMap hashMap) {
                        if (hashMap != null) {
                            int dataType = (int) hashMap.get("dataType");
                            Log.e("qob", "onRealDataResponse " + i + " dataType " + dataType);
                            if (i == Constants.DATATYPE.Real_UploadECG) {
                                final List<Integer> tData = (List<Integer>) hashMap.get("data");
                                //System.out.println("chong----------ecgData==" + tData.toString());
                                //一定要在主线程分析
                                runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        Log.e("qob", "AI " + tData.size());
                                    }
                                });
                            } else if (i == Constants.DATATYPE.Real_UploadPPG) {
                                byte[] param = (byte[]) hashMap.get("data");
                                Log.e("qob", "ppg: " + Arrays.toString(param));
                            } else if (i == Constants.DATATYPE.Real_UploadECGHrv) {
                                float param = (float) hashMap.get("data");
                                Log.e("qob", "HRV: " + param);
                            } else if (i == Constants.DATATYPE.Real_UploadECGRR) {
                                float param = (float) hashMap.get("data");
                                Log.e("qob", "RR invo " + param);
                            } else if (i == Constants.DATATYPE.Real_UploadBlood) {
                                int heart = (int) hashMap.get("heartValue");//心率
                                int tDBP = (int) hashMap.get("bloodDBP");//低压
                                int tSBP = (int) hashMap.get("bloodSBP");//高压
                            }
                        }
                    }
                });
                break;
            }
            case R.id.bt_write_stop: {
                YCBTClient.appEcgTestEnd(new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        System.out.println("chong------测试结束i==" + i);
                        if (i != 0) {
                            //测试异常
                            return;
                        }
                        HealthNormBean bean = AITools.getInstance().getHealthNorm();
                        if (bean != null) {
                            if (bean.flag == -1) {
                                //错误
                            } else {//正常
                                float heavy_load = bean.heavyLoad;//负荷指数 （越大越不好 传出）
                                float pressure = bean.pressure;//压力指数 （越大越不好 传出）
                                float HRV_norm = bean.hrvNorm;//HRV指数 （越大越好 传出）
                                float body = bean.body;//身体指数 （越大越好 传出）
                                int respRate = bean.respiratoryRate;//呼吸率
                                float sympatheticParasympathetic = bean.sympatheticParasympathetic;//副交感神经兴奋指数
                            }
                        }

                        AITools.getInstance().getAIDiagnosisResult(new BleAIDiagnosisResponse() {
                            @Override
                            public void onAIDiagnosisResponse(AIDataBean aiDataBean) {
                                if (aiDataBean != null) {
                                    short heart = aiDataBean.heart;//心率
                                    int qrstype = aiDataBean.qrstype;//类型 1正常心拍 5室早心拍 9房早心拍  14噪声
                                    boolean is_atrial_fibrillation = aiDataBean.is_atrial_fibrillation;//是否心房颤动
                                    System.out.println("chong------heart==" + heart + "--qrstype==" + qrstype + "--is_atrial_fibrillation==" + is_atrial_fibrillation);
                                }
                            }
                        });
                    }
                });
                break;
            }
            case R.id.bt_write_real: {
                /*YCBTClient.getAllRealDataFromDevice(new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        System.out.println("chong---------hashmap==" + hashMap.toString());
                    }
                });*/
                YCBTClient.deviceToApp(new BleDeviceToAppDataResponse() {
                    @Override
                    public void onDataResponse(int code, HashMap dataMap) {
                        System.out.println("chong---code==" + code + "--" + dataMap.toString());
                        if (dataMap != null && (int) dataMap.get("dataType") == Constants.DATATYPE.DeviceMeasurementResult) {
                            byte[] datas = (byte[]) dataMap.get("datas");
                            if (datas[0] == 0x05) {
                                if (datas[1] == 0) {//手表退出测量

                                } else if (datas[1] == 1) {//测量成功

                                } else if (datas[1] == 2) {//测量失败

                                } else if (datas[1] == 3) {//手表开启测量
                                    AITools.getInstance().init();
                                }
                            }
                        }
                    }
                });
                /*AITools.getInstance().getHRV();

                if(YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTEMP)){
                    YCBTClient.appTemperatureMeasure(1, null);
                    YCBTClient.getRealTemp(new BleDataResponse() {
                        @Override
                        public void onDataResponse(int code, float ratio, HashMap resultMap) {
                            System.out.println("result==" + resultMap.toString());
                        }
                    });
                }*/

                break;
            }
            case R.id.bt_ui_getinfo: {
                YCBTClient.getDeviceInfo(new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                    }
                });/*if(hashMap != null){
                            HashMap map = (HashMap) hashMap.get("data");
                            String deviceId = (String) map.get("deviceId");
                            String deviceVersion = (String) map.get("deviceVersion");
                            String deviceBatteryState = (String) map.get("deviceBatteryState");
                            String deviceBatteryValue = (String) map.get("deviceBatteryValue");
                        }*/
                break;
            }
            case R.id.bt_get_history_data:
                closeRegisterRealStepData();
                YCBTClient.healthHistoryData(0x052D, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        if (hashMap != null) {
                            System.out.println("chong---------hashmap==" + hashMap.toString());
                        }
                    }
                });
                openRegisterRealStepData();
                break;
            case R.id.bt_delete_history_data:
                /*YCBTClient.deleteHealthHistoryData(0x0544, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        if (i == 0) {//delete success

                        }
                    }
                });*/
                break;
            case R.id.read_real_temp://read real temp
                readRealTemp();
                break;
            case R.id.open_real_temp://open real temp
                openRealTemp();
                break;
            case R.id.close_real_temp://close real temp
                closeRealTemp();
                break;
            case R.id.send_message:
                YCBTClient.appSengMessageToDevice(0x03, "ทานยาก่อนอาหาร", "ตัวอย่าง: เพนิซิลลิน 1 เม็ด, พาราเซตามอล 10 เม็ด", new BleDataResponse() {//วันนี้มีนัดพบคุณหมอนะครับ  รพ.น้ำหนึ่งวิญญู 16:00:00
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        if (i == 0) {
                            //success sendMessage
                        }
                    }
                });
                break;
            case R.id.send_model:
                YCBTClient.appMobileModel("OPPO A77", new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        if (i == 0) {
                            //success
                            int sleepNum = (int) hashMap.get("SleepNum");
                            int sleepTotalTime = (int) hashMap.get("SleepTotalTime");
                            int heartNum = (int) hashMap.get("HeartNum");
                            int sportNum = (int) hashMap.get("SportNum");
                            int bloodNum = (int) hashMap.get("BloodNum");
                            int bloodOxygenNum = (int) hashMap.get("BloodOxygenNum");
                            int tempHumidNum = (int) hashMap.get("TempHumidNum");
                            int tempNum = (int) hashMap.get("TempNum");
                            int ambientLightNum = (int) hashMap.get("AmbientLightNum");
                        }
                    }
                });
                break;
            case R.id.send_reset_order:
//                YCBTClient.settingRestoreFactory(new BleDataResponse() {
//                    @Override
//                    public void onDataResponse(int code, float ratio, HashMap resultMap) {
//                        Log.e("cellhomepartssss",".......reset...order...");
//                    }
//                });


                Intent otherIntent = new Intent(MainActivity.this, OtherActivity.class);
                startActivity(otherIntent);
                break;
            case R.id.start_sport:
                YCBTClient.appRunMode(0x01, 0x01, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        System.out.println("chong---------run mode start==" + i);
                    }
                });
                break;
            case R.id.end_sport:
                YCBTClient.appRunModeEnd(0x01, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        System.out.println("chong---------run mode end==" + i);
                    }
                });
                break;
            case R.id.history_data_view:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在同步数据...", true, false);
                }
                if (YCBTClient.connectState() == ReadWriteOK) {
                    syncHistoryThreeTime();
                } else {
                    dissmissDialog();
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.history_ecg_data_index:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在同步数据...", true, false);
                }
                if (YCBTClient.connectState() == ReadWriteOK) {
                    syncEcgHistoryTime(1);
                } else {
                    dissmissDialog();
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.history_ecg_data_timestamp:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在同步数据...", true, false);
                }
                if (YCBTClient.connectState() == ReadWriteOK) {
                    syncEcgHistoryTime(2);
                } else {
                    dissmissDialog();
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.history_blood_data_view:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在同步数据...", true, false);
                }
                if (YCBTClient.connectState() == ReadWriteOK) {
                    syncHistoryBloodTime();
                } else {
                    dissmissDialog();
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.history_ppg_data_view:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在同步数据...", true, true);
                }
                if (YCBTClient.connectState() == ReadWriteOK) {
                    YCBTClient.settingLanguage(1, null);
                    syncHistoryPpgIndexs();
                } else {
                    dissmissDialog();
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.delete_history_data_view:
                if (YCBTClient.connectState() == ReadWriteOK) {
                    deleteThreeHistory(0xffffffff);
                } else {
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.delete_history_blood_data_view:
                if (YCBTClient.connectState() == ReadWriteOK) {
                    deleteBloodHistory(0xffffffff);
                } else {
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.start_test_blood_view:
                if (YCBTClient.connectState() == ReadWriteOK) {
                    startActivity(new Intent(MainActivity.this, TestBoolActivity.class));
                }
                break;
            case R.id.history_data_light:
                showDialog();
                YCBTClient.healthHistoryData(0x0520, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {
                        if (i == 0) {
                            handler.sendEmptyMessage(4);
                            StringBuilder builder = new StringBuilder();
                            ArrayList<HashMap> lists = (ArrayList<HashMap>) hashMap.get("data");
                            for (HashMap map : lists) {
                                builder.append(getDateTimeToString((long) map.get("startTime")) + "  ").append((int) map.get("value") + "\n");
                            }
                            if (lists != null && lists.size() > 0) {
                                YCBTLog.saveFile(YCBTClient.getBindDeviceMac() + "_" + getDateToString(System.currentTimeMillis()) + ".txt", builder.toString(), true);
                                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteAmbientLight, new BleDataResponse() {
                                    @Override
                                    public void onDataResponse(int i, float v, HashMap hashMap) {

                                    }
                                });
                            } else {
                                handler.sendEmptyMessage(2);
                            }
                        } else {
                            handler.sendEmptyMessage(3);
                        }
                    }
                });
                break;
            /*case R.id.delete_history_data_light:
                YCBTClient.deleteHealthHistoryData(Constants.DATATYPE.Health_DeleteAmbientLight, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int i, float v, HashMap hashMap) {

                    }
                });
                break;*/
            case R.id.set_history_data_invert_time:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在设置...", true, false);
                }
                if (YCBTClient.connectState() == ReadWriteOK) {
                    setInvertTime();
                } else {
                    dissmissDialog();
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.get_ppi:
                YCBTClient.appRegisterRealDataCallBack(new BleRealDataResponse() {
                    @Override
                    public void onRealDataResponse(int dataType, HashMap dataMap) {
                        if (dataMap == null)
                            return;
                        System.out.println("chong-------" + dataMap.toString());
                    }
                });
                YCBTClient.appRunMode(0x01, 0x01, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int code, float ratio, HashMap resultMap) {
                        if (code == 0) {
                            System.out.println("chong------开启成功");
                        }
                    }
                });

                /*try {
                    InputStream in = getResources().openRawResource(R.raw.custom_e80_0_8);
                    //创建byte数组
                    byte[]  buffer = new byte[1024];
                    int len = 0;
                    ByteArrayOutputStream bos = new ByteArrayOutputStream();
                    while ((len = in.read(buffer)) != -1) {
                        bos.write(buffer, 0, len);
                    }
                    bos.flush();

                    YCBTClient.watchDialDownload(1, bos.toByteArray(), 2147483539, 0, 1, new BleDataResponse() {
                        @Override
                        public void onDataResponse(int code, float ratio, HashMap resultMap) {

                        }
                    });
                } catch (Exception e) {
                    e.printStackTrace();
                }*/
                break;
            case R.id.history_ppi_data_view:
                if (progressDialog == null) {
                    progressDialog = ProgressDialog.show(this, "提示", "正在同步数据...", true, false);
                }
                if (YCBTClient.connectState() == ReadWriteOK) {
                    syncHistoryPpiTime();
                } else {
                    dissmissDialog();
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.delete_history_ppi_data_view:
                if (YCBTClient.connectState() == ReadWriteOK) {
                    deletePpiHistory(0xffffffff);
                } else {
                    Toast.makeText(MainActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                }
                break;
            case R.id.auto_ui_upgrade:
                startActivity(new Intent(MainActivity.this, AutoUiUpgradeActivity.class));
                break;
            case R.id.auto_firmware_upgrade:
                startActivity(new Intent(MainActivity.this, AutoFirmwareUpgradeActivity.class));
                break;
            case R.id.firmware_recovery:
                startActivity(new Intent(MainActivity.this, FirmwareRecoveryActivity.class));
                break;
        }
    }

    private int times = 0;
    private boolean isSuccess = true;

    /**
     * 不同工作模式下数据采集配置
     * 模式  0x00：设置为正常工作模式采集配置  0x01:设置为关怀工作模式采集配置  0x02：设置为省电工作模式采集配置  0x03:设置运动模式下采集配置
     * 数据类型 0x00:PPG,  0x01:六轴,  0x02：ECG,  0x03：温湿度,  0x04：环境光,  0x05：体温,  0x06：心率
     * 每次采集时长（单位： 秒）（关闭时填 0）
     * 采集间隔(单位：分钟) （关闭时填 0）
     */
    private void setInvertTime() {
        showDialog();
        times = 0;
        isSuccess = true;
        for (int i = 0; i < 4; i++) {
            YCBTClient.settingConfigInDifWorkingModes(i, 0x05, 20, invertTime, new BleDataResponse() {
                @Override
                public void onDataResponse(int i, float v, HashMap hashMap) {
                    if (i != 0) {
                        isSuccess = false;
                    }
                    times++;
                    if (times == 12) {
                        showToast(isSuccess);
                    }
                }
            });
            YCBTClient.settingConfigInDifWorkingModes(i, 0x06, 20, invertTime, new BleDataResponse() {
                @Override
                public void onDataResponse(int i, float v, HashMap hashMap) {
                    if (i != 0) {
                        isSuccess = false;
                    }
                    times++;
                    if (times == 12) {
                        showToast(isSuccess);
                    }
                }
            });
            YCBTClient.settingConfigInDifWorkingModes(i, 0x03, 20, invertTime, new BleDataResponse() {
                @Override
                public void onDataResponse(int i, float v, HashMap hashMap) {
                    if (i != 0) {
                        isSuccess = false;
                    }
                    times++;
                    if (times == 12) {
                        showToast(isSuccess);
                    }
                }
            });
        }
    }

    private void showToast(boolean isSuccess) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                dissmissDialog();
                if (isSuccess) {
                    Toast.makeText(MainActivity.this, "设置成功！", Toast.LENGTH_LONG).show();
                } else {
                    Toast.makeText(MainActivity.this, "设置失败！", Toast.LENGTH_LONG).show();
                }
            }
        });
    }

    private void appShutDown() {
        YCBTClient.appShutDown(0x03, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                System.out.println("chong----------type==重启");
            }
        });
    }

    //获取三轴传感器数据的时间戳
    private void syncHistoryThreeTime() {
        showDialog();
        Log.e("yc-ble", "同步三轴加速传感器数据。。。。");
        //获取ppg时间戳
        YCBTClient.collectHistoryListData(0x02, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (hashMap != null) {
                    Log.e("historydata", "历史三轴加速传感器数据 hashMap=" + hashMap.toString());
                    List<HashMap> data = (List<HashMap>) hashMap.get("data");
                    for (HashMap map : data) {
                        threeTimes.add((Long) map.get("collectSendTime"));
                    }
                    getThreeHistory();
                } else {
                    handler.sendEmptyMessage(2);
                    Log.e("historydata", "没有历史三轴加速传感器数据");
                }
            }
        });
    }

    private List<Long> threeTimes = new ArrayList<>();
    private List<Long> bloodTimes = new ArrayList<>();
    private List<Long> ppiTimes = new ArrayList<>();
    private List<Integer> ppgIndexs = new ArrayList<>();

    //获取ppg下标
    private void syncHistoryPpgIndexs() {
        showDialog();
        Log.e("yc-ble", "同步PPG数据。。。。");
        YCBTClient.collectHistoryListData(0x01, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float v, HashMap hashMap) {
                if (code == 0) {
                    if (hashMap != null) {
                        Log.e("historydata", "历史PPG数据 hashMap=" + hashMap);
                        List<HashMap> data = (List<HashMap>) hashMap.get("data");
                        for (HashMap map : data) {
                            ppgIndexs.add((int) map.get("collectSN"));
                        }
                        getPpgHistory();
                    } else {
                        handler.sendEmptyMessage(2);
                        Log.e("historydata", "没有历史ppg数据");
                    }
                } else {
                    if (code == 0xFB) {
                        Log.e("historydata", "不支持的Command ID");
                    } else if (code == 0xFC) {
                        Log.e("historydata", "没有历史ppg数据");
                    } else if (code == 0xFD) {
                        Log.e("historydata", "没有历史ppg数据");
                    } else if (code == 0xFE) {
                        Log.e("historydata", "没有历史ppg数据");
                    } else if (code == 0xFF) {
                        Log.e("historydata", "没有历史ppg数据");
                    } else {
                        Log.e("historydata", "同步失败");
                    }
                    handler.sendEmptyMessage(3);
                }
            }
        });
    }

    //获取ppg时间戳
    private void syncHistoryBloodTime() {
        showDialog();
        Log.e("yc-ble", "同步充气血压数据。。。。");
        YCBTClient.collectHistoryListData(0x06, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (hashMap != null) {
                    Log.e("historydata", "历史充气血压数据 hashMap=" + hashMap);
                    List<HashMap> data = (List<HashMap>) hashMap.get("data");
                    for (HashMap map : data) {
                        bloodTimes.add((Long) map.get("collectSendTime"));
                    }
                    getBloodHistory();
                } else {
                    handler.sendEmptyMessage(2);
                    Log.e("historydata", "没有历史充气血压数据");
                }
            }
        });
    }

    //获取ppg时间戳
    private void syncHistoryPpiTime() {
        showDialog();
        Log.e("yc-ble", "同步ppi数据。。。。");
        YCBTClient.collectHistoryListData(0x07, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (hashMap != null) {
                    Log.e("historydata", "历史ppi数据 hashMap=" + hashMap);
                    List<HashMap> data = (List<HashMap>) hashMap.get("data");
                    for (HashMap map : data) {
                        ppiTimes.add((Long) map.get("collectSendTime"));
                    }
                    getPPiHistory();
                } else {
                    handler.sendEmptyMessage(2);
                    Log.e("historydata", "没有历史ppi数据");
                }
            }
        });
    }

    private void getThreeHistory() {
        if (threeTimes.size() > 0) {
            final long time = threeTimes.get(0);
            threeTimes.remove(0);
            YCBTClient.collectHistoryDataWithTimestamp(0x02, time, new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    Log.e("historydata", "完成历史三轴加速传感器数据 hashMap=" + resultMap);
                    if (code == 0) {
                        YCBTLog.saveThreeFile(time + "_" + YCBTClient.getBindDeviceMac() + "_" + getDateTimeToString((time + YCBTClient.SecFrom30Year) * 1000 - YCBTClient.millisFromGMT) + ".txt", (byte[]) resultMap.get("data"));
                        getThreeHistory();
                    } else {
                        handler.sendEmptyMessage(3);
                    }
                }
            });
        } else {
            handler.sendEmptyMessage(4);
        }
    }

    private void getBloodHistory() {
        if (bloodTimes.size() > 0) {
            final long time = bloodTimes.get(0);
            bloodTimes.remove(0);
            YCBTClient.collectHistoryDataWithTimestamp(0x06, time, new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    Log.e("historydata", "完成历史充气血压数据 hashMap=" + resultMap);
                    if (code == 0) {
                        byte[] data = (byte[]) resultMap.get("data");
                        long startTime = (time + YCBTClient.SecFrom30Year) * 1000 - TimeZone.getDefault().getOffset(System.currentTimeMillis());
                        String info = "";
                        if (data != null && data.length > 9) {
                            info = "血压" + "-" + (data[2] & 0xff) + "-" + (data[3] & 0xff) + "mmhg-"//(char) (data[1] & 0xff) + (char) (data[0] & 0xff) +
                                    + (data[4] & 0xff) + "bpm-" + (data[5] & 0xff) + "cm-" + (data[6] & 0xff) + "kg-" + (data[7] & 0xff) + "岁-" + (data[8] == 0 ? "男" : "女");
                        }
                        String fileName = getDateTimeToString(startTime) + " " + info + ".txt";
                        YCBTLog.saveBoolFile(fileName, data);
                        getBloodHistory();
                    } else {
                        handler.sendEmptyMessage(3);
                    }
                }
            });
        } else {
            handler.sendEmptyMessage(4);
        }
    }

    private void getPPiHistory() {
        if (ppiTimes.size() > 0) {
            final long time = ppiTimes.get(0);
            ppiTimes.remove(0);
            YCBTClient.collectHistoryDataWithTimestamp(0x00, time, new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    Log.e("historydata", "完成历史ppi数据 hashMap=" + resultMap);
                    if (code == 0) {
                        byte[] data = (byte[]) resultMap.get("data");
                        System.out.println("chong----------data==" + Arrays.toString(data));
                        getPPiHistory();
                    } else {
                        handler.sendEmptyMessage(3);
                    }
                }
            });
        } else {
            handler.sendEmptyMessage(4);
        }
    }

    private void getPpgHistory() {
        if (ppgIndexs.size() > 0) {
            final int ppgIndex = ppgIndexs.get(0);
            ppgIndexs.remove(0);
            /*YCBTClient.collectPpgDataWithIndex(ppgIndex, new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    Log.e("historydata", "完成历史ppg数据 hashMap=" + resultMap);
                    if (code == 0) {
                        byte[] data = (byte[]) resultMap.get("data");
                        YCBTLog.saveFile(YCBTClient.getBindDeviceMac() + "_" + getDateToString(System.currentTimeMillis()) + "_3.txt", ByteUtil.byteToString(data), true);
                        System.out.println("chong----------data==" + Arrays.toString(data));
                        getPpgHistory();
                    } else {
                        handler.sendEmptyMessage(3);
                    }
                }
            });*/
            YCBTClient.collectHistoryDataWithIndex(0x01, ppgIndex, new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    Log.e("historydata", "完成历史ppg数据 hashMap=" + resultMap);
                    if (code == 0) {
                        byte[] data = (byte[]) resultMap.get("data");
                        YCBTLog.saveFile(YCBTClient.getBindDeviceMac() + "_" + getDateToString(System.currentTimeMillis()) + "_4.txt", ByteUtil.byteToString(data), true);
                        System.out.println("chong----------data==" + Arrays.toString(data));
                        getPpgHistory();
                    } else {
                        handler.sendEmptyMessage(3);
                    }
                }
            });
        } else {
            handler.sendEmptyMessage(4);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    private void deleteThreeHistory(long time) {
        YCBTClient.deleteHistoryListData(0x02, time, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(MainActivity.this, "删除成功", Toast.LENGTH_LONG).show();
                    }
                });
            }
        });
    }

    private void deleteBloodHistory(long time) {
        YCBTClient.deleteHistoryListData(0x06, time, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(MainActivity.this, "删除成功", Toast.LENGTH_LONG).show();
                    }
                });
            }
        });
    }

    private void deletePpiHistory(long time) {
        YCBTClient.deleteHistoryListData(0x07, time, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(MainActivity.this, "删除成功", Toast.LENGTH_LONG).show();
                    }
                });
            }
        });
    }

    public static String getDateTimeToString(long milSecond) {
        Date date = new Date(milSecond);
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return format.format(date);
    }

    public static String getDateToString(long milSecond) {
        Date date = new Date(milSecond);
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return format.format(date);
    }

    public static String getString(InputStream inputStream) {
        InputStreamReader inputStreamReader = null;
        try {
            inputStreamReader = new InputStreamReader(inputStream, "utf-8");
        } catch (UnsupportedEncodingException e1) {
            e1.printStackTrace();
        }
        BufferedReader reader = new BufferedReader(inputStreamReader);
        StringBuilder sb = new StringBuilder();
        String line;
        try {
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        if (sb.length() > 0) {
            sb.deleteCharAt(sb.length() - 1);
        }
        return sb.toString();
    }

    public static List<String> getFileName(String fileAbsolutePath) {
        List<String> lists = new ArrayList<>();
        try {
            File[] subFile = new File(fileAbsolutePath).listFiles();
            if (subFile != null && subFile.length > 0) {
                for (File file : subFile) {
                    if (!file.isDirectory() && file.getName().endsWith(".txt")) {
                        lists.add(file.getName());
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return lists;
    }

    /**
     * After opening, the bracelet will be black. This is normal.
     */
    private void openRealTemp() {
        YCBTClient.appTemperatureMeasure(0x01, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (i == 0) {
                    //success
                }
            }
        });
    }

    /**
     * if your need more, you can loop through this method.
     * but it must be after start_real_temp method.
     */
    private void readRealTemp() {
        YCBTClient.getRealTemp(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (i == 0) {
                    String temp = (String) hashMap.get("tempValue");
                }
            }
        });
    }

    /**
     * If you call the startRealTemp() method, you must call this method.
     * Otherwise, the bracelet will always be black and the temperature will be monitored in the background.
     */
    private void closeRealTemp() {
        YCBTClient.appTemperatureMeasure(0x00, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (i == 0) {
                    //success
                }
            }
        });
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void connectEvent(ConnectEvent connectEvent) {
        Log.e("mainorder", ".....connectent...........");
        if (connectEvent.state == 1 && isResume) {
            baseOrderSet();
            Intent timeIntent = new Intent(MainActivity.this, ChoseActivity.class);
            timeIntent.putExtra("mac", macVal);
            startActivity(timeIntent);
            Toast.makeText(MainActivity.this, getResources().getString(R.string.connect_success), Toast.LENGTH_SHORT).show();
        }
    }


    /***
     * 语言设置
     *   0x00:英语 0x01: 中文 0x02: 俄语 0x03: 德语 0x04: 法语
     * 0x05: 日语 0x06: 西班牙语 0x07: 意大利语 0x08: 葡萄牙文
     * 0x09: 韩文 0x0A: 波兰文 0x0B: 马来文 0x0C: 繁体中文 0xFF:其它
     * @param
     */
    //基础指令设置
    private void baseOrderSet() {


        /***
         * 语言设置
         * @param langType 0x00:英语 0x01: 中文 0x02: 俄语 0x03: 德语 0x04: 法语
         * 0x05: 日语 0x06: 西班牙语 0x07: 意大利语 0x08: 葡萄牙文
         * 0x09: 韩文 0x0A: 波兰文 0x0B: 马来文 0x0C: 繁体中文 0xFF:其它
         * @param dataResponse
         */
        YCBTClient.settingLanguage(0x01, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                Log.e("device", "同步语言结束");
            }
        });


        setPhoneTime();


        //心率采集
        YCBTClient.settingHeartMonitor(0x01, 10, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                Log.e("device", "设置10分钟间隔采集心率");
            }
        });


       /* //无感检测
        YCBTClient.settingPpgCollect(0x01, 60, 60, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                Log.e("device", "设置无感数据采集");
            }
        });


        //同步心率
        syncHisHr();
        //同步睡眠
        syncHisSleep();

        syncHisStep();*/


    }


    private void setPhoneTime() {

        Calendar calendar = Calendar.getInstance();
        int year = calendar.get(Calendar.YEAR);
        int month = calendar.get(Calendar.MONTH) + 1;
        int dayOfMonth = calendar.get(Calendar.DAY_OF_MONTH);
        int week = calendar.get(Calendar.DAY_OF_WEEK);
        int week2 = calendar.get(Calendar.DAY_OF_WEEK);
        int hour = calendar.get(Calendar.HOUR_OF_DAY);
        int min = calendar.get(Calendar.MINUTE);
        int sec = calendar.get(Calendar.SECOND);

        if (week == 1) {
            week += 5;
        } else {
            week -= 2;
        }


//        周 0-6(星期一~星期天)
        // 0 周一，1周二，2周三，3周四，4周五，5周六，6周日
        Log.e("device", "day of week jian=" + week);
        Log.e("device", "day of week week2=" + week2);

        YCBTClient.getDeviceInfo(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

            }
        });

    }


    //同步历史心率
    private void syncHisHr() {
        YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistoryHeart, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                if (hashMap != null) {

                    Log.e("history", "hashMap=" + hashMap.toString());

                    Log.e("history", "hr time=" + hashMap.get("heartStartTime"));

                    Log.e("history", "hr val=" + hashMap.get("heartValue"));
                } else {
                    Log.e("history", "no ..hr..data....");
                }

//                syncHisStep();
            }
        });
    }


    //同步历史睡眠
    private void syncHisSleep() {
        YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistorySleep, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                if (hashMap != null) {
                    Log.e("history", "hashMap=" + hashMap.toString());

                } else {
                    Log.e("history", "no ..sleep..data....");
                }

                //同步步数
//                syncHisStep();
//                hashMap.get();
            }
        });
    }

    //同步历史步数
    private void syncHisStep() {
        YCBTClient.healthHistoryData(Constants.DATATYPE.Health_HistorySport, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (hashMap != null) {

                    Log.e("history", "hashMap=" + hashMap.toString());

                    Log.e("history", "step start time=" + hashMap.get("sportStartTime"));
                    Log.e("history", "step end time=" + hashMap.get("sportEndTime"));
                    Log.e("history", "step num=" + hashMap.get("sportStep"));
                } else {
                    Log.e("history", "no...step ..data....");
                }
            }
        });
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();
        EventBus.getDefault().unregister(this);
        //YCBTClient.disconnectA2dp();
        //YCBTClient.closeA2dp();
    }

    private void closeRegisterRealStepData() {
        YCBTClient.appRealSportFromDevice(0x00, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                //Log.e(TAG,"....");
                //healthHistoryData();
            }
        });
    }

    private void openRegisterRealStepData() {
        YCBTClient.appRealSportFromDevice(0x01, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                //Log.e(TAG,"....");
            }
        });
        YCBTClient.appRegisterRealDataCallBack(new BleRealDataResponse() {
            @Override
            public void onRealDataResponse(int i, HashMap hashMap) {
                if (i == Constants.DATATYPE.Real_UploadSport) {
                    if (hashMap != null && hashMap.size() > 0) {
                        int sportStep = (int) hashMap.get("sportStep");
                        int sportDistance = (int) hashMap.get("sportDistance");
                        int sportCalorie = (int) hashMap.get("sportCalorie");
                        //Log.e(TAG,"实时监听步数 sportStep = "+sportStep+" ,sportDistance = " + sportDistance+" ,sportCalorie = "+sportCalorie);
                    }
                }
            }
        });
    }

    private String isExistDir(String saveDir) throws IOException {
        // 下载位置
        File downloadFile = new File(Environment.getExternalStorageDirectory(), saveDir);
        if (!downloadFile.mkdirs()) {
            downloadFile.createNewFile();
        }
        return downloadFile.getAbsolutePath();
    }

    private void dial() {
        /*try {
            List<String> names = getFileName(isExistDir("health/dial"));
            for (String name : names) {
                FileInputStream inputStream = new FileInputStream(new File(isExistDir("health/dial") + "/" + name));
                String[] content = getString(inputStream).split(",");
                inputStream.close();
                int[] data = Arrays.asList(content).stream().mapToInt(Integer::parseInt).toArray();
                System.out.println("chong--------filename == " + name.substring(0, name.indexOf(".")));
                long startTime = (Long.parseLong(name.substring(0, name.indexOf(".")), 16) + YCBTClient.SecFrom30Year) * 1000L - TimeZone.getDefault().getOffset(System.currentTimeMillis());
                String info = "";
                if (data != null && data.length > 9) {
                    info = "血压" + "-" + (data[2] & 0xff) + "-" + (data[3] & 0xff) + "mmhg-"//(char) (data[1] & 0xff) + (char) (data[0] & 0xff) +
                            + (data[4] & 0xff) + "bpm-" + (data[5] & 0xff) + "cm-" + (data[6] & 0xff) + "kg-" + (data[7] & 0xff) + "岁-" + (data[8] == 0 ? "男" : "女");
                }
                String fileName = getDateTimeToString(startTime) + " " + info + ".txt";
                //YCBTLog.savaFile(fileName, ByteUtil.boolIntToString(data));
                System.out.println("chong------保存文件--" + fileName + "==" + startTime);
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("chong-----开始安装表盘报错");
        }*/
    }

    private List<Long> ecgTimes = new ArrayList<>();
    private List<Integer> ecgIndexs = new ArrayList<>();

    //获取ecg数据的时间戳  type 1：根据下标获取   2：根据时间戳获取
    private void syncEcgHistoryTime(int type) {
        showDialog();
        //0x00: 心电图数据（ECG） 0x01: PPG 数据 0x02: 三轴加速度数据 0x03: 六轴传感器数据（3 轴加速度+3 轴陀螺仪）
        //     *              0x04: 九轴传感器数据（3 轴加速度+3 轴陀螺仪+3 轴磁力计） 0x05:三轴磁力计数据 0x06: 充气血压数据
        YCBTClient.collectHistoryListData(0x00, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (hashMap != null) {
                    Log.e("historydata", "hashMap=" + hashMap.toString());
                    List<HashMap> data = (List<HashMap>) hashMap.get("data");
                    for (HashMap map : data) {
                        if (type == 1) {
                            ecgIndexs.add((int) map.get("collectSN"));
                        } else {
                            ecgTimes.add((Long) map.get("collectSendTime"));
                        }
                    }
                    getEcgHistory(type);
                } else {
                    handler.sendEmptyMessage(2);
                    Log.e("historydata", "没有历史ECG数据");
                }
            }
        });
    }

    private void getEcgHistory(int type) {
        if (ecgTimes.size() > 0 && type == 2) {
            final long time = ecgTimes.get(0);
            ecgTimes.remove(0);
            YCBTClient.collectEcgDataWithTimestamp(time, new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    Log.e("historydata", "hashMap=" + resultMap);
                    if (code == 0) {
                        byte[] data = (byte[]) resultMap.get("data");
                        getEcgHistory(type);
                    } else {
                        handler.sendEmptyMessage(3);
                    }
                }
            });
        } else if (ecgIndexs.size() > 0 && type == 1) {
            final int index = ecgIndexs.get(0);
            ecgIndexs.remove(0);
            YCBTClient.collectEcgDataWithIndex(index, new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    Log.e("historydata", "hashMap=" + resultMap);
                    if (code == 0) {
                        byte[] data = (byte[]) resultMap.get("data");
                        getEcgHistory(type);
                    } else {
                        handler.sendEmptyMessage(3);
                    }
                }
            });
        } else {
            handler.sendEmptyMessage(4);
        }

        YCBTClient.resetQueue();
    }

    private boolean isResume = false;

    @Override
    protected void onResume() {
        super.onResume();
        isResume = true;
    }

    @Override
    protected void onPause() {
        super.onPause();
        isResume = false;
    }

}
