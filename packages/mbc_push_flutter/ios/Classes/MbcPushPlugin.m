#import "MbcPushPlugin.h"
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
#import <objc/runtime.h>

/**
 * 配置参数
 *  Init时传入？
 *  APPID
 *  HOST
 */
@implementation MbcPushPlugin {
    FlutterMethodChannel *_channel;
    NSDictionary *_launchNotification;
    UIUserNotificationType notificationTypes;
    BOOL _resumingFromBackground;
    NSString *ncAppID;
    NSString *ncDomain;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"mbc_push"
                                     binaryMessenger:[registrar messenger]];
    id instance = [[MbcPushPlugin alloc] initWithChannel:channel];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    
    if (self) {
        _channel = channel;
        _resumingFromBackground = NO;
    }
    return self;
}

/**
 * - 设备信息相关
 * initPush
 * getDeviceID
 * getPushServiceName
 * getDeviceToken
 * getChannelList
 *
 * - 订阅相关
 * subscribeAllInOne
 * subscribeNotification
 * getSubscribeNotification
 * getSubscribeTopic
 */
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *method = call.method;
    // [call arguments] || call.arguments
    if ([@"requestNotificationPermissions" isEqualToString:method]) {
        if (@available(iOS 10.0, *)) {
            
            [UNUserNotificationCenter currentNotificationCenter].delegate = self;
            
            notificationTypes = 0;
            NSDictionary *arguments = call.arguments;
            if ([arguments[@"sound"] boolValue]) {
                notificationTypes |= UNAuthorizationOptionSound;
            }
            if ([arguments[@"alert"] boolValue]) {
                notificationTypes |= UNAuthorizationOptionAlert;
            }
            if ([arguments[@"badge"] boolValue]) {
                notificationTypes |= UNAuthorizationOptionBadge;
            }
            
            UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert |
            UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
            [[UNUserNotificationCenter currentNotificationCenter]
             requestAuthorizationWithOptions:authOptions
             completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if(granted){
                    NSLog(@"granted success");
                }else{
                    NSLog(@"granted fail");
                }
            }];
            
        } else {
            notificationTypes = 0;
            NSDictionary *arguments = call.arguments;
            if ([arguments[@"sound"] boolValue]) {
                notificationTypes |= UIUserNotificationTypeSound;
            }
            if ([arguments[@"alert"] boolValue]) {
                notificationTypes |= UIUserNotificationTypeAlert;
            }
            if ([arguments[@"badge"] boolValue]) {
                notificationTypes |= UIUserNotificationTypeBadge;
            }
            UIUserNotificationSettings *settings =
            [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            
        }
        result(nil);
    } else if ([@"configure" isEqualToString:method]) {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        result(nil);
    } else if ([@"configApp" isEqual:method]) {
        ncAppID = call.arguments[@"ncAppID"];
        ncDomain = call.arguments[@"ncDomain"];
        result(@"");
    } else if ([@"isNotificationPermissionGranted" isEqual:method]) {
        if ([self isNotificationPermissionGranted]) {
            result(@"success");
        } else {
            result(@"false");
        }
    } else if([@"initPush" isEqualToString:call.method]) {
        NSLog(@"MBC kit - IOS pushInit");
        ncAppID = call.arguments[@"ncAppID"];
        ncDomain = call.arguments[@"ncDomain"];
        [self updatePushInformation];
        result(@"");
    } else if([@"getDeviceToken" isEqualToString:call.method]) {
        result([self getDeviceToken]);
    } else if([@"getDeviceID" isEqualToString:call.method]) {
        result([self getDeviceID]);
    } else if([@"getPushServiceName" isEqualToString:call.method]) {
        result(@"");
    } else if([@"getChannelList" isEqualToString:call.method]) {
        result(@"");
    } else if([@"subscribeAllInOne" isEqualToString:call.method]) {
        [self subscribeAllInOne:call result:result];
    } else if([@"subscribeNotification" isEqualToString:call.method]) {
        [self subscribeNotification:call result:result];
    } else if([@"getSubscribeTopic" isEqualToString:call.method]) {
        [self getSubscribedTopic:call result:result];
    } else if([@"updateChannel" isEqualToString:call.method]) {
        [self updateChannel:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (NSString *)getDeviceID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (NSString *)getDeviceToken {
    NSLog(@"MBC kit - getDeviceToken:");
    //模拟器
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"simulator can not get deviceToken");
    return @"";
    //真机
#elif TARGET_OS_IPHONE
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey: @"mbc_deviceToken"] != nil) {
        // 如果已经成功获取 registrationID，从本地获取直接缓存
        return [defaults objectForKey: @"mbc_deviceToken"];
    } else {
        NSLog(@"Can not get deviceToken");
        return @"";
    }
#endif
}

- (NSString *)getOldDeviceToken {
    NSLog(@"MBC kit - getOldDeviceToken:");
    //模拟器
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"simulator can not get old deviceToken");
    return @"";
    //真机
