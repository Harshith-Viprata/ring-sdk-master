package com.example.yc_product_plugin;

import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;

import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;

public class YcProductPluginSetting {

    /// 设置时间
    public static void setDeviceSyncPhoneTime(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.settingTime(new BleDataResponse() {
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

    /// 设置步数
    public static void setDeviceStepGoal(Object arguments, @NonNull MethodChannel.Result result) {

        int step = (int)arguments;
        YCBTClient.settingGoal(0, step, 0, 0, new BleDataResponse() {
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

    /// 设置睡眠目标
    public static void setDeviceSleepGoal(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList args = (ArrayList) arguments;

        if (args.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int hour = (int) args.get(0);
        int minute = (int) args.get(1);

        YCBTClient.settingGoal(3, 0, hour, minute, new BleDataResponse() {
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

    /// 设置用户信息
    public static void setDeviceUserInfo(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList args = (ArrayList) arguments;

        if (args.size() < 4) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int height = (int) args.get(0);
        int weight = (int) args.get(1);
        int gender = (int) args.get(2);
        int age = (int) args.get(3);

        YCBTClient.settingUserInfo(height, weight, gender, age, new BleDataResponse() {
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

    /// 设置肤色
    public static void setDeviceSkinColor(Object arguments, @NonNull MethodChannel.Result result) {
        int level = (int) arguments;
        YCBTClient.settingSkin(level, new BleDataResponse() {
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

    /// 设置单位
    public static void setDeviceUnit(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList args = (ArrayList) arguments;

        if (args.size() < 6) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int distanceUnit = (int) args.get(0);
        int weightUnit = (int) args.get(1);
        int temperatureUnit = (int) args.get(2);
        int timeFormat = (int) args.get(3);
        int bloodSugarUnit = (int) args.get(4);
        int uricAcidUnit = (int) args.get(5);

        YCBTClient.settingUnit(distanceUnit, weightUnit, temperatureUnit, timeFormat, bloodSugarUnit, uricAcidUnit, new BleDataResponse() {
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

    /// 设置防丢
    public static void setDeviceAntiLost(Object arguments, @NonNull MethodChannel.Result result) {

        Boolean flag = (Boolean) arguments;

        YCBTClient.settingAntiLose(flag ? 2 : 0, new BleDataResponse() {
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

    /// 设置勿扰
    public static void setDeviceNotDisturb(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList args = (ArrayList) arguments;

        if (args.size() < 5) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int isEnable = (int)args.get(0);
        int startTimeHour = (int)args.get(1);
        int startTimeMin = (int)args.get(2);
        int endTimeHour = (int)args.get(3);
        int endTimeMin = (int)args.get(4);

        YCBTClient.settingNotDisturb(isEnable, startTimeHour, startTimeMin, endTimeHour, endTimeMin, new BleDataResponse() {
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


    /// 设置语言
    public static void setDeviceLanguage(Object arguments, @NonNull MethodChannel.Result result) {
        int lan = (int)arguments;
        YCBTClient.settingLanguage(lan, new BleDataResponse() {
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

    /// 设置久坐提醒
    public static void setDeviceSedentary(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList args = (ArrayList) arguments;

        if (args.size() < 10) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int startHour1 = (int) args.get(0);
        int startMinute1 = (int) args.get(1);
        int endHour1 = (int) args.get(2);
        int endMinute1 = (int) args.get(3);

        int startHour2 = (int) args.get(4);
        int startMinute2 = (int) args.get(5);
        int endHour2 = (int) args.get(6);
        int endMinute2 = (int) args.get(7);

        int interval = (int) args.get(8);
        int repeatValue = (int) args.get(9);

        YCBTClient.settingLongsite(startHour1, startMinute1, endHour1, endMinute1, startHour2, startMinute2, endHour2, endMinute2, interval, repeatValue, new BleDataResponse() {
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

    /// 设置左右手佩戴
    public  static void setDeviceWearingPosition(Object arguments, @NonNull MethodChannel.Result result) {
        int position = (int) arguments;

        YCBTClient.settingHandWear(position, new BleDataResponse() {
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

    /// 设置手机系统信息
    public static void setPhoneSystemInfo(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.settingAppSystem(0, Build.VERSION.RELEASE, new BleDataResponse() {
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
     * 抬腕亮屏
     * @param arguments
     * @param result
     */
    public static void setDeviceWristBrightScreen (Object arguments, @NonNull MethodChannel.Result result) {
        Boolean isEnable = (Boolean) arguments;
        YCBTClient.settingRaiseScreen(isEnable ? 1 : 0, new BleDataResponse() {
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
     * 亮度设置
     * @param arguments
     * @param result
     */
    public static void  setDeviceDisplayBrightness(Object arguments, @NonNull MethodChannel.Result result) {
        int level = (int) arguments;

        YCBTClient.settingDisplayBrightness(level, new BleDataResponse() {
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
     * 健康监测
     * @param arguments
     * @param result
     */
    public static void setDeviceHealthMonitoringMode (Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int interval = (int) list.get(1);

        YCBTClient.settingHeartMonitor(flag, interval, new BleDataResponse() {
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
     * 温度监测
     * @param arguments
     * @param result
     */
    public static void setDeviceTemperatureMonitoringMode (Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int interval = (int) list.get(1);

        YCBTClient.settingTemperatureMonitor(flag != 0, interval, new BleDataResponse() {
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
     * 心率报警
     * @param arguments
     * @param result
     */
    public static void setDeviceHeartRateAlarm (Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 3) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int maxValue = (int) list.get(1);
        int minValue = (int) list.get(2);

        YCBTClient.settingHeartAlarm(flag, maxValue, minValue, new BleDataResponse() {
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
     * 血压报警
     * @param arguments
     * @param result
     */
    public static void setDeviceBloodPressureAlarm (Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 5) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int maxSBP = (int) list.get(1);
        int maxDBP = (int) list.get(2);
        int minSBP = (int) list.get(3);
        int minDBP = (int) list.get(4);

        YCBTClient.settingBloodAlarm(flag, maxSBP, maxDBP, minSBP, minDBP, new BleDataResponse() {
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
     * 血氧报警
     * @param arguments
     * @param result
     */
    public static void setDeviceBloodOxygenAlarm (Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 2) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int minValue = (int) list.get(1);

        YCBTClient.settingBloodOxygenAlarm(flag, minValue, new BleDataResponse() {
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
     * 呼吸率
     * @param arguments
     * @param result
     */
    public static void setDeviceRespirationRateAlarm (Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 3) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int maxValue = (int) list.get(1);
        int minValue = (int) list.get(2);

        YCBTClient.settingRespiratoryRateAlarm(flag, maxValue, minValue, new BleDataResponse() {
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
     * 温度报警
     * @param arguments
     * @param result
     */
    public static void setDeviceTemperatureAlarm (Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 5) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int highTemperatureIntegerValue = (int) list.get(1);
        int highTemperatureDecimalValue = (int) list.get(2);
        int lowTemperatureIntegerValue = (int) list.get(3);
        int lowTemperatureDecimalValue = (int) list.get(4);

        YCBTClient.newSettingTemperatureAlarm(flag != 0, highTemperatureIntegerValue, highTemperatureDecimalValue, lowTemperatureIntegerValue, lowTemperatureDecimalValue, new BleDataResponse() {
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
     * 查询主题
     * @param arguments
     * @param result
     */
    public static void queryDeviceTheme (Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.getThemeInfo(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                int state = YcProductPlugin.convertPluginState(i);
                map.put("code", state);

                if (i == 0 && hashMap != null) {
                    HashMap item = new HashMap();
                    int index = (int)hashMap.get("themeCurrentIndex");
                    int count = (int) hashMap.get("themeTotal");
                    item.put("index", index);
                    item.put("count", count);

                    map.put("data", item);
                } else {
                    map.put("data", "");
                }

                result.success(map);
            }
        });
    }

    /**
     * 设置主题
     * @param arguments
     * @param result
     */
    public  static void setDeviceTheme(Object arguments, @NonNull MethodChannel.Result result) {
        int index = (int) arguments;

        YCBTClient.settingMainTheme(index, new BleDataResponse() {
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
     * 睡眠提醒
     * @param arguments
     * @param result
     */
    public  static void setDeviceSleepReminder(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 3) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int hour = (int) list.get(0);
        int minute = (int) list.get(1);
        int repeatValue = (int) list.get(2);

        YCBTClient.settingSleepRemind(hour, minute, repeatValue, new BleDataResponse() {
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
     * 设置消息推送
     * @param arguments
     * @param result
     */
    public static void setDeviceInfoPush(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList list = (ArrayList) arguments;

        if (list.size() < 4) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int flag = (int) list.get(0);
        int item1 = (int) list.get(1);
        int item2 = (int) list.get(2);
        int item3 = (int) list.get(3);

        YCBTClient.settingNotify(flag, item1, item2, item3, new BleDataResponse() {
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

    /// 设置久坐提醒
    public static void setDevicePeriodicReminderTask(Object arguments, @NonNull MethodChannel.Result result) {

        ArrayList args = (ArrayList) arguments;

        if (args.size() < 8) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int reminderType = (int)args.get(0);
        int startHour = (int) args.get(1);
        int startMinute = (int) args.get(2);
        int endHour = (int) args.get(3);
        int endMinute = (int) args.get(4);
        int interval = (int) args.get(5);
        int repeatValue = (int) args.get(6);
        String content = (String) args.get(7);

        YCBTClient.settingRegularReminder(reminderType, startHour, startMinute, endHour, endMinute, repeatValue, interval, content, new BleDataResponse() {
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

    /// 恢复出厂设置
    public static void restoreFactorySettings(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.settingRestoreFactory(new BleDataResponse() {
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

    /// 查询闹钟
    public static void settingGetAllAlarm(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.settingGetAllAlarm(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {
//                if (i == 0 && hashMap != null) {
//                    HashMap item = new HashMap();
//                    int alarmHour = (int)hashMap.get("alarmHour");
//                    int alarmMin = (int) hashMap.get("alarmMin");
//                    int alarmDelayTime = (int) hashMap.get("alarmDelayTime");
//                    int alarmType = (int) hashMap.get("alarmType");
//                    int alarmRepeat = (int) hashMap.get("alarmRepeat");
//
//                    item.put("alarmHour", alarmHour);
//                    item.put("alarmMin", alarmMin);
//
//                    map.put("data", item);
//                } else {
//                    map.put("data", "");
//                }

//                if (hashMap != null) {
//                   ArrayList data= (ArrayList) hashMap.get("data");
//                    map.put("data", data);
//                    HashMap item = new HashMap();
//                    int index = (int)hashMap.get("themeCurrentIndex");
//                    int count = (int) hashMap.get("themeTotal");
//                    item.put("index", index);
//                    item.put("count", count);
//
//                    map.put("data", item);
//                } else {
//                    map.put("data", "");
//                }
                ArrayList datas = new ArrayList();

                if (0 == i && hashMap != null) {

                    try {

                        ArrayList list = (ArrayList) hashMap.get("data");

                        for (int index = 0; index < list.size(); index++) {

                            HashMap obj = (HashMap) list.get(index);

                            int alarmHour = (int) obj.get("alarmHour");
                            int alarmType = (int) obj.get("alarmType");
                            int alarmMin = (int) obj.get("alarmMin");
                            int alarmRepeat = (int) obj.get("alarmRepeat");
                            int alarmDelayTime = (int) obj.get("alarmDelayTime");

                            HashMap info = new HashMap();
                            info.put("alarmHour", alarmHour);
                            info.put("alarmType", alarmType);
                            info.put("alarmMin", alarmMin);
                            info.put("alarmRepeat", alarmRepeat);
                            info.put("alarmDelayTime", alarmDelayTime);

                            datas.add(info);
                        }

                    } catch (Exception e) {

                        // 返回空值, 什么都不处理
                    }
                }

                HashMap map = new HashMap();
                map.put("code", 0);
                map.put("data", datas);
                result.success(map);

            }
        });
    }

    /// 添加闹钟
    public static void settingAddAlarm(Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList args = (ArrayList) arguments;

        if (args.size() < 5) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int type = (int)args.get(0);
        int startHour = (int) args.get(1);
        int startMin = (int) args.get(2);
        String weekRepeat = (String) args.get(3);
        int decimal = Integer.parseInt(weekRepeat, 2);
        int delayTime = (int) args.get(4);

        YCBTClient.settingAddAlarm(type,startHour,startMin,decimal,delayTime,new BleDataResponse() {
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

    /// 修改闹钟
    public static void settingModfiyAlarm(Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList args = (ArrayList) arguments;

        if (args.size() < 7) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;
        }

        int startHour = (int) args.get(0);
        int startMin = (int) args.get(1);
        int newType = (int) args.get(2);
        int newStartHour = (int) args.get(3);
        int newStartMin = (int) args.get(4);
        String newWeekRepeat = (String) args.get(5);
        int decimal = Integer.parseInt(newWeekRepeat, 2);
        int newDelayTime = (int) args.get(6);

        YCBTClient.settingModfiyAlarm(startHour,startMin,newType,newStartHour,newStartMin,decimal,newDelayTime,new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int code=0;
                if (i==3) {
                    code=YcProductPluginFlutterType.PluginState.succeed;
                } else {
                    code=YcProductPluginFlutterType.PluginState.failed;

                }
                HashMap map = new HashMap();
                map.put("code", code);
                map.put("data", "");
                result.success(map);
            }
        });
    }

    public static void updateCallAlerts(Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList args = (ArrayList) arguments;
        if (args.size() < 1) {
            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.failed);
            map.put("data", "");
            result.success(map);
            return;


        }
        boolean isAlerts = (boolean) args.get(0);
        YCBTClient.updateCallAlerts(isAlerts);

    }

    public static void appQuerySampleRate(Object arguments, @NonNull MethodChannel.Result result) {
        int type = (int) arguments;
        YCBTClient.appQuerySampleRate(type,new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                map.put("code", i);
                map.put("data",hashMap);
                result.success(map);
            }
        });
    }

    public static void appConfigureSampleRate(Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList args = (ArrayList) arguments;
        int type = (int)args.get(0);
        int sampleRate = (int)args.get(1);
        YCBTClient.appConfigureSampleRate(type,sampleRate,new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                map.put("code", i);
                map.put("data",hashMap);
                result.success(map);
            }
        });
    }

    public static void appConfigureRealTimePpg(Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList args = (ArrayList) arguments;
        ArrayList data1 = (ArrayList)args.get(0);
        int data2 = (int)args.get(1);
        ArrayList data3 = (ArrayList)args.get(2);
        ArrayList data4 = (ArrayList)args.get(3);
        ArrayList data5 = (ArrayList)args.get(4);
        ArrayList data6 = (ArrayList)args.get(5);
        ArrayList data7 = (ArrayList)args.get(6);
        ArrayList data8 = (ArrayList)args.get(7);
        YCBTClient.appConfigureRealTimeAcquisitionOfPpg(data1,data2,data3,data4,data5,data6,data7,data8,new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                map.put("code", i);
                map.put("data",hashMap);
                result.success(map);
            }
        });
    }
    public static void appQueryMems(Object arguments, @NonNull MethodChannel.Result result) {
        YCBTClient.appQueryMemsConfigure(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                map.put("code", i);
                map.put("data",hashMap);
                result.success(map);
            }
        });
    }
    public static void appMemsSwitch(Object arguments, @NonNull MethodChannel.Result result) {
        ArrayList args = (ArrayList) arguments;
        int onOff = (int)args.get(0);
        ArrayList type = (ArrayList)args.get(1);
        YCBTClient.appMemsSwitch(onOff,type,new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                map.put("code", i);
                map.put("data",hashMap);
                result.success(map);
            }
        });
    }

    public static void settingVibrationIntensity(Object arguments, @NonNull MethodChannel.Result result) {
        int level = (int) arguments;
        YCBTClient.settingVibrationIntensity(level,new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                HashMap map = new HashMap();
                map.put("code", i);
                map.put("data",hashMap);
                result.success(map);
            }
        });
    }

}
