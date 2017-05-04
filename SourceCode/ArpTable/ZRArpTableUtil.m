//
//  ZRArpTableUtil.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 04/05/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRArpTableUtil.h"
#import "ZRArpTableModel.h"
#import "ZRMacAddrOperation.h"
#import "ZRPingOperation.h"

#if TARGET_IPHONE_SIMULATOR
#include <net/route.h>
#else
#include "route.h"
#endif

#include "if_ether.h"
#include <arpa/inet.h>
#include <netdb.h>

#define BUFLEN (sizeof(struct rt_msghdr) + 512)
#define SEQ 9999
#define RTM_VERSION	5	// important, version 2 does not return a mac address!
#define RTM_GET	0x4	// Report Metrics
#define RTF_LLINFO	0x400	// generated by link layer (e.g. ARP)
#define RTF_IFSCOPE 0x1000000 // has valid interface scope
#define RTA_DST	0x1	// destination sockaddr present


@interface ZRArpTableUtil()
{
    BOOL isFinished;
    BOOL isCancelled;
}

@property (nonatomic,strong) NSDictionary *networkCardDict;
@property (nonatomic,strong) NSOperationQueue *queue;
@property (nonatomic,assign,readwrite)BOOL isScanning;

@end

@implementation ZRArpTableUtil

+ (NSString *)getHostnameViaIPAddress:(NSString*)ipAddress {
    struct addrinfo *result = NULL;
    struct addrinfo hints;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags = AI_NUMERICHOST;
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
    
    int errorStatus = getaddrinfo([ipAddress cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
    if (errorStatus != 0) {
        return nil;
    }
    
    CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
    if (addressRef == nil) {
        return nil;
    }
    freeaddrinfo(result);
    
    CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
    if (hostRef == nil) {
        return nil;
    }
    CFRelease(addressRef);
    
    BOOL succeeded = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
    if (!succeeded) {
        return nil;
    }
    
    NSMutableArray *hostnames = [NSMutableArray array];
    
    CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
    for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
        [hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
    }
    
    return hostnames[0];
}

+ (NSString*)getMacAddressViaIPAddr:(NSString*)ipaddress {
    
    const char *ip = [ipaddress UTF8String];
    
    int sockfd;
    unsigned char buf[BUFLEN];
    unsigned char buf2[BUFLEN];
    ssize_t n;
    struct rt_msghdr *rtm;
    struct sockaddr_in *sin;
    memset(buf,0,sizeof(buf));
    memset(buf2,0,sizeof(buf2));
    
    sockfd = socket(AF_ROUTE, SOCK_RAW, 0);
    rtm = (struct rt_msghdr *) buf;
    rtm->rtm_msglen = sizeof(struct rt_msghdr) + sizeof(struct sockaddr_in);
    rtm->rtm_version = RTM_VERSION;
    rtm->rtm_type = RTM_GET;
    rtm->rtm_addrs = RTA_DST;
    rtm->rtm_flags = RTF_LLINFO;
    rtm->rtm_pid = 1234;
    rtm->rtm_seq = SEQ;
    
    
    sin = (struct sockaddr_in *) (rtm + 1);
    sin->sin_len = sizeof(struct sockaddr_in);
    sin->sin_family = AF_INET;
    sin->sin_addr.s_addr = inet_addr(ip);
    write(sockfd, rtm, rtm->rtm_msglen);
    
    n = read(sockfd, buf2, BUFLEN);
    close(sockfd);
    
    if (n != 0) {
        int index =  sizeof(struct rt_msghdr) + sizeof(struct sockaddr_inarp) + 8;
        // savedata("test",buf2,n);
        NSString *macAddress =[NSString stringWithFormat:@"%2.2x:%2.2x:%2.2x:%2.2x:%2.2x:%2.2x",buf2[index+0], buf2[index+1], buf2[index+2], buf2[index+3], buf2[index+4], buf2[index+5]];
        //If macAddress is equal to 00:00.. then mac address not exist in ARP table and returns nil. If it retuns 08:00.. then the mac address not exist because it's not in the same subnet with the device and return nil
        if ([macAddress isEqualToString:@"00:00:00:00:00:00"] || [macAddress isEqualToString:@"08:00:00:00:00:00"] ) {
            return nil;
        }
        return macAddress;
    }
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        //Initializing the dictionary that holds the Network Cards Brand name for each MAC Address
        NSData *JSONData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NetworkCardsDatabase" ofType:@"json"]];
        self.networkCardDict = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:nil];
        
        //Initializing the NSOperationQueue
        self.queue = [[NSOperationQueue alloc] init];
        //Setting the concurrent operations to 50
        [self.queue setMaxConcurrentOperationCount:50];
        
        //Add observer to notify the delegate when queue is empty.
        [self.queue addObserver:self forKeyPath:@"operations" options:0 context:nil];
        
        isFinished = NO;
        isCancelled = NO;
        self.isScanning = NO;
    }
    return self;
}

