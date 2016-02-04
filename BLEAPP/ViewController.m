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

UIButton* weekButn[7];
UIButton* armButn[2];

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
        
        UIButton* Butn3 = [[UIButton alloc] initWithFrame:CGRectMake(BUTN_SIZE_X + BUTN_SIZE_WIDTH*2 + 30, BUTN_SIZE_Y, BUTN_SIZE_WIDTH, BUTN_SIZE_HEIGHT)];
        [Butn3 setTitle: @"예  약" forState:UIControlStateNormal];
//        [Butn3 setBackgroundColor:[UIColor grayColor]];
        [Butn3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [Butn3 addTarget:self action:@selector(reservationSchedule) forControlEvents:UIControlEventTouchUpInside];
        Butn3.layer.borderColor = [UIColor brownColor].CGColor;
        Butn3.layer.cornerRadius = 5;
        Butn3.layer.borderWidth = 2;
        [self.view addSubview:Butn3];
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

-(void)compareData : (NSArray*)recvDataArray{
    
    switch ([recvDataArray[1] intValue]) {
            
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
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner scanHexInt:&value];
    string = [NSString stringWithFormat:@"%u", value];
    return string;
}

//1바이트 헥사 만들기
-(NSString*)decToHex : (NSString*) data{
    int intForHex = [data intValue];
    short a = intForHex / 16;
    short b = intForHex % 16;
    NSMutableString* string = [NSMutableString string];
    switch (a) {
        case 15:
            [string appendString:@"f"];
            break;
        case 14:
            [string appendString:@"e"];
            break;
        case 13:
            [string appendString:@"d"];
            break;
        case 12:
            [string appendString:@"c"];
            break;
        case 11:
            [string appendString:@"b"];
            break;
        case 10:
            [string appendString:@"a"];
            break;
        default:
            [string appendString:[NSString stringWithFormat:@"%d",a]];
            break;
    }
    switch (b) {
        case 15:
            [string appendString:@"f"];
            break;
        case 14:
            [string appendString:@"e"];
            break;
        case 13:
            [string appendString:@"d"];
            break;
        case 12:
            [string appendString:@"c"];
            break;
        case 11:
            [string appendString:@"b"];
            break;
        case 10:
            [string appendString:@"a"];
            break;
        default:
            [string appendString:[NSString stringWithFormat:@"%d",b]];
            break;
    }
    data = string;
    return data;
}

-(void)sendStartDataToBand{
    UInt8 dataInUint[7] = {0x88, 0xaa, 0x11, 0x03, 0xa4, 0x01, 0x01};           //보낼 데이터"
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

-(void)sendDataToPeripheral : (CBPeripheral*)peripheral
                       data : (NSData*)data{
    [peripheral writeValue:data forCharacteristic:writeCharacteristic type:CBCharacteristicWriteWithResponse];
    NSLog(@"data to send : %@",data);
}

//예약 ui 만들기
-(void)reservationSchedule{
    UIButton* reservationButn = [[UIButton alloc] initWithFrame:CGRectMake(680, 440, 80, 21)];
    [reservationButn setTitle:@"예약하기" forState:UIControlStateNormal];
    [reservationButn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [reservationButn addTarget:self action:@selector(reservation) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reservationButn];
    
    UILabel* selectDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 481, 60, 21)];
    selectDataLabel.text = @"예약일정";
    selectDataLabel.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:selectDataLabel];
    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(80, 481, 300, 120)];
    datePicker.minimumDate = [[NSDate alloc] init];
    [self.view addSubview:datePicker];
    
    
    UILabel* repeatInterval = [[UILabel alloc] initWithFrame:CGRectMake(450, 481, 80, 21)];
    repeatInterval.text = @"반복시간 :";
    repeatInterval.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:repeatInterval];
    repeatData = [NSArray arrayWithObjects:@"없음",@"10분 후",@"5분 후", nil];
    repeatAlarmPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(540, 481, 200, 120)];
    repeatAlarmPicker.delegate = self;
    repeatAlarmPicker.dataSource = self;
    [self.view addSubview:repeatAlarmPicker];
    
    UILabel* preAlarm = [[UILabel alloc] initWithFrame:CGRectMake(80, 650, 80, 21)];
    preAlarm.text = @"미리알람 :";
    preAlarm.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:preAlarm];
    preAlarmData = [NSArray arrayWithObjects:@"없음",@"하루 전",@"1시간 전", @"30분 전", nil];
    preAlarmPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(165, 650, 200, 120)];
    preAlarmPicker.delegate = self;
    preAlarmPicker.dataSource = self;
    [self.view addSubview:preAlarmPicker];
    
    UILabel* alarmMethod = [[UILabel alloc] initWithFrame:CGRectMake(400, 650, 80, 21)];
    alarmMethod.text = @"알림방법 :";
    alarmMethod.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:alarmMethod];
    methodData = [NSArray arrayWithObjects:@"진동",@"팝업",@"진동 및 팝업", @"음성 메시지", @"진동 및 음성", @"팝업 및 음성", @"모두", nil];
    methodPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(490, 650, 200, 120)];
    methodPicker.delegate = self;
    methodPicker.dataSource = self;
    [self.view addSubview:methodPicker];
    
    UILabel* weeklyRepeat = [[UILabel alloc] initWithFrame:CGRectMake(80, 800, 80, 21)];
    weeklyRepeat.text = @"주간반복";
