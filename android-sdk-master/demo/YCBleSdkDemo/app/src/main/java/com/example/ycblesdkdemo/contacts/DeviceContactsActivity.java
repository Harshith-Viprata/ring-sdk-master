package com.example.ycblesdkdemo.contacts;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.view.View;

import com.example.ycblesdkdemo.R;
import com.yucheng.ycbtsdk.jl.WatchManager;

import androidx.annotation.Nullable;

/**
 * @author StevenLiu
 * @date 2022/10/19
 * @desc one word for this class
 */
public class DeviceContactsActivity extends Activity {
    private WatchManager watchManager;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_device_contacts);
        initView();
    }

    private void initView() {
        watchManager = WatchManager.getInstance();
        findViewById(R.id.get_device_contacts).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.set_device_contacts).setOnClickListener(new OnClickListenerImpl());
    }

    private class OnClickListenerImpl implements View.OnClickListener {

        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.get_device_contacts:
                    getDeviceContacts(DeviceContactsActivity.this);
                    break;
                case R.id.set_device_contacts:
                    setDeviceContacts(DeviceContactsActivity.this);
                    break;
            }
        }
    }

    private void getDeviceContacts(Context context) {
        //WatchManager是WatchOpImpl的子类，须在1.3配置好sdk

    }

    private void setDeviceContacts(Context context) {
        //WatchManager是WatchOpImpl的子类，须在1.3配置好sdk

    }
}
