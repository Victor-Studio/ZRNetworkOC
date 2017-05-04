//
//  ZRifconfigViewController.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRifconfigViewController.h"
#import "ifconfig.h"
#import "ZRNetworkConfiguration.h"

@interface ZRifconfigViewController ()

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ZRifconfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ifconfig";
    
    
    [self setData];
}

- (void)setData
{
    self.dataArray = [[NSMutableArray alloc] init];
    
    [self.dataArray addObject:[ifconfig ifconfig]];
    
    ZRNetworkInfoIPAddress *currentIPAddress = [ZRNetworkConfiguration getCurrentIPAddress];
    [self.dataArray addObject:currentIPAddress];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        NSArray *arr0 = [self.dataArray objectAtIndex:0];
        return arr0.count;
    }
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuse_cell = @"reuse_cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse_cell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuse_cell];
    }
    
    if (indexPath.section == 0) {
        NSArray *arr0 = [self.dataArray objectAtIndex:indexPath.section];
        NSDictionary *dict = [arr0 firstObject];
        NSString *name = dict[@"Name"];
        cell.textLabel.text = name;
        
        if ([name isEqualToString:@"en0"]) {
            cell.textLabel.text = [[NSString alloc] initWithFormat:@"%@ (Current Address)", name];
        }
        
        cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"IP : %@  Mac : %@", dict[@"IPAddress"], dict[@"MACAddress"]];
    } else {
        
        ZRNetworkInfoIPAddress *currentIPAddress = [self.dataArray objectAtIndex:indexPath.section];
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = [NSString stringWithFormat:@"name：%@" ,currentIPAddress.interfaceName];
                break;
            case 1:
                cell.textLabel.text = [NSString stringWithFormat:@"IP：%@" ,currentIPAddress.IPAddress];
                break;
            case 2:
                cell.textLabel.text = [NSString stringWithFormat:@"subnet mast：%@" ,currentIPAddress.subnetMast];
                break;
            case 3:
                cell.textLabel.text = [NSString stringWithFormat:@"broadcast addr：%@" ,currentIPAddress.broadcastAddress];
                break;
            default:
                break;
        }
    }
    
    return cell;
}

@end
