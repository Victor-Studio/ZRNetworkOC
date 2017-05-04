//
//  ZRNetworkConfiguration.h
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZRNetworkInfoSSIDInterface : NSObject

@property (nonatomic, copy) NSString *SSID;
@property (nonatomic, copy) NSString *BSSID;
@property (nonatomic, strong) NSData *SSIDDATA;

@end


@interface ZRNetworkInfoIPAddress : NSObject

@property (nonatomic, copy) NSString *interfaceName;
@property (nonatomic, copy) NSString *IPAddress;
@property (nonatomic, copy) NSString *broadcastAddress;
@property (nonatomic, copy) NSString *subnetMast;

@end


@interface ZRCarrierInfo : NSObject

@property (nonatomic, copy) NSString *carrierName;
@property (nonatomic, copy) NSString *mobileCountryCode;
@property (nonatomic, copy) NSString *mobileNetworkCode;
@property (nonatomic, copy) NSString* isoCountryCode;
@property (nonatomic, assign) BOOL allowsVOIP;

@end


/*
 * https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/UIStatusBarSignalStrengthItemView.h*
 */
@interface ZRNetworkWiFiSignalInfo : NSObject

/*
 * 指的是信号强度，单位: dBm
 */
@property (nonatomic, assign) int signalStrength;

/*
 * 信号强度，表示当前显示几格，范围0-5
 */
@property (nonatomic, assign) int signalStrengthBars;

@end


/*
 * https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/UIStatusBarDataNetworkItemView.h
 */
typedef NS_ENUM(NSInteger, ZRNetworkSignalType) {
    ZRNetworkSignalNone             = 0,  //获取失败
    ZRNetworkSignal2G               = 1,  //2G网络
    ZRNetworkSignal3G               = 2,  //3G网络
    ZRNetworkSignal4G               = 3,  //4G网络
    ZRNetworkSignalLTE              = 4,  //LTE网络
    ZRNetworkSignalWiFi             = 5,  //WiFi网络
};

@interface ZRNetworkSignalInfo : NSObject

@property (nonatomic, assign) ZRNetworkSignalType networkSignalType;

/*
 * 信号强度，表示当前显示几格，范围0-5
 */
@property (nonatomic, assign) int strengthRaw;

/*
 * 信号强度，表示当前显示几格，范围: 0-3
 */
@property (nonatomic, assign) int wifiStrengthBars;

@end







@interface ZRNetworkConfiguration : NSObject

/*
 * 是否连接上WiFi
 **/
+ (BOOL)isConnectedWiFi;

/*
 * 获取SSID信息
 * @返回 ZRNetworkInfoSSIDInterface 模型包含相关信息
 **/
+ (ZRNetworkInfoSSIDInterface *)fetchSSIDInfo;

/*
 * 获取当前已连接的WiFi信息
 * @返回 ZRNetworkInfoIPAddress 模型包含相关信息
 **/
+ (ZRNetworkInfoIPAddress *)getCurrentIPAddress;

/*
 * 获取通信信号强度，不是WiFi信息强度
 * 此方法只能在UIStatusBar显示的情况下，可以正常使用
 * @返回 ZRNetworkWiFiSignalInfo 模型包含相关信息
 **/
+ (ZRNetworkWiFiSignalInfo *)getWiFiSignalStrength;

/*
 * 获取信号类型和强度
 * 此方法只能在UIStatusBar显示的情况下，可以正常使用
 * @返回 ZRNetworkSignalInfo 模型包含相关信息
 **/
+ (ZRNetworkSignalInfo *)getNetworkSignal;

/*
 * 获取移动蜂窝信息
 * @返回 ZRCarrierInfo 模型包含相关信息
 **/
+ (ZRCarrierInfo *)getCarrierInfo;

/*
 * 获取IP归属地，及经纬度相关信息
 **/
- (void)getIPAttributionWithCompletion:(void(^ _Nullable)(NSDictionary * _Nullable, NSError * _Nullable))completion;

@end
