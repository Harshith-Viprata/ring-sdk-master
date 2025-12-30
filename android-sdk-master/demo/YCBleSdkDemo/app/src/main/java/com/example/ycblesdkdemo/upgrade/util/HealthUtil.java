package com.example.ycblesdkdemo.upgrade.util;

import android.content.Context;
import android.util.Log;

import com.yucheng.ycbtsdk.Constants;

import java.io.File;

/**
 * @author StevenLiu
 * @date 2022/8/6
 * @desc one word for this class
 */
public class HealthUtil {
    /**
     * 创建文件路径
     *
     * @param context  上下文
     * @param dirNames 文件夹名
     * @return 路径
     */
    public static String createFilePath(Context context, String... dirNames) {
        if (context == null || dirNames == null || dirNames.length == 0) return null;
        File file = context.getExternalFilesDir(null);
        if (file == null || !file.exists()) return null;
        StringBuilder filePath = new StringBuilder(file.getPath());
        if (filePath.toString().endsWith("/")) {
            filePath = new StringBuilder(filePath.substring(0, filePath.lastIndexOf("/")));
        }
        for (String dirName : dirNames) {
            filePath.append("/").append(dirName);
            file = new File(filePath.toString());
            if (!file.exists() || file.isFile()) {//文件不存在
                if (!file.mkdir()) {
                    Log.w("yc_sdk", "create dir failed. filePath = " + filePath);
                    break;
                }
            }
        }
        return filePath.toString();
    }

}
