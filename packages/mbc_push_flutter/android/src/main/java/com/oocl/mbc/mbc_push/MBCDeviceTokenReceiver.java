package com.oocl.mbc.mbc_push;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.oocl.mbc.util.SpUtils;
import com.oocl.mbc.util.MBCKitConstant;

public class MBCDeviceTokenReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        String deviceToken = intent.getStringExtra("deviceToken");
        Log.d("mbc push", "Receiver sending token to receiver. token:" + deviceToken);
        // 将旧的token存入oldToken中，否则为空
        String originToken = (String)SpUtils.get(context, MBCKitConstant.SP_KEY_DEVICETOKEN, "");
        SpUtils.put(context, MBCKitConstant.SP_KEY_OLD_DEVICETOKEN, originToken);
        SpUtils.put(context, MBCKitConstant.SP_KEY_DEVICETOKEN, deviceToken);
        MbcPushPlugin.channel.invokeMethod("onReceiveDeviceToken", deviceToken);
    }
}
