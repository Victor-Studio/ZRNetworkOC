//
//  ZRArpTableUtil.h
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 04/05/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h> 
 

@class ZRArpTableModel;
@protocol ZRArpTableDelegate <NSObject>

- (void)arpTableScanWithResultModel:(ZRArpTableModel *)arpTableModel;

@end



@interface ZRArpTableUtil : NSObject

@property (nonatomic, weak) id<ZRArpTableDelegate> arpTableDelegate;

+ (NSString *)getHostnameViaIPAddress:(NSString *)ipAddress;

+ (NSString *)getMacAddressViaIPAddr:(NSString *)ipaddress;

- (void)startGettingAllHostsViaIPAddr:(NSString *)ipAddress andSubnet:(NSString *)subnetMask;

@end
