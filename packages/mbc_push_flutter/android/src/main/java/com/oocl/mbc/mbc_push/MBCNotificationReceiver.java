package com.oocl.mbc.mbc_push;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

public class MBCNotificationReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        Log.i("mbc push", "notification payload");
        Map<String, String> mapData = new HashMap<>();
        if (intent.getStringExtra("type").equals("clickAction") || intent.getAction().equals("com.oocl.mbc.notification.open")) {
            // TODO： 还需要判断应用是否运行/在前台还是后台
            // Click notification action
            mapData.put("title", intent.getStringExtra("title"));
            mapData.put("message", intent.getStringExtra("message"));
            mapData.put("payload", intent.getStringExtra("payload"));
            MbcPushPlugin.channel.invokeMethod("onOpenNotification", mapData);
        } else if (intent.getStringExtra("type").equals("recvMessage") || intent.getAction().equals("com.oocl.mbc.notification.recv")) {
            // Receive notification action
            mapData.put("title", intent.getStringExtra("title"));
            mapData.put("message", intent.getStringExtra("message"));
            mapData.put("payload", intent.getStringExtra("payload"));
            MbcPushPlugin.channel.invokeMethod("onOpenNotification", mapData);
        }
    }
}
