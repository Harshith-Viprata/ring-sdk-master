/*
package com.example.ycblesdkdemo.upgrade;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothProfile;
import android.content.Context;

import com.jieli.jl_bt_ota.constant.StateCode;
import com.jieli.jl_bt_ota.impl.BluetoothOTAManager;
import com.jieli.jl_bt_ota.model.base.BaseError;
import com.realsil.sdk.core.corespec.BleManager;

import java.util.UUID;

*/
/**
 * OTA 管理器实现
 *//*


public class OTAManager extends BluetoothOTAManager {
    private final BleManager bleManager = BleManager.getInstance();//BLE连接的实现

    public OTAManager(Context context) {
        super(context);
        //TODO:用户通过自行实现的连接库对象完成传递设备连接状态和接收到的数据
        bleManager.registerBleEventCallback(new BleEventCallback() {
            @Override
            public void onBleConnection(BluetoothDevice device, int status) {
                super.onBleConnection(device, status);
                int connectStatus = changeConnectStatus(status); //注意：转变成OTA库的连接状态
                //传递设备的连接状态
                onBtDeviceConnection(device, connectStatus);
            }

            @Override
            public void onBleDataNotification(BluetoothDevice device, UUID serviceUuid, UUID characteristicsUuid, byte[] data) {
                super.onBleDataNotification(device, serviceUuid, characteristicsUuid, data);
                //传递设备的接收数据
                onReceiveDeviceData(device, data);
            }

            @Override
            public void onBleDataBlockChanged(BluetoothDevice device, int block, int status) {
                super.onBleDataBlockChanged(device, block, status);
                //传递BLE的MTU改变
                onMtuChanged(getConnectedBluetoothGatt(), block, status);
            }
        });
    }

    */
/**
     * 获取已连接的蓝牙设备
     * <p>
     * 注意：是通讯方式对应的蓝牙设备对象
     * </p>
     *//*


    @Override
    public BluetoothDevice getConnectedDevice() {
        //TODO:用户自行实现
        return bleManager.getConnectedBtDevice();
    }


    */
/**
     * 获取已连接的BluetoothGatt对象
     * <p>
     * 若选择BLE方式OTA，需要实现此方法。反之，SPP方式不需要实现
     * </p>
     *//*


    @Override
    public BluetoothGatt getConnectedBluetoothGatt() {
        //TODO:用户自行实现
        return bleManager.getConnectedBtGatt();
    }


    */
/**
     * 连接蓝牙设备
     * <p>
     * 注意:这里必须是单纯连接蓝牙设备的通讯方式。
     * 例如，BLE方式，只连接BLE，不应联动连接经典蓝牙。
     * SPP方式，只连接SPP，不能连接A2DP,HFP和BLE。
     * </p>
     *
     * @param device 通讯方式的蓝牙设备
     *//*


    @Override
    public void connectBluetoothDevice(BluetoothDevice device) {
        //TODO:用户自行实现连接设备
        bleManager.connectBleDevice(device);
    }

    */
/**
     * 断开蓝牙设备的连接
     *
     * @param device 通讯方式的蓝牙设备
     *//*


    @Override
    public void disconnectBluetoothDevice(BluetoothDevice device) {
        //TODO:用户自行实现断开设备
        bleManager.disconnectBleDevice(device);
    }

    */
/**
     * 发送数据到蓝牙设备
     * <p>
     * 注意: 如果是BLE发送数据，应该注意MTU限制。BLE方式会主动把MTU重新设置为OTA配置参数设置的值。
     * </p>
     *
     * @param device 已连接的蓝牙设备
     * @param data   数据包
     * @return 操作结果
     *//*


    @Override
    public boolean sendDataToDevice(BluetoothDevice device, byte[] data) {
        //TODO:用户自行实现发送数据，BLE方式，需要注意MTU分包和队列式发数
        bleManager.writeDataByBleAsync(device, BleManager.BLE_UUID_SERVICE, BleManager.BLE_UUID_WRITE, data, new OnWriteDataCallback() {
            @Override
            public void onBleResult(BluetoothDevice device, UUID serviceUUID, UUID characteristicUUID, boolean result, byte[] data) {
                //返回结果
            }
        });
        //也可以阻塞等待结果
        return true;
    }

    */
/**
     * 用户通知OTA库的错误事件
     *//*


    @Override
    public void errorEventCallback(BaseError error) {

    }

    */
/**
     * 用于释放资源
     *//*


    @Override
    public void release() {

    }

    //连接状态转换
    private int changeConnectStatus(int status) {
        int changeStatus = StateCode.CONNECTION_DISCONNECT;
        switch (status) {
            case BluetoothProfile.STATE_DISCONNECTED:
            case BluetoothProfile.STATE_DISCONNECTING: {
                changeStatus = StateCode.CONNECTION_DISCONNECT;
                break;
            }
            case BluetoothProfile.STATE_CONNECTED:
                changeStatus = StateCode.CONNECTION_OK;
                break;
            case BluetoothProfile.STATE_CONNECTING:
                changeStatus = StateCode.CONNECTION_CONNECTING;
                break;
        }
        return changeStatus;
    }
}

*/
