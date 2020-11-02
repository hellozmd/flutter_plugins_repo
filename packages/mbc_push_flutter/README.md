# mbc_push

MBC push kit for flutter plugin

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Usage

1. 在不同平台获取对应配置。在Android项目下的app folder中添加配置文件 google-services.json（谷歌推送对应配置）  (your-flutter-project/android/app/google-service.json)
在Android项目下添加配置文件 agconnect-services.json（华为推送对应配置）  (your-flutter-project/android/agconnect-services.json)
2. 在项目级的build.gradle文件中(your-flutter-project/android/build.gradle)的dependencies节点中添加
```
classpath 'com.google.gms:google-services:4.3.3'
classpath 'com.huawei.agconnect:agcp:1.3.1.300'
```
3. 在应用级的build.gradle文件中(your-flutter-project/android/app/build.gradle)添加依赖
```
apply plugin: 'com.huawei.agconnect'
apply plugin: 'com.google.gms.google-services'
```
4. 在应用级的build.gradle文件中(your-flutter-project/android/app/build.gradle)， 在Android模块里添加JPush配置
```
    manifestPlaceholders = [
            JPUSH_PKGNAME : applicationId,
            JPUSH_APPKEY : "5a12f2ffa46a80fa0099b625", //JPush 上注册的包名对应的 Appkey.
            JPUSH_CHANNEL : "developer-default", //暂时填写默认值即可.
    ]
```
5. 在应用级的build.gradle文件中(your-flutter-project/android/app/build.gradle)， 在Android模块里配置对应签名
```
    signingConfigs {
        config {
            keyAlias 'test0'
            keyPassword 'password'
            storeFile file('./test0.jks')
            storePassword 'password'
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.config
        }
        release {
            signingConfig signingConfigs.config
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
```

5. 配置Android清单文件,若是不配置的话ANDROID版本会编译不通过（HWService配置了一个gradle命令会读取对应的值）
该值可以可以在对应的控制台中获取，也可以从agconnect-services.json中获得，
<!-- HUAWEI APP ID -->
<meta-data
    android:name="com.huawei.hms.client.appid"
    android:value="[对应的华为AppId]" >
</meta-data>

6. API
