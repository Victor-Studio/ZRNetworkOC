//
//  ZRSSIDViewController.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRSSIDViewController.h"
#import "ZRNetworkConfiguration.h"

@interface ZRSSIDViewController ()
@property (weak, nonatomic) IBOutlet UILabel *ssid;
@property (weak, nonatomic) IBOutlet UILabel *bssid;
@property (weak, nonatomic) IBOutlet UILabel *ssiddata;
@property (weak, nonatomic) IBOutlet UILabel *currentIp;

@end

@implementation ZRSSIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"SSID Info";

    [self setData];
}

- (void)setData
{
    ZRNetworkInfoSSIDInterface *interlistModel = [ZRNetworkConfiguration fetchSSIDInfo];
    
    self.ssid.text = interlistModel.SSID;
    self.bssid.text = interlistModel.BSSID;
    self.ssiddata.text = [[NSString alloc] initWithData:interlistModel.SSIDDATA encoding:NSUTF8StringEncoding];
}

@end
