//
//  ZRARPUtil.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 20/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRArpUtil.h"

#if TARGET_IPHONE_SIMULATOR
#include <net/route.h>
#else
#include "route.h"
#endif

#import "if_types.h"
#import "if_ether.h"

#import <arpa/inet.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <ifaddrs.h>
#import <net/if_dl.h>
#import <net/if.h>
#import <netinet/in.h>
#include <netdb.h>

#define ROUNDUP(a) ((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))


@interface ZRArpUtil()

@end

@implementation ZRArpUtil

- (void)startGettingIPAddressList
{
    NSString* macAddress = nil;
    NSString *ipAddress = nil;
    NSString *hostName = nil;
    NSString *manufacturerName = nil;
    
    size_t needed;
    char *buf, *next;
    
    struct rt_msghdr *rtm;
    struct sockaddr_inarp *sin;
    struct sockaddr_dl *sdl;
    
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_LLINFO};
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0)
    {
        NSLog(@"error in route-sysctl-estimate");
        return;
    }
    
    if ((buf = (char*)malloc(needed)) == NULL)
    {
        NSLog(@"error in malloc");
        return;
    }
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0)
    {
        NSLog(@"retrieval of routing table");
        return;
    }
    
    //Network Card Manufacturer dictionary
    NSDictionary *networkCardDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"plist"]];
    
    NSString *lastMacAddr = nil;
    for (next = buf; next < buf + needed; next += rtm->rtm_msglen)
    {
        rtm = (struct rt_msghdr *)next;
        sin = (struct sockaddr_inarp *)(rtm + 1);
        sdl = (struct sockaddr_dl *)(sin + 1);
#ifdef DEBUG
//        [self logSockaddrInarp:*sin];
#endif
        
//        if (addr != sin->sin_addr.s_addr || sdl->sdl_alen < 6)
//            continue;
        
        u_char *cp = (u_char*)LLADDR(sdl);
        
        macAddress = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
               cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
        
        ipAddress =  [NSString stringWithUTF8String:inet_ntoa(sin->sin_addr)];
        
        hostName = [self getHostnameByIPAddress:ipAddress];
        
        manufacturerName = [networkCardDict objectForKey:[[macAddress substringWithRange:NSMakeRange(0, 8)] stringByReplacingOccurrencesOfString:@":" withString:@"-"]];
        
        if([macAddress isEqualToString:lastMacAddr]) {
            lastMacAddr = macAddress;
            continue;
        }
        if (!lastMacAddr.length) {
            lastMacAddr = macAddress;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.arpDelegate respondsToSelector:@selector(arpTableScanWithResultHostName:iPAddress:macAddress:networkCardManufacturerName:)]) {
                [self.arpDelegate arpTableScanWithResultHostName:hostName iPAddress:ipAddress macAddress:macAddress networkCardManufacturerName:manufacturerName];
            }
        });
        
//        break;
    }
    
    free(buf);

}

- (NSString*)getDefaultGatewayIp
{
    NSString* res = nil;
    
    size_t needed;
    char *buf, *next;
    
    struct rt_msghdr *rtm;
    struct sockaddr * sa;
    struct sockaddr * sa_tab[RTAX_MAX];
    int i = 0;
    
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_GATEWAY};
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0)
    {
        NSLog(@"error in route-sysctl-estimate");
        return nil;
    }
    
    if ((buf = (char*)malloc(needed)) == NULL)
    {
        NSLog(@"error in malloc");
        return nil;
    }
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0)
    {
        NSLog(@"retrieval of routing table");
        return nil;
    }
    
    for (next = buf; next < buf + needed; next += rtm->rtm_msglen)
    {
        rtm = (struct rt_msghdr *)next;
        sa = (struct sockaddr *)(rtm + 1);
        for(i = 0; i < RTAX_MAX; i++)
        {
            if(rtm->rtm_addrs & (1 << i))
            {
                sa_tab[i] = sa;
                sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
            }
            else
            {
                sa_tab[i] = NULL;
            }
        }
        
        if(((rtm->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
           && sa_tab[RTAX_DST]->sa_family == AF_INET
           && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET)
        {
            if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0)
            {
                char ifName[128];
                if_indextoname(rtm->rtm_index,ifName);
                
                if(strcmp("en0",ifName) == 0)
                {
                    struct in_addr temp;
                    temp.s_addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                    res = [NSString stringWithUTF8String:inet_ntoa(temp)];
                }
            }
        }
    }
    
    free(buf);
    
    return res;
}

- (NSString *)getHostnameByIPAddress:(NSString*)ipAddress {
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

- (void)logSockaddrInarp:(struct sockaddr_inarp)sockaddr
{
    printf("sockaddr_inarp:\n");
    printf("    sin_addr = %s\n", inet_ntoa(sockaddr.sin_addr));
    printf("    sin_family = %uc\n", sockaddr.sin_family);
    printf("    sin_len = %uc\n", sockaddr.sin_len);
    printf("    sin_other = %us\n", sockaddr.sin_other);
    printf("    sin_port = %us\n", sockaddr.sin_port);
    printf("    sin_srcaddr = %s\n", inet_ntoa(sockaddr.sin_srcaddr));
    printf("    sin_tos = %us\n", sockaddr.sin_tos);
}

@end
