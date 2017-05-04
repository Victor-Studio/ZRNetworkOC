//
//  ZRMacAddrOperation.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 04/05/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRMacAddrOperation.h"
#import "ZRArpTableUtil.h"
#import "ZRArpTableModel.h"

@interface ZRMacAddrOperation()

@property (nonatomic, strong) NSDictionary *networkCardDict;

@property (nonatomic, copy) NSString *ipaddr;

@property (nonatomic, copy) CompletionHandler completionHandler;

@property (nonatomic, strong) ZRArpTableModel *arpTableModel;

@property (nonatomic, strong) NSError *errorMessage;

@end

@implementation ZRMacAddrOperation

- (instancetype)initWithIpAddr:(NSString *)ipAddr networkCardDict:(NSDictionary *)networkCardDict completion:(CompletionHandler)completionHandler {
    if (self = [super init]) {
        self.name = self.ipaddr;
        _networkCardDict = networkCardDict;
        _ipaddr = ipAddr;
        _completionHandler = completionHandler;
        _arpTableModel = [[ZRArpTableModel alloc] init];
        
        _isExecuting = NO;
        _isFinished = NO;
    }
    return self;
}

-(void)start {
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self getMACDetails];
}

- (void)finishMAC {
    
    if (self.isCancelled) {
        [self finish];
        return;
    }
    
    if (self.completionHandler) {
        self.completionHandler(_errorMessage, self.arpTableModel);
    }
    
    [self finish];
}

- (void)finish {
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
}

- (BOOL)isExecuting {
    return _isExecuting;
}

- (BOOL)isFinished {
    return _isFinished;
}

- (void)getMACDetails {
    
    self.arpTableModel.ipAddress = self.ipaddr;
    self.arpTableModel.hostname = [ZRArpTableUtil getHostnameViaIPAddress:self.ipaddr];
    self.arpTableModel.macAddress = [ZRArpTableUtil getMacAddressViaIPAddr:self.ipaddr];
    
    if (!self.arpTableModel.macAddress.length) {
        _errorMessage = [NSError errorWithDomain:@"MAC Address Not Exist" code:10 userInfo:nil];
    } else {
        NSString *networkCard = [self.arpTableModel.macAddress substringWithRange:NSMakeRange(0, 8)];
        networkCard = [[networkCard stringByReplacingOccurrencesOfString:@":" withString:@""] uppercaseString];
        self.arpTableModel.networkCardManufacturer = [self.networkCardDict valueForKey:networkCard];
    }
    
    [self finishMAC];
}

@end
