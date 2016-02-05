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

//UIButton* weekButn[7];
//UIButton* armButn[2];
//short seqNum;
NSMutableArray* arrayOfSchedule;
//UILabel* seqNumLabel[10];

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    mycentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    peripheralName.text = discoveredPeripheral.name;
    RSSIButn.text = [RSSINumber stringValue];
    dataToDisplay = [[NSMutableString alloc] init];
    state.text = @"Not Connect";
//    seqNum = 1;
    arrayOfSchedule = [NSMutableArray array];
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
    if([discoveredPeripheral.name isEqual:@"PAARBand"])
        [peripheral discoverServices:@[[CBUUID UUIDWithString:TEST_SERVICE_UUID]]];
    else
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
//    [startButn setBackgroundColor:[UIColor grayColor]];
    startButn.layer.borderColor = [UIColor brownColor].CGColor;
    startButn.layer.cornerRadius = 5;
    startButn.layer.borderWidth = 2;
    [startButn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    // PAAR Watch만 여러 버튼 생성
    if([discoveredPeripheral.name isEqual:@"PAAR Watch"]){
        [startButn addTarget:self action:@selector(sendStartData) forControlEvents:UIControlEventTouchUpInside];
        [startButn setTitle: @"왼팔 측정" forState:UIControlStateNormal];

        UIButton* Butn2 = [[UIButton alloc] initWithFrame:CGRectMake(BUTN_SIZE_X + BUTN_SIZE_WIDTH + 15, BUTN_SIZE_Y, BUTN_SIZE_WIDTH, BUTN_SIZE_HEIGHT)];
        [Butn2 setTitle: @"오른팔 측정" forState:UIControlStateNormal];
//        [Butn2 setBackgroundColor:[UIColor grayColor]];
        [Butn2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [Butn2 addTarget:self action:@selector(sendStartData2) forControlEvents:UIControlEventTouchUpInside];
        Butn2.layer.borderColor = [UIColor brownColor].CGColor;
        Butn2.layer.cornerRadius = 5;
        Butn2.layer.borderWidth = 2;
        [self.view addSubview:Butn2];
        
        UIButton* Butn3 = [[UIButton alloc] initWithFrame:CGRectMake(BUTN_SIZE_X + BUTN_SIZE_WIDTH*2 + 30, BUTN_SIZE_Y, BUTN_SIZE_WIDTH*3/2, BUTN_SIZE_HEIGHT)];
        [Butn3 setTitle: @"왼팔(등 뒤) 측정" forState:UIControlStateNormal];
        //        [Butn2 setBackgroundColor:[UIColor grayColor]];
        [Butn3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [Butn3 addTarget:self action:@selector(sendStartData3) forControlEvents:UIControlEventTouchUpInside];
        Butn3.layer.borderColor = [UIColor brownColor].CGColor;
        Butn3.layer.cornerRadius = 5;
        Butn3.layer.borderWidth = 2;
        [self.view addSubview:Butn3];
        
        UIButton* Butn4 = [[UIButton alloc] initWithFrame:CGRectMake(BUTN_SIZE_X + BUTN_SIZE_WIDTH*7/2 + 45, BUTN_SIZE_Y, BUTN_SIZE_WIDTH*3/2, BUTN_SIZE_HEIGHT)];
        [Butn4 setTitle: @"오른팔(등 뒤) 측정" forState:UIControlStateNormal];
        //        [Butn3 setBackgroundColor:[UIColor grayColor]];
        [Butn4 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [Butn4 addTarget:self action:@selector(sendStartData3) forControlEvents:UIControlEventTouchUpInside];
        Butn4.layer.borderColor = [UIColor brownColor].CGColor;
        Butn4.layer.cornerRadius = 5;
        Butn4.layer.borderWidth = 2;
        [self.view addSubview:Butn4];
        
        UIButton* Butn5 = [[UIButton alloc] initWithFrame:CGRectMake(BUTN_SIZE_X + BUTN_SIZE_WIDTH*5 + 60, BUTN_SIZE_Y, BUTN_SIZE_WIDTH, BUTN_SIZE_HEIGHT)];
        [Butn5 setTitle: @"예  약" forState:UIControlStateNormal];
//        [Butn3 setBackgroundColor:[UIColor grayColor]];
        [Butn5 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [Butn5 addTarget:self action:@selector(reservationSchedule:) forControlEvents:UIControlEventTouchUpInside];
        Butn5.layer.borderColor = [UIColor brownColor].CGColor;
        Butn5.layer.cornerRadius = 5;
        Butn5.layer.borderWidth = 2;
        [self.view addSubview:Butn5];
    }
    else{
        [startButn addTarget:self action:@selector(sendStartDataToBand) forControlEvents:UIControlEventTouchUpInside];
        [startButn setTitle: @"Start" forState:UIControlStateNormal];
    }
    [self.view addSubview:startButn];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error)
        NSLog(@"noti error : %@",error);
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error)
        NSLog(@"update value error : %@",error);
    NSLog(@"%@",characteristic.value);
    NSArray* recvDataArray = [self divideData:characteristic.value];
    NSLog(@"string = %@",recvDataArray);
    [self compareData:recvDataArray];
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
        for(int i=0;i<4;i++){
            range.location = 1+i*9;
            if(string.length-range.location == 0)
                break;
            if(string.length-range.location < 8){
                range.length = string.length-range.location-1;
                [formatedString appendString: [string substringWithRange:range]];
                break;
            }
            [formatedString appendString: [string substringWithRange:range]];
        }

        //자르기
        range.length = 2;
        for(int i=0;i<4;i++){
            range.location = i*2;
            [alignnedData addObject:[formatedString substringWithRange:range]];
        }
        switch ([alignnedData[1] intValue]) {
                // paar watch 각도측정일때
            case SVC_CALCULATE_DEGREE_NUM :
                range.location += 2;
                [alignnedData addObject:[formatedString substringWithRange:range]];
                range.location += 2;
                [alignnedData addObject:[formatedString substringWithRange:range]];
                range.location += 2;
                range.length = 4;
                [alignnedData addObject:[self hexToDec:[formatedString substringWithRange:range]]];     // 2byte 데이터를 10진수로 바꿔서 저장
                break;
                
                //나머지 잡다한 경우
            default:
                range.location += 2;
                [alignnedData addObject:[formatedString substringFromIndex:range.location]];

        }
        return alignnedData;
    }
}

-(void)alertReservation{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"예약하기" message:@"예약 되었습니다." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)compareData : (NSArray*)recvDataArray{
    
    switch ([recvDataArray[1] intValue]) {
            
        case 31:
            [self alertReservation];
            break;
            
        case SVC_CALCULATE_DEGREE_NUM:
            state.font = [UIFont fontWithName:@"font" size:20];
            
            //타입별 구분
            switch ([recvDataArray[4] intValue]) {
                    
                case DEGREE_STATE_FINISH:
                    state.text = @"측정 완료";
                    dataLabel.text = recvDataArray[6];
                    break;
                    
                case DEGREE_STATE_ING:
                    state.text = @"측정중";
                    dataLabel.text = recvDataArray[6];
                    break;
                    
                case DEGREE_STATE_OFFLINE:
                    state.text = @"오프라인 모드";
                    break;
                    
                case DEGREE_STATE_ERROR:
                    
                    switch ([recvDataArray[5] intValue]) {
                        case 1:
                            state.text = @"Time Out";
                            break;
                            
                        default:
                            state.text = @"잘못된 측정";
                            break;
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            state.text = @"Received Data";
            dataLabel.text = recvDataArray[6];
            break;
    }
}

-(NSString*)hexToDec : (NSString*) string{
    unsigned value = 0;
    int trueValue;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner scanHexInt:&value];
    trueValue = value;
    trueValue = trueValue << 16;
    trueValue = trueValue >> 16;
    string = [NSString stringWithFormat:@"%d", trueValue];
    return string;
}

-(void)sendStartDataToBand{
    UInt8 dataInUint[7] = {0x88, 0xaa, 0x11, 0x03, 0xa4, 0x01, 0x01};           //보낼 데이터
    NSData* dataToSend = [[NSData alloc] initWithBytes:&dataInUint length:7];
    [self sendDataToPeripheral:discoveredPeripheral data:dataToSend];
    state.text = @"측정시작";
}

-(void)sendStartData{
    UInt8 dataInUint[6] = {0x88, 0x61, 0x11, 0x02, 0x03, 0x01};           //보낼 데이터
    NSData* dataToSend = [[NSData alloc] initWithBytes:&dataInUint length:6];
    [self sendDataToPeripheral:discoveredPeripheral data:dataToSend];
    state.text = @"왼팔 측정시작";
}

-(void)sendStartData2{
    UInt8 dataInUint[6] = {0x88, 0x61, 0x11, 0x02, 0x03, 0x02};           //보낼 데이터
    NSData* dataToSend = [[NSData alloc] initWithBytes:&dataInUint length:6];
    [self sendDataToPeripheral:discoveredPeripheral data:dataToSend];
    state.text = @"오른팔 측정시작";
}

-(void)sendStartData3{
    UInt8 dataInUint[6] = {0x88, 0x61, 0x11, 0x02, 0x03, 0x03};           //보낼 데이터
    NSData* dataToSend = [[NSData alloc] initWithBytes:&dataInUint length:6];
    [self sendDataToPeripheral:discoveredPeripheral data:dataToSend];
    state.text = @"왼팔(등 뒤) 측정시작";
}

-(void)sendStartData4{
    UInt8 dataInUint[6] = {0x88, 0x61, 0x11, 0x02, 0x03, 0x04};           //보낼 데이터
    NSData* dataToSend = [[NSData alloc] initWithBytes:&dataInUint length:6];
    [self sendDataToPeripheral:discoveredPeripheral data:dataToSend];
    state.text = @"오른팔(등 뒤) 측정시작";
}

-(void)sendDataToPeripheral : (CBPeripheral*)peripheral
                       data : (NSData*)data{
    [peripheral writeValue:data forCharacteristic:writeCharacteristic type:CBCharacteristicWriteWithResponse];
    NSLog(@"data to send : %@",data);
}

//예약 ui 만들기
-(IBAction)reservationSchedule:(UIButton*)sender{
    if([sender isSelected])
        return;
    UIButton* reservationButn = [[UIButton alloc] initWithFrame:CGRectMake(640, 580, 80, 21)];
    [reservationButn setTitle:@"예약하기" forState:UIControlStateNormal];
    [reservationButn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [reservationButn addTarget:self action:@selector(reservation) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reservationButn];
//
    UILabel* selectDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 581, 60, 21)];
    selectDataLabel.text = @"예약일정";
    selectDataLabel.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:selectDataLabel];
    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(80, 581, 300, 120)];
    datePicker.minimumDate = [[NSDate alloc] init];
    [self.view addSubview:datePicker];
