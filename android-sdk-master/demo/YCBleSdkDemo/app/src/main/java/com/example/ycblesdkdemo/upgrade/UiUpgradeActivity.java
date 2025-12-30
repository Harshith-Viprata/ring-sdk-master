package com.example.ycblesdkdemo.upgrade;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.ycblesdkdemo.R;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;

import java.util.HashMap;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import static com.yucheng.ycbtsdk.Constants.BLEState.ReadWriteOK;

/**
 * @author StevenLiu
 * @date 2022/8/5
 * @desc one word for this class
 */
public class UiUpgradeActivity extends Activity {
    private TextView ui_url;
    private ProgressDialog progressDialog;
    private TextView progressNumber;
    private ProgressBar progressBar;

    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(@NonNull Message msg) {
            switch (msg.what) {
                case 5:
                    Toast.makeText(UiUpgradeActivity.this, "升级成功", Toast.LENGTH_LONG).show();
                    dissmissDialog();
                    break;
                case 6:
                    Toast.makeText(UiUpgradeActivity.this, "升级失败", Toast.LENGTH_LONG).show();
                    dissmissDialog();
                    break;
            }
            return false;
        }
    });

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_ui_upgrade);
        init();
    }

    private void init() {
        findViewById(R.id.select_ui_url).setOnClickListener(new OnClickListenerImpl());
        findViewById(R.id.ui_upgrade).setOnClickListener(new OnClickListenerImpl());
        ui_url = findViewById(R.id.ui_url);
        progressNumber = findViewById(R.id.progress_number);
        progressBar = findViewById(R.id.progress_bar);
    }

    private class OnClickListenerImpl implements View.OnClickListener {
        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.select_ui_url:
                    startActivityForResult(new Intent(UiUpgradeActivity.this, GetUrlActivity.class), 1564);
                    break;
                case R.id.ui_upgrade:
                    if (progressDialog == null) {
                        progressDialog = ProgressDialog.show(UiUpgradeActivity.this, "提示", "正在UI升级...", true, false);
                    }
                    if (YCBTClient.connectState() != ReadWriteOK) {
                        dissmissDialog();
                        Toast.makeText(UiUpgradeActivity.this, "请先连接设备...", Toast.LENGTH_LONG).show();
                        return;
                    }
                    if (!"".equals(ui_url.getText().toString())) {
                        showDialog();
                        YCBTClient.watchUiUpgrade(ui_url.getText().toString(), new BleDataResponse() {
                            @Override
                            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                                System.out.println("chong--------progress==" + resultMap);
                                if (code == 0 && resultMap != null) {
                                    runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            if (resultMap.get("progress") != null) {
                                                progressBar.setProgress((int) ((float) resultMap.get("progress")));
                                                progressNumber.setText(String.format("%.2f", (float) resultMap.get("progress")) + "%");
                                            }
                                        }
                                    });
                                    if (resultMap.get("data") != null && code == 0) {
                                        if ((int) resultMap.get("data") == 0) {
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
                        Toast.makeText(UiUpgradeActivity.this, "请先选择文件", Toast.LENGTH_LONG).show();
                    }
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
        if (!UiUpgradeActivity.this.isFinishing() && progressDialog != null && !progressDialog.isShowing()) {
            progressDialog.show();
        }
    }

    private void dissmissDialog() {
        if (!UiUpgradeActivity.this.isFinishing() && progressDialog != null && progressDialog.isShowing()) {
            progressDialog.dismiss();
        }
    }
}
