//
//  ViewController.h
//  BLEAPP
//
//  Created by RTLab on 2015. 12. 22..
//  Copyright © 2015년 RTLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TableViewController.h"

#define SERVICE_UUID                        @"2650"
#define TEST_SERVICE_UUID                   @"2651"
#define NOTIFYCATION_UUID                   @"7f01"
#define SEND_UUID                           @"7f02"     // 스마트폰 -> 밴드
#define INDICATION_UUID                     @"7F03"     // 밴드 -> 스마트폰

#pragma mark - AMD Header
#define AMD_CMD                             @"88"

#pragma mark - Service ID
#define SVC_CALCULATE_DEGREE                @"61"
#define SVC_CALCULATE_DEGREE_NUM            61

#define DEGREE_STATE_ING                    1
#define DEGREE_STATE_FINISH                 2
#define DEGREE_STATE_START                  3
#define DEGREE_STATE_OFFLINE                4
#define DEGREE_STATE_ERROR                  5

#define BUTN_SIZE_WIDTH                     90
#define BUTN_SIZE_HEIGHT                    30
#define BUTN_SIZE_Y                         321
#define BUTN_SIZE_X                         138

@interface ViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate, UIPickerViewDataSource, UIPickerViewDelegate>{
    NSMutableString* dataToDisplay;
    CBCentralManager* mycentralManager;
    CBCharacteristic* writeCharacteristic;
    CBCharacteristic* notifyCharacteristic;
    CBCharacteristic* readCharacteristic;
    NSArray* preAlarmData;
    NSArray* methodData;
    NSArray* repeatData;
    NSArray* armData;
    UIPickerView* preAlarmPicker;
    UIPickerView* repeatAlarmPicker;
    UIPickerView* methodPicker;
    UIPickerView* armPicker;
    UIDatePicker* datePicker;
    UIView* subview;
}
@property (strong, nonatomic) IBOutlet UILabel *state;
@property (strong, nonatomic) IBOutlet UILabel *peripheralName;
@property (strong, nonatomic) IBOutlet UILabel *RSSIButn;
@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (nonatomic) CBPeripheral* discoveredPeripheral;
@property (nonatomic) CBCentralManager* centralManager;
@property (nonatomic) NSNumber* RSSINumber;

@end

//65571383