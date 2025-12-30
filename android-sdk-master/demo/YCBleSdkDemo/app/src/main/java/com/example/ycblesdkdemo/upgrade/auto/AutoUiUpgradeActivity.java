package com.example.ycblesdkdemo.upgrade.auto;

import android.Manifest;
import android.app.Activity;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.PowerManager;
import android.view.View;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;
import com.example.ycblesdkdemo.model.ConnectEvent;
import com.example.ycblesdkdemo.upgrade.GetUrlActivity;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.ScanDeviceBean;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleScanResponse;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import static com.yucheng.ycbtsdk.Constants.BLEState.ReadWriteOK;

/**
 * @author StevenLiu
 * @date 2022/9/5
 * @desc one word for this class
 */
public class AutoUiUpgradeActivity extends Activity {
    private TextView ui_url;
    private ProgressDialog progressDialog;
    private TextView progressNumber;
    private ProgressBar progressBar;
    private EditText ed_tab;
    private String name = "";
    private PowerManager powerManager = null;
    private PowerManager.WakeLock wakeLock = null;
    private TextView tv_ui_upgrade_state, tv_ui_upgrade_success_number;
    private int number;
    private float progress, old_progress;
    private boolean isConnecting = false;
    private BluetoothAdapter mBluetoothAdapter;
    private List<String> macs = new ArrayList<>();

    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            switch (msg.what) {
                case 5://升级成功
                    Toast.makeText(AutoUiUpgradeActivity.this, "升级成功", Toast.LENGTH_LONG).show();
                    isUpgrading = false;
                    tv_ui_upgrade_state.setText("准备关机");
                    isShutDown = true;
                    number++;
                    tv_ui_upgrade_success_number.setText(number + "");
                    break;
                case 6://升级失败
                    Toast.makeText(AutoUiUpgradeActivity.this, "升级失败", Toast.LENGTH_LONG).show();
                    dissmissDialog();
                    startUiUpgrade();
                    break;
                case 7:
                    if (progress != 0 && progress == old_progress) {
                        n++;
                        if (n > 5) {
                            n = 0;
                            if (isShutDown) {
                                tv_ui_upgrade_state.setText("正在关机");
                                YCBTClient.resetQueue();
                                shutDown();
                            } else {
                                startUiUpgrade();
                                tv_ui_upgrade_state.setText("发送数据超时");
                            }
                        }
                    } else {
                        if (isConnecting) {
                            isConnecting = (progress == 0);
                        }
                        if (!isConnecting && progress == 0 && isUpgrading) {
                            n++;
                            if (n > 5) {
                                n = 0;
                                startUiUpgrade();
                                tv_ui_upgrade_state.setText("发送数据超时");
                            }
                        } else {
                            n = 0;
                        }
                        old_progress = progress;
                        progressBar.setProgress((int) progress);
                        progressNumber.setText(String.format("%.2f", progress) + "%");
                    }
                    break;
                case 8:
                    isConnecting = false;
                    isUpgrading = false;
                    tv_ui_upgrade_state.setText("连接超时");
                    mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
                    if (mBluetoothAdapter != null) {
                        if (mBluetoothAdapter.isEnabled()) {
                            mBluetoothAdapter.disable();
                        } else {
                            mBluetoothAdapter.enable();
                        }
                    }
                    break;
                case 9:
                    tv_ui_upgrade_state.setText("正在搜索...");
                    break;
                case 10:
                    handler.sendEmptyMessageDelayed(8, 60000);
                    tv_ui_upgrade_state.setText("正在连接...");
                    break;
            }
            return false;
        }
    });

    private int n = 0;
    private boolean isStart = false;

    Thread thread = new Thread(new Runnable() {
        @Override
        public void run() {
            while (!isFinishing()) {
                if (YCBTClient.connectState() != ReadWriteOK) {
                    isShutDown = false;
                    if (!YCBTClient.isScaning() && !isConnecting && !isUpgrading && isStart) {
                        startScan();
                    }
                }
                handler.sendEmptyMessage(7);
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }
    });

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_ui_auto_upgrade);
        init();
        powerManager = (PowerManager) getSystemService(this.POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.FULL_WAKE_LOCK, "My Lock");
        thread.start();
    }

    private void init() {
        hasPermission();
        YCBTClient.setOta(true);
        EventBus.getDefault().register(this);
        findViewById(R.id.select_ui_url).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.ui_upgrade).setOnClickListener(new OnClickListenerImpl());
        ui_url = findViewById(R.id.ui_url);
        progressNumber = findViewById(R.id.progress_number);
        progressBar = findViewById(R.id.progress_bar);
        ed_tab = findViewById(R.id.auto_ui_upgrade_tab);
        tv_ui_upgrade_state = findViewById(R.id.ui_upgrade_state);
        tv_ui_upgrade_success_number = findViewById(R.id.ui_upgrade_success_number);
    }

    private class OnClickListenerImpl implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.select_ui_url:
                    startActivityForResult(new Intent(AutoUiUpgradeActivity.this, GetUrlActivity.class), 1564);
                    break;
                case R.id.ui_upgrade:
                    if (!hasPermission()) {
                        return;
                    }
                    if ("".equals(ed_tab.getEditableText().toString().trim())) {
                        Toast.makeText(AutoUiUpgradeActivity.this, "请先输入过滤条件", Toast.LENGTH_LONG).show();
                        return;
                    }
                    name = ed_tab.getEditableText().toString().trim();
                    isStart = true;
                    startScan();
                    break;
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent intent) {
        System.out.println("chong--------requestCode==" + requestCode + "--" + intent);
        if (resultCode == 4535 && requestCode == 1564 && intent != null && intent.getStringExtra("url") != null) {
            ui_url.setText(intent.getStringExtra("url"));
        }
    }

    private void showDialog() {
        if (AutoUiUpgradeActivity.this.isFinishing()) {
            return;
        }
        if (progressDialog == null) {
            progressDialog = ProgressDialog.show(AutoUiUpgradeActivity.this, "提示", "正在UI升级...", true, false);
        }
        if (progressDialog != null && !progressDialog.isShowing()) {
            progressDialog.show();
        }
    }

    private void dissmissDialog() {
        if (!AutoUiUpgradeActivity.this.isFinishing() && progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }

    private void startScan() {
        if (YCBTClient.isScaning()) {
            return;
        }
        handler.sendEmptyMessage(9);
        YCBTClient.startScanBle(new BleScanResponse() {
            @Override
            public void onScanResponse(int i, ScanDeviceBean scanDeviceBean) {
                if (scanDeviceBean != null && scanDeviceBean.getDeviceName() != null) {
                    if (scanDeviceBean.getDeviceName().contains(name) && !isUpgrading && !isConnecting && scanDeviceBean.getDeviceRssi() >= -60) {
                        isUpgrading = true;
                        isConnecting = true;
                        handler.sendEmptyMessage(10);
                        YCBTClient.connectBle(scanDeviceBean.getDeviceMac(), null);
                    }
                }
            }
        }, 6);
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void connectEvent(ConnectEvent connectEvent) {
        if (connectEvent.state == 1) {
            tv_ui_upgrade_state.setText("连接成功");
            isConnecting = false;
            handler.removeMessages(8);
            if (macs.contains(YCBTClient.getBindDeviceMac())) {
                progress = 100;
                isShutDown = true;
            } else {
                startUiUpgrade();
            }
        } else if (connectEvent.state == 0) {
            tv_ui_upgrade_state.setText("连接断开");
            isConnecting = false;
            isUpgrading = false;
            handler.removeMessages(8);
        }
    }

    private void shutDown() {
        if (YCBTClient.connectState() != ReadWriteOK) {
            isShutDown = false;
            return;
        }
        YCBTClient.appShutDown(1, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                System.out.println("chong--------shutDown==" + code + "--" + resultMap);
                if (code == 0 && resultMap.get("data") != null && (int) resultMap.get("data") == 0) {
                    isShutDown = false;
                }
            }
        });
    }

    private boolean isUpgrading = false;
    private boolean isShutDown = false;

    private void startUiUpgrade() {
        if (isShutDown) {
            return;
        }
        progress = 0;
        if (YCBTClient.connectState() != ReadWriteOK) {
            dissmissDialog();
            isUpgrading = false;
            startScan();
            return;
        }
        if (!"".equals(ui_url.getText().toString())) {
            System.out.println("chong--------ui_url==" + ui_url.getText().toString());
            showDialog();
            YCBTClient.resetQueue();
            YCBTClient.watchUiUpgrade(ui_url.getText().toString(), new BleDataResponse() {
                @Override
                public void onDataResponse(int code, float ratio, HashMap resultMap) {
                    System.out.println("chong--------progress==" + resultMap);
                    if (code == 0 && resultMap != null) {
                        if (resultMap.get("progress") != null) {
                            progress = (float) resultMap.get("progress");
                        } else if (resultMap.get("data") != null) {
                            if ((int) resultMap.get("data") == 0) {
                                macs.add(YCBTClient.getBindDeviceMac());
                                handler.sendEmptyMessage(5);
                            } else {
                                handler.sendEmptyMessage(6);
                            }
                        }
                    } else {
                        handler.sendEmptyMessage(6);
                    }
                }
            });
        } else {
            Toast.makeText(AutoUiUpgradeActivity.this, "请先选择文件", Toast.LENGTH_LONG).show();
        }
    }

    private boolean hasPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(AutoUiUpgradeActivity.this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED
                    || ContextCompat.checkSelfPermission(AutoUiUpgradeActivity.this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(AutoUiUpgradeActivity.this, Manifest.permission.BLUETOOTH_SCAN)
                        || ActivityCompat.shouldShowRequestPermissionRationale(AutoUiUpgradeActivity.this, Manifest.permission.BLUETOOTH_CONNECT)) {
                    requestPermissions(new String[]{Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT}, 1);
                } else {
                    Toast.makeText(AutoUiUpgradeActivity.this, "手动开启允许查找附近设备权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(AutoUiUpgradeActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(AutoUiUpgradeActivity.this, Manifest.permission.ACCESS_FINE_LOCATION)) {
                    requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
                } else {
                    Toast.makeText(AutoUiUpgradeActivity.this, "手动开启定位权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
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

    @Override
    protected void onPause() {
        super.onPause();
        if (wakeLock != null && wakeLock.isHeld()) {
            wakeLock.release();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        EventBus.getDefault().unregister(this);
        YCBTClient.setOta(false);
    }

}