//
//  ZRNetworkSignalViewController.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRNetworkSignalViewController.h"
#import "ZRNetworkConfiguration.h"

@interface ZRNetworkSignalViewController ()

@property (weak, nonatomic) IBOutlet UILabel *signalType;

@property (weak, nonatomic) IBOutlet UILabel *signalStrength;

@property (weak, nonatomic) IBOutlet UILabel *signalStrengthBars;

@end

@implementation ZRNetworkSignalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Network Signal";
    
    [self setData];
}

- (void)setData
{
    ZRNetworkSignalInfo *networkSignal = [ZRNetworkConfiguration getNetworkSignal];
    
    self.signalType.text = [NSString stringWithFormat:@"%ld", (long)networkSignal.networkSignalType];
    self.signalStrength.text = [NSString stringWithFormat:@"%d", networkSignal.strengthRaw];
    self.signalStrengthBars.text = [NSString stringWithFormat:@"%d", networkSignal.wifiStrengthBars];
}

@end
