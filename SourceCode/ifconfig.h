//
//  VLIPAddress.h
//  Longan
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ifconfig : NSObject

/*
 * 获取当前设备的网卡信息
 * 相当于在电脑终端输入ifconfig输出的数据，包含网卡名称，IP地址, MAC地址
 **/
+ (NSArray *)ifconfig;

@end
