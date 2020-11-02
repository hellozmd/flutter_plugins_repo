package com.oocl.mbc.mbc_push_example;

import io.flutter.embedding.android.FlutterActivity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.oocl.mbc.mbc_push.MbcPushPlugin;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i("test1234", "onCreate");
        // Init receiver on activity create
        MbcPushPlugin.registerMBCReceiver();
    }

    @Override
    public void onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed();
        Log.i("test1234", "onFlutterUiDisplayed");
        MbcPushPlugin.dispatcherClickNotificationEvt(getIntent());
        getIntent().removeExtra("type");
        getIntent().setData(null);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        Log.i("test1234", "onNewIntent");
        MbcPushPlugin.dispatcherClickNotificationEvt(intent);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.i("test1234", "onDestroy");
        MbcPushPlugin.unRegisterTokenReceiver();
    }
}
