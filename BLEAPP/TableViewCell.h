//
//  TableViewCell.h
//  BLEAPP
//
//  Created by RTLab on 2015. 12. 22..
//  Copyright © 2015년 RTLab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *peripheralName;
@property (strong, nonatomic) IBOutlet UILabel *RSSI;
@property (strong, nonatomic) IBOutlet UILabel *address;

@end
