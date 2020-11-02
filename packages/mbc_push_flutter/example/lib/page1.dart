import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbc_push/mbc_push.dart';
import 'package:mbc_push_example/page2.dart';

import 'main.dart';

class Page1 extends StatefulWidget {
  @override
  _Page1State createState() => _Page1State();

  static GlobalKey<NavigatorState> get navigatorState => GlobalKey();
}

class _Page1State extends State<Page1> {
  String _platformVersion = 'Unknown';
  String _init = 'Unknown';
  String _channel = 'Unknown';
  final MbcPush mbcPushKit = new MbcPush();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      MbcPush flutterPlugin = MbcPush();
      flutterPlugin.onMessageReceived((Map<String, dynamic> message) async {
        print("test123 - flutter onReceiveNotification: $message");
      });
      flutterPlugin.onMessageOpen((Map<String, dynamic> message) async {
        print("test123 - flutter onOpenNotification: $message");
                        MyApp.navigatorState.currentState
                    .push(MaterialPageRoute(builder: (BuildContext context) {
                  return Page2(
                  );
                }));
      });
      await flutterPlugin.init(onTokenReceive: (String token) => {
        print("test1234: " + token),
        print("test1234: " + token),
      }, ncAppID: 'd2a61920-1c9f-11ea-8b2b-a1f0876a7732', ncDomain: 'http://10.222.151.31:3005');
    } catch (e) {

    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = "test";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Column(
            children: <Widget>[
              Center(
                child: Text('Running on: $_platformVersion\n'),
              ),
              Center(
                child: Text('Token: $_init\n'),
              ),
              Center(
                child: Text('Channel: $_channel\n'),
              ),
              FlatButton(
                child: Text('Get token'),
                onPressed: () async {
                  try {
                    String dtoken = await MbcPush.getDeviceToken;
                    _init = dtoken;
                    setState(() {

                    });
                  } catch(err) {
                    print('error' + err);
                  }
                },
              ),
              FlatButton(
                child: Text('Get channel'),
                onPressed: () async {
                  String channel = await MbcPush().getPushServiceName();
                  _channel = channel;
                  setState(() {

                  });
                },
              ),
              FlatButton(
                child: Text('Subscribe all in one'),
                onPressed: () async {
                  List<String> a = <String>[
                    'aaaaa',
                    'bbbb',
                    'ccccc'
                  ];
                  List<String> b = <String>[
                    'aaaaa',
                    'bbbb',
                    'ccccc'
                  ];
                  String result = await MbcPush.subscribeAllInOne(subscribeList: a, unSubscribeList: b);
                  _channel = result;
                  setState(() {

                  });
                },
              ),
              FlatButton(
                child: Text('Subscribe notification'),
                onPressed: () async {
                  List<String> a = <String>[
                    'aaaaa',
                    'bbbb',
                    'ccccc'
                  ];
                  String result = await MbcPush.subscribeNotification(subscribeList: a, action: 'S');
                  _channel = result;
                  setState(() {

                  });
                },
              ),
              FlatButton(
                child: Text('Get subscribed topic'),
                onPressed: () async {
                  List<String> a = <String>[
                    'aaaaa',
                    'bbbb',
                    'ccccc'
                  ];
                  List<String> b = <String>[
                    'aaaaa',
                    'bbbb',
                    'ccccc'
                  ];
                  String result = await MbcPush.getSubscribeTopic();
                  _channel = result;
                  setState(() {

                  });
                },
              ),
            ],
          )
      ),
    );
  }
}