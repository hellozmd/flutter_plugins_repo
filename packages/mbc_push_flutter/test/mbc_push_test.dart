import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mbc_push/mbc_push.dart';

void main() {
  const MethodChannel channel = MethodChannel('mbc_push');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  // test('getPlatformVersion', () async {
  //   expect(await MbcPush.platformVersion, '42');
  // });
}
