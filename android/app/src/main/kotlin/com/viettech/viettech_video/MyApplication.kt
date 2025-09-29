package com.viettech.viettech_video

import io.flutter.app.FlutterApplication
import com.zing.zalo.zalosdk.oauth.ZaloSDKApplication

class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        ZaloSDKApplication.wrap(this)
    }
}