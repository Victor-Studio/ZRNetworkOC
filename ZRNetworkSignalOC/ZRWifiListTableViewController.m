//
//  ZRWifiListTableViewController.m
//  ZRNetworkSignalOC
//
//  Created by VictorZhang on 19/04/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "ZRWifiListTableViewController.h" 

@interface ZRWifiListTableViewController ()


@end

@implementation ZRWifiListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"WiFi List";
 
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuse_cell = @"reuse_cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse_cell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuse_cell];
    }
    cell.textLabel.text = @"暂无";
    
    return cell;
}
@end
