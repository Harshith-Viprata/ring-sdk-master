package com.example.yc_product_plugin;

import android.annotation.TargetApi;
import android.app.PendingIntent;
import android.content.ActivityNotFoundException;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import io.flutter.plugin.common.MethodChannel;

import com.jieli.jl_rcsp.task.SimpleTaskListener;
import com.jieli.jl_rcsp.task.contacts.DeviceContacts;
import com.jieli.jl_rcsp.task.contacts.UpdateContactsTask;
import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.ContactsBean;
import com.yucheng.ycbtsdk.jl.WatchManager;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.response.BleRealDataResponse;
import com.yucheng.ycbtsdk.utils.ByteUtil;
import com.yucheng.ycbtsdk.utils.LogToFileUtils;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.HashMap;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

public class YcProductPluginLogger {

    /**
     * 获取日志文件
     *
     * @param arguments
     * @param result
     */
    public static void getLogFilePath(Context context, Object arguments, @NonNull MethodChannel.Result result) {
        File logFile = LogToFileUtils.getLogFile("yclogs.txt");
        if(logFile.getPath().isEmpty()){
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
        }else{
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.succeed);
            map.put("data", logFile.getPath());
            result.success(map);
        }

    }

    /**
     * 获取杰理日志文件
     *
     * @param arguments
     * @param result
     */
    public static void getJLDeviceLogFilePath(Context context, Object arguments, @NonNull MethodChannel.Result result) {

        // 日志名称
        // 安卓+设备类型+mac地址+固件版本号+yclogs
        // 安卓+设备类型+mac地址+固件版本号+杰理
        // 安卓+设备类型+mac地址+固件版本号
        String lastBindDeviceMac = YCBTClient.getLastBindDeviceMac();
        String bindDeviceVersion = YCBTClient.getBindDeviceVersion();
        String macStr = lastBindDeviceMac.replace(":", "");
        String[] split = bindDeviceVersion.split("\\.");
        String type = (String) YCBTClient.readDeviceInfo(com.yucheng.ycbtsdk.Constants.FunctionConstant.DEVICETYPE);

        String name = "Android_" + type + "_" + macStr + "_" + split[0] + "@" + split[1];

        File ycfile = LogToFileUtils.getLogFile(name + "_yclogs.txt");// SDK日志文件

        String jlLogName = name;// 杰理日志名称

        WatchManager.getInstance().getLog(new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {
                if (code == 0) {
                    if (resultMap != null && resultMap.containsKey("size")) {
                        int size = (int) resultMap.get("size");
                        byte[] data = (byte[]) resultMap.get("data");

                        String filePath = LogToFileUtils.writeJLLog(jlLogName, data);
                        HashMap map = new HashMap();
                        map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                        map.put("data", filePath);
                        result.success(map);
                    }
                }else{
                    HashMap map = new HashMap();
                    map.put("code", YcProductPluginFlutterType.PluginState.failed);
                    map.put("data", "");
                    result.success(map);
                }
            }
        });
    }

    /**
     * 获取设备日志文件
     *
     * @param arguments
     * @param result
     */
    public static void getDeviceLogFilePath(Context context, Object arguments, @NonNull MethodChannel.Result result) {

        // 日志名称
        // 安卓+设备类型+mac地址+固件版本号+yclogs
        // 安卓+设备类型+mac地址+固件版本号+杰理
        // 安卓+设备类型+mac地址+固件版本号
        String lastBindDeviceMac = YCBTClient.getLastBindDeviceMac();
        String bindDeviceVersion = YCBTClient.getBindDeviceVersion();
        String macStr = lastBindDeviceMac.replace(":", "");
        String[] split = bindDeviceVersion.split("\\.");
        String type = (String) YCBTClient.readDeviceInfo(com.yucheng.ycbtsdk.Constants.FunctionConstant.DEVICETYPE);

        String name = "Android_" + type + "_" + macStr + "_" + split[0] + "@" + split[1];

        String deviceLogName = name + ".txt";// 设备日志
        String logFilePath = getLogFilePath(context);// 设备日志目录

        YCBTClient.getDeviceLog(0, new BleDataResponse() {
            @Override
            public void onDataResponse(int code, float ratio, HashMap resultMap) {

                if (code == Constants.CODE.Code_OK) {
                    Object one_data = resultMap.get("one_data");
                    if (one_data != null) {
                        String data = one_data.toString();
                        write(logFilePath, logFilePath + deviceLogName, data, true);
                    }

                    if (resultMap.containsKey("dataType")) {
                        int dataType = (int) resultMap.get("dataType");
                        if (Constants.DATATYPE.GetDeviceLog == dataType) {
//                            Logger.d("UploadFile upload=" + logFilePath + deviceLogName);
                            HashMap map = new HashMap();
                            map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                            map.put("data", logFilePath + deviceLogName);
                            result.success(map);
                        }
                    }

                }else{
                    HashMap map = new HashMap();
                    map.put("code", YcProductPluginFlutterType.PluginState.failed);
                    map.put("data", "");
                    result.success(map);
                }
            }
        }, new BleRealDataResponse() {
            @Override
            public void onRealDataResponse(int dataType, HashMap dataMap) {

            }
        });
    }

    public static String getLogFilePath(Context mContext) {
        File file;
        // 判断是否有SD卡或者外部存储器
        if (Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)) {
            // 有SD卡则使用SD - PS:没SD卡但是有外部存储器，会使用外部存储器
            // SD\Android\data\包名\files\Log\logs.txt
            file = new File(mContext.getExternalFilesDir("YCLog").getPath() + "/");
            //           Log.e(MY_TAG, " Storage " + file.getAbsolutePath());
        } else {
            // 没有SD卡或者外部存储器，使用内部存储器
            // \data\data\包名\files\Log\logs.txt
            file = new File(mContext.getFilesDir().getPath() + "/YCLog/");
            //           Log.e(MY_TAG, " 内部存储器 " + file.getAbsolutePath());
        }
        // 若目录不存在则创建目录
        if (!file.exists()) {
            file.mkdir();
        }
        return file.getAbsolutePath()+"/";
    }

    public static void write(String path,String fileName, String content, boolean cover) {
        String tag = "ShareUtil";
//        String path = getPPGFilePath(mContext);
//        String path = getSDPath(mContext);
//        Logger.d("chong----------filePath==" + path);

        File file = null;
        file = new File(path + fileName);
        if (!file.exists()) {
            File filePath = new File(file.getParent());
            if (!filePath.exists()) {
                filePath.mkdirs();
            }
            try {
                file.createNewFile();
            } catch (Exception e) {
                Log.e(tag, "create file(yc_file) failure !!! " + e.toString());
                return;
            }
        }
        try {
            BufferedWriter bw = new BufferedWriter(new FileWriter(file, cover));
            bw.write(content);
            bw.write("\r\n");
            bw.flush();
        } catch (Exception e) {
            Log.e(tag, "Write failure !!! " + e.toString());
        }
    }


    /**
     * 清除SDK日志文件
     *
     * @param arguments
     * @param result
     */
    public static void clearSDKLog(Context context, Object arguments, @NonNull MethodChannel.Result result) {
        LogToFileUtils.clearLog();

        HashMap map = new HashMap();
        map.put("code", YcProductPluginFlutterType.PluginState.succeed);
        map.put("data", "");
        result.success(map);
    }

    public static void shareLogFile(Context context, ActivityPluginBinding activityPluginBinding,Object arguments, @NonNull MethodChannel.Result result) {
        File logFile1 = LogToFileUtils.getLogFile("yclogs.txt");
        if (!logFile1.getPath().isEmpty()) {
            try {
                if (!logFile1.exists()) {
                    return;
                }
               // String packageName = context.getApplicationContext().getPackageName();

          //   String log_path1 = logFile1.getAbsolutePath();
                //  String log_path=getRealPathFromUri(context,uri);

//                String log_path="";
//
//                if (Build.VERSION.SDK_INT > Build.VERSION_CODES.KITKAT) {//4.4以后
//                    log_path = getFilePathFromUri(context,uri);
//                } else {
//                    log_path = getFilePathFromUri(context,uri);
//                }

                StringBuilder content = new StringBuilder();
                ;

                try (BufferedReader in = new BufferedReader(new InputStreamReader(new FileInputStream(logFile1),"UTF-8"))) {
                    int data;
                    while ((data = in.read()) != -1) {
                        content.append((char) data);
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
                String result1=content.toString();

                File file2 = new File(Environment.getExternalStorageDirectory()+"/1.txt");
                if(!file2.exists()){
                    file2.createNewFile();
                }
                try (OutputStreamWriter writer = new OutputStreamWriter(new FileOutputStream(file2), "UTF-8")) {
                    writer.write(result1);
                } catch (IOException e) {
                    e.printStackTrace();
                }

               String log_path2 = file2.getAbsolutePath();
                Uri uri1 = FileProvider.getUriForFile(context, context.getApplicationInfo().processName + ".fileProvider", file2);


                String fileName = log_path2.substring(log_path2.lastIndexOf("/") + 1);
                Intent intent = new Intent(Intent.ACTION_SEND);

              //  context.grantUriPermission(context.getPackageName(), uri1, Intent.FLAG_GRANT_READ_URI_PERMISSION);

                intent.putExtra("subject", fileName);
                intent.putExtra("body", "  ");
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                intent.putExtra(Intent.EXTRA_STREAM, uri1);
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
                intent.setType("text/plain");
                if (activityPluginBinding.getActivity() != null) {
                    activityPluginBinding.getActivity().startActivity(Intent.createChooser(intent, "share"));
                }
           //     PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent, android.os.Build.VERSION.SDK_INT >= 31?PendingIntent.FLAG_IMMUTABLE:PendingIntent.FLAG_UPDATE_CURRENT);
             //   pendingIntent.send();
            } catch (ActivityNotFoundException e) {
                Toast.makeText(context, "发送失败！", Toast.LENGTH_SHORT).show();
                e.printStackTrace();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public static String getFilePathFromUri(Context context, Uri uri) {
        if (null == uri) return null;
        final String scheme = uri.getScheme();
        String data = null;
        if (scheme == null)
            data = uri.getPath();
        else if (ContentResolver.SCHEME_FILE.equals(scheme)) {
            data = uri.getPath();
        } else if (ContentResolver.SCHEME_CONTENT.equals(scheme)) {
            Cursor cursor = context.getContentResolver().query(uri, new String[]{MediaStore.Images.ImageColumns
                    .DATA}, null, null, null);
            if (null != cursor) {
                if (cursor.moveToFirst()) {
                    int index = cursor.getColumnIndex(MediaStore.Files.FileColumns.DATA);
                    if (index > -1) {
                        data = cursor.getString(index);
                    }
                }
                cursor.close();
            }
        }
        return data;
    }

    public String getDataColumn(Context context, Uri uri, String selection, String[] selectionArgs) {
        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {column};

        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
                    null);
            if (cursor != null && cursor.moveToFirst()) {
                final int column_index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(column_index);
            }
        } finally {
            if (cursor != null)
                cursor.close();
        }
        return null;
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    public boolean isExternalStorageDocument(Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    public boolean isDownloadsDocument(Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    public boolean isMediaDocument(Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }

    //获取文件的真实路径
    public static String getRealPathFromURI(Context context,Uri contentUri) {
        String res = null;
        String[] proj = { MediaStore.Images.Media.DATA };
        Cursor cursor = context.getContentResolver().query(contentUri, proj, null, null, null);
        if(cursor.moveToFirst()){;
            int column_index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
            res = cursor.getString(column_index);
        }
        cursor.close();
        return res;
    }
}
