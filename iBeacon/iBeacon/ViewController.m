//
//  ViewController.m
//  iBeacon
//
//  Created by myqiqiang on 2017/3/14.
//  Copyright © 2017年 Wythe. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>

@interface ViewController ()<CLLocationManagerDelegate>

@property (strong, nonatomic)   CLLocationManager   *locationManager;
@property (nonatomic)           CLBeaconRegion      *beaconRegion;
//StoryBoard上的label
@property (weak, nonatomic) IBOutlet UILabel        *location;

@property (nonatomic)   CLBeaconRegion  *lastBeaconRegion;

@end

@implementation ViewController

#pragma mark - LifeCycle

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
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"FDA50693-A4E2-4FB1-AFCF-C6EB07647825"]
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

- (void)viewDidAppear:(BOOL)animated {
    NSString *message = [[[NSUserDefaults standardUserDefaults]objectForKey:@"VisitTime"] description];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"app 记录的上次到店时间" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}

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

#pragma mark - Private Methods
/**
 发送通知
 */
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

- (NSString *)nameForProximity:(CLProximity)proximity {
    switch (proximity) {
        case CLProximityUnknown:
            return @"Unknown";
            break;
        case CLProximityImmediate:
            return @"Immediate";
            break;
        case CLProximityNear:
            return @"Near";
            break;
        case CLProximityFar:
            return @"Far";
            break;
    }
}

@end
