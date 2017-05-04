//
//  ZRArpTableModel.h
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 04/05/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZRArpTableModel : NSObject

@property (nonatomic,strong) NSString *hostname;
@property (nonatomic,strong) NSString *ipAddress;
@property (nonatomic,strong) NSString *macAddress;
@property (nonatomic,strong) NSString *networkCardManufacturer;

@end