//Getting all the hosts and returns them as array
- (void)startGettingAllHostsViaIPAddr:(NSString*)ipAddress andSubnet:(NSString*)subnetMask {
    
    //In case of the developer call it repeatedly or it's already running
    if (self.queue.operationCount!=0) {
        [self stop];
    }
    
    //Check if valid IP
    if (![[self class] isValidIPAddress:ipAddress] || ![[self class] isValidIPAddress:subnetMask]) {
        
        return;
    }
    
    //Converting IP and Subnet to Binary
    NSArray *ipArray = [[self class] ipToBinary:ipAddress];
    NSArray *subnetArray = [[self class] ipToBinary:subnetMask];
    
    //Getting the first and last IP as array binary
    NSArray *firstIPArray = [[self class] firstIPToPingForIPAddress:ipArray subnetMask:subnetArray];
    NSArray *lastIPArray = [[self class] lastIPToPingForIPAddress:ipArray subnetMask:subnetArray];
    
    //Looping through all possible IPs and extracting them as NSString in NSArray
    NSMutableArray *ipArr = [[NSMutableArray alloc]init];
    
    NSArray *currentIP = [NSArray arrayWithArray:firstIPArray];
    
    while (![[self class] isEqualBinary:currentIP :lastIPArray]) {
        
        [ipArr addObject:[[self class] binaryToIP:currentIP]];
        currentIP = [NSArray arrayWithArray:[[self class] increaseBitArray:currentIP]];
    }
    //Adding the last one
    [ipArr addObject:[[self class] binaryToIP:currentIP]];
    
    
    
    //Construct final array data
    for (NSString *ipaddr in ipArr) {
        
        ZRPingOperation *pingOperation = [[ZRPingOperation alloc] initWithIPToPing:ipaddr andCompletionHandler:^(NSError * _Nullable error, NSString * _Nonnull ip) {
            
        }];
        
        ZRMacAddrOperation *macOperation = [[ZRMacAddrOperation alloc] initWithIpAddr:ipaddr networkCardDict:self.networkCardDict completion:^(NSError * _Nullable error, ZRArpTableModel * _Nonnull arpTable) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.arpTableDelegate respondsToSelector:@selector(arpTableScanWithResultModel:)]) {
                    [self.arpTableDelegate arpTableScanWithResultModel:arpTable];
                }
            });
            
        }];
        
        //Adding dependancy on macOperation. For each IP there 2 operations (macOperation and pingOperation). The dependancy makes sure that macOperation will run after pingOperation
        [macOperation addDependency:pingOperation];
        
        //Adding the operations in the queue
        [self.queue addOperation:pingOperation];
        [self.queue addOperation:macOperation];
    }
    
}

- (void)stop {
    
    isCancelled = YES;
    [self.queue cancelAllOperations];
    [self.queue waitUntilAllOperationsAreFinished];
    self.isScanning = NO;
}



#pragma mark - NSOperationQueue Observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    //Observing the NSOperationQueue and as soon as it finished we send a message to delegate
    if ([keyPath isEqualToString:@"operations"]) {
        
        if (self.queue.operationCount == 0 && isFinished == NO) {
            
            isFinished=YES;
            self.isScanning = NO; 
         
            [self stop];
        }
    }
}


- (void)dealloc {
    //Removing the observer on dealloc
    [self.queue removeObserver:self forKeyPath:@"operations"];
}


#pragma mark - Helper Methods for Net Calc
+ (NSArray*)firstIPToPingForIPAddress:(NSArray*)ipArray subnetMask:(NSArray*)subnetArray{
    
    NSMutableArray *firstIPArray = [[NSMutableArray alloc]init];
    
    //Performing bitwise AND on the IP and the Subnet to find the Network IP
    for (int i=0; i < [ipArray count]-1; i++) {
        
        [firstIPArray addObject:[NSNumber numberWithInt:[ipArray[i] intValue] & [subnetArray[i] intValue]]];
    }
    
    //Adding the last digit to 1 in order to get the first
    //The first IP
    [firstIPArray addObject:[NSNumber numberWithInt:1]];
    
    //return [self binaryToIP:firstIPArray];
    
    return firstIPArray;
}

+ (NSArray*)lastIPToPingForIPAddress:(NSArray*)ipArray subnetMask:(NSArray*)subnetArray{
    
    NSMutableArray *lastIPArray = [[NSMutableArray alloc]init];
    
    //Reversing the subnet to wild card
    NSArray *wildCard = [self subnetToWildCard:subnetArray];
    
    //Performing bit wise OR on Wild card and IP to get the last host
    for (int i=0; i < [ipArray count]-1; i++) {
        
        [lastIPArray addObject:[NSNumber numberWithInt:[ipArray[i] intValue] | [wildCard[i] intValue]]];
    }
    
    //The Last IP
    [lastIPArray addObject:[NSNumber numberWithInt:0]];
    
    return lastIPArray;
}

//Increasing by one the IP on binary representation and returns the IP on string
+ (NSString*)increaseBit:(NSArray*)ipArray {
    
    NSMutableArray *ipArr = [[NSMutableArray alloc]initWithArray:ipArray];
    
    int ipCount = (int)[ipArr count];
    
    for (int i= ipCount-1; i > 0; i--) {
        
        if ([ipArr[i] intValue]==0) {
            
            ipArr[i]=[NSNumber numberWithInt:1];
            break;
        }
        else {
            
            ipArr[i]=[NSNumber numberWithInt:0];
            if (ipArray[i-1]==0) {
                ipArr[i-1]=[NSNumber numberWithInt:1];
                break;
            }
        }
    }
    
    return [self binaryToIP:ipArr];
}

//Increasing by one the IP on binary representation and returns the IP on NSArray (Binarry)
+ (NSArray*)increaseBitArray:(NSArray*)ipArray {
    
    NSMutableArray *ipArr = [[NSMutableArray alloc]initWithArray:ipArray];
    
    int ipCount = (int)[ipArr count];
    
    for (int i= ipCount-1; i > 0; i--) {
        
        if ([ipArr[i] intValue]==0) {
            
            ipArr[i]=[NSNumber numberWithInt:1];
            break;
        }
        else {
            
            ipArr[i]=[NSNumber numberWithInt:0];
            if (ipArray[i-1]==0) {
                ipArr[i-1]=[NSNumber numberWithInt:1];
                break;
            }
        }
    }
    
    return ipArr;
}
//Checks if IP is valid
+ (BOOL)isValidIPAddress:(NSString*)ipAddress {
    
    NSArray *ipArray = [ipAddress componentsSeparatedByString:@"."];
    
    if ([ipArray count] != 4) {
        
        return NO;
    }
    
    for (NSString *sub in ipArray) {
        
        int part = [sub intValue];
        
        if (part<0 || part>255) {
            return NO;
        }
    }
    
    return YES;
}

//This function convert decimals to binary
+ (NSString *)print01:(int)int11{
    
    int n =128;
    char array12[8];
    NSString *str;
    
    if(int11==0)
        return str= [NSString stringWithFormat:@"00000000"];
    
    for(int j=0;j<8;j++) {
        if ((int11-n)>=0){
            array12[j]='1';
            int11-=n;
            
        }
        else
            array12[j]='0';
        
        n=n/2;
    }
    
    str= [[NSString stringWithFormat:@"%s",array12] substringWithRange:NSMakeRange(0,8)];
    
    return str;
};

//Converts an IP NSString to binary
+ (NSArray*)ipToBinary:(NSString*)ipAddress {
    
    NSArray *ipArray = [ipAddress componentsSeparatedByString:@"."];
    
    //Convert the string to the 4(integer) numbers of IP
    int int1 = [ipArray[0] intValue];
    int int2 = [ipArray[1] intValue];
    int int3 = [ipArray[2] intValue];
    int int4 = [ipArray[3] intValue];
    
    NSString *t1,*t2,*t3,*t4;
    
    t1= [self print01:int1];
    t2= [self print01:int2];
    t3= [self print01:int3];
    t4= [self print01:int4];
    
    NSMutableArray *ipBinary = [[NSMutableArray alloc]initWithCapacity:32];
    
    for(int i=0;i<=7;i++) {
        
        [ipBinary addObject:[NSNumber numberWithInt:[t1 characterAtIndex:i]- '0']];
    }
    
    for(int i=0;i<=7;i++) {
        
        [ipBinary addObject:[NSNumber numberWithInt:[t2 characterAtIndex:i]- '0']];
    }
    
    for(int i=0;i<=7;i++) {
        
        [ipBinary addObject:[NSNumber numberWithInt:[t3 characterAtIndex:i]- '0']];
    }
    
    for(int i=0;i<=7;i++) {
        
        [ipBinary addObject:[NSNumber numberWithInt:[t4 characterAtIndex:i]- '0']];
    }
    
    return ipBinary;
    
}

//Converts binary IP to NSString
+ (NSString*)binaryToIP:(NSArray*)binaryArray {
    
    int bits=128;
    
    int t1=0,t2=0,t3=0,t4=0;
    
    for(int i=0;i<=7;i++){
        
        if ([binaryArray[i] intValue]==1)
            t1+=bits;
        if ([binaryArray[i+8] intValue]==1)
            t2+=bits;
        if ([binaryArray[i+16] intValue]==1)
            t3+=bits;
        if ([binaryArray[i+24] intValue]==1)
            t4+=bits;
        
        bits=bits/2;
    }
    
    return [NSString stringWithFormat:@"%d.%d.%d.%d",t1,t2,t3,t4];
    
}

//Check if the binary IP is equal with another binary IP
+ (BOOL)isEqualBinary:(NSArray*)binArray1 :(NSArray*)binArray2{
    
    for (int i=0; i < [binArray1 count]; i++) {
        
        if ([binArray1[i] intValue]!= [binArray2[i] intValue]) {
            
            return NO;
        }
    }
    
    return YES;
}

//Converts Subnet to Wild Card
+ (NSArray*)subnetToWildCard:(NSArray*)subnetArray {
    
    NSMutableArray *subArray = [NSMutableArray arrayWithArray:subnetArray];
    
    for(int i=0; i < [subArray count]; i++) {
        
        int intNum = [[subArray objectAtIndex:i] intValue];
        
        if (intNum==0) {
            
            [subArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:1]];
        }
        else {
            
            [subArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
        }
    }
    
    return subArray;
}

@end