#elif TARGET_OS_IPHONE
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey: @"mbc_oldDeviceToken"] != nil) {
        // 如果已经成功获取 registrationID，从本地获取直接缓存
        return [defaults objectForKey: @"mbc_oldDeviceToken"];
    } else {
        NSLog(@"Can not get old deviceToken");
        return @"";
    }
#endif
}

- (void) subscribeAllInOne: (FlutterMethodCall*)call result:(FlutterResult)result {
    if ([ncDomain isEqual:nil] || [ncAppID isEqual:nil]) {
        return;
    }
    NSString *targetUrl = [ncDomain stringByAppendingString:@"/nj_prs_notification/api/subscribe/allInOne"];
    NSDictionary *dict = @{
        @"subscribeList": call.arguments[@"subscribeList"],
        @"unSubscribeList": call.arguments[@"unSubscribeList"],
        @"appID": ncAppID,
        @"deviceUUID": [self getDeviceID],
        @"channel": @"IOS",
        @"deviceToken": [self getDeviceToken],
        @"oldDeviceToken": [self getOldDeviceToken],
        @"notiChannelName": @"IOS",
    };
    [self sendUsingAFNetworkingRequestURL:targetUrl withMethod:@"POST" withParam:dict withResult:result];
}

- (void) subscribeNotification: (FlutterMethodCall*)call result:(FlutterResult)result {
    if ([ncDomain isEqual:nil] || [ncAppID isEqual:nil]) {
        return;
    }
    NSString *targetUrl = [ncDomain stringByAppendingString:@"/nj_prs_notification/api/subscribe/apiAdvance"];
    NSDictionary *dict = @{
        @"appID": ncAppID,
        @"topicString": call.arguments[@"topicString"],
        @"deviceUUID": [self getDeviceID],
        @"channel": @"IOS",
        @"deviceToken": [self getDeviceToken],
        // TODO: get device token
        @"oldDeviceToken": [self getOldDeviceToken],
        @"notiChannelName": @"IOS",
        @"deviceModel": @"IPhone",
        @"action": call.arguments[@"action"]
    };
    [self sendUsingAFNetworkingRequestURL:targetUrl withMethod:@"POST" withParam:dict withResult:result];
}

- (void) getSubscribedTopic: (FlutterMethodCall*)call result:(FlutterResult)result {
    if ([ncDomain isEqual:nil] || [ncAppID isEqual:nil]) {
        return;
    }
    NSString *targetUrl = [ncDomain stringByAppendingString:@"/nj_prs_notification/api/subscribe/subscribedTopic"];
    NSDictionary *dict = @{
        @"appID": ncAppID,
        @"deviceToken": [self getDeviceToken]
    };
    [self sendUsingAFNetworkingRequestURL:targetUrl withMethod:@"POST" withParam:dict withResult:result];
}

- (void) updateChannel: (FlutterResult)result {
    if ([ncDomain isEqual:nil] || [ncAppID isEqual:nil]) {
        return;
    }
    NSString *targetUrl = [ncDomain stringByAppendingString:@"/nj_prs_notification/api/subscribe/updateChannel"];
    NSDictionary *dict = @{
        @"appID": ncAppID,
        @"deviceUUID": [self getDeviceID],
        @"channel": @"IOS",
        @"deviceToken": [self getOldDeviceToken],
        @"permission": [self isNotificationPermissionGranted] ? @"1" : @"0"
    };
    [self sendUsingAFNetworkingRequestURL:targetUrl withMethod:@"POST" withParam:dict withResult:nil];
}

- (NSString *)stringWithDeviceToken:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    return [token copy];
}

- (void)sendUsingAFNetworkingRequestURL:(NSString *)url withMethod:(NSString *)method withParam:(NSDictionary *)params withResult:(FlutterResult)result {
    //    NSURL *URL = [NSURL URLWithString:url];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 60.0;
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSLog(@"%@",url);
    // Start request
    if([method isEqualToString:@"POST"]) {
        [manager POST:(NSString *)url parameters:params headers:nil progress:^(NSProgress * uploadProgress) {
            // Ignore
        } success:^(NSURLSessionDataTask * task, id  responseObject) {
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:nil error:nil];
            NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            // Success callback
            if (result != nil) {
                result(jsonStr);
            }
        } failure:^(NSURLSessionDataTask * task, NSError * error) {
            // Failure callback
            // [error.userInfo objectForKey:@"NSLocalizedDescription"]
            if (result != nil) {
                result([@"\"success\": false" stringByAppendingString:[error.userInfo objectForKey:@"NSLocalizedDescription"]]);
            }
        }];
    } else {
        [manager GET:(NSString *)url parameters:params headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            // Ignore
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:nil error:nil];
            NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            // Success callback
            if(result != nil) {
                result(jsonStr);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            // Failure callback
            if(result != nil) {
                result([@"\"success\": false" stringByAppendingString:[error.userInfo objectForKey:@"NSLocalizedDescription"]]);
            }
        }];
    }
}

