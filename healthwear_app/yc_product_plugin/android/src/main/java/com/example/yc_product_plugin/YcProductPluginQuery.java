package com.example.yc_product_plugin;


import androidx.annotation.NonNull;

import com.yucheng.ycbtsdk.Constants;
import com.yucheng.ycbtsdk.YCBTClient;
import com.yucheng.ycbtsdk.response.BleDataResponse;
import com.yucheng.ycbtsdk.utils.DeviceSupportFunctionUtil;
import com.yucheng.ycbtsdk.utils.SPUtil;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

// MARK: - 查询
public class YcProductPluginQuery {

    /// 查询基本信息
    public static void queryDeviceBasicInfo(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.getDeviceInfo(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);
                HashMap map = new HashMap();
                HashMap data = new HashMap();

                if (i == 0 && hashMap != null) {

                    HashMap obj = (HashMap) hashMap.get("data");

                    int deviceID = (int) obj.get("deviceId");
                    int deviceType = (int) obj.get("hardwareType");
                    int batteryStatus = (int) obj.get("deviceBatteryState");
                    int batteryPower = (int) obj.get("deviceBatteryValue");
                    int firmwareMajorVersion = (int) obj.get("deviceMainVersion");
                    int firmwareSubVersion = (int) obj.get("deviceSubVersion");

                    data.put("deviceID", deviceID);
                    data.put("deviceType", deviceType);
                    data.put("batteryStatus", batteryStatus);
                    data.put("batteryPower", batteryPower);
                    data.put("firmwareMajorVersion", firmwareMajorVersion);
                    data.put("firmwareSubVersion", firmwareSubVersion);
                }

                map.put("code", state);
                map.put("data", data);
                result.success(map);
            }
        });
    }

    /// 查询mac地址
    public static void queryDeviceMacAddress(Object arguments, @NonNull MethodChannel.Result result) {

        String macAddress = YCBTClient.getBindDeviceMac();

        int state = 0;

        if (macAddress.isEmpty()) {
            state = YcProductPluginFlutterType.PluginState.failed;
        }

        HashMap map = new HashMap();
        map.put("code", state);
        map.put("data", macAddress);
        result.success(map);
    }

    /// 查询设备型号
    public static void queryDeviceModel(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.getDeviceName(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);

                String deviceName = "";
                if (i == 0 && hashMap != null) {
                    deviceName = (String) hashMap.get("data");
                }

                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", deviceName);
                result.success(map);
            }
        });
    }

    /// 查询设备主控平台
    public static void queryDeviceMCU(Object arguments, @NonNull MethodChannel.Result result) {

        YCBTClient.getChipScheme(new BleDataResponse() {
            @Override
            public void onDataResponse(int i, float v, HashMap hashMap) {

                int state = YcProductPlugin.convertPluginState(i);

                int chipScheme = 0;

                if (i == 0 && hashMap != null) {
                    chipScheme = (int) hashMap.get("chipScheme");
                }

                // 兼容旧设备
                if (state == YcProductPluginFlutterType.PluginState.unavailable) {
                    state = YcProductPluginFlutterType.PluginState.succeed;
                    chipScheme = 0;
                }

                HashMap map = new HashMap();
                map.put("code", state);
                map.put("data", chipScheme);
                result.success(map);
            }
        });
    }

    /**
     * 获取功能列表
     *
     * @param arguments
     * @param result
     */
    public static void getDeviceFeature(Object arguments, @NonNull MethodChannel.Result result) {

        try {

            if (YCBTClient.connectState() != Constants.BLEState.ReadWriteOK) {

                HashMap map = new HashMap();
                map.put("code", YcProductPluginFlutterType.PluginState.failed);
                map.put("data", new HashMap());
                result.success(map);

                return;
            }


            HashMap deviceFeature = new HashMap();

            /// 血压
            deviceFeature.put("isSupportBloodPressure", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOOD));

            /// 语言设置
            deviceFeature.put("isSupportLanguageSettings", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMANYLANGUAGE));

            /// 消息推送 (总开关)
            deviceFeature.put("isSupportInformationPush", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASINFORMATION));

            /// 心率
            deviceFeature.put("isSupportHeartRate", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASHEARTRATE));

            /// OTA升级
            deviceFeature.put("isSupportOta", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFIRMWAREUPDATE));

            /// 实时数据上传
            deviceFeature.put("isSupportRealTimeDataUpload", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASREALDATA));

            /// 睡眠
            deviceFeature.put("isSupportSleep", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSLEEP));

            /// 计步
            deviceFeature.put("isSupportStep", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSTEPCOUNT));

            // MARK: - === 主要功能2 ===

            /// 多运动
            deviceFeature.put("isSupportSport", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMORESPORT));

            /// HRV
            deviceFeature.put("isSupportHRV", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASHRV));

            /// 呼吸率
            deviceFeature.put("isSupportRespirationRate", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASRESPIRATORYRATE));

            /// 血氧
            deviceFeature.put("isSupportBloodOxygen", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOODOXYGEN));

            /// 历史ECG
            deviceFeature.put("isSupportHistoricalECG", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASECGHISTORYUPLOAD));

            /// 实时ECG
            deviceFeature.put("isSupportRealTimeECG", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASECGREALUPLOAD));

            /// 血压告警
            deviceFeature.put("isSupportBloodPressureAlarm", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOODALARM));

            /// 心率告警
            deviceFeature.put("isSupportHeartRateAlarm", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASHEARTALARM));


            // MARK: - === 闹钟类型 ====

            /// 闹钟数量( alarmClockCount 0表示不支持闹钟)
            int alarmClockCount = YCBTClient.getAlarmCount();
            deviceFeature.put("isSupportAlarm", alarmClockCount > 0);

            /// 闹钟类型 起床
            deviceFeature.put("isSupportAlarmTypeWakeUp", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASGETUP));

            /// 闹钟类型 起床
            deviceFeature.put("isSupportAlarmTypeSleep", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTAKESLEEP));

            /// 闹钟类型 锻炼
            deviceFeature.put("isSupportAlarmTypeExercise", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTAKEEXERCISE));

            /// 闹钟类型 吃药
            deviceFeature.put("isSupportAlarmTypeMedicine", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTAKEPILLS));

            /// 闹钟类型 约会
            deviceFeature.put("isSupportAlarmTypeAppointment", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASAPPOINT));

            /// 闹钟类型 聚会
            deviceFeature.put("isSupportAlarmTypeParty", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASPARTY));

            /// 闹钟类型 会议
            deviceFeature.put("isSupportAlarmTypeMeeting", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMEETING));

            /// 闹钟类型 自定义
            deviceFeature.put("isSupportAlarmTypeCustom", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASCUSTOM));


            // MARK: - === 消息推送 ===

            // 第一组
            deviceFeature.put("isSupportInformationTypeTwitter", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTWITTER));
            deviceFeature.put("isSupportInformationTypeFacebook", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFACEBOOK));
            deviceFeature.put("isSupportInformationTypeWeiBo", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSINA));
            deviceFeature.put("isSupportInformationTypeQQ", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASQQ));
            deviceFeature.put("isSupportInformationTypeWeChat", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASWECHAT));
            deviceFeature.put("isSupportInformationTypeEmail", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASEMAIL));
            deviceFeature.put("isSupportInformationTypeSMS", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMESSAGE));
            deviceFeature.put("isSupportInformationTypeCall", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASCALLPHONE));

            // 第二组
            deviceFeature.put("isSupportInformationTypeTelegram", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASOTHERMESSENGER));
            deviceFeature.put("isSupportInformationTypeSkype", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSKYPE));
            deviceFeature.put("isSupportInformationTypeSnapchat", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSNAPCHAT));
            deviceFeature.put("isSupportInformationTypeLine", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASLINE));
            deviceFeature.put("isSupportInformationTypeLinkedIn", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASLINKEDIN));
            deviceFeature.put("isSupportInformationTypeInstagram", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASINSTAGRAM));
            deviceFeature.put("isSupportInformationTypeMessenger", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMESSENGER));
            deviceFeature.put("isSupportInformationTypeWhatsApp", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASWHATSAPP));

            // MARK: - === 其它功能1 ===

            /// 翻腕亮屏
            deviceFeature.put("isSupportWristBrightScreen", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASLIFTBRIGHT));

            /// 勿扰模式
            deviceFeature.put("isSupportDoNotDisturbMode", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASNOTITOGGLE));

            /// 血压水平设置
            deviceFeature.put("isSupportBloodPressureLevelSetting", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOODLEVEL));

            /// 出厂设置
            deviceFeature.put("isSupportFactorySettings", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFACTORYSETTING));

            /// 找设备
            deviceFeature.put("isSupportFindDevice", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFINDDEVICE));

            /// 找手机
            deviceFeature.put("isSupportFindPhone", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFINDPHONE));

            /// 防丢提醒
            deviceFeature.put("isSupportAntiLostReminder", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASANTILOST));

            /// 久坐提醒
            deviceFeature.put("isSupportSedentaryReminder", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASLONGSITTING));

            // MARK: - === 其它功能2 ===

            /// 上传数据 加密
            deviceFeature.put("isSupportUploadDataEncryption", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASENCRYPTION));

            /// 通话
            deviceFeature.put("isSupportCall", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASPHONESUPPORT));

            /// 心电诊断
            deviceFeature.put("isSupportECGDiagnosis", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASECGDIAGNOSIS));

            /// 明日天气
            deviceFeature.put("isSupportTomorrowWeather", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTOMORROWWEATHER));

            /// 今日天气
            deviceFeature.put("isSupportTodayWeather", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTODAYWEATHER));

            /// 搜周边
            deviceFeature.put("isSupportSearchAround", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSEARCHAROUND));

            /// 微信运动
            deviceFeature.put("isSupportWeChatSports", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASWECHATSPORT));

            /// 肤色设置
            deviceFeature.put("isSupportSkinColorSettings", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSKINCOLOR));


            // MARK: - === 其它功能3 ===

            /// 温度
            deviceFeature.put("isSupportTemperature", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTEMP));

            /// 压力
            deviceFeature.put("isSupportPressure", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_PRESSURE));

            /// 最大摄氧量
            deviceFeature.put("isSupportVo2max", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_MAXIMAL_OXYGEN_INTAKE));

            /// 音乐控制
            deviceFeature.put("isSupportMusicControl", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMUSIC));

            /// 主题
            deviceFeature.put("isSupportTheme", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTHEME));

            /// 电极位置
            deviceFeature.put("isSupportElectrodePosition", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASECGRIGHTELECTRODE));

            /// 血压校准
            deviceFeature.put("isSupportBloodPressureCalibration", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOODPRESSURECALIBRATION));

            /// CVRR
            deviceFeature.put("isSupportCVRR", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASCVRR));

            /// 腋温测量
            deviceFeature.put("isSupportAxillaryTemperatureMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTEMPAXILLARYTEST));

            /// 温度预警
            deviceFeature.put("isSupportTemperatureAlarm", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTEMPALARM));

            // MARK: - === 其它功能4 ===

            /// 温度校准
            deviceFeature.put("isSupportTemperatureCalibration", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTEMPCALIBRATION));

            /// 机主信息编辑
            deviceFeature.put("isSupportHostInfomationEdit", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSETINFO));

            /// 手动拍照
            deviceFeature.put("isSupportManualPhotographing", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMANUALTAKEPHOTO));

            /// 摇一摇拍照
            deviceFeature.put("isSupportShakePhotographing", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSHAKETAKEPHOTO));

            /// 女性生理周期
            deviceFeature.put("isSupportFemalePhysiologicalCycle", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFEMALEPHYSIOLOGICALCYCLE));

            /// 表盘功能
            deviceFeature.put("isSupportWatchFace", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASDIAL));

            /// 通讯录
            deviceFeature.put("isSupportAddressBook", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASCONTACTS));

            /// ECG结果精准
            deviceFeature.put("isECGResultsAccurate", !YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASINACCURATEECG));


            // MARK: - 运动模式

            /// 登山
            deviceFeature.put("isSupportMountaineering", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASMOUNTAINCLIMBING));

            /// 足球
            deviceFeature.put("isSupportFootball", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFOOTBALL));

            /// 乒乓球
            deviceFeature.put("isSupportPingPang", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASPINGPONG));

            /// 户外跑步
            deviceFeature.put("isSupportOutdoorRunning", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASOUTDOORRUNING));

            /// 室内跑步
            deviceFeature.put("isSupportIndoorRunning", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASINDOORRUNING));

            /// 户外步行
            deviceFeature.put("isSupportOutdoorWalking", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASOUTDOORWALKING));

            /// 室内步行
            deviceFeature.put("isSupportIndoorWalking", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASINDOORWALKING));

            /// 实时监护模式
            deviceFeature.put("isSupportRealTimeMonitoring", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASREALTIMEMONITORINGMODE));

            /// 羽毛球
            deviceFeature.put("isSupportBadminton", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBADMINTON));

            /// 健走
            deviceFeature.put("isSupportWalk", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASWALKING));

            /// 游泳
            deviceFeature.put("isSupportSwimming", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSWIMMING));

            /// 篮球
            deviceFeature.put("isSupportPlayBall", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBASKETBALL));

            /// 跳绳
            deviceFeature.put("isSupportRopeSkipping", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASROPESKIPPING));

            /// 骑行
            deviceFeature.put("isSupportRiding", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASRIDING));

            /// 健身
            deviceFeature.put("isSupportFitness", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASFITNESS));

            /// 跑步
            deviceFeature.put("isSupportRun", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASRUNNING));

            /// 室内骑行
            deviceFeature.put("isSupportIndoorRiding", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASINDOORRIDING));

            /// 踏步机
            deviceFeature.put("isSupportStepper", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSTEPPER));

            /// 划船机
            deviceFeature.put("isSupportRowingMachine", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASROWINGMACHINE));

            /// 仰卧起坐
            deviceFeature.put("isSupportSitUps", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSITUPS));

            /// 跳跃运动
            deviceFeature.put("isSupportJumping", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASJUMPING));

            /// 重量训练
            deviceFeature.put("isSupportWeightTraining", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASWEIGHTTRAINING));

            /// 瑜伽
            deviceFeature.put("isSupportYoga", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASYOGA));

            /// 徒步
            deviceFeature.put("isSupportOnFoot", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASONFOOT));

            // MARK: - === 扩充功能

            /// 同步运动实时数据
            deviceFeature.put("isSupportSyncRealSportData", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASREALEXERCISEDATA));

            /// 启动心率测量
            deviceFeature.put("isSupportStartHeartRateMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHATESTHEART));

            /// 启动血压测量
            deviceFeature.put("isSupportStartBloodPressureMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTESTBLOOD));

            /// 启动血氧测量
            deviceFeature.put("isSupportStartBloodOxygenMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTESTSPO2));

            /// 启动体温测量
            deviceFeature.put("isSupportStartBodyTemperatureMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTESTTEMP));

            /// 启动压力测量
            deviceFeature.put("isSupportStartPressureMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_PRESSURE_MEASUREMENT));

            /// 启动呼吸率测量
            deviceFeature.put("isSupportStartRespirationRateMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTESTRESPIRATIONRATE));

            /// 启动血糖测量
            deviceFeature.put("isSupportStartBloodGlucoseMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_BLOODSUGAR_MEASUREMENT));

            /// 启动HRV测量
            deviceFeature.put("isSupportStartHRVMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_HRV_MEASUREMENT));

            //多种类型信息推送
//        public static final String ISHASKINDSINFORMATIONPUSH = "isHasKindsInformationPush";

            /// 自定义表盘
            deviceFeature.put("isSupportCustomWatchface", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASCUSTOMDIAL));

            // =========

            /// 精准血压测量
            deviceFeature.put("isSupportAccurateBloodPressureMeasurement", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASINFLATED));

            /// SOS开关
            deviceFeature.put("isSupportSOS", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSOS));

            /// 血氧报警
            deviceFeature.put("isSupportBloodOxygenAlarm", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOODOXYGENALARM));

            /// 精准血压实时数据上传
            deviceFeature.put("isSupportAccurateBloodPressureRealTimeDataUpload", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASUPLOADINFLATEBLOOD));

            /// Viber消息推送
            deviceFeature.put("isSupportInformationTypeViber", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASVIBERNOTIFY));

            /// 其它消息推送
            deviceFeature.put("isSupportInformationTypeOther", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASOTHRENOTIFY));

            /// 自定义表盘颜色翻转
            deviceFeature.put("isFlipCustomDialColor", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISFLIPDIALIMAGE));

            /// 手表亮度调节五档
            deviceFeature.put("isSupportFiveSpeedBrightness", YCBTClient.isSupportFunction(Constants.FunctionConstant.WATCHSCREENBRIGHTNESS));


            // =============

            /// 震动强度设置
            deviceFeature.put("isSupportVibrationIntensitySetting", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASVIBRATIONINTENSITY));

            /// 亮屏时间设置
            deviceFeature.put("isSupportScreenTimeSetting", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASSETSCREENTIME));

            /// 亮屏亮度调节
            deviceFeature.put("isSupportScreenBrightnessAdjust", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASWATCHSCREENBRIGHTNESS));

            /// 血糖测量
            deviceFeature.put("isSupportBloodGlucose", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOODSUGAR));

            /// 运动暂停
            deviceFeature.put("isSupportSportPause", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASPAUSEEXERCISE));

            /// 是否支持运动断开延迟
            deviceFeature.put("isSupportMotionDelayDisconnect", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_MOTION_DELAY_DISCONNECT));

            /// 喝水提醒
            deviceFeature.put("isSupportDrinkWaterReminder", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASDRINKWATERREMINDER));

            /// 发送名片
            deviceFeature.put("isSupportBusinessCard", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBUSINESSCARD));

            /// 尿酸测量
            deviceFeature.put("isSupportUricAcid", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASURICACIDMEASUREMENT));


            // MARK: - 运动模式4

            /// 网球
            deviceFeature.put("isSupportVolleyball", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASVOLLEYBALL));

            /// 皮划艇
            deviceFeature.put("isSupportKayak", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASKAYAK));

            /// 轮滑
            deviceFeature.put("isSupportRollerSkating", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASROLLERSKATING));

            /// 网球
            deviceFeature.put("isSupportTennis", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTENNIS));

            /// 高尔夫
            deviceFeature.put("isSupportGolf", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASGOLF));

            /// 椭圆机
            deviceFeature.put("isSupportEllipticalMachine", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASELLIPTICALMACHINE));

            /// 舞蹈
            deviceFeature.put("isSupportDance", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASDANCE));

            /// 攀岩
            deviceFeature.put("isSupportRockClimbing", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASROCKCLIMBING));


            /// 健身操
            deviceFeature.put("isSupportAerobics", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASAEROBICS));

            /// 其它运动
            deviceFeature.put("isSupportOtherSports", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASOTHERSPORTS));

            /// 血酮测量
            deviceFeature.put("isSupportBloodKetone", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASBLOODKETONEMEASUREMENT));

            /// 支持支付宝
            deviceFeature.put("isSupportAliPay", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASALIIOT));

            /// 安卓绑定
            deviceFeature.put("isSupportAndroidBind", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASCREATEBOND));

            /// 呼吸率告警
            deviceFeature.put("isSupportRespirationRateAlarm", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASRESPIRATORYRATEALARM));

            /// 血脂测量
            deviceFeature.put("isSupportBloodFat", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASIMPRECISEBLOODFAT));

            /// 独立监测时间(E200测量)
            deviceFeature.put("isSupportIndependentMonitoringTime", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_INDEPENDENT_AUTOMATIC_TIME_MEASUREMENT));

            /// 本地录音上传
            deviceFeature.put("isSupportLocalRecordingFileUpload", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_RECORDING_FILE));

            /// 理疗记录
            deviceFeature.put("isSupportPhysiotherapyRecords", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_PHYSIOTHERAPY));

            /// 是否支持消息推送 Zoom
            deviceFeature.put("isSupportInformationTypeZoom", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASZOOMNOTIFY));

            /// 是否支持消息推送 TikTok
            deviceFeature.put("isSupportInformationTypeTikTok", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASTIKTOKNOTIFY));

            /// 是否支持消息推送 KakaoTalk
            deviceFeature.put("isSupportInformationTypeKaKaoTalk", YCBTClient.isSupportFunction(Constants.FunctionConstant.ISHASKAKAOTALKNOTIFY));


            // MARK: -

            /// 是否支持睡眠提醒
            deviceFeature.put("isSupportSleepReminder", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_SLEEP_REMIND));

            /// 是否支持设备规格设置
            deviceFeature.put("isSupportDeviceSpecificationsSetting", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_DEVICE_SPEC));

            /// 是否支持设备本地运动上传
            deviceFeature.put("isSupportLocalSportDataUpload", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_LOCAL_SPORT_DATA));

            /// 是否支持零星小睡
            deviceFeature.put("isSupportFewSleep", YCBTClient.isSupportFunction(Constants.FunctionConstant.IS_HAS_Sporadic_Naps));

            HashMap map = new HashMap();
            map.put("code", YcProductPluginFlutterType.PluginState.succeed);
            map.put("data", deviceFeature);
            result.success(map);
        } catch (java.lang.Exception e) {
            result.error("GET_DEVICE_FEATURE_ERROR", e.getMessage(), null);
        }

    }
}
