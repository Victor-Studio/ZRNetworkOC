//
//  ZRSignalViewController.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRSignalViewController.h"
#import "ZRNetworkConfiguration.h"

@interface ZRSignalViewController ()
@property (weak, nonatomic) IBOutlet UILabel *signalStrength;
@property (weak, nonatomic) IBOutlet UILabel *signalStrengthBars;

@end

@implementation ZRSignalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Signal Info";
    
    [self setData];
}

- (void)setData
{
    ZRNetworkWiFiSignalInfo *wifiSignal = [ZRNetworkConfiguration getWiFiSignalStrength];
    
    self.signalStrength.text = [NSString stringWithFormat:@"%d", wifiSignal.signalStrength];
    self.signalStrengthBars.text = [NSString stringWithFormat:@"%d", wifiSignal.signalStrengthBars];
}


@end
