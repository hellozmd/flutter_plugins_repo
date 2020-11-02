import 'dart:async';

import 'package:flutter/services.dart';
typedef Future<dynamic> EventHandler(Map<String, dynamic> event);
class MbcPush {
  static const MethodChannel _channel =
  const MethodChannel('mbc_push');

  EventHandler _onReceiveNotification;
  EventHandler _onOpenNotification;
  Function _onTokenReceive;

  /// 获取设备标识
  Future<String> getDeviceID() async {
    return await _channel.invokeMethod('getDeviceID');
  }

  /// 获取当前厂商通道
  Future<String> getPushServiceName() async {
    return await _channel.invokeMethod('getPushServiceName');
  }

  /// 初始化代码
  /// @param onTokenReceive 接收token的回调函数 Function(String token){}
  /// @param ncDomain Notification Center的host
  /// @param ncAppID Notification Center上对应APP的appID
  Future<void> init({Function onTokenReceive, String ncDomain, String ncAppID}) async {
    // Channel set method call
    _onTokenReceive = onTokenReceive;
    _channel.setMethodCallHandler(_handleMethod);
    await _channel.invokeMethod('initPush', {
          'ncDomain': ncDomain,
          'ncAppID': ncAppID
        });
  }

  /// 接收到通知的回调(还没有打开通知， 用作预处理通知内容)
  /// @param onReceiveNotification Function(Map<String, dynamic> event)
  void onMessageReceived(EventHandler onReceiveNotification) {
    _onReceiveNotification = onReceiveNotification;
  }

  /// 点击通知的回调
  /// @param onMessageOpen Function(Map<String, dynamic> event)
  void onMessageOpen(EventHandler onMessageOpen) {
    _onOpenNotification = onMessageOpen;
  }

  /// 获取device token
  static Future<String> get getDeviceToken async {
    return await _channel.invokeMethod('getDeviceToken');
  }

  /// 获取支持的厂商推送列表
  static Future<List<String>> get getChannelList async {
    return await _channel.invokeMethod('getChannelList');
  }

  /// 订阅API
  /// @param subscribeList 订阅的topic数组
  /// @param unSubscribeList 取消订阅的topic数组
  static Future<String> subscribeAllInOne({List<String> subscribeList, List<String> unSubscribeList}) async {
    return await _channel.invokeMethod('subscribeAllInOne', <String, dynamic> {
      'subscribeList': subscribeList,
      'unSubscribeList': unSubscribeList,
    });
  }

  /// 订阅API
  /// @param subscribeList 订阅的topic数组
  /// @param action 订阅的行为 S: 订阅 U: 取消订阅
  static Future<String> subscribeNotification({List<String> subscribeList, String action}) async {
    return await _channel.invokeMethod('subscribeNotification', <String, dynamic> {
      'topicString': subscribeList,
      'action': action
    });
  }

  /// 获取该设备已经订阅的topic
  static Future<String> getSubscribeTopic() async {
    return await _channel.invokeMethod('getSubscribeTopic');
  }

  /// 更新设备订阅信息
  static Future<String> updateChannel() async {
    return await _channel.invokeMethod('updateChannel');
  }

  /// 统一分发Native请求调用的函数
  Future<Null> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onReceiveNotification":
        return _onReceiveNotification(call.arguments.cast<String, dynamic>());
      case "onOpenNotification":
        return _onOpenNotification(call.arguments.cast<String, dynamic>());
      case "onReceiveDeviceToken":
        return _onTokenReceive(call.arguments);
      default:
        throw new UnsupportedError("Unrecognized Event");
    }
  }
}
