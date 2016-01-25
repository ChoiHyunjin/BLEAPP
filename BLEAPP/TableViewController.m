//
//  TableViewController.m
//  BLEAPP
//
//  Created by RTLab on 2015. 12. 22..
//  Copyright © 2015년 RTLab. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()

@end

@implementation TableViewController

@synthesize uiTableView;


- (void)viewDidLoad {
    [super viewDidLoad];
    peripheralList = [[NSMutableArray alloc] init];
    RSSIArray = [[NSMutableArray alloc] init];
//    uiTableView = [[UITableView alloc] init];

    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
//    if(!centralManager.isScanning){
//        NSLog(@"Scan Restart!");
//        [centralManager scanForPeripheralsWithServices:nil options:nil];
//    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    [peripheralList removeAllObjects];
    [centralManager scanForPeripheralsWithServices:nil options:nil];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{

    [central scanForPeripheralsWithServices:nil options:nil];
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber *)RSSI{
    BOOL peripheralIdentifier = NO;
    for(int i=0;i<peripheralList.count;i++){
        if([peripheralList[i] isEqual:peripheral]){
            peripheralIdentifier = YES;
            if(RSSIArray[i] != RSSI)
                RSSIArray[i] = RSSI;
            break;
        }
    }
    if(peripheralIdentifier == NO){
        [peripheralList addObject:peripheral];
        [RSSIArray addObject:RSSI];
        [uiTableView reloadData];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return peripheralList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [uiTableView dequeueReusableCellWithIdentifier:@"TableViewCell"];

    CBPeripheral* cellPeripheral = [peripheralList objectAtIndex:indexPath.row];

    cell.peripheralName.text = cellPeripheral.name;
    cell.RSSI.text =[[RSSIArray objectAtIndex:indexPath.row] stringValue];
    cell.address.text = cellPeripheral.identifier.UUIDString;
    
    // Configure the cell...
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ViewController* viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    viewController.discoveredPeripheral = [peripheralList objectAtIndex:indexPath.row];
    viewController.centralManager = centralManager;
    [centralManager stopScan];
    viewController.RSSINumber = [RSSIArray objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:viewController animated:YES];

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
