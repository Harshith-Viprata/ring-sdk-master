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
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;
import com.example.ycblesdkdemo.model.ConnectEvent;
import com.example.ycblesdkdemo.upgrade.GetUrlActivity;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.ScanDeviceBean;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleScanResponse;
import com.yucheng.ycbtsdk.upgrade.DfuCallBack;
import com.yucheng.ycbtsdk.utils.YCBTLog;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Locale;

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
public class AutoFirmwareUpgradeActivity extends Activity {
    private TextView firmware_url;
    private ProgressDialog progressDialog;
    private TextView progressNumber;
    private ProgressBar progressBar;
    private EditText ed_tab;
    private PowerManager powerManager = null;
    private PowerManager.WakeLock wakeLock = null;
    private TextView tv_firmware_upgrade_state, tv_firmware_upgrade_success_number;
    private int number;
    private boolean isUpgrading = false;
    private boolean isConnecting = false;
    private int errorNumber = 0;
    private RadioGroup radioGroup;
    private boolean isCheckedTemp = false;
    private String mac = "";
    private EditText edRRi, edMtu;
    private BluetoothAdapter mBluetoothAdapter;
    private int max = 100;

    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            if (isFinishing()) {
                return false;
            }
            switch (msg.what) {
                case 2://循环搜索
                    if (!isUpgrading && !YCBTClient.isScaning()) {
                        startScan();
                    }
                    handler.sendEmptyMessageDelayed(2, 10000);
                    break;
                case 3://关机后重新扫描
                    handler.removeMessages(3);
                    reStartScanDevice();
                    break;
                case 5://升级成功
                    handler.removeMessages(15);
                    YCBTLog.saveFile("mac地址.txt", mac + "\n", true);
                    errorNumber = 0;
                    Toast.makeText(AutoFirmwareUpgradeActivity.this, "升级成功", Toast.LENGTH_LONG).show();
                    number++;
                    tv_firmware_upgrade_success_number.setText(number + "");
                    isUpgrading = false;
                    dissmissDialog();
                    break;
                case 6://升级失败
                    handler.removeMessages(15);
                    errorNumber++;
                    Toast.makeText(AutoFirmwareUpgradeActivity.this, "升级失败", Toast.LENGTH_LONG).show();
                    isUpgrading = false;
                    if (errorNumber >= 3) {
                        errorNumber = 0;
                        dissmissDialog();
                    } else {
                        startFirmwareUpgrade();
                    }
                    break;
                case 8://已是最新版本
                    handler.removeMessages(15);
                    errorNumber = 0;
                    Toast.makeText(AutoFirmwareUpgradeActivity.this, "已是最新版本", Toast.LENGTH_LONG).show();
                    handler.removeMessages(13);
                    handler.sendEmptyMessageDelayed(13, 2000);
                    shutDown();
                    break;
                case 9:
                    tv_firmware_upgrade_state.setText("固件升级正在连接...");
                    break;
                case 10:
                    tv_firmware_upgrade_state.setText("固件升级连接成功");
                    break;
                case 11:
                    tv_firmware_upgrade_state.setText("固件升级断开连接");
                    break;
                case 12://温度校准
                    errorNumber = 0;
                    handler.sendEmptyMessageDelayed(13, 4000);
                    temperatureCorrect();
                    break;
                case 13:
                    handler.removeMessages(13);
                    reStartScanDevice();
                    break;
                case 14://升级错误
                    tv_firmware_upgrade_state.setText("升级错误");
                    reStartScanDevice();
                    break;
                case 15://升级超时
                    tv_firmware_upgrade_state.setText("升级超时");
                    reStartScanDevice();
                    break;
                case 16://连接超时
                    isConnecting = false;
                    isUpgrading = false;
                    tv_firmware_upgrade_state.setText("连接超时");
                    mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
                    if (mBluetoothAdapter != null) {
                        if (mBluetoothAdapter.isEnabled()) {
                            mBluetoothAdapter.disable();
                            handler.sendEmptyMessageDelayed(18, 5000);
                        } else {
                            mBluetoothAdapter.enable();
                        }
                    } else {
                        reStartScanDevice();
                    }
                    break;
                case 17:
                    tv_firmware_upgrade_state.setText("正在连接...");
                    handler.removeMessages(16);
                    handler.sendEmptyMessageDelayed(16, 60000);
                    break;
                case 18://重启蓝牙
                    mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
                    if (mBluetoothAdapter != null && !mBluetoothAdapter.isEnabled()) {
                        mBluetoothAdapter.enable();
                    } else {
                        reStartScanDevice();
                    }
                    break;
            }
            return false;
        }
    });

    private void reStartScanDevice() {
        isUpgrading = false;
        YCBTClient.disconnectBle();
        startScan();
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_firmware_auto_upgrade);
        //JL_Log.setIsLog(BuildConfig.DEBUG);
        //JL_Log.setIsSaveLogFile(getApplicationContext(), BuildConfig.DEBUG);
        //JL_Log.setUseTest(BuildConfig.DEBUG);
        init();
        initData();
    }

    private void init() {
        YCBTClient.setOta(true);
        hasPermission();
        EventBus.getDefault().register(this);
        findViewById(R.id.select_firmware_url).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.firmware_upgrade).setOnClickListener(new OnClickListenerImpl());
        firmware_url = findViewById(R.id.firmware_url);
        progressNumber = findViewById(R.id.progress_number);
        progressBar = findViewById(R.id.progress_bar);
        ed_tab = findViewById(R.id.auto_ui_upgrade_tab);
        tv_firmware_upgrade_state = findViewById(R.id.firmware_upgrade_state);
        tv_firmware_upgrade_success_number = findViewById(R.id.firmware_upgrade_success_number);
        radioGroup = findViewById(R.id.firmware_upgrade_radio_group);
        edRRi = findViewById(R.id.auto_upgrade_rri_ed);
        edMtu = findViewById(R.id.auto_upgrade_mtu_ed);
    }

    private void initData() {
        firmware_url.setText(copyAssetGetFilePath("et210-v1.63.zip"));
        powerManager = (PowerManager) getSystemService(this.POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.FULL_WAKE_LOCK, "My Lock");
        radioGroup.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                switch (checkedId) {
                    case R.id.firmware_upgrade_temp_calibration:
                        isCheckedTemp = ((RadioButton) group.findViewById(checkedId)).isChecked();
                        break;
                }
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
            if(outFile.exists()){
                outFile.delete();
            }
            boolean res = outFile.createNewFile();
            if (!res) {
                return null;
            }
            /*if (!outFile.exists()) {
                boolean res = outFile.createNewFile();
                if (!res) {
                    return null;
                }
            } else {
                if (outFile.length() > 10) {//表示已经写入一次
                    return outFile.getPath();
                }
            }*/
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
                    startActivityForResult(new Intent(AutoFirmwareUpgradeActivity.this, GetUrlActivity.class), 1564);
                    break;
                case R.id.firmware_upgrade:
                    handler.removeMessages(2);
                    handler.sendEmptyMessage(2);
                    System.out.println("chong------------upgrade==");
                    startFirmwareUpgrade();
                    break;
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent intent) {
        System.out.println("chong--------requestCode==" + requestCode + "--" + intent);
        if (resultCode == 4535 && requestCode == 1564 && intent != null && intent.getStringExtra("url") != null) {
            firmware_url.setText(intent.getStringExtra("url"));
        }
    }

    private void showDialog() {
        if (AutoFirmwareUpgradeActivity.this.isFinishing()) {
            return;
        }
        if (progressDialog == null) {
            progressDialog = ProgressDialog.show(AutoFirmwareUpgradeActivity.this, "提示", "正在固件升级...", true, false);
        }
        if (progressDialog != null && !progressDialog.isShowing()) {
            progressDialog.show();
        }
    }

    private void dissmissDialog() {
        if (!AutoFirmwareUpgradeActivity.this.isFinishing() && progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }

    private void startScan() {
        if (YCBTClient.isScaning() || isUpgrading || isConnecting) {
            return;
        }
        if (YCBTClient.connectState() == ReadWriteOK && !isUpgrading) {
            startFirmwareUpgrade();
            return;
        }
        dissmissDialog();
        tv_firmware_upgrade_state.setText("正在搜索...");
        /*if(YCBTClient.getBindDeviceMac() != null){
            YCBTClient.connectBle(YCBTClient.getBindDeviceMac(), null);
            return;
        }*/
        YCBTClient.startScanBle(new BleScanResponse() {
            @Override
            public void onScanResponse(int i, ScanDeviceBean scanDeviceBean) {
                if (scanDeviceBean != null && scanDeviceBean.getDeviceName() != null) {
                    if (!isUpgrading) {
                        if (scanDeviceBean.getDeviceName().contains(ed_tab.getEditableText().toString().trim())) {
                            try {
                                int mtu = Integer.parseInt(edMtu.getEditableText().toString());
                                if (mtu <= 512 && mtu >= 23) {
                                    YCBTClient.setMtu(mtu);
                                }
                            } catch (Exception e) {
                            }
                            int rssi = -70;
                            try {
                                rssi = Integer.parseInt(edRRi.getEditableText().toString()) * -1;
                            } catch (Exception e) {
                            }
                            if (scanDeviceBean.getDeviceRssi() > rssi) {
                                System.out.println("chong----rssi==" + scanDeviceBean.getDeviceRssi());
                                YCBTClient.stopScanBle();
                                mac = scanDeviceBean.getDeviceMac();
                                isConnecting = true;
                                YCBTClient.connectBle(scanDeviceBean.getDeviceMac(), null);
                                handler.sendEmptyMessage(17);
                            }
                        } else if (scanDeviceBean.getDeviceName().toLowerCase(Locale.ROOT).contains("dfu")) {
                            YCBTClient.stopScanBle();
                            mac = getMacSubOne(scanDeviceBean.getDeviceMac());
                            upgrade(scanDeviceBean.getDeviceMac(), scanDeviceBean.getDeviceName());
                        }
                    }
                }
            }
        }, 6);
    }

    private String getMacSubOne(String mac) {
        String end = Integer.toHexString((Integer.valueOf(mac.split(":")[mac.split(":").length - 1], 16) - 1) & 0xff).toUpperCase();
        return mac.substring(0, mac.length() - 2) + (end.length() == 2 ? end : "0" + end);
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void connectEvent(ConnectEvent connectEvent) {
        isUpgrading = false;
        if (connectEvent.state == 1) {
            handler.removeMessages(16);
            tv_firmware_upgrade_state.setText("连接成功");
            isConnecting = false;
            isUpgrading = false;
            startFirmwareUpgrade();
        } else if (connectEvent.state == 0) {
            handler.removeMessages(16);
            tv_firmware_upgrade_state.setText("连接断开");
            isConnecting = false;
            isUpgrading = false;
            YCBTClient.stopScanBle();
        }
    }

    private void shutDown() {
        YCBTClient.appShutDown(1, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
            }
        });
    }

    private void temperatureCorrect() {
        YCBTClient.appTemperatureCorrect(0, 0, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                if (code == 0) {
                    handler.removeMessages(13);
                    handler.sendEmptyMessageDelayed(8, 5000);
                } else {
                    handler.removeMessages(13);
                    handler.sendEmptyMessage(13);
                }
            }
        });
    }

    private void startFirmwareUpgrade() {
        System.out.println("chong------checked==" + checked() + "--state==" + (YCBTClient.connectState() != ReadWriteOK));
        System.out.println("chong------checked==" + checked() + "--state==" + (YCBTClient.connectState() != ReadWriteOK) + "--auth==" + YCBTClient.getAuthPass());
        if (!checked()) {
            return;
        }
        if (YCBTClient.connectState() != ReadWriteOK) {
            startScan();
            return;
        }
        if (YCBTClient.getChipScheme() == 3) {
            if (!YCBTClient.getAuthPass()) {
                YCBTClient.setAuthPass(null);
                return;
            }
        }
        System.out.println("chong------YCBTClient.getBindDeviceVersion()==" + YCBTClient.getBindDeviceVersion());
        if (!checkVersion(firmware_url.getText().toString())) {
            return;
        }
        System.out.println("chong----开始准备升级");
        if (isUpgrading) {
            return;
        }
        upgrade(null, null);
    }

    private void upgrade(String mac, String name) {
        isUpgrading = true;
        if (YCBTClient.getChipScheme() != 3) {
            handler.removeMessages(15);
            handler.sendEmptyMessageDelayed(15, 120000);
        }
        showDialog();
        if (YCBTClient.getChipScheme() == 3) {
            max = 10000;
            progressNumber.setText("0.00%");
        } else {
            progressNumber.setText(0 + "%");
            max = 100;
        }
        progressBar.setMax(max);
        progressBar.setProgress(0);

        YCBTClient.upgradeFirmware(AutoFirmwareUpgradeActivity.this, mac, name, firmware_url.getText().toString(), new DfuCallBack() {
            @Override
            public void progress(int progress) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        progressBar.setProgress(progress);
                        String mCurrentProgress;
                        if (max > 100) {
                            mCurrentProgress = String.format("%.2f", progress * 100.0f / max);
                        } else {
                            mCurrentProgress = String.format("%d", progress * 100 / max);
                        }
                        progressNumber.setText(mCurrentProgress + "%");
                    }
                });
            }

            @Override
            public void success() {
                handler.sendEmptyMessage(5);
            }

            @Override
            public void failed(String msg) {
                handler.removeMessages(6);
                handler.sendEmptyMessageDelayed(6, 1000);
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
                if (isCheckedTemp) {
                    handler.sendEmptyMessage(12);
                } else {
                    handler.sendEmptyMessage(8);
                }
            }

            @Override
            public void error(String msg) {
                handler.sendEmptyMessage(14);
            }
        });
    }

    private boolean hasPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(AutoFirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED
                    || ContextCompat.checkSelfPermission(AutoFirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(AutoFirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_SCAN)
                        || ActivityCompat.shouldShowRequestPermissionRationale(AutoFirmwareUpgradeActivity.this, Manifest.permission.BLUETOOTH_CONNECT)) {
                    requestPermissions(new String[]{Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT}, 1);
                } else {
                    Toast.makeText(AutoFirmwareUpgradeActivity.this, "手动开启允许查找附近设备权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(AutoFirmwareUpgradeActivity.this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                if (ActivityCompat.shouldShowRequestPermissionRationale(AutoFirmwareUpgradeActivity.this, Manifest.permission.ACCESS_FINE_LOCATION)) {
                    requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION}, 1);
                } else {
                    Toast.makeText(AutoFirmwareUpgradeActivity.this, "手动开启定位权限", Toast.LENGTH_LONG).show();
                }
                return false;
            }
        }
        return true;
    }

    private boolean checked() {
        if (!hasPermission()) {
            Toast.makeText(AutoFirmwareUpgradeActivity.this, "请先开启蓝牙权限", Toast.LENGTH_LONG).show();
            return false;
        }
        if ("".equals(ed_tab.getEditableText().toString().trim())) {
            Toast.makeText(AutoFirmwareUpgradeActivity.this, "请先输入过滤条件", Toast.LENGTH_LONG).show();
            return false;
        }
        if ("".equals(firmware_url.getText().toString().trim())) {
            Toast.makeText(AutoFirmwareUpgradeActivity.this, "请先选择升级文件", Toast.LENGTH_LONG).show();
            return false;
        }
        return true;
    }

    private boolean checkVersion(String firmwareFilePath) {
        try {
            System.out.println("chong---------version==" + YCBTClient.getBindDeviceVersion());
            String[] version = YCBTClient.getBindDeviceVersion().split("\\.");
            if (version.length < 2 || ("0".equals(version[0]) && "0".equals(version[1]))) {
                return false;
            }
            int deviceMainVersion = Integer.parseInt(version[0]);
            int deviceSubVersion = Integer.parseInt(version[1]);
            String name = firmwareFilePath.substring(firmwareFilePath.lastIndexOf("/") + 1, firmwareFilePath.length());
            String[] versions = name.substring(name.lastIndexOf("-") + 2, name.length()).split("\\.");
            if (versions.length > 2) {
                int firmwareMainVersion = Integer.parseInt(versions[0]);
                int firmwareSubVersion = Integer.parseInt(versions[1]);
                //if (firmwareMainVersion > deviceMainVersion || (firmwareMainVersion == deviceMainVersion && firmwareSubVersion > deviceSubVersion)) {
                if (firmwareMainVersion != deviceMainVersion || firmwareSubVersion != deviceSubVersion) {
                    return true;
                } else {
                    isUpgrading = true;
                    handler.sendEmptyMessage(8);
                }
            } else {
                reStartScanDevice();
                YCBTLog.e("FirmwareFilePath is error.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            reStartScanDevice();
            YCBTLog.e("FirmwareFilePath is error.");
        }
        return false;
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
