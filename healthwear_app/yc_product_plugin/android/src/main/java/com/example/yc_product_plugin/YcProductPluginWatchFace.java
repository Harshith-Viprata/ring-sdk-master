package com.example.yc_product_plugin;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.jieli.jl_fatfs.model.FatFile;
import com.jieli.jl_fatfs.utils.FatUtil;
import com.jieli.jl_rcsp.interfaces.watch.OnWatchOpCallback;
import com.jieli.jl_rcsp.model.base.BaseError;
import com.jieli.jl_rcsp.model.device.VoiceData;
import com.jieli.jl_rcsp.tool.WatchCacheManager;
import com.yucheng.ycbtsdk.AITools;
import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.bean.DialsBean;
import com.yucheng.ycbtsdk.bean.ImageBean;
import com.yucheng.ycbtsdk.jl.WatchManager;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.utils.DialUtils;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;

public class YcProductPluginWatchFace {


    /**
     * 查询表盘信息
     *
     * @param arguments
     * @param result
     */
    public static void queryWatchFaceInfo(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.watchDialInfo(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                int state = YcProductPlugin.convertPluginState(i);
                ArrayList watchFaces = new ArrayList();

                if (0 == i && null != hashMap && hashMap.containsKey("dials")) {

                    ArrayList dials = (ArrayList) hashMap.get("dials");
                    ArrayList customDials = (ArrayList) hashMap.get("customDials");

                    // 合并表盘
                    ArrayList list = new ArrayList();
                    list.addAll(dials);
                    list.addAll(customDials);

                    int limitCount = (int) hashMap.get("maxDials");
                    int localCount = (int) hashMap.get("currDials");

                    if (YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASCUSTOMDIAL)) {
                        limitCount += 1;
                    }

                    for (int index = 0; index < list.size(); index++) {

                        DialsBean dialsBean = (DialsBean) list.get(index);

                        HashMap info = new HashMap();
                        info.put("dialID", dialsBean.dialplateId);
                        info.put("blockCount", dialsBean.blockNumber);
                        info.put("isSupportDelete", dialsBean.isCanDelete);
                        info.put("version", dialsBean.dialVersion);

                        info.put("limitCount", limitCount);
                        info.put("localCount", localCount);

                        watchFaces.add(info);
                    }

                }

                map.put("code", state);
                map.put("data", watchFaces);

                result.success(map);
            }
        });
    }


    /**
     * 切换表盘
     *
     * @param arguments
     * @param result
     */
    public static void changeWatchFace(Object arguments, @NonNull MethodChannel.Result result) {

        int dialID = (int) arguments;

        YCBTClient.watchDialSetCurrent(dialID, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                result.success(map);
            }
        });
    }

    /**
     * 切换表盘
     *
     * @param arguments
     * @param result
     */
    public static void deleteWatchFace(Object arguments, @NonNull MethodChannel.Result result) {

        int dialID = (int) arguments;

        YCBTClient.watchDialDelete(dialID, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                result.success(map);
            }
        });
    }


    /**
     * 下载表盘
     *
     * @param arguments
     * @param result
     */
    public static void installWatchFace(MethodChannel methodChannel, Handler handler, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;
        if (list.size() < 5) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        Boolean isEnable = (Boolean) list.get(0);
        int dialID = (int) list.get(1);
        int blockCount = (int) list.get(2);
        int dialVersion = (int) list.get(3);
        String filePath = (String) list.get(4);

        try {

            FileInputStream inputStream = new FileInputStream(new File(filePath));
            byte[] buffer = new byte[1024];
            int len = 0;
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            while ((len = inputStream.read(buffer)) != -1) {
                bos.write(buffer, 0, len);
            }

            bos.flush();

            bos.toByteArray();

            HashMap info = new HashMap();

            YCBTClient.watchDialDownload(isEnable ? 1 : 0, bos.toByteArray(), dialID, blockCount, dialVersion, new BleDataResponse() {
                @Override
                public void onDataResponse(int i, float v, HashMap hashMap) {

                    // 主线程执行
                    handler.post(new Runnable() {
                        @Override
                        public void run() {

                            if (0 == i && hashMap != null) {

                                // 获取进度
                                int type = (int) hashMap.get("dataType");
                                if (type == Constants.DATATYPE.WatchDialProgress) {

                                    float progress = (float) hashMap.get("progress");
                                    info.clear();
                                    info.put("code", YcProductPluginFlutterType.DeviceUpdateState.installingWatchFace);
                                    info.put("progress", String.format("%.2f", progress * 0.01));
                                    info.put("error", "");

                                    methodChannel.invokeMethod("upgradeState", info);

                                } else {

                                    HashMap map = new HashMap();
                                    map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                                    map.put("data", "");
                                    result.success(map);
                                }

                            } else {

                                HashMap map = new HashMap();
                                map.put("code", YcProductPluginFlutterType.PluginState.failed);
                                map.put("data", "" + i);
                                result.success(map);
                            }
                        }
                    });

                }
            });

        } catch (Exception e) {

            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", e.getMessage());
            result.success(map);
        }

    }

    /**
     * 查询文件内容
     *
     * @param arguments
     * @param result
     */
    public static void queryDeviceCustomWatchFaceInfo(Object arguments, @NonNull MethodChannel.Result result) {

        String filePath = (String) arguments;

        int size = 0;
        int width = 0;
        int height = 0;
        int radius = 0;

        int thumbnailSize = 0;
        int thumbnailWidth = 0;
        int thumbnailHeight = 0;
        int thumbnailRadius = 0;

        try {

            FileInputStream inputStream = new FileInputStream(new File(filePath));
            byte[] buffer = new byte[1024];
            int len = 0;
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            while ((len = inputStream.read(buffer)) != -1) {
                bos.write(buffer, 0, len);
            }

            bos.flush();
            byte[] bins = bos.toByteArray();

            ImageBean bgImageBean = AITools.getInstance().getBmpSize(bins);
            ImageBean cpImageBean = AITools.getInstance().getCompressionBmpSize(bins);

            size = bgImageBean.size;
            width = bgImageBean.width;
            height = bgImageBean.height;
            radius = bgImageBean.radius;

            thumbnailSize = cpImageBean.size;
            thumbnailWidth = cpImageBean.width;
            ;
            thumbnailHeight = cpImageBean.height;
            ;
            thumbnailRadius = cpImageBean.radius;

            HashMap info = new HashMap();
            info.put("size", size);
            info.put("width", width);
            info.put("height", height);
            info.put("radius", radius);

            info.put("thumbnailSize", thumbnailSize);
            info.put("thumbnailWidth", thumbnailWidth);
            info.put("thumbnailHeight", thumbnailHeight);
            info.put("thumbnailRadius", thumbnailRadius);


            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.succeed);
            map.put("data", info);
            result.success(map);

        } catch (Exception e) {


            HashMap info = new HashMap();
            info.put("size", size);
            info.put("width", width);
            info.put("height", height);
            info.put("radius", radius);

            info.put("thumbnailSize", thumbnailSize);
            info.put("thumbnailWidth", thumbnailWidth);
            info.put("thumbnailHeight", thumbnailHeight);
            info.put("thumbnailRadius", thumbnailRadius);


            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", info);
            result.success(map);
        }
    }

    /**
     * 安装自定义表盘
     *
     * @param methodChannel
     * @param handler
     * @param arguments
     * @param result
     */
    public static void installCustomWatchFace(Context context, MethodChannel methodChannel, Handler handler, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;
        if (list.size() < 9) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int dialID = (int) list.get(0);
        String filePath = (String) list.get(1);
        String backgroundPath = (String) list.get(2);
        String thumbnailPath = (String) list.get(3);

        int timeX = (int) list.get(4);
        int timeY = (int) list.get(5);

        int redColor = (int) list.get(6);
        int greenColor = (int) list.get(7);
        int blueColor = (int) list.get(8);

        // 将颜色分量转换为RGB565格式
        int red565 = ((redColor & 0xFF) >> 3) & 0x1F;
        int green565 = ((greenColor & 0xFF) >> 2) & 0x3F;
        int blue565 = ((blueColor & 0xFF) >> 3) & 0x1F;

        int rgb565 = (red565 << 11) | (green565 << 5) | blue565;


        // 先删除表盘
        YCBTClient.watchDialDelete(dialID, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {


// 重新安装表盘
                YCBTClient.setDialCustomize(
                        context,
                        backgroundPath,
                        thumbnailPath,
                        dialID,
                        filePath,
                        timeX,
                        timeY,
                        0,
                        rgb565,
                        true,
                        new DialUtils.DialProgressListener() {

                            @Override
                            public void onDialProgress(int i, float progress) {

                                handler.post(new Runnable() {
                                    @Override
                                    public void run() {


                                        if (0 == i) {
                                            HashMap info = new HashMap();
                                            info.put("code", YcProductPluginFlutterType.DeviceUpdateState.installingWatchFace);
                                            info.put("progress", String.format("%.2f", progress * 0.01));
                                            info.put("error", "");

                                            methodChannel.invokeMethod("upgradeState", info);

                                        } else if (1 == i) {

                                            HashMap info = new HashMap();
                                            info.put("code", YcProductPluginFlutterType.PluginState.succeed);
                                            info.put("progress", "1.0");
                                            info.put("error", "");
                                            result.success(info);


                                        } else if (2 == i) {

                                            HashMap map = new HashMap();
                                            map.put("code", YcProductPluginFlutterType.PluginState.failed);
                                            map.put("data", "limited");
                                            result.success(map);

                                        } else if (3 == i) {
                                            HashMap map = new HashMap();
                                            map.put("code", YcProductPluginFlutterType.PluginState.failed);
                                            map.put("data", "failed");
                                            result.success(map);

                                        }

                                    }
                                });


                            }

                        }

                );
            }
        });

    }


    /**
     * 切换表盘
     *
     * @param arguments
     * @param result
     */
    public static void changeJieLiWatchFace(Object arguments, @NonNull MethodChannel.Result result) {

        String watchName = (String) arguments;

        YCBTClient.jlWatchDialSetCurrent("/" + watchName, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                result.success(map);
            }
        });
    }


    /**
     * 删除表盘
     *
     * @param arguments
     * @param result
     */
    public static void deleteJieLiWatchFace(Object arguments, @NonNull MethodChannel.Result result) {
        String watchName = (String) arguments;

        YCBTClient.jlWatchDialDelete("/" + watchName, new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", "");
                result.success(map);
            }
        });
    }


    /**
     * 安装杰理表盘
     *
     * @param methodChannel
     * @param handler
     * @param arguments
     * @param result
     */
    public static void installJieLiWatchFace(MethodChannel methodChannel, Handler handler, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;
        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        String watchName = (String) list.get(0);
        String filePath = (String) list.get(1);

        try {

            FileInputStream inputStream = new FileInputStream(new File(filePath));
            byte[] buffer = new byte[1024];
            int len = 0;
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            while ((len = inputStream.read(buffer)) != -1) {
                bos.write(buffer, 0, len);
            }

            bos.flush();

            bos.toByteArray();

            HashMap info = new HashMap();

            YCBTClient.jlWatchDialDownload(filePath, false, new BleDataResponse() {
                @Override
                public void onDataResponse(int i, float v, HashMap hashMap) {

                    // 主线程执行
                    handler.post(new Runnable() {
                        @Override
                        public void run() {

                            if (0 == i && hashMap != null) {

                                // 获取进度
                                int type = (int) hashMap.get("dataType");
                                if (type == Constants.DATATYPE.WatchDialProgress) {

                                    float progress = (float) hashMap.get("progress");
                                    info.clear();
                                    info.put("code", YcProductPluginFlutterType.DeviceUpdateState.installingWatchFace);
                                    info.put("progress", String.format("%.2f", progress * 0.01));
                                    info.put("error", "");

                                    methodChannel.invokeMethod("upgradeState", info);

                                } else {

                                    HashMap map = new HashMap();
                                    map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                                    map.put("data", "");
                                    result.success(map);
                                }

                            } else {

                                HashMap map = new HashMap();
                                map.put("code", YcProductPluginFlutterType.PluginState.failed);
                                map.put("data", "" + i);
                                result.success(map);
                            }
                        }
                    });
                }
            });

        } catch (Exception e) {

            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", e.getMessage());
            result.success(map);
        }
    }


    /**
     * 获取设备显示参数
     *
     * @param arguments
     * @param result
     */
    public static void queryDeviceDisplayParametersInfo(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.getScreenParameters(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                if (0 == i && hashMap != null) {

                    int screenType = (int) hashMap.get("screenType");
                    int widthPixels = (int) hashMap.get("screenWidth");
                    int heightPixels = (int) hashMap.get("screenHeight");
                    int filletRadiusPixels = (int) hashMap.get("screenCorner");

                    int thumbnailWidthPixels = (int) hashMap.get("screenCpWidth");
                    int thumbnailHeightPixels = (int) hashMap.get("screenCpHeight");
                    int thumbnailRadiusPixels = (int) hashMap.get("screenCpCorner");

                    HashMap parametersMap = new HashMap();

                    parametersMap.put("screenType", screenType);

                    parametersMap.put("widthPixels", widthPixels);
                    parametersMap.put("heightPixels", heightPixels);
                    parametersMap.put("filletRadiusPixels", filletRadiusPixels);

                    parametersMap.put("thumbnailWidthPixels", thumbnailWidthPixels);
                    parametersMap.put("thumbnailHeightPixels", thumbnailHeightPixels);
                    parametersMap.put("thumbnailRadiusPixels", thumbnailRadiusPixels);


                    HashMap map = new HashMap();
                    map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                    map.put("data", parametersMap);
                    result.success(map);

                    return;
                }

                HashMap map = new HashMap();
                map.put("code", YcProductPluginFlutterType.PluginState.failed);
                map.put("data", "");
                result.success(map);
            }
        });
    }


    /**
     * 安装杰理表盘
     *
     * @param methodChannel
     * @param handler
     * @param arguments
     * @param result
     */
    public static void installJieLiCustomWatchFace(
            Context context,
            MethodChannel methodChannel, Handler handler, Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;
        if (list.size() < 11) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        String watchName = (String) list.get(0);
        String backgroundPath = (String) list.get(1);
        int backgroundImageWidth = (int) list.get(2);
        int backgroundImageHeight = (int) list.get(3);
        int filletRadiusPixels = (int) list.get(4);

        String thumbnailPath = (String) list.get(5);
        int thumbnailWidth = (int) list.get(6);
        int thumbnailHeight = (int) list.get(7);
        int thumbnailRadiusPixels = (int) list.get(8);

        int timeLocation = (int) list.get(9);
        int timeTextColor = (int) list.get(10);

//        Bitmap bitmap = BitmapFactory.decodeFile(backgroundPath);
//        int width = bitmap.getWidth();
//        int height = bitmap.getHeight();
//        Log.d("setDialCustomize","width="+width+" height="+height);


        YCBTClient.setDialCustomize(
                context,
                backgroundPath,
                thumbnailPath,
                0,
                watchName,
                0,
                0,
                timeLocation,
                timeTextColor,
                false,
                new DialUtils.DialProgressListener() {
                    @Override
                    public void onDialProgress(int i, float progress) {


                        if (0 == i) {
                            HashMap info = new HashMap();
                            info.put("code", YcProductPluginFlutterType.DeviceUpdateState.installingWatchFace);
                            info.put("progress", String.format("%.2f", progress * 0.01));
                            info.put("error", "");

                            methodChannel.invokeMethod("upgradeState", info);

                        } else if (1 == i) {

//                            YCBTClient.jlWatchDialSetCurrent("/" + watchName, new BleDataResponse() {
//                                @Override
//                                public void onDataResponse(int i, float v, HashMap hashMap) {
//
//                                    int state = YcProductPlugin.convertPluginState(i);
//                                    HashMap map = new HashMap();
//                                    map.put("code", state);
//                                    map.put("data", "");
//                                    result.success(map);
//                                }
//                            });


                            WatchManager.getInstance().enableCustomWatchBg(FatUtil.getFatFilePath(backgroundPath), new OnWatchOpCallback<FatFile>() {
                                @Override
                                public void onSuccess(FatFile fatFile) {

                                    HashMap map = new HashMap();
                                    map.put("code", YcProductPluginFlutterType.PluginState.succeed);
                                    map.put("data", "");
                                    result.success(map);
                                }

                                @Override
                                public void onFailed(BaseError baseError) {

                                    HashMap map = new HashMap();
                                    map.put("code", YcProductPluginFlutterType.PluginState.failed);
                                    map.put("data", "");
                                    result.success(map);
                                }
                            });


                        } else if (2 == i) {

                            HashMap map = new HashMap();
                            map.put("code", YcProductPluginFlutterType.PluginState.failed);
                            map.put("data", "limited");
                            result.success(map);

                        } else if (3 == i) {
                            HashMap map = new HashMap();
                            map.put("code", YcProductPluginFlutterType.PluginState.failed);
                            map.put("data", "failed");
                            result.success(map);

                        }


                    }
                }

        );

    }
}
