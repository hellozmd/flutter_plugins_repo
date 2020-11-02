package com.oocl.mbc.mbc_push;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import com.oocl.mbc.core.MBCPushKit;
import com.oocl.mbc.network.NotificationService;
import com.oocl.mbc.receiver.MBCJPushReceiver;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import okhttp3.Callback;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

import cn.jpush.android.api.NotificationMessage;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.app.Activity;

import androidx.annotation.NonNull;

/**
 * MbcPushPlugin
 */
public class MbcPushPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    public static MethodChannel channel;
    private static volatile Context context;
    private static MbcPushPlugin instance;
    private static Activity mActivity;
    private static MBCDeviceTokenReceiver mbcDeviceTokenReceiver;
    private static MBCNotificationReceiver mbcNotificationRecv;


    public static MbcPushPlugin getInstance() {
        return instance;
    }

    private MbcPushPlugin(String abc) {
        instance = new MbcPushPlugin();
    }

    public MbcPushPlugin() {
    }

    public static Context getContext() {
        return MbcPushPlugin.context;
    }

    public static void setContext(Context context) {
        MbcPushPlugin.context = context;
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "mbc_push");
        channel.setMethodCallHandler(this);
        MbcPushPlugin.setContext(flutterPluginBinding.getApplicationContext());
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    public static void registerWith(Registrar registrar) {
        mActivity = registrar.activity();
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "mbc_push_kit");
        channel.setMethodCallHandler(new MbcPushPlugin(""));
    }

    @SuppressLint("HardwareIds")
    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + Build.VERSION.RELEASE);
                break;
            case "initPush":
                // Dynamic register deviceToken receiver <==> Handle plugin method
                MBCPushKit.getInstance(MbcPushPlugin.context).init((String)call.argument("ncDomain"), (String)call.argument("ncAppID"));
                result.success("Native init call");
                // getDeviceToken
                break;
            case "configApp":
                MBCPushKit.configApp((String)call.argument("ncDomain"), (String)call.argument("ncAppID"));
                break;
            case "isNotificationPermissionGranted":
                if (MBCPushKit.isNotificationEnable(context)) {
                    result.success("true");
                } else {
                    result.success("false");
                }
                break;
            case "getDeviceToken":
                String dToken = MBCPushKit.getInstance(MbcPushPlugin.context).getDeviceToken(MbcPushPlugin.context);
                result.success(dToken);
                break;
            case "getPushServiceName":
                result.success(MBCPushKit.getDeviceChannel());
                break;
            case "getDeviceID":
                String deviceID = "";
                deviceID = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
                result.success(deviceID);
                break;
            case "getChannelList":
                result.success(MBCPushKit.getChannelList());
                break;
            case "getSubscribeTopic":
                MBCPushKit.getSubscribedTopic(
                        new Callback() {
                            @Override
                            public void onFailure(Call call, final IOException e) {
                                mActivity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(String.format("\"success\": \"false\", \"data\": \"%s\"", e.getMessage()));
                                    }
                                });
                            }

                            @Override
                            public void onResponse(Call call, final Response response) throws IOException {
                                mActivity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        try {
                                            if (response.body() != null) {
                                                result.success(response.body().string());
                                            } else {
                                                result.success(String.format("\"success\": \"false\", \"data\": \"%s\"", "Response body is empty"));
                                            }
                                        } catch (IOException e) {
                                            result.success(String.format("\"success\": \"false\", \"data\": \"%s\"", e.getMessage()));
                                        }
                                    }
                                });
                            }
                        });
                break;
            case "subscribeAllInOne":
                // ArrayList<String>
                List<String> subscribeList = call.argument("subscribeList");
                List<String> unSubscribeList = call.argument("unSubscribeList");
                MBCPushKit.subscribeAllInOne(
                        subscribeList,
                        unSubscribeList,
                        new Callback() {
                            @Override
                            public void onFailure(Call call, final IOException e) {
                                mActivity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(String.format("\"success\": \"false\", \"data\": \"%s\"", e.getMessage()));
                                    }
                                });
                            }

                            @Override
                            public void onResponse(Call call, final Response response) throws IOException {
                                mActivity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        try {
                                            if (response.body() != null) {
                                                result.success(response.body().string());
                                            } else {
                                                result.success(String.format("\"success\": \"false\", \"data\": \"%s\"", "Response body is empty"));
                                            }
                                        } catch (IOException e) {
                                            result.success(String.format("\"success\": \"false\", \"data\": \"%s\"", e.getMessage()));
                                        }
                                    }
                                });
                            }
                        });
                break;
            case "subscribeNotification":
                // ArrayList<String>
                List<String> topicString = call.argument("topicString");
                String action = call.argument("action");
                MBCPushKit.subscribeNotification(
                        topicString,
                        action,
                        new Callback() {
                            @Override
                            public void onFailure(Call call, final IOException e) {
                                mActivity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(String.format("\"success\": false, \"data\": \"%s\"", e.getMessage()));
                                    }
                                });
                            }

                            @Override
                            public void onResponse(Call call, final Response response) throws IOException {
                                mActivity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        try {
                                            if (response.body() != null) {
                                                result.success(response.body().string());
                                            } else {
                                                result.success(String.format("\"success\": false, \"data\": \"%s\"", "Response body is empty"));
                                            }
                                        } catch (IOException e) {
                                            result.success(String.format("\"success\": false, \"data\": \"%s\"", e.getMessage()));
                                        }
                                    }
                                });
                            }
                        });
                break;
            case "updateChannel":
                MBCPushKit.updateChannel(
                        MBCPushKit.isNotificationEnable(context) ? "1" : "0",
                        new Callback() {
                    @Override
                    public void onFailure(Call call, final IOException e) {
                        mActivity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                result.success(String.format("\"success\": false, \"data\": \"%s\"", e.getMessage()));
                            }
                        });
                    }

                    @Override
                    public void onResponse(Call call, final Response response) throws IOException {
                        mActivity.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                try {
                                    if (response.body() != null) {
                                        result.success(response.body().string());
                                    } else {
                                        result.success(String.format("\"success\": false, \"data\": \"%s\"", "Response body is empty"));
                                    }
                                } catch (IOException e) {
                                    result.success(String.format("\"success\": false, \"data\": \"%s\"", e.getMessage()));
                                }
                            }
                        });
                    }
                });
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    public static void onOpenNotification(Map<String, String> mapData) {
        channel.invokeMethod("onOpenNotification", mapData);
    }

    public static void onTokenReceive(String deviceToken) {
        channel.invokeMethod("onTokenReceive", deviceToken);
    }

    public static void dispatcherClickNotificationEvt(Intent intent) {
        if (null != intent) {
            if (intent.getExtras() != null && intent.getExtras().keySet() != null) {
                for (String a : intent.getExtras().keySet()) {
                    Log.i("test1234", "key: " + a);
                }
            }
//      if (MBCPushKit.getInstance(context).getDeviceChannel().equals("FCM")) {
//        if (null != intent.getStringExtra("payload")) {
//          String payload = intent.getStringExtra("payload");
//          Intent notificationIntent = new Intent("com.oocl.mbc.notification.recv");
//          Log.i("MBC push", "FCM payload");
//          Log.i("MBC push", payload);
//          notificationIntent.setClass(getContext(), MBCNotificationReceiver.class);
//          notificationIntent.putExtra("type", "clickAction");
//          notificationIntent.putExtra("payload", payload);
//          getContext().sendBroadcast(notificationIntent);
//        }
//      } else {
            // 方法1设置的数据通过如下方式获取
            if (null != intent.getData()) {
                String type = intent.getData().getQueryParameter("type");
                if (null != type && type.equals("nc")) {
                    String payload = intent.getData().getQueryParameter("payload");
                    if (null != payload) {
                        Intent notificationIntent = new Intent("com.oocl.mbc.notification.recv");
                        notificationIntent.setClass(getContext(), MBCNotificationReceiver.class);
                        notificationIntent.putExtra("type", "clickAction");
                        notificationIntent.putExtra("payload", payload);
                        getContext().sendBroadcast(notificationIntent);
                    }
                }
            }
//      }
        }
    }

    public static void registerMBCReceiver() {
        // Register notification receiver
        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction("com.oocl.mbc.notification.recv");
        intentFilter.addAction("com.oocl.mbc.notification.open");
        mbcNotificationRecv = new MBCNotificationReceiver();
        context.registerReceiver(mbcNotificationRecv, intentFilter);
        // Register token receiver
        IntentFilter tokenIntentFilter = new IntentFilter();
        tokenIntentFilter.addAction("com.oocl.mbc.token.dispatcher");
        mbcDeviceTokenReceiver = new MBCDeviceTokenReceiver();
        context.registerReceiver(mbcDeviceTokenReceiver, tokenIntentFilter);
    }

    public static void unRegisterTokenReceiver() {
        context.unregisterReceiver(mbcNotificationRecv);
        context.unregisterReceiver(mbcDeviceTokenReceiver);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        if (null != mActivity) {
            mActivity = null;
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        if (null != mActivity) {
            mActivity = null;
        }
    }
}
