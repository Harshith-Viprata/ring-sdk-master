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
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;
import com.example.ycblesdkdemo.adapter.DeviceAdapter;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.ScanDeviceBean;
import com.yucheng.ycbtsdk.response.BleScanResponse;
import com.yucheng.ycbtsdk.upgrade.DfuCallBack;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

/**
 * @author StevenLiu
 * @date 2022/8/5
 * @desc one word for this class
 */
public class FirmwareRecoveryActivity extends Activity {
    private TextView firmware_url, firmware_upgrade_state;
    private ProgressDialog progressDialog;
    private TextView progressNumber;
    private ProgressBar progressBar;

    private ListView listView;
    private List<ScanDeviceBean> listModel = new ArrayList<>();
    private List<String> listVal = new ArrayList<>();
    private DeviceAdapter deviceAdapter;
    private ScanDeviceBean scanDeviceBean;

    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            switch (msg.what) {
                case 5:
                    Toast.makeText(FirmwareRecoveryActivity.this, "升级成功", Toast.LENGTH_LONG).show();
                    dissmissDialog();
                    break;
                case 6:
                    Toast.makeText(FirmwareRecoveryActivity.this, "升级失败", Toast.LENGTH_LONG).show();
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
        setContentView(R.layout.activity_firmware_recovery);
        init();
        initData();
    }

    private void init() {
        findViewById(R.id.select_firmware_url).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.firmware_upgrade).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.bt_start_scan).setOnClickListener(new OnClickListenerImpl());
        firmware_url = findViewById(R.id.firmware_url);
        progressNumber = findViewById(R.id.progress_number);
        progressBar = findViewById(R.id.progress_bar);
        firmware_upgrade_state = findViewById(R.id.firmware_upgrade_state);
        listView = findViewById(R.id.device_list_view);
    }

    private void initData() {
        try {
            //InputStream abpath = getClass().getResourceAsStream("/assets/ks05_0.92.zip");
            //firmware_url.setText("file:///android_asset/assets/ks05_0.92.zip");
            firmware_url.setText(copyAssetGetFilePath("ks05_0.92.zip"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        deviceAdapter = new DeviceAdapter(FirmwareRecoveryActivity.this, listModel);
        listView.setAdapter(deviceAdapter);
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                YCBTClient.stopScanBle();
                scanDeviceBean = (ScanDeviceBean) parent.getItemAtPosition(position);
            }
        });
    }

    private String copyAssetGetFilePath(String fileName) {
        try {
            File cacheDir = getApplicationContext().getCacheDir();
            if (!cacheDir.exists()) {
                cacheDir.mkdirs();
            }
            File outFile = new File(cacheDir, fileName);
            if (!outFile.exists()) {
                boolean res = outFile.createNewFile();
                if (!res) {
                    return null;
                }
            } else {
                if (outFile.length() > 10) {//表示已经写入一次
                    return outFile.getPath();
                }
            }
            InputStream is = getApplicationContext().getAssets().open(fileName);
            FileOutputStream fos = new FileOutputStream(outFile);
            byte[] buffer = new byte[1024];
            int byteCount;
            while ((byteCount = is.read(buffer)) != -1) {
                fos.write(buffer, 0, byteCount);
            }
            fos.flush();
            is.close();
            fos.close();
            return outFile.getPath();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    private class OnClickListenerImpl implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.select_firmware_url:
                    startActivityForResult(new Intent(FirmwareRecoveryActivity.this, GetUrlActivity.class), 1564);
                    break;
                case R.id.firmware_upgrade:
                    upgrade();
                    break;
                case R.id.bt_start_scan: {
                    //YCBTClient.connectBle("DA:18:56:2C:3C:D0", null);
                    YCBTClient.startScanBle(new BleScanResponse() {
                        @Override
                        public void onScanResponse(int i, ScanDeviceBean scanDeviceBean) {
                            if (scanDeviceBean != null && scanDeviceBean.getDeviceMac() != null && scanDeviceBean.getDeviceName() != null) {
                                if (!listVal.contains(scanDeviceBean.getDeviceMac())) {
                                    listVal.add(scanDeviceBean.getDeviceMac());
                                    deviceAdapter.addModel(scanDeviceBean);
                                }
                                Log.e("device", "mac=" + scanDeviceBean.getDeviceMac() + ";name=" + scanDeviceBean.getDeviceName() + "rssi=" + scanDeviceBean.getDeviceRssi());
                            }
                        }
                    }, 6);
                    break;
                }
            }
        }
    }

    private void upgrade() {
        if (!checked()) {
            return;
        }
        showDialog();
        YCBTClient.upgradeFirmware(FirmwareRecoveryActivity.this, scanDeviceBean.getDeviceMac(), scanDeviceBean.getDeviceName(), firmware_url.getText().toString(), new DfuCallBack() {
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
            public void error(String msg) {

            }
        });
    }

    private boolean checked() {
        if (!hasPermission()) {
            Toast.makeText(FirmwareRecoveryActivity.this, "请先开启蓝牙权限", Toast.LENGTH_LONG).show();
            return false;
        }
        if ("".equals(firmware_url.getText().toString().trim())) {
            Toast.makeText(FirmwareRecoveryActivity.this, "请先选择升级文件", Toast.LENGTH_LONG).show();
            return false;
        }
        if (scanDeviceBean == null) {
            Toast.makeText(FirmwareRecoveryActivity.this, "请先选择设备", Toast.LENGTH_LONG).show();
            return false;
        }
        return true;
    }

    private boolean hasPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(FirmwareRecoveryActivity.this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED
                    || ContextCompat.checkSelfPermission(FirmwareRecoveryActivity.this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(FirmwareRecoveryActivity.this, Manifest.permission.BLUETOOTH_SCAN)
                        || ActivityCompat.shouldShowRequestPermissionRationale(FirmwareRecoveryActivity.this, Manifest.permission.BLUETOOTH_CONNECT)) {
                    requestPermissions(new String[]{Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT}, 1);
                } else {
                    Toast.makeText(FirmwareRecoveryActivity.this, "手动开启允许查找附近设备权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(FirmwareRecoveryActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(FirmwareRecoveryActivity.this, Manifest.permission.ACCESS_FINE_LOCATION)) {
                    requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
                } else {
                    Toast.makeText(FirmwareRecoveryActivity.this, "手动开启定位权限", Toast.LENGTH_LONG).show();
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
        if (FirmwareRecoveryActivity.this.isFinishing()) {
            return;
        }
        if (progressDialog == null) {
            progressDialog = ProgressDialog.show(FirmwareRecoveryActivity.this, "提示", "正在固件恢复...", true, false);
        }
        if (progressDialog != null && !progressDialog.isShowing()) {
            progressDialog.show();
        }
    }

    private void dissmissDialog() {
        if (!FirmwareRecoveryActivity.this.isFinishing() && progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }


}