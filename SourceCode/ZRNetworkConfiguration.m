//
//  ZRNetworkConfiguration.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRNetworkConfiguration.h"
#import <UIKit/UIKit.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#include <ifaddrs.h>
#include <arpa/inet.h>


@implementation ZRNetworkInfoSSIDInterface

@end

@implementation ZRNetworkInfoIPAddress

@end

@implementation ZRCarrierInfo

@end

@implementation ZRNetworkWiFiSignalInfo

@end

@implementation ZRNetworkSignalInfo

@end



@implementation ZRNetworkConfiguration

+ (BOOL)isConnectedWiFi {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    if (!ifs || ifs.count == 0) {
        return NO;
    }
    
    for (NSString *ifnam in ifs) {
        id info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSString *wifilabName = [info objectForKey:@"SSID"];
        if(wifilabName){
            return YES;
        }
    }
    return NO;
}


+ (ZRNetworkInfoSSIDInterface *)fetchSSIDInfo {
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    
    if (!interfaceNames && interfaceNames.count <= 0) {
        return nil;
    }
    
    ZRNetworkInfoSSIDInterface *infoSSID = [[ZRNetworkInfoSSIDInterface alloc] init];
    for (NSString *interfaceName in interfaceNames) {
        NSDictionary *dict = CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        NSString *SSID = dict[CFBridgingRelease(kCNNetworkInfoKeySSID)];
        NSString *BSSID = dict[CFBridgingRelease(kCNNetworkInfoKeyBSSID)];
        NSData *SSIDDATA = dict[CFBridgingRelease(kCNNetworkInfoKeySSIDData)];
        
        infoSSID.SSID = SSID;
        infoSSID.BSSID = BSSID;
        infoSSID.SSIDDATA = SSIDDATA;
    }
    return infoSSID;
}

+ (ZRNetworkInfoIPAddress *)getCurrentIPAddress {
    ZRNetworkInfoIPAddress *networkInfo = [[ZRNetworkInfoIPAddress alloc] init];
    struct ifaddrs *interfaces = NULL;
    
    // retrieve the current interfaces - returns 0 on success
    if (getifaddrs(&interfaces) == 0) {
        // Loop through linked list of interfaces
        while(interfaces != NULL) {
            
            if(interfaces->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:interfaces->ifa_name] isEqualToString:@"en0"]) {
                    
                    // Get NSString from C String
                    NSString *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)interfaces->ifa_addr)->sin_addr)];
                    networkInfo.IPAddress = address;
                    
                    //broadcast address , also known as router IP
                    NSString * broadcastAddress = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)interfaces->ifa_dstaddr)->sin_addr)];
                    networkInfo.broadcastAddress = broadcastAddress;
                    
                    //--255.255.255.0 wifi subnet mast
                    NSString *wifiSubnetMast = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)interfaces->ifa_netmask)->sin_addr)];
                    networkInfo.subnetMast = wifiSubnetMast;
                    
                    //--en0 port name
                    NSString *wifiInterface = [NSString stringWithUTF8String:interfaces->ifa_name];
                    networkInfo.interfaceName = wifiInterface;
                }
            }
            interfaces = interfaces->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return networkInfo;
}

+ (ZRNetworkWiFiSignalInfo *)getWiFiSignalStrength {
    
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
    if (!subviews) {
        return nil;
    }
    
    NSString *signalNetworkItemView = nil;
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarSignalStrengthItemView") class]]) {
            signalNetworkItemView = subview;
        }
    }
    
    ZRNetworkWiFiSignalInfo *wifiSignal = [[ZRNetworkWiFiSignalInfo alloc] init];
    wifiSignal.signalStrengthBars = [[signalNetworkItemView valueForKey:@"signalStrengthBars"] intValue];
    wifiSignal.signalStrength = [[signalNetworkItemView valueForKey:@"signalStrengthRaw"] intValue];
    return wifiSignal;
}

+ (ZRNetworkSignalInfo *)getNetworkSignal {
    
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
    if (!subviews) {
        return nil;
    }
    
    NSString *dataNetworkItemView = nil;
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
        }
    }
    
    ZRNetworkSignalInfo *networkSignal = [[ZRNetworkSignalInfo alloc] init];
    networkSignal.strengthRaw = [[dataNetworkItemView valueForKey:@"wifiStrengthRaw"] intValue];
    networkSignal.wifiStrengthBars = [[dataNetworkItemView valueForKey:@"wifiStrengthBars"] intValue];
    networkSignal.networkSignalType = [[dataNetworkItemView valueForKey:@"dataNetworkType"] intValue];
    return networkSignal;
}

+ (ZRCarrierInfo *)getCarrierInfo {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    if (!carrier) {
        return nil;
    }
    
    ZRCarrierInfo *model = [[ZRCarrierInfo alloc] init];
    model.carrierName = carrier.carrierName;
    model.mobileCountryCode = carrier.mobileCountryCode;
    model.mobileNetworkCode = carrier.mobileNetworkCode;
    model.isoCountryCode = carrier.isoCountryCode;
    model.allowsVOIP = carrier.allowsVOIP;
    return model;
}

- (void)getIPAttributionWithCompletion:(void(^ _Nullable)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    
    NSMutableURLRequest *requestHTTP = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://ip-api.com/json"]
                                                               cachePolicy:NSURLRequestReloadIgnoringCacheData  timeoutInterval:10];
    [requestHTTP setHTTPMethod:@"GET"];
    [requestHTTP setValue: @"text/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:requestHTTP completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (completion) {
            completion(dict, error);
        }
        
    }];
    [task resume];
}


@end
