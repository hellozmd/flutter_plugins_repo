import 'package:flutter/material.dart';
import 'package:mbc_push/mbc_push.dart';
import 'package:mbc_push_example/page1.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MbcPush flutterPlugin = MbcPush();
//  flutterPlugin.addEventHandler(
//      onReceiveNotification: (Map<String, dynamic> event) {
//        print('aaaaaaaa');
//        event.forEach((key, value) {
//          print(key);
//          print(value);
//        });
//      },
//      onOpenNotification: (Map<String, dynamic> event){
//        print('bbbbbbbb');
//        event.forEach((key, value) {
//          print(key);
//          print(value);
//        });
//        MyApp.navigatorState.currentState
//            .push(MaterialPageRoute(builder: (BuildContext context) {
//          return Page2(
//          );
//        }));
//      }
//  );
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
//  @override
//  _MyAppState createState() => _MyAppState();

  static GlobalKey<NavigatorState> navigatorState = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorState,
      home: Page1(),
    );
  }
}
//
//class _MyAppState extends State<MyApp> {
//  String _platformVersion = 'Unknown';
//  String _init = 'Unknown';
//  final FlutterPlugin flutterPlugin = new FlutterPlugin();
//
//  @override
//  void initState() {
//    super.initState();
//    flutterPlugin.addEventHandler(
//        onReceiveNotification: (Map<String, dynamic> event) {
//          print('aaaaaaaa');
//          event.forEach((key, value) {
//            print(key);
//            print(value);
//          });
//        },
//        onOpenNotification: (Map<String, dynamic> event){
//          print('bbbbbbbb');
//          print('bbbbbbbb');
//          print('bbbbbbbb');
//          print('bbbbbbbb');
//          print('bbbbbbbb');
//          print('bbbbbbbb');
//          print('bbbbbbbb');
//          print('bbbbbbbb');
//          event.forEach((key, value) {
//            print(key);
//            print(value);
//          });
//          MyApp.navigatorState.currentState
//              .push(MaterialPageRoute(builder: (BuildContext context) {
//            return Page2(
//            );
//          }));
//          print('CCCCCCCCCC');
//          print('CCCCCCCCCC');
//          print('CCCCCCCCCC');
//          print('CCCCCCCCCC');
//        }
//      );
//    initPlatformState();
//  }
//
//  // Platform messages are asynchronous, so we initialize in an async method.
//  Future<void> initPlatformState() async {
//    String platformVersion;
//    // Platform messages may fail, so we use a try/catch PlatformException.
//    try {
//      platformVersion = await FlutterPlugin.platformVersion;
//      _init = await FlutterPlugin.pushInit;
//    } on PlatformException {
//      platformVersion = 'Failed to get platform version.';
//    }
//
//    // If the widget was removed from the tree while the asynchronous platform
//    // message was in flight, we want to discard the reply rather than calling
//    // setState to update our non-existent appearance.
//    if (!mounted) return;
//
//    setState(() {
//      _platformVersion = platformVersion;
//    });
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      navigatorKey: MyApp.navigatorState,
//      home: Scaffold(
//        appBar: AppBar(
//          title: const Text('Plugin example app'),
//        ),
//        body: Column(
//          children: <Widget>[
//            Center(
//              child: Text('Running on: $_platformVersion\n'),
//            ),
//            Center(
//              child: Text('Running on: $_init\n'),
//            ),
//            FlatButton(
//              child: Text('Get token'),
//              onPressed: () async {
//                String dtoken = await FlutterPlugin.mbcdeviceToken;
//                _init = dtoken;
//                setState(() {
//
//                });
//              },
//            ),
//            FlatButton(
//              child: Text('Go to another page'),
//              onPressed: () async {
////                Navigator.push(
////                  context,
////                  new MaterialPageRoute(builder: (context) => new Page2()),
////                );
////                MyApp.navigatorState.currentState
////                    .push(MaterialPageRoute(builder: (BuildContext context) {
////                  return Page2(
////                  );
////                }));
//                Navigator.push(context, MaterialPageRoute(builder: (context) {
//                  return Page2();
//                }));
//              },
//            ),
//          ],
//        )
//      ),
//    );
//  }
//}
