//
//  ZRCarrierViewController.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRCarrierViewController.h"
#import "ZRNetworkConfiguration.h"

@interface ZRCarrierViewController()

@property (weak, nonatomic) IBOutlet UILabel *carrierName;
@property (weak, nonatomic) IBOutlet UILabel *isoCountryCode;
@property (weak, nonatomic) IBOutlet UILabel *mobileNetworkCode;
@property (weak, nonatomic) IBOutlet UILabel *mobileCountryCode;

@end

@implementation ZRCarrierViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Carrier Info";
    
    [self setData];
}

- (void)setData
{
    ZRCarrierInfo * carrierInfo = [ZRNetworkConfiguration getCarrierInfo];
    
    self.carrierName.text = carrierInfo.carrierName;
    self.isoCountryCode.text = carrierInfo.isoCountryCode;
    self.mobileNetworkCode.text = carrierInfo.mobileNetworkCode;
    self.mobileCountryCode.text = carrierInfo.mobileCountryCode;
}

@end
