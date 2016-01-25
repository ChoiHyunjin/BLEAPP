//
//  ViewController.m
//  BLEAPP
//
//  Created by RTLab on 2015. 12. 22..
//  Copyright © 2015년 RTLab. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize discoveredPeripheral;
@synthesize centralManager;
@synthesize RSSINumber;
@synthesize peripheralName;
@synthesize RSSIButn;
@synthesize dataLabel;
@synthesize state;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    mycentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    peripheralName.text = discoveredPeripheral.name;
    RSSIButn.text = [RSSINumber stringValue];
    dataToDisplay = [[NSMutableString alloc] init];
    state.text = @"Not Connect";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidDisappear:(BOOL)animated{
    [mycentralManager cancelPeripheralConnection:discoveredPeripheral];
}

#pragma mark - BLE 통신
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSLog(@"Central Manager Updated");
    if(mycentralManager.state == CBCentralManagerStatePoweredOn){
        [mycentralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber *)RSSI{
    peripheral.delegate = self;
    RSSIButn.text = [RSSI stringValue];

    if([peripheral.identifier.UUIDString isEqual:discoveredPeripheral.identifier.UUIDString]){
        discoveredPeripheral = peripheral;
        [mycentralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if(error){
        NSLog(@"%@",error);
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [central stopScan];
    [peripheral setDelegate:self];
    state.text = @"Connected";
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if(error)
        NSLog(@"discover service error : %@",error);
    NSLog(@"services : %@",peripheral.services);

    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if(error)
        NSLog(@"discover char error : %@",error);
    NSLog(@"characteristics : %@",service.characteristics);
    NSLog(@"Update Notify");
    for (CBCharacteristic *characteristic in service.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SEND_UUID]]&&(characteristic.properties == 0x08)){
            writeCharacteristic = characteristic;
        }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:NOTIFYCATION_UUID]]&&(characteristic.properties == 0x12)){
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            notifyCharacteristic = characteristic;
        }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:INDICATION_UUID]]||(characteristic.properties == 0x22)){
            readCharacteristic = characteristic;
        }
    }

    // 준비완료 시 버튼 생성
    UIButton* startButn = [[UIButton alloc] initWithFrame:CGRectMake(BUTN_SIZE_X, BUTN_SIZE_Y, BUTN_SIZE_WIDTH, BUTN_SIZE_HEIGHT)];
    [startButn setTitle: @"Start" forState:UIControlStateNormal];
    [startButn setBackgroundColor:[UIColor darkGrayColor]];
    [startButn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [startButn addTarget:self action:@selector(sendStartData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButn];
}

-(void)sendStartData{
    UInt8 dataInUint[5] = {0x88, 0x61, 0x11, 0x01, 0xee};           //보낼 데이터
    NSData* dataToSend = [[NSData alloc] initWithBytes:&dataInUint length:5];
    [self sendDataToPeripheral:discoveredPeripheral data:dataToSend];
    state.text = @"측정시작";
}

-(void)sendDataToPeripheral : (CBPeripheral*)peripheral
                       data : (NSData*)data{
    [peripheral writeValue:data forCharacteristic:writeCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error)
        NSLog(@"noti error : %@",error);
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error)
        NSLog(@"update value error : %@",error);
    NSLog(@"%@",characteristic.value);
    NSMutableArray* recvDataArray = [self divideData:characteristic.value];
    NSLog(@"string = %@",recvDataArray);
    switch ([recvDataArray[6] intValue]) {
        case SVC_CALCULATE_DEGREE_NUM:
            state.font = [UIFont fontWithName:@"font" size:20];
            switch ([recvDataArray[7] intValue]) {
                case DEGREE_STATE_FINISH:
                    state.text = @"측정 완료";
                    break;
                    
                default:
                    state.text = @"측정중";
                    break;
            }
            dataLabel.text = recvDataArray[8];
            break;

        default:
            state.text = @"Received Data";
            dataLabel.text = recvDataArray[7];
            break;
    }
}

-(NSString*)decToHex : (NSString*) string{
    unsigned value = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner scanHexInt:&value];
    string = [NSString stringWithFormat:@"%u", value];
    return string;
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error)
        NSLog(@"%@ error : %@",characteristic,error);
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if(error)
        NSLog(@"disconnect error : %@",error);
    NSLog(@"************* BLE Disconnected *************");
    state.text = @"Disconnect";
//    [mycentralManager scanForPeripheralsWithServices:nil options:nil];
    NSLog(@"Start Scanning");
}

#pragma mark - 데이터 처리

-(NSMutableArray*) divideData : (NSData*) data{
    @autoreleasepool {
        NSMutableArray* alignnedData = [[NSMutableArray alloc] init];
        NSString* string = [NSString stringWithFormat:@"%@",data];
        NSMutableString *formatedString = [[NSMutableString alloc] init];
        NSRange range;
        range.location=1;
        range.length=2;
        if(![[string substringWithRange:range] isEqual:AMD_CMD])
            return nil;

        //<,>,공백 잘라내기
        range.length = 8;
        range.location = 0;
        for(int i=0;i<4;i++){
            range.location = 1+i*9;
            if(string.length-range.location < 8){
                range.length = string.length-range.location-1;
                [formatedString appendString: [string substringWithRange:range]];
                break;
            }
            [formatedString appendString: [string substringWithRange:range]];
        }

        //자르기
        range.length = 2;
        for(int i=0;i<7;i++){
            range.location = i*2;
            [alignnedData addObject:[formatedString substringWithRange:range]];
        }
        switch ([alignnedData[6] intValue]) {
            case SVC_CALCULATE_DEGREE_NUM :
                range.location += 2;
                [alignnedData addObject:[formatedString substringWithRange:range]];
                range.location += 2;
                range.length = 4;
                [alignnedData addObject:[self decToHex:[formatedString substringWithRange:range]]];     // 2byte 데이터를 10진수로 바꿔서 저장
                break;
                
            default:
                range.location += 2;
                [alignnedData addObject:[formatedString substringFromIndex:range.location]];

        }
        return alignnedData;
    }
}


@end
