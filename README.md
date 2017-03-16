# iBeacon
iBeacon 二三事，介绍是什么和怎么做

公司提到有可能需要类似的功能，就自己调研了一番， 也写了个 Demo，写一点笔记。

## 什么是 iBeacon

iBeacon 是苹果与2013年推出来的一套解决方案，基于蓝牙，需要配合用到蓝牙设备--称之为 Beacon ，价格十几到上百不等，同时需要一个移动 app，主要用来做三件事，室内定位、移动支付和 LBS 推送。

Beacon 设备发射的信号受距离和墙壁的影响，体验大概如同平时的蓝牙音响类似。Beacon 设备本身并不能发送信息或者定位，它只发送信号，移动设备上的 app 收到信号做相关处理。如下图所示。


![iBeacon.jpg](http://upload-images.jianshu.io/upload_images/446839-736d0a1d46585f20.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 优势和劣势

就三个主要使用方向来谈谈 iBeacon 的优势和劣势。

iBeacon 设备比较便宜，低得十几块就可以了，部署简单，这是明显也很重要的优势。部署多个 Beacon 设备，定位精度最高可达分米数量级，可以说是相当惊艳了。并不是没有其他方案达到这种精度，只是在费用和部署难度上，被 iBeacon 远远甩开了。

最初很多人看到它在移动支付上的前景，以为能和 NFC 干一架，也有很多的美国公司支持，只是没想到最后苹果自己的 Apple Pay 还是选择了 NFC。猜测可能是因为安全和市场等方面原因放弃了吧，不过 iBeacon 在这方面也确实没有明显优势。

而在 LBS 推送上，我觉得它是被低估的。很多上家是有这种需求的，当顾客走到店子附近，比如十米的时候，给你发送一些优惠信息，吸引用户到店消费。不过由于技术和推广等各方面原因，现在大都是凭人工在店门口发送优惠券，期待以后进一步的发展。

这一块，微信是有布局的。有很多公交车站有提示你打开微信摇一摇，然后就能收到优惠信息。实际就是在那里有 Beacon 设备，并将 UUID 和跳转网页在微信公众号后台配置好，即可。相信微信在未来会提高这块的权重。

微信摇一摇的接入流程

![BeaconWechat.jpg](http://upload-images.jianshu.io/upload_images/446839-024daccc2c995ac9.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


##以下是开发相关，无关人员请退散

中文互联网内大多数 iBeacon 开发的文章都翻译自 https://www.raywenderlich.com/101891/ibeacons-tutorial-ios-swift 这篇文章，甚至是这篇的早期版本，上面的代码早起是 OC，现在能下到的 Swift2.1，基本上跑起来都有点小问题。我也是参考了这篇，有些小地方不一样，基于 OC。

###创建工程
 首先创建一个 iBeacon 工程，再往界面里面拖一个 UILabel 就 OK 了，接下来的都是基于这个工程。

###请求和监控 GPS 信息
iBeacon 是 GPS 相关的，用的时候也要请求 GPS 授权。

首先导入 **CoreLocation**，
```objc
  #import <CoreLocation/CoreLocation.h>
```
然后在控制器里声明如下属性
```objc
@property (strong, nonatomic)   CLLocationManager *locationManager;
@property (nonatomic)           CLBeaconRegion      *beaconRegion;
//StoryBoard上的label
@property (weak, nonatomic)     IBOutlet UILabel      *location;
```
接着就是监控位置信息
```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    
    [self startMonitoring];
}

- (void)startMonitoring
{
    //uuid、major、minor跟iBeacon的参数对应。
    //这里我就写死了
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:你的设备UUID]
                                                            major:10
                                                            minor:7
                                                       identifier:@"test"];
    //这里可以自己指定接受何种通知
    self.beaconRegion.notifyOnEntry=YES;
    self.beaconRegion.notifyOnExit=YES;
    self.beaconRegion.notifyEntryStateOnDisplay=YES;
    
    [self.locationManager startMonitoringForRegion:_beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:_beaconRegion];
}
```
到这里就可以通过代理方法监控，走进或者走出 Beacon 信号范围了
```objc
#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed: %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager requestStateForRegion:self.beaconRegion];
    NSLog(@"Started monitoring %@ region", region.identifier);
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (state == CLRegionStateInside)
    {
        //Start Ranging
        [manager startRangingBeaconsInRegion:self.beaconRegion];
        
    }
    else
    {
        NSLog(@"Started monitoring %@ region", region.identifier);
        //Stop Ranging here
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    //监控在信号范围内，用户的移动情况，一般可以做个验证
    //是否是自己的信号
    for (CLBeacon *beacon in beacons) {
        
        _location.text = [NSString stringWithFormat:@"%@", [self nameForProximity:beacon.proximity]];
   
    }
}

//iOS设备进入iBeacon范围
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{

    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        //自定义的本地信息推送
        [self postNotificationWithTitle:@"欢迎光临"];

    }
}

//iOS设备离开iBeacon范围
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        //自定义的本地信息推送
        self.lastBeaconRegion = nil;
        
        [self postNotificationWithTitle:@"谢谢惠顾"];
    }
}

//iOS10 的通知
- (void)postNotificationWithTitle:(NSString *)title {
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title == nil?@"发送通知":title;
    
    UNTimeIntervalNotificationTrigger *trigger1 = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    
    NSString *requestIdentifier = [NSString stringWithFormat:@"sampleRequest%u",arc4random()%255];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestIdentifier
                                                                          content:content
                                                                          trigger:trigger1];
    [ [UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"%@",error);
    }];
}
```
另外 iOS10 的通知和以前有些不一样，在 AppDelegate 里需要做如下处理
```objc
UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"request authorization succeeded!");
        }
    }];
    
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSLog(@"%@",settings);
    }];
```

FYI:虽然 Beacon 设备还比较便宜，但是开发调研的时候还是很少会去买设备的，事实上现在主流 iOS 设备都可以用来模拟 Beacon 信号。不过关于如何模拟这块，我还没有研究，目前就用的这个 [app](http://www.cloudnapps.com/wanzhuan-beacon) （或者 AsppStore 搜索 玩转 Beacon），后面有时间的话可能也会写个 app。

FYI2：代码我整理一下，会放到 Github。

FYI3：Android 5.0 也开始支持 iBeacon 了。

谢谢阅读。

___
我是 Wythe，iOS 开发者，对其他技术也有好奇。公众号 WytheTalk，从一个程序员的角度看世界，主要是技术分享，也有对互联网各种事的观点。欢迎关注。


![WytheTalk.jpg](http://upload-images.jianshu.io/upload_images/446839-6e1ec13cf518d34c.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