//
//    
//    UILabel* repeatInterval = [[UILabel alloc] initWithFrame:CGRectMake(450, 481, 80, 21)];
//    repeatInterval.text = @"반복시간 :";
//    repeatInterval.font = [UIFont systemFontOfSize:17];
//    [self.view addSubview:repeatInterval];
//    repeatData = [NSArray arrayWithObjects:@"없음",@"10분 후",@"5분 후", nil];
//    repeatAlarmPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(540, 481, 200, 120)];
//    repeatAlarmPicker.delegate = self;
//    repeatAlarmPicker.dataSource = self;
//    [self.view addSubview:repeatAlarmPicker];
//    
//    UILabel* preAlarm = [[UILabel alloc] initWithFrame:CGRectMake(80, 650, 80, 21)];
//    preAlarm.text = @"미리알람 :";
//    preAlarm.font = [UIFont systemFontOfSize:17];
//    [self.view addSubview:preAlarm];
//    preAlarmData = [NSArray arrayWithObjects:@"없음",@"하루 전",@"1시간 전", @"30분 전", nil];
//    preAlarmPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(165, 650, 200, 120)];
//    preAlarmPicker.delegate = self;
//    preAlarmPicker.dataSource = self;
//    [self.view addSubview:preAlarmPicker];
//    
//    UILabel* alarmMethod = [[UILabel alloc] initWithFrame:CGRectMake(400, 650, 80, 21)];
//    alarmMethod.text = @"알림방법 :";
//    alarmMethod.font = [UIFont systemFontOfSize:17];
//    [self.view addSubview:alarmMethod];
//    methodData = [NSArray arrayWithObjects:@"진동",@"팝업",@"진동 및 팝업", @"음성 메시지", @"진동 및 음성", @"팝업 및 음성", @"모두", nil];
//    methodPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(490, 650, 200, 120)];
//    methodPicker.delegate = self;
//    methodPicker.dataSource = self;
//    [self.view addSubview:methodPicker];
//    
//    UILabel* weeklyRepeat = [[UILabel alloc] initWithFrame:CGRectMake(80, 800, 80, 21)];
//    weeklyRepeat.text = @"주간반복";
////    weeklyRepeat.font = [UIFont systemFontOfSize:17];
//    [self.view addSubview:weeklyRepeat];
//    NSArray* weekArray = [NSArray arrayWithObjects:@"월", @"화", @"수", @"목", @"금", @"토", @"일", nil];
//    for (int i=0; i<7; i++) {
//        weekButn[i] = [[UIButton alloc] initWithFrame:CGRectMake(80+40*i, 830, 30, 30)];
//        [weekButn[i] setTitle:weekArray[i] forState:UIControlStateNormal];
//        [weekButn[i] setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
//        [weekButn[i] setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
//        weekButn[i].layer.borderColor = [UIColor whiteColor].CGColor;
//        weekButn[i].layer.borderWidth = 1;
//        weekButn[i].layer.cornerRadius = 4;
//        [weekButn[i] addTarget:self action:@selector(butnDidChangeState:) forControlEvents:UIControlEventTouchUpInside];
//        [self.view addSubview: weekButn[i]];
//    }
    
    [sender setSelected:YES];
    
    UILabel* kindofArm = [[UILabel alloc] initWithFrame:CGRectMake(80, 750, 80, 21)];
    kindofArm.text = @"측정부위 :";
    kindofArm.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:kindofArm];
    armData = [NSArray arrayWithObjects:@"왼팔",@"오른팔",@"왼팔(등 뒤)", @"오른팔(등 뒤)", nil];
    armPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(165, 750, 200, 120)];
    armPicker.delegate = self;
    armPicker.dataSource = self;
    [self.view addSubview:armPicker];
    
