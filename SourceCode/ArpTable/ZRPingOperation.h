//
//  ZRIPAddrOperation.h
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 04/05/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZRPingOperation : NSOperation
{
    BOOL _isFinished;
    BOOL _isExecuting;
}

- (nullable instancetype)initWithIPToPing:(nonnull NSString*)ip andCompletionHandler:(nullable void (^)(NSError  * _Nullable error, NSString  * _Nonnull ip))result;
@end