//    weeklyRepeat.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:weeklyRepeat];
    NSArray* weekArray = [NSArray arrayWithObjects:@"월", @"화", @"수", @"목", @"금", @"토", @"일", nil];
    for (int i=0; i<7; i++) {
        weekButn[i] = [[UIButton alloc] initWithFrame:CGRectMake(80+40*i, 830, 30, 30)];
        [weekButn[i] setTitle:weekArray[i] forState:UIControlStateNormal];
        [weekButn[i] setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [weekButn[i] setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        weekButn[i].layer.borderColor = [UIColor blueColor].CGColor;
        weekButn[i].layer.borderWidth = 1;
        weekButn[i].layer.cornerRadius = 4;
        [weekButn[i] addTarget:self action:@selector(butnDidChangeState:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview: weekButn[i]];
    }
    
    UILabel* kindofArm = [[UILabel alloc] initWithFrame:CGRectMake(400, 800, 80, 21)];
    kindofArm.text = @"측정부위 :";
    kindofArm.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:kindofArm];
    NSArray* armArray = [NSArray arrayWithObjects:@"왼 팔", @"오른팔", nil];
    for (int i=0; i<2; i++) {
        armButn[i] = [[UIButton alloc] initWithFrame:CGRectMake(490+65*i, 800, 60, 30)];
        [armButn[i] setTitle:armArray[i] forState:UIControlStateNormal];
        [armButn[i] setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [armButn[i] setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        armButn[i].layer.borderColor = [UIColor grayColor].CGColor;
        armButn[i].layer.borderWidth = 1;
        armButn[i].layer.cornerRadius = 4;
        [armButn[i] addTarget:self action:@selector(armButnDidChangeState:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview: armButn[i]];
    }
    [armButn[0] setSelected:YES];
    armButn[0].layer.backgroundColor = [UIColor grayColor].CGColor;
}

-(IBAction)butnDidChangeState:(UIButton*)sender{
    if(![sender isSelected]){
        sender.layer.borderColor = [UIColor grayColor].CGColor;
        sender.layer.backgroundColor = [UIColor whiteColor].CGColor;
    }else{
        sender.layer.borderColor = [UIColor whiteColor].CGColor;
        sender.layer.backgroundColor = [UIColor grayColor].CGColor;
    }
}

-(IBAction)armButnDidChangeState:(UIButton*)sender{
    if([sender isEqual:armButn[0]]){
        if(![sender isSelected]){
            sender.layer.borderColor = [UIColor grayColor].CGColor;
            sender.layer.backgroundColor = [UIColor whiteColor].CGColor;
            [armButn[1] setSelected:YES];
        }else{
            sender.layer.borderColor = [UIColor whiteColor].CGColor;
            sender.layer.backgroundColor = [UIColor grayColor].CGColor;
            [armButn[1] setSelected:NO];
        }
    }else{
        if(![sender isSelected]){
            sender.layer.borderColor = [UIColor grayColor].CGColor;
            sender.layer.backgroundColor = [UIColor whiteColor].CGColor;
            [armButn[0] setSelected:YES];
        }else{
            sender.layer.borderColor = [UIColor whiteColor].CGColor;
            sender.layer.backgroundColor = [UIColor grayColor].CGColor;
            [armButn[0] setSelected:NO];
        }
    }
}

-(void)reservation{
    UInt8 data1[19] = {0x88, 0x31, 0x13, 0x15, 0x01, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};           //보낼 데이터
    NSString* date = [NSString stringWithFormat:@"%@",datePicker.date];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSRange range;
    range.length = 2;
    NSString* dateOfData[7]; // year1, year2, month, day, time, minute, second
    dateOfData[0] = [date substringToIndex:2];
    data1[6] = [dateOfData[0] intValue];
    range.location = 2;
    dateOfData[1] = [date substringWithRange:range];
    data1[7] = [dateOfData[1] intValue];
    NSInteger hour = [gregorianCalendar component:NSCalendarUnitHour fromDate:datePicker.date];
    for(int i=1;i<4;i++){
        range.location = i*3-1;
        dateOfData[i] = [date substringWithRange:range];
        data1[i+6] = [dateOfData[i] intValue];
    }
    data1[10] = hour;
    data1[11] = [gregorianCalendar component:NSCalendarUnitMinute fromDate:datePicker.date];
    data1[12] = [gregorianCalendar component:NSCalendarUnitSecond fromDate:datePicker.date];
    
    //미리알림
    data1[13] = [preAlarmPicker selectedRowInComponent:0]+1;
    
    //주간 반복
    for(int i=0 ; i<7 ; i++){
        if([weekButn[i] isSelected])
            data1[14] += pow(2, 6-i);
    }
    
    //알람 방법
    data1[15] = [methodPicker selectedRowInComponent:0]+1;
    
    //반복 알람
    data1[16] = [repeatAlarmPicker selectedRowInComponent:0];
    
    //왼팔, 오른팔
    if([armButn[0] isSelected])
        data1[17] = 1;
    else
        data1[17] = 2;
    
    NSData* dataToSend = [[NSData alloc] initWithBytes:&data1 length:19];
    NSLog(@"%@",dataToSend);
//    [self sendDataToPeripheral:discoveredPeripheral data:dataToSend];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if([pickerView isEqual:preAlarmPicker]){
        return preAlarmData.count;
    }else if([pickerView isEqual:repeatAlarmPicker]){
        return repeatData.count;
    }else if([pickerView isEqual:methodPicker]){
        return methodData.count;
    }
    return 0;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if([pickerView isEqual:preAlarmPicker]){
        return preAlarmData[row];
    }else if([pickerView isEqual:repeatAlarmPicker]){
        return repeatData[row];
    }else if([pickerView isEqual:methodPicker]){
        return methodData[row];
    }
    return 0;
}
- (IBAction)a:(UIButton *)sender {
}
- (IBAction)abc:(UIButton *)sender forEvent:(UIEvent *)event {
}
@end