//    seqNumLabel[seqNum-1] = [[UILabel alloc] initWithFrame:CGRectMake(40+40*seqNum, 520, 30, 30)];
//    seqNumLabel[seqNum-1].text = [NSString stringWithFormat:@"%d",seqNum];
//    seqNumLabel[seqNum-1].layer.borderColor = [UIColor blueColor].CGColor;
//    seqNumLabel[seqNum-1].textColor = [UIColor blueColor];
//    seqNumLabel[seqNum-1].layer.borderWidth = 1;
//    seqNumLabel[seqNum-1].layer.cornerRadius = 4;
//    seqNumLabel[seqNum-1].textAlignment = NSTextAlignmentCenter;
//    [self.view addSubview:seqNumLabel[seqNum-1]];
}

//-(IBAction)butnDidChangeState:(UIButton*)sender{
//    if([sender isSelected]){
//        sender.layer.borderColor = [UIColor whiteColor].CGColor;
//        [sender setSelected:NO];
//    }else{
//        sender.layer.borderColor = [UIColor blackColor].CGColor;
//        [sender setSelected:YES];
//    }
//}

// 예약하기 버튼 누를 시 수행
-(void)reservation{
    UInt8 data[3][19] = {{0x88, 0x31, 0x13, 0x0f, 0x01, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0x88, 0x31, 0x23, 0x0f, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0x88, 0x31, 0x33, 0x0f, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}};              //보낼 데이터
//    data[0][5]=seqNum;
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger year = [gregorianCalendar component:NSCalendarUnitYear fromDate:datePicker.date];
    data[0][6] = year % 256;
    data[0][7] = year / 256;
    data[0][8] = [gregorianCalendar component:NSCalendarUnitMonth fromDate:datePicker.date];
    data[0][9] = [gregorianCalendar component:NSCalendarUnitDay fromDate:datePicker.date];
    data[0][10] = [gregorianCalendar component:NSCalendarUnitHour fromDate:datePicker.date];
    data[0][11] = [gregorianCalendar component:NSCalendarUnitMinute fromDate:datePicker.date];
    data[0][12] = 0;
//    data[0][13] = [preAlarmPicker selectedRowInComponent:0]+1;                  //미리알림
//    
//    for(int i=0 ; i<7 ; i++){                                                   //주간 반복
//        if([weekButn[i] isSelected])
//            data[0][14] += pow(2, 6-i);
//    }
//    
    data[0][15] = 3;                                                                //알람 방법
//    data[0][16] = [repeatAlarmPicker selectedRowInComponent:0];                 //반복 알람
    data[0][17] = [armPicker selectedRowInComponent:0]+1;                       //왼팔, 오른팔
    
    NSData* dataToSend[3];
    
    for(int i=0 ; i<3; i++){
        dataToSend[i] = [[NSData alloc] initWithBytes:&data[i] length:19];
        [self sendDataToPeripheral:discoveredPeripheral data:dataToSend[i]];
    }
    NSLog(@"%@",dataToSend[0]);
//    seqNum++;
//    if(seqNum > 10)
//        seqNum = 1;
//    
    //시퀀스 넘버 라벨
//    if(!seqNumLabel[seqNum]){
//        seqNumLabel[seqNum-1] = [[UILabel alloc] initWithFrame:CGRectMake(40+40*seqNum, 520, 30, 30)];
//        seqNumLabel[seqNum-1].text = [NSString stringWithFormat:@"%d",seqNum];
//        seqNumLabel[seqNum-1].layer.borderColor = [UIColor blueColor].CGColor;
//        seqNumLabel[seqNum-1].textColor = [UIColor blueColor];
//        seqNumLabel[seqNum-1].textAlignment = NSTextAlignmentCenter;
//        seqNumLabel[seqNum-1].layer.borderWidth = 1;
//        seqNumLabel[seqNum-1].layer.cornerRadius = 4;
//        [self.view addSubview:seqNumLabel[seqNum-1]];
//        
//        seqNumLabel[seqNum-2].layer.borderColor = [UIColor blackColor].CGColor;
//        seqNumLabel[seqNum-2].textColor = [UIColor blackColor];
//    }else{
//        seqNumLabel[seqNum-1].layer.borderColor = [UIColor blueColor].CGColor;
//        seqNumLabel[seqNum-1].textColor = [UIColor blueColor];
//        if(seqNum==1){
//            seqNumLabel[9].layer.borderColor = [UIColor blackColor].CGColor;
//            seqNumLabel[9].textColor = [UIColor blackColor];
//        }else{
//            seqNumLabel[seqNum-2].layer.borderColor = [UIColor blackColor].CGColor;
//            seqNumLabel[seqNum-2].textColor = [UIColor blackColor];
//        }
//    }
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
//    if([pickerView isEqual:preAlarmPicker]){
//        return preAlarmData.count;
//    }else if([pickerView isEqual:repeatAlarmPicker]){
//        return repeatData.count;
//    }else if([pickerView isEqual:methodPicker]){
//        return methodData.count;
//    }else if([pickerView isEqual:armPicker]){
//        return armData.count;
//    }
    return armData.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
//    if([pickerView isEqual:preAlarmPicker]){
//        return preAlarmData[row];
//    }else if([pickerView isEqual:repeatAlarmPicker]){
//        return repeatData[row];
//    }else if([pickerView isEqual:methodPicker]){
//        return methodData[row];
//    }else if([pickerView isEqual:armPicker]){
//        return armData[row];
//    }
    return armData[row];
}

@end
