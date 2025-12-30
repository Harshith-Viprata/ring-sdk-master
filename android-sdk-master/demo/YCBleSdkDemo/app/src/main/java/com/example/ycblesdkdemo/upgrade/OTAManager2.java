/*
package com.example.ycblesdkdemo.upgrade;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.content.Context;

import com.example.ycblesdkdemo.upgrade.jl.BluetoothEventListener;
import com.example.ycblesdkdemo.upgrade.jl.BluetoothHelper;
import com.example.ycblesdkdemo.upgrade.jl.HealthUtil;
import com.jieli.bluetooth_connect.bean.history.HistoryRecord;
import com.jieli.bluetooth_connect.constant.BluetoothConstant;
import com.jieli.bluetooth_connect.util.BluetoothUtil;
import com.jieli.jl_bt_ota.constant.StateCode;
import com.jieli.jl_bt_ota.impl.BluetoothOTAManager;
import com.jieli.jl_bt_ota.interfaces.IUpgradeCallback;
import com.jieli.jl_bt_ota.model.BluetoothOTAConfigure;
import com.jieli.jl_bt_ota.model.base.BaseError;
import com.jieli.jl_bt_ota.model.response.TargetInfoResponse;

import java.io.File;


*/
/**
 * OTA实现类
 *
 * @author zqjasonZhong
 * @since 2021/3/8
 *//*

public class OTAManager2 extends BluetoothOTAManager {
    private Context context;
    private final BluetoothHelper mBluetoothHelper = BluetoothHelper.getInstance();

    private BluetoothDevice mTargetDevice; //目标设备
    private String mNeedReconnectAddress;  //需要回连的设备地址

    public final static String OTA_FILE_SUFFIX = ".ufw";
    public final static String OTA_FILE_NAME = "update.ufw";
    public final static String OTA_ZIP_SUFFIX = ".zip";

    public OTAManager2(Context context) {
        super(context);
        this.context = context;
        mBluetoothHelper.addBluetoothEventListener(mBluetoothEventListener);
        configureOTA();
    }

    @Override
    public BluetoothDevice getConnectedDevice() {
        return mTargetDevice;
    }

    @Override
    public BluetoothGatt getConnectedBluetoothGatt() {
        return mBluetoothHelper.getConnectedBluetoothGatt(mTargetDevice);
    }

    @Override
    public void connectBluetoothDevice(BluetoothDevice bluetoothDevice) {
        // 添加映射的OTA地址
        updateHistoryRecord(bluetoothDevice.getAddress());
        mBluetoothHelper.connectDeviceWithoutRecord(bluetoothDevice);
    }

    @Override
    public void disconnectBluetoothDevice(BluetoothDevice bluetoothDevice) {
        mBluetoothHelper.disconnectDevice(bluetoothDevice);
    }

    @Override
    public boolean sendDataToDevice(BluetoothDevice bluetoothDevice, byte[] bytes) {
        return mBluetoothHelper.sendDataToDevice(bluetoothDevice, bytes);
    }

    @Override
    public void release() {
        super.release();
        mBluetoothHelper.removeBluetoothEventListener(mBluetoothEventListener);
    }

    @Override
    public void startOTA(IUpgradeCallback callback) {
        setTargetDevice(getConnectedDevice());
        super.startOTA(new CustomUpgradeCallback(callback));
    }

    private void configureOTA() {
        BluetoothOTAConfigure configure = BluetoothOTAConfigure.createDefault();
        int connectWay = mBluetoothHelper.getBluetoothOp().getBluetoothOption().getPriority();
        if (mBluetoothHelper.isConnectedDevice()) {
            BluetoothDevice device = mBluetoothHelper.getConnectedBtDevice();
            connectWay = mBluetoothHelper.getBluetoothOp().isConnectedSppDevice(device) ? BluetoothConstant.PROTOCOL_TYPE_SPP : BluetoothConstant.PROTOCOL_TYPE_BLE;
        }
        configure.setPriority(connectWay)
                .setNeedChangeMtu(false)
                .setMtu(BluetoothConstant.BLE_MTU_MIN).
                setUseAuthDevice(false)
                .setUseReconnect(false);
        String otaDir = HealthUtil.createFilePath(context, "upgrade");
        File dir = new File(otaDir);
        boolean isExistDir = dir.exists();
        if (!isExistDir) {
            isExistDir = dir.mkdir();
        }
        if (isExistDir) {
            String otaFilePath = HealthUtil.obtainUpdateFilePath(otaDir, OTA_FILE_SUFFIX);
            if (null == otaFilePath) {
                otaFilePath = otaDir + "/" + OTA_FILE_NAME;
            }
            configure.setFirmwareFilePath(otaFilePath);
        }
        configure(configure);
        if (mBluetoothHelper.isConnectedDevice()) {
            onBtDeviceConnection(mBluetoothHelper.getConnectedBtDevice(), StateCode.CONNECTION_OK);
            setTargetDevice(mBluetoothHelper.getConnectedBtDevice());
        }
    }

    private void setTargetDevice(BluetoothDevice device) {
        mTargetDevice = device;
        if (null != device && mBluetoothHelper.getBluetoothOp().isConnectedBLEDevice(device)) {
            int mtu = mBluetoothHelper.getBluetoothOp().getBleMtu(device);
            if (mBluetoothHelper.getBluetoothOp().getDeviceGatt(device) != null) {
                onMtuChanged(mBluetoothHelper.getBluetoothOp().getDeviceGatt(device), mtu + 3, BluetoothGatt.GATT_SUCCESS);
            }
        }
    }

    private void updateHistoryRecord(String updateAddress) {
        HistoryRecord record = mBluetoothHelper.getBluetoothOp().getHistoryRecord(mNeedReconnectAddress);
        if (record != null && record.getUpdateAddress() != null
                && !record.getUpdateAddress().equals(updateAddress)) {
            record.setUpdateAddress(updateAddress);
            mBluetoothHelper.getBluetoothOp().getHistoryRecordHelper().updateHistoryRecord(record);
        }
    }

    private boolean isSingleOTA() {
        TargetInfoResponse deviceInfo = getDeviceInfo();
        return deviceInfo != null && !deviceInfo.isSupportDoubleBackup();
    }

    private final BluetoothEventListener mBluetoothEventListener = new BluetoothEventListener() {

        @Override
        public void onBleMtuChange(BluetoothGatt gatt, int mtu, int status) {
            onMtuChanged(gatt, mtu, status);
        }

        @Override
        public void onConnection(BluetoothDevice device, int status) {
            status = HealthUtil.convertOtaConnectStatus(status);
            if (status == StateCode.CONNECTION_OK) {
                if (mTargetDevice == null || mBluetoothHelper.isUsedBtDevice(device)) {
                    setTargetDevice(device);
                }
            }
            if (BluetoothUtil.deviceEquals(device, mTargetDevice)) {
                onBtDeviceConnection(device, status);
                if (status == StateCode.CONNECTION_DISCONNECT) {
                    setTargetDevice(null);
                }
            }
        }

        @Override
        public void onReceiveData(BluetoothDevice device, byte[] data) {
            onReceiveDeviceData(device, data);
        }
    };

    private final class CustomUpgradeCallback implements IUpgradeCallback {
        private final IUpgradeCallback mIUpgradeCallback;

        public CustomUpgradeCallback(IUpgradeCallback callback) {
            mIUpgradeCallback = callback;
        }

        @Override
        public void onStartOTA() {
            if (mIUpgradeCallback != null) mIUpgradeCallback.onStartOTA();
        }

        @Override
        public void onNeedReconnect(String s, boolean isNewADV) {
            HistoryRecord record = mBluetoothHelper.getBluetoothOp().getHistoryRecord(s);
            if (record != null && record.getConnectType() != BluetoothConstant.PROTOCOL_TYPE_BLE) {
                String bleAddress = record.getMappedAddress();
                String edrAddress = record.getAddress();
                //更新连接方式
                record.setAddress(bleAddress);
                record.setConnectType(BluetoothConstant.PROTOCOL_TYPE_BLE);
                record.setMappedAddress(edrAddress);
                mBluetoothHelper.getBluetoothOp().getHistoryRecordHelper().updateHistoryRecord(record);
            }
            if (mIUpgradeCallback != null) mIUpgradeCallback.onNeedReconnect(s, isNewADV);
        }

        @Override
        public void onProgress(int i, float v) {
            if (i == 0 && v > 50 && mNeedReconnectAddress == null && isSingleOTA()) {
                mNeedReconnectAddress = getConnectedDevice().getAddress();
            }
            if (mIUpgradeCallback != null) mIUpgradeCallback.onProgress(i, v);
        }

        @Override
        public void onStopOTA() {
            // 移除映射的OTA地址
            updateHistoryRecord(null);
            mNeedReconnectAddress = null;
            if (mIUpgradeCallback != null) mIUpgradeCallback.onStopOTA();
            String otaFilePath = getBluetoothOption().getFirmwareFilePath();
            if (null != otaFilePath) {
                try {
                    File file = new File(otaFilePath);
                    if (file != null && file.exists()) {
                        file.delete();
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        @Override
        public void onCancelOTA() {
            if (mIUpgradeCallback != null) mIUpgradeCallback.onCancelOTA();
        }

        @Override
        public void onError(BaseError baseError) {
            if (mIUpgradeCallback != null) mIUpgradeCallback.onError(baseError);
        }
    }
}
*/
