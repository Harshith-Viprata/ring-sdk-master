package com.example.ycblesdkdemo.upgrade.auto;

import android.Manifest;
import android.app.Activity;
import android.app.ProgressDialog;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.PowerManager;
import android.view.View;
import android.widget.EditText;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;
import com.example.ycblesdkdemo.util.ToastUtil;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.ScanDeviceBean;
import com.yucheng.ycbtsdk.response.BleConnectResponse;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleScanResponse;
import com.yucheng.ycbtsdk.utils.YCBTLog;

import org.greenrobot.eventbus.EventBus;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

/**
 * @author StevenLiu
 * @date 2023/5/17
 * @desc one word for this class
 */
public class AutoFactoryActivity extends Activity {
    private ProgressDialog progressDialog;
    private EditText ed_tab;
    private PowerManager powerManager = null;
    private PowerManager.WakeLock wakeLock = null;
    private TextView tv_add_new_number, tv_add_all_number;
    private int new_numbers;
    private EditText edRRi, edProductInfo;
    private String productInfo;
    private List<String> macs = new ArrayList<>();
    private boolean isWorking = false;
    private RadioGroup radioGroup;
    private List<Integer> ids = new ArrayList<>();
    private int state = 0, count = 0;
    private TextView tvDeviceState;

    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            if (isFinishing()) {
                return false;
            }
            switch (msg.what) {
                case 1://连接
                    if (macs == null || macs.size() == 0 || new_numbers <= 0 || isWorking) {
                        return false;
                    }
                    connectDevice();
                    break;
                case 2://成功
                    if (macs.size() > 0 && new_numbers > 0) {
                        int index = macs.size() - new_numbers;
                        new_numbers--;
                        tv_add_new_number.setText(new_numbers + "");
                        tv_add_all_number.setText((index + 1) + "");
                        YCBTLog.saveFile("mac地址.txt", macs.get(index), true);
                    }
                    isWorking = false;
                    shutDown();
                    break;
                case 3://搜索更新
                    tv_add_new_number.setText(new_numbers + "");
                    break;
                case 4://失败或超时
                    if (macs.size() > 0 && new_numbers > 0) {
                        macs.remove(macs.size() - new_numbers);
                        new_numbers--;
                    }
                    tvDeviceState.setText("连接断开");
                    YCBTClient.disconnectBle();
                    isWorking = false;
                    break;
                case 5://是否激活
                    if (state == 1) {
                        tvDeviceState.setText("激活成功");
                        ToastUtil.getInstance(AutoFactoryActivity.this).toast("激活成功");
                        handler.sendEmptyMessage(2);
                    } else if (count < 20) {
                        getState();
                        tvDeviceState.setText("正在激活");
                        handler.sendEmptyMessageDelayed(5, 3000);
                        count++;
                    } else {
                        handler.sendEmptyMessage(4);
                        ToastUtil.getInstance(AutoFactoryActivity.this).toast("激活失败");
                    }
                    break;
                case 6:
                    tvDeviceState.setText("正在激活");
                    break;
                case 7:
                    setData();
                    break;
            }
            return false;
        }
    });

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_firmware_auto_factory);
        init();
        initData();
    }

    private void init() {
        hasPermission();
        radioGroup = findViewById(R.id.auto_funs);
        tvDeviceState = findViewById(R.id.tv_device_state);
        findViewById(R.id.firmware_upgrade).setOnClickListener(new OnClickListenerImpl());
        ed_tab = findViewById(R.id.auto_ui_upgrade_tab);
        tv_add_new_number = findViewById(R.id.tv_add_new_number);
        tv_add_all_number = findViewById(R.id.tv_add_all_number);
        edRRi = findViewById(R.id.auto_rri_ed);
        edProductInfo = findViewById(R.id.auto_product_info_ed);
    }

    private void initData() {
        powerManager = (PowerManager) getSystemService(this.POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.FULL_WAKE_LOCK, "My Lock");
        radioGroup.setOnCheckedChangeListener(new OnCheckedChangeListenerImpl());
    }

    Thread thread = new Thread(new Runnable() {
        @Override
        public void run() {
            while (!isFinishing()) {
                if (!YCBTClient.isScaning() && !isWorking) {
                    if (new_numbers == 0) {
                        startScan();
                    } else {
                        handler.sendEmptyMessage(1);
                    }
                }
                try {
                    Thread.sleep(15000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    });

    private class OnClickListenerImpl implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.firmware_upgrade:
                    if (checked()) {
                        if (ids.size() > 0) {
                            showDialog();
                            thread.start();
                        }
                    }
                    break;
            }
        }
    }

    private void showDialog() {
        if (AutoFactoryActivity.this.isFinishing()) {
            return;
        }
        if (progressDialog == null) {
            progressDialog = ProgressDialog.show(AutoFactoryActivity.this, "提示", "正在运行...", true, false);
        }
        if (progressDialog != null && !progressDialog.isShowing()) {
            progressDialog.show();
        }
    }

    private void dissmissDialog() {
        if (!AutoFactoryActivity.this.isFinishing() && progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }

    private void startScan() {
        if (YCBTClient.isScaning()) {
            return;
        }
        YCBTClient.startScanBle(new BleScanResponse() {
            @Override
            public void onScanResponse(int i, ScanDeviceBean scanDeviceBean) {
                if (scanDeviceBean != null && scanDeviceBean.getDeviceName() != null) {
                    if (scanDeviceBean.getDeviceName().contains(ed_tab.getEditableText().toString().trim())) {
                        int rssi = -70;
                        try {
                            rssi = Integer.parseInt(edRRi.getEditableText().toString()) * -1;
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                        if (scanDeviceBean.getDeviceRssi() > rssi && !macs.contains(scanDeviceBean.getDeviceMac())) {
                            macs.add(scanDeviceBean.getDeviceMac());
                            new_numbers++;
                            handler.sendEmptyMessage(3);
                        }
                    }
                }
            }
        }, 6);
    }

    private boolean hasPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(AutoFactoryActivity.this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED
                    || ContextCompat.checkSelfPermission(AutoFactoryActivity.this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(AutoFactoryActivity.this, Manifest.permission.BLUETOOTH_SCAN)
                        || ActivityCompat.shouldShowRequestPermissionRationale(AutoFactoryActivity.this, Manifest.permission.BLUETOOTH_CONNECT)) {
                    requestPermissions(new String[]{Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT}, 1);
                } else {
                    Toast.makeText(AutoFactoryActivity.this, "手动开启允许查找附近设备权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(AutoFactoryActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(AutoFactoryActivity.this, Manifest.permission.ACCESS_FINE_LOCATION)) {
                    requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
                } else {
                    Toast.makeText(AutoFactoryActivity.this, "手动开启定位权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        }
        return true;
    }

    private boolean checked() {
        if (!hasPermission()) {
            Toast.makeText(AutoFactoryActivity.this, "请先开启蓝牙权限", Toast.LENGTH_LONG).show();
            return false;
        }
        if ("".equals(ed_tab.getEditableText().toString().trim())) {
            Toast.makeText(AutoFactoryActivity.this, "请先输入过滤条件", Toast.LENGTH_LONG).show();
            return false;
        }
        if ("".equals(edRRi.getEditableText().toString().trim())) {
            Toast.makeText(AutoFactoryActivity.this, "请先输入信号值", Toast.LENGTH_LONG).show();
            return false;
        }
        return true;
    }

    @Override
    protected void onResume() {
        super.onResume();
        try {
            if (wakeLock == null) {
                wakeLock = powerManager.newWakeLock(PowerManager.FULL_WAKE_LOCK, "My Lock");
            }
            if (!wakeLock.isHeld()) {
                wakeLock.acquire();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void connectDevice() {
        isWorking = true;
        handler.sendEmptyMessageDelayed(4, 20000);
        tvDeviceState.setText("正在连接");
        YCBTClient.connectBle(macs.get(macs.size() - new_numbers), new BleConnectResponse() {
            @Override
            public void onConnectResponse(int code) {
                if (code == 0) {
                    handler.sendEmptyMessage(7);
                } else {
                    handler.removeMessages(4);
                    handler.sendEmptyMessage(4);
                }
            }
        });
    }

    private void setData() {
        handler.removeMessages(4);
        handler.sendEmptyMessageDelayed(4, 20000);
        if (ids.size() == 0) return;
        switch (ids.get(0)) {
            case R.id.auto_fun_ali:
                state = 0;
                count = 0;
                tvDeviceState.setText("连接服务器");
                YCBTClient.aLiIOTKitStartChecked(AutoFactoryActivity.this, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int code, float ratio, HashMap resultMap) {
                        handler.removeMessages(4);
                        if (code == 0) {
                            if (ratio == 10) {
                                handler.sendEmptyMessage(2);
                            } else {
                                handler.sendEmptyMessage(6);
                                handler.sendEmptyMessageDelayed(5, 25000);
                            }
                        } else {
                            handler.sendEmptyMessage(4);
                        }
                    }
                });
                break;
            case R.id.auto_fun_product_info:
                try {
                    productInfo = edProductInfo.getEditableText().toString();
                } catch (NumberFormatException e) {
                    e.printStackTrace();
                    return;
                }
                YCBTClient.appSendProductInfo(0, productInfo, new BleDataResponse() {
                    @Override
                    public void onDataResponse(int code, float ratio, HashMap resultMap) {
                        System.out.println("chong---code==" + code);
                        handler.removeMessages(4);
                        if (code == 0) {
                            handler.sendEmptyMessageDelayed(2, 3000);
                        } else {
                            handler.sendEmptyMessage(4);
                        }
                    }
                });
                break;
        }
    }

    private void shutDown() {
        YCBTClient.appShutDown(1, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
            }
        });
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (wakeLock != null && wakeLock.isHeld()) {
            wakeLock.release();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        EventBus.getDefault().unregister(this);
    }

    private class OnCheckedChangeListenerImpl implements RadioGroup.OnCheckedChangeListener {
        @Override
        public void onCheckedChanged(RadioGroup group, int checkedId) {
            switch (checkedId) {
                case R.id.auto_fun_ali:
                    ids.add(R.id.auto_fun_ali);
                    break;
                case R.id.auto_fun_product_info:
                    ids.add(R.id.auto_fun_product_info);
                    break;
            }
        }
    }

    private void getState() {
        YCBTClient.getALiIOTActivationState(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                if (i == 0 && hashMap != null) {
                    try {
                        state = (int) hashMap.get("state");
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }
}
