//
//  TableViewController.h
//  BLEAPP
//
//  Created by RTLab on 2015. 12. 22..
//  Copyright © 2015년 RTLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TableViewCell.h"
#import "ViewController.h"

@interface TableViewController : UITableViewController<CBCentralManagerDelegate, CBPeripheralDelegate>{
    NSMutableArray* peripheralList;
    CBCentralManager* centralManager;
    NSMutableArray* RSSIArray;
    NSMutableArray* addressArray;
    UITableView* uiTableView;
}
@property (strong, nonatomic) IBOutlet UITableView *uiTableView;

- (IBAction)refresh:(id)sender;

@end