- (BOOL)isNotificationPermissionGranted {
    　　//首先判断应用通知是否授权，注意iOS10.0之后方法不一样
    __block BOOL enabled = NO;
    if (@available(iOS 10.0, *)) {
        dispatch_semaphore_t sem;
        sem = dispatch_semaphore_create(0);
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined)
            {
                NSLog(@"未选择");
                enabled = false;
            } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                NSLog(@"未授权");
                enabled = false;
            } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                NSLog(@"已授权");
                enabled = true;
            }
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        return enabled;
    } else {
        if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == 0) {
            return false;
        }
        return true;
    }
}

- (void) updatePushInformation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 获取是否已经保存过上次应用开启时的权限
    bool hasSavedPermission = [defaults boolForKey:@"hasSavedPermission"];
    // 获取上次保存的权限
    bool formerPermission = [defaults boolForKey:@"formerPermission"];
    bool latestPermission = [self isNotificationPermissionGranted];
    // 如果还未存储过通知权限的状态，则保存
    if (!hasSavedPermission) {
        [defaults setBool:latestPermission forKey:@"formerPermission"];
        [defaults setBool:true forKey:@"hasSavedPermission"];
    }
    // 判断和上次启动应用相比，通知权限是否发生了改变
    bool isPermissionChanged = hasSavedPermission && formerPermission != latestPermission;
    if (isPermissionChanged) {
        // 如果通知权限发生改变，则更新此次应用的权限
        [defaults setBool:latestPermission forKey:@"formerPermission"];
        if ([ncDomain isEqual:nil] || [ncAppID isEqual:nil]) {
            return;
        }
        NSString *targetUrl = [ncDomain stringByAppendingString:@"/nj_prs_notification/api/subscribe/updateChannel"];
        NSDictionary *dict = @{
            @"appID": ncAppID,
            @"deviceUUID": [self getDeviceID],
            @"channel": @"IOS",
            @"deviceToken": [self getOldDeviceToken],
            @"permission": latestPermission ? @"1" : @"0"
        };
        [self sendUsingAFNetworkingRequestURL:targetUrl withMethod:@"POST" withParam:dict withResult:nil];
    }
}

#pragma mark - AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (launchOptions != nil) {
        _launchNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    }
    // 注册通知权限
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0){
        // IOS 10.0xi t
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[UIApplication sharedApplication] registerForRemoteNotifications];
                            });
                        }
                    }];
                }
            }];
        }
    } else if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0){
        if (@available(iOS 8.0, *)) {
            if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
                UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            } else {
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
            }
        }
    }
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _resumingFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    _resumingFromBackground = NO;
    // Clears push notifications from the notification center, with the
    // side effect of resetting the badge count. We need to clear notifications
    // because otherwise the user could tap notifications in the notification
    // center while the app is in the foreground, and we wouldn't be able to
    // distinguish that case from the case where a message came in and the
    // user dismissed the notification center without tapping anything.
    // TODO(goderbauer): Revisit this behavior once we provide an API for managing
    // the badge number, or if we add support for running Dart in the background.
    // Setting badgeNumber to 0 is a no-op (= notifications will not be cleared)
    // if it is already 0,
    // therefore the next line is setting it to 1 first before clearing it again
    // to remove all
    // notifications.
    application.applicationIconBadgeNumber = 1;
    application.applicationIconBadgeNumber = 0;
}

- (bool)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    // [self didReceiveRemoteNotification:userInfo];
    [_channel invokeMethod:@"onReceiveNotification" arguments:userInfo];
    completionHandler(UIBackgroundFetchResultNoData);
    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // 获得解析后的deviceToken
    NSString * token = [self stringWithDeviceToken:deviceToken];
    // 获得UserDefault实例
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 从UICKeyChainStore中获取keychain实例
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService: [[NSBundle mainBundle] bundleIdentifier]];
    keychain.accessibility = UICKeyChainStoreAccessibilityAfterFirstUnlock;
    // 将旧的token存入user default当中
    [defaults setObject:keychain[@"mbc_deviceToken"] forKey:@"mbc_oldDeviceToken"];
    // 将新的token放入userDefault以及keychain当中
    [defaults setObject:token forKey:@"mbc_deviceToken"];
    keychain[@"mbc_deviceToken"] = token;
    [defaults synchronize];
    [_channel invokeMethod:@"onReceiveDeviceToken" arguments:token];
}

// ios 10+ notification API
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)){
    NSDictionary * userInfo = notification.request.content.userInfo;
    [_channel invokeMethod:@"onReceiveNotification" arguments:userInfo];
    //  completionHandler(notificationTypes);
    completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert);
}

// ios 10+ notification API
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler API_AVAILABLE(ios(10.0)){
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    [_channel invokeMethod:@"onOpenNotification" arguments:userInfo];
    completionHandler();
}

- (void)application:(UIApplication *)application
didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    NSDictionary *settingsDictionary = @{
        @"sound" : [NSNumber numberWithBool:notificationSettings.types & UIUserNotificationTypeSound],
        @"badge" : [NSNumber numberWithBool:notificationSettings.types & UIUserNotificationTypeBadge],
        @"alert" : [NSNumber numberWithBool:notificationSettings.types & UIUserNotificationTypeAlert],
    };
    [_channel invokeMethod:@"onIosSettingsRegistered" arguments:settingsDictionary];
}
@end
