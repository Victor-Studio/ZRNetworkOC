//
//  ZRARPTableViewController.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 20/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRARPTableViewController.h"
#import "ZRNetworkConfiguration.h"
#import "ZRArpTableModel.h"
#import "ZRArpUtil.h"
#import "ZRArpTableUtil.h"

#define  kTableViewCellSingleHeight   20




@interface ZRARPTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *hostLabel;

@property (nonatomic, strong) UILabel *ipLabel;

@property (nonatomic, strong) UILabel *macAddrLabel;

@property (nonatomic, strong) UILabel *manufacturerLabel;

@end

@implementation ZRARPTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        CGRect rect = [UIScreen mainScreen].bounds;
        
        CGFloat X = 15;
        CGFloat W = rect.size.width - X * 2;
        CGFloat H = kTableViewCellSingleHeight;
        CGFloat Y = 0;
        
        UILabel *lab1 = [[UILabel alloc] initWithFrame:CGRectMake(X, Y, W, H)];
        lab1.text = @"host name";
        lab1.textColor = [UIColor blackColor];
        lab1.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:lab1];
        _hostLabel = lab1;
        
        Y = H;
        UILabel *lab2 = [[UILabel alloc] initWithFrame:CGRectMake(X, Y, W, H)];
        lab2.text = @"ip addr";
        lab2.textColor = [UIColor blackColor];
        lab2.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:lab2];
        _ipLabel = lab2;
        
        Y = H * 2;
        UILabel *lab3 = [[UILabel alloc] initWithFrame:CGRectMake(X, Y, W, H)];
        lab3.text = @"mac addr";
        lab3.textColor = [UIColor blackColor];
        lab3.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:lab3];
        _macAddrLabel = lab3;
        
        Y = H * 3;
        UILabel *lab4 = [[UILabel alloc] initWithFrame:CGRectMake(X, Y, W, H)];
        lab4.text = @"network card";
        lab4.textColor = [UIColor blackColor];
        lab4.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:lab4];
        _manufacturerLabel = lab4;

    }
    return self;
}

@end









@interface ZRARPTableViewController ()<ZRArpTableDelegate /*, ZRArpDelegate*/>

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ZRARPTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setData2];
}

/*
- (void)setData1
{
    _dataArray = [[NSMutableArray alloc] init];
    
    ZRArpUtil *arpUtil = [[ZRArpUtil alloc] init];
    arpUtil.arpDelegate = self;
    [arpUtil startGettingIPAddressList];
}

#pragma mark - ZRArpDelegate
- (void)arpTableScanWithResultHostName:(NSString *)hostName iPAddress:(NSString *)ipAddress macAddress:(NSString *)macAddress networkCardManufacturerName:(NSString *)networkCardManufacturerName
{
    NSMutableArray *marr = [[NSMutableArray alloc] init];
    [marr addObject:hostName?:@""];
    [marr addObject:ipAddress];
    [marr addObject:macAddress];
    [marr addObject:networkCardManufacturerName?:@""];
    
    [_dataArray addObject:marr];
    
    self.title = [NSString stringWithFormat:@"Found %ld devices", _dataArray.count];
    
    [self.tableView reloadData];
}
*/

- (void)setData2
{
    _dataArray = [[NSMutableArray alloc] init];
    
    ZRNetworkInfoIPAddress *currentModel = [ZRNetworkConfiguration getCurrentIPAddress];
    
    ZRArpTableUtil *arpUtil = [[ZRArpTableUtil alloc] init];
    arpUtil.arpTableDelegate = self;
    [arpUtil startGettingAllHostsViaIPAddr:currentModel.IPAddress andSubnet:currentModel.subnetMast];
}

#pragma mark - ZRArpTableDelegate
- (void)arpTableScanWithResultModel:(ZRArpTableModel *)arpTableModel
{
    NSMutableArray *marr = [[NSMutableArray alloc] init];
    [marr addObject:arpTableModel.hostname?:@""];
    [marr addObject:arpTableModel.ipAddress];
    [marr addObject:arpTableModel.macAddress?:@""];
    [marr addObject:arpTableModel.networkCardManufacturer?:@""];
    
    [_dataArray addObject:marr];
    
    self.title = [NSString stringWithFormat:@"Found %ld devices", _dataArray.count];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arr = [self.dataArray objectAtIndex:indexPath.row];
    return arr.count * kTableViewCellSingleHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuse_cell = @"macAndIpAddress_reuse_cell";
    
    ZRARPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse_cell];
    if (!cell) {
        cell = [[ZRARPTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuse_cell];
    }
    
    NSArray *arr = [self.dataArray objectAtIndex:indexPath.row];
    cell.hostLabel.text = arr[0];
    cell.ipLabel.text = arr[1];
    cell.macAddrLabel.text = arr[2];
    cell.manufacturerLabel.text = arr[3];
    
    return cell;
}

@end
