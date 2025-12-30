package com.example.ycblesdkdemo;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.example.ycblesdkdemo.util.PermissionUtils;

import java.util.ArrayList;
import java.util.List;

public class WelComActivity extends Activity {
    private String[] permissionArray = new String[]{
            Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE,//访问sd卡权限
            Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION,//蓝牙搜索定位权限
            Manifest.permission.READ_PHONE_STATE, Manifest.permission.CALL_PHONE,//电话权限
            Manifest.permission.READ_CONTACTS, Manifest.permission.WRITE_CONTACTS//联系人权限
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_welcome);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            boolean isPermission = PermissionUtils.checkPermissionArray(WelComActivity.this, permissionArray, 3);
//            if (isPermission) {
                goMain();
//            }
        } else {
            goMain();
        }

    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != 3) {
            return;
        }
        if (grantResults.length > 0) {
            List<String> deniedPermissionList = new ArrayList<>();
            for (int i = 0; i < grantResults.length; i++) {
                if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                    deniedPermissionList.add(permissions[i]);
                }
            }
            if (deniedPermissionList.isEmpty()) {//已经全部授权
                goMain();
            } else {
                //如果有拒绝的权限，就继续询问
                PermissionUtils.checkPermissionArray(WelComActivity.this, permissionArray, 3);
                //勾选了对话框中”Don’t ask again”的选项, 返回false
                for (String deniedPermission : deniedPermissionList) {
                    boolean flag = shouldShowRequestPermissionRationale(deniedPermission);
                    if (!flag) {//拒绝授权
                        Toast.makeText(WelComActivity.this, "请前往设置页面，手动开启权限", Toast.LENGTH_SHORT).show();
//                        return;
                    }
                }
                Intent mainIntent = new Intent(WelComActivity.this, MainActivity.class);
                startActivity(mainIntent);
                finish();
            }
        }
    }

    private void requestPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                intent.addCategory("android.intent.category.DEFAULT");
                intent.setData(Uri.parse(String.format("package:%s", getApplicationContext().getPackageName())));
                startActivityForResult(intent, 2296);
            } catch (Exception e) {
                Intent intent = new Intent();
                intent.setAction(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
                startActivityForResult(intent, 2296);
            }
        }else{
            Intent mainIntent = new Intent(WelComActivity.this, MainActivity.class);
            startActivity(mainIntent);
            finish();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 2296) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (Environment.isExternalStorageManager()) {
                    // perform action when allow permission success
                    goMain();
                } else {
                    Toast.makeText(this, "Allow permission for storage access!", Toast.LENGTH_SHORT).show();
                    Intent mainIntent = new Intent(WelComActivity.this, MainActivity.class);
                    startActivity(mainIntent);
                    finish();
                }
            }
        }
    }

    //授权后跳转主页面
    private void goMain() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !Environment.isExternalStorageManager()) {//Android 11以后需要获取全部文件操作，这个不能弹出授权对话框，需要跳转设置页面手动开启
            requestPermission();
            Intent mainIntent = new Intent(WelComActivity.this, MainActivity.class);
            startActivity(mainIntent);
            finish();
        } else {
            Intent mainIntent = new Intent(WelComActivity.this, MainActivity.class);
            startActivity(mainIntent);
            finish();
        }
    }

}
