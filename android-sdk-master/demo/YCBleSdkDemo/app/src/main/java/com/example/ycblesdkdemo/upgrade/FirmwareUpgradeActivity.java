package com.example.ycblesdkdemo.upgrade;

import android.Manifest;
import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.PowerManager;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.upgrade.DfuCallBack;

import java.util.HashMap;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import static com.yucheng.ycbtsdk.Constants.BLEState.ReadWriteOK;

/**
 * @author StevenLiu
 * @date 2022/8/5
 * @desc one word for this class
 */
public class FirmwareUpgradeActivity extends Activity {
    private TextView firmware_url, firmware_version, firmware_upgrade_state;
    private ProgressDialog progressDialog;
    private TextView progressNumber;
    private ProgressBar progressBar;
    private String deviceVersion;
    private final static String TAG = FirmwareUpgradeActivity.class.getSimpleName();
    PowerManager powerManager = null;
    PowerManager.WakeLock wakeLock = null;

    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            switch (msg.what) {
                case 4:
                    ((TextView) findViewById(R.id.firmware_version)).setText("v" + deviceVersion);
                    break;
                case 5:
                    Toast.makeText(FirmwareUpgradeActivity.this, "升级成功", Toast.LENGTH_LONG).show();
                    dissmissDialog();
                    break;
                case 6:
                    Toast.makeText(FirmwareUpgradeActivity.this, "升级失败", Toast.LENGTH_LONG).show();
                    dissmissDialog();
                    break;
                case 8:
                    Toast.makeText(FirmwareUpgradeActivity.this, "Is the latest version.", Toast.LENGTH_LONG).show();
                    dissmissDialog();
                    break;
                case 9:
                    firmware_upgrade_state.setText("固件升级正在连接...");
                    break;
                case 10:
                    firmware_upgrade_state.setText("固件升级连接成功");
                    break;
                case 11:
                    firmware_upgrade_state.setText("固件升级断开连接");
                    break;
            }
            return false;
        }
    });

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_firmware_upgrade);
        init();
        initData();
    }

    private void init() {
        findViewById(R.id.select_firmware_url).setOnClickListener(new FirmwareUpgradeActivity.OnClickListenerImpl());
        findViewById(R.id.firmware_upgrade).setOnClickListener(new FirmwareUpgradeActivity.OnClickListenerImpl());
        firmware_url = findViewById(R.id.firmware_url);
        progressNumber = findViewById(R.id.progress_number);
        progressBar = findViewById(R.id.progress_bar);
        firmware_upgrade_state = findViewById(R.id.firmware_upgrade_state);
        powerManager = (PowerManager) getSystemService(this.POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.FULL_WAKE_LOCK, "My Lock");
        if (wakeLock != null) {
            wakeLock.acquire();
        }
    }

    private void initData() {
        YCBTClient.getDeviceInfo(new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                if (code == 0) {
                    if (resultMap != null) {
                        HashMap data = (HashMap) resultMap.get("data");
                        if (data != null) {
                            deviceVersion = (String) data.get("deviceVersion");
                            handler.sendEmptyMessage(4);
                        }
                    }
                }
            }
        });
    }

    private class OnClickListenerImpl implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.select_firmware_url:
                    startActivityForResult(new Intent(FirmwareUpgradeActivity.this, GetUrlActivity.class), 1564);
                    break;
                case R.id.firmware_upgrade:
                    upgrade();
                    break;
            }
        }
    }

    private void upgrade() {
        if (!checked()) {
            return;
        }
        showDialog();
        YCBTClient.upgradeFirmware(FirmwareUpgradeActivity.this, null, null, firmware_url.getText().toString(), new DfuCallBack() {
            @Override
            public void progress(int progress) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        progressBar.setProgress(progress);
                        progressNumber.setText(progress + "%");
                    }
                });
            }

            @Override
            public void success() {
                handler.sendEmptyMessage(5);
            }

            @Override
            public void failed(String msg) {
                handler.sendEmptyMessage(6);
            }

            @Override
            public void disconnect() {
                handler.sendEmptyMessage(11);
            }

            @Override
            public void connecting() {
                handler.sendEmptyMessage(9);
            }

            @Override
            public void connected() {
                handler.sendEmptyMessage(10);
            }

            @Override
            public void latest() {
                handler.sendEmptyMessage(8);
            }

            @Override
            public void error(String msg){

            }
        });
    }


    private boolean checked() {
        if (!hasPermission()) {
            Toast.makeText(FirmwareUpgradeActivity.this, "请先开启蓝牙权限", Toast.LENGTH_LONG).show();
            return false;
        }
        if (YCBTClient.connectState() != ReadWriteOK) {
            Toast.makeText(FirmwareUpgradeActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
            return false;
        }
        if ("".equals(firmware_url.getText().toString().trim())) {
            Toast.makeText(FirmwareUpgradeActivity.this, "请先选择升级文件", Toast.LENGTH_LONG).show();
            return false;
        }
        return true;
    }

    private boolean hasPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(FirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED
                    || ContextCompat.checkSelfPermission(FirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(FirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_SCAN)
                        || ActivityCompat.shouldShowRequestPermissionRationale(FirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_CONNECT)) {
                    requestPermissions(new String[]{Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT}, 1);
                } else {
                    Toast.makeText(FirmwareUpgradeActivity.this, "手动开启允许查找附近设备权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(FirmwareUpgradeActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(FirmwareUpgradeActivity.this, Manifest.permission.ACCESS_FINE_LOCATION)) {
                    requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
                } else {
                    Toast.makeText(FirmwareUpgradeActivity.this, "手动开启定位权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        }
        return true;
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent intent) {
        System.out.println("chong--------requestCode==" + requestCode + "--" + intent);
        if (resultCode == 4535 && requestCode == 1564 && intent != null && intent.getStringExtra("url") != null) {
            firmware_url.setText(intent.getStringExtra("url"));
        }
    }

    private void showDialog() {
        if (FirmwareUpgradeActivity.this.isFinishing()) {
            return;
        }
        if (progressDialog == null) {
            progressDialog = ProgressDialog.show(FirmwareUpgradeActivity.this, "提示", "正在固件升级...", true, false);
        }
        if (progressDialog != null && !progressDialog.isShowing()) {
            progressDialog.show();
        }
    }

    private void dissmissDialog() {
        if (!FirmwareUpgradeActivity.this.isFinishing() && progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            if (wakeLock != null && wakeLock.isHeld()) {
                wakeLock.release();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}