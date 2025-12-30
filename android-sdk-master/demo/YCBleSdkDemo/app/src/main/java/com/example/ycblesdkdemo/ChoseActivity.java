package com.example.ycblesdkdemo;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import com.example.ycblesdkdemo.contacts.DeviceContactsActivity;
import com.example.ycblesdkdemo.ecg.EcgActicvity;
import com.example.ycblesdkdemo.upgrade.FirmwareUpgradeActivity;
import com.example.ycblesdkdemo.upgrade.UiUpgradeActivity;
import com.example.ycblesdkdemo.util.ToastUtil;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;

import java.util.HashMap;

public class ChoseActivity extends Activity {
    private String macVal;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chose);
        initView();

    }

    private void initView() {
        findViewById(R.id.chose_new_view).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.chose_old_view).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.chose_other_view).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.chose_firmware_upgrade).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.chose_ui_upgrade).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.chose_ecg).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.chose_device_contacts).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.chose_device_check_aliiotkit).setOnClickListener(new OnClickListenerImpl());
        macVal = getIntent().getStringExtra("mac");
    }

    private class OnClickListenerImpl implements View.OnClickListener {

        @Override
        public void onClick(View v) {
            Intent intent = null;
            switch (v.getId()) {
                case R.id.chose_new_view:
                    intent = new Intent(ChoseActivity.this, TimeSetActivity.class);
                    break;
                case R.id.chose_old_view:
                    intent = new Intent(ChoseActivity.this, OldActivity.class);
                    break;
                case R.id.chose_other_view:
                    intent = new Intent(ChoseActivity.this, OtherActivity.class);
                    break;
                case R.id.chose_firmware_upgrade:
                    intent = new Intent(ChoseActivity.this, FirmwareUpgradeActivity.class);
                    break;
                case R.id.chose_ui_upgrade:
                    intent = new Intent(ChoseActivity.this, UiUpgradeActivity.class);
                    break;
                case R.id.chose_ecg:
                    intent = new Intent(ChoseActivity.this, EcgActicvity.class);
                    break;
                case R.id.chose_device_contacts:
                    intent = new Intent(ChoseActivity.this, DeviceContactsActivity.class);
                    break;
                case R.id.chose_device_check_aliiotkit:
                    YCBTClient.checkALiIOTKit(new BleDataResponse() {
                        @Override
                        public void onDataResponse(int code, float ratio, HashMap resultMap) {
                            if (code == 0) {
                                ToastUtil.getInstance(ChoseActivity.this).toast("激活成功");
                            } else {
                                ToastUtil.getInstance(ChoseActivity.this).toast("激活失败");
                            }
                        }
                    });
                    break;
            }
            if (intent != null) {
                startActivity(intent);
            }
        }
    }

}
