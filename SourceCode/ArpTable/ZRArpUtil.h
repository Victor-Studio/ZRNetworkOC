//
//  ZRARPUtil.h
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 20/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZRArpDelegate <NSObject>

- (void)arpTableScanWithResultHostName:(NSString *)hostName iPAddress:(NSString *)ipAddress macAddress:(NSString *)macAddress networkCardManufacturerName:(NSString *)networkCardManufacturerName;

@end

@interface ZRArpUtil : NSObject

@property (nonatomic, weak) id<ZRArpDelegate> arpDelegate;

- (void)startGettingIPAddressList;

- (NSString*)getDefaultGatewayIp;

@end
