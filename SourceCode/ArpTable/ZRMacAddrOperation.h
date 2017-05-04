//
//  ZRMacAddrOperation.h
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 04/05/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZRArpTableModel;

typedef void (^CompletionHandler)(NSError  * _Nullable error, ZRArpTableModel * _Nonnull arpTable);

@interface ZRMacAddrOperation : NSOperation
{
    BOOL _isFinished;
    BOOL _isExecuting;
}

- (instancetype _Nonnull )initWithIpAddr:(NSString * _Nonnull)ipAddr networkCardDict:(NSDictionary * _Nonnull)networkCardDict completion:(CompletionHandler _Nonnull )completionHandler;

@end
