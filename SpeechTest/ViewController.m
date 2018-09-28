#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Intents/Intents.h>

#import "ViewController.h"
#import "PXSiriWave.h"
#import "ApiClients.h"
#import "OrderAMenuIntent.h"
#import "SendAnOrderMessageIntent.h"

#define LUIS_API @"https://westus.api.cognitive.microsoft.com/luis/v2.0/apps/f49530b9-2871-4d65-9532-a0aeec393a22?subscription-key=1f51c767b9d24b118a7415281806acf7&timezoneOffset=-360&q="
#define KEY_ORDER @"注文"
#define KEY_CANCEL_ORDER @"キャンセル"
#define KEY_FINISH_ORDER @"終了"
#define KEY_NONE_ORDER @"None"

#define KEY_RESPONSE_TOPSCOREINTENT @"topScoringIntent"
#define KEY_RESPONSE_TOPSCOREINTENT_SCORE @"score"
#define KEY_RESPONSE_TOPSCOREINTENT_INTENT @"intent"

#define KEY_RESPONSE_INTENTS @"intents"
#define KEY_RESPONSE_QUERY @"query"
#define KEY_RESPONSE_ENTITIES @"entities"

#define KEY_RESPONSE_ENTITY_CONTENT @"entity"
#define KEY_RESPONSE_ENTITY_TYPE @"type"
#define KEY_RESPONSE_ENTITY_TYPE_MENU @"menu"
#define KEY_RESPONSE_ENTITY_TYPE_NUMBER @"builtin.number"
#define KEY_RESPONSE_ENTITY_TYPE_NUMBER_ORDER_JP @"numberOfOrder"
#define KEY_RESPONSE_ENTITY_TYPE_NUMBER_JP @"numberJp"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *regconizedText;
@property (weak, nonatomic) IBOutlet UILabel *regconizerStatus;
@property (weak, nonatomic) IBOutlet UILabel *regconizerKeyResponse;
@property (weak, nonatomic) IBOutlet UITextView *responseJson;
@property (weak, nonatomic) IBOutlet UITableView *tableOrderedMenu;
@property (weak, nonatomic) IBOutlet UIButton *redoOrder;
@end

typedef NS_ENUM(NSInteger, orderStage) {
    OrderingFood,
    CancelingFood,
    FinishingOrder,
    ConfirmingOrder,
    StopOrder
};

@implementation ViewController

NSTimer *siriTimer;
PXSiriWave *siriWave;
NSString *inputText;
NSInteger actionOfOrder;
NSMutableDictionary *tableViewData;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Initialize the Speech Recognizer with the locale, couldn't find a list of locales
    // but I assume it's standard UTF-8 https://wiki.archlinux.org/index.php/locale
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
    
    // Set speech recognizer delegate
    speechRecognizer.delegate = self;
    
    // Request the authorization to make sure the user is asked for permission so you can
    // get an authorized response, also remember to change the .plist file, check the repo's
    // readme file or this projects info.plist
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                NSLog(@"Authorized");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                NSLog(@"Denied");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                NSLog(@"Not Determined");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                NSLog(@"Restricted");
                break;
            default:
                break;
        }
    }];
    
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    self.synthesizer.delegate = self;
    
    self.tableOrderedMenu.dataSource = self;
    self.tableOrderedMenu.delegate = self;
    
    tableViewData = [[NSMutableDictionary alloc] init];
    
    //    [self donateInteraction];
    //    [self donateRelevantShortcut];
    //    [self donateDefaultSendMessageInteration];
}

-(void) speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"Playback finished");
    if (actionOfOrder != StopOrder) {
        [self startListening];
        [self startSiriFakeAnimation];
    }
}

- (void) speechText:(NSString *)text {
    [audioEngine stop];
    [recognitionRequest endAudio];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.responseJson.text = text;
        
        [self.tableOrderedMenu reloadData];
    });
    
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:text];
//    utterance.rate = 0.5;
    utterance.pitchMultiplier = 1;
    //utterance.rate = AVSpeechUtteranceMinimumSpeechRate;
    utterance.volume = 1;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja-JP"];
    [self.synthesizer speakUtterance:utterance];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self speechText:@"ご注文をどうぞ"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableViewData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"cellReuseIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
    
    // Here we use the provided setImageWithURL: method to load the web image
    // Ensure you use a placeholder image otherwise cells will be initialized with no image
    UILabel *lblMenuName = [cell viewWithTag:2];
    UILabel *lblMenuQuantity = [cell viewWithTag:3];
//    [tableViewData object]
    
    NSString *menuName = [tableViewData allKeys][indexPath.row];
    NSNumber *menuQuantity = [tableViewData objectForKey:menuName];
    lblMenuName.text = menuName;
    lblMenuQuantity.text = [menuQuantity stringValue];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


/*!
 * @brief Starts listening and recognizing user input through the phone's microphone
 */

- (void) startListening {
    
    // Initialize the AVAudioEngine
    audioEngine = [[AVAudioEngine alloc] init];
    
    
    // Make sure there's not a recognition task already running
    if (recognitionTask || recognitionRequest) {
        [recognitionTask cancel];
        recognitionTask = nil;
        recognitionRequest = nil;
    }
    
    // Starts an AVAudio Session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    // Starts a recognition process, in the block it logs the input or stops the audio
    // process if there's an error.
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    recognitionRequest.shouldReportPartialResults = YES;
    __block NSTimer *stopRegconitionWhenNotInputTimer;
    __block BOOL isSentLUIS = NO;
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __block BOOL isFinal = NO;
        NSString* resultText;
        if (result) {
            // Whatever you say in the mic after pressing the button should be being logged
            // in the console.
            resultText = result.bestTranscription.formattedString;
            NSLog(@"RESULT:%@",resultText);
            
            inputText = resultText;
            isFinal = result.isFinal;
        }
        
        if (stopRegconitionWhenNotInputTimer.isValid) {
            if (isFinal) {
                [stopRegconitionWhenNotInputTimer invalidate];
            }
        } else {
            stopRegconitionWhenNotInputTimer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
                if (!isSentLUIS) {
                    isSentLUIS = YES;
                    [self stopListenSession];
                    isFinal = YES;
                    [stopRegconitionWhenNotInputTimer invalidate];
                }
            }];
        }
        
        if (error || isFinal) {
            [audioEngine stop];
            [inputNode removeTapOnBus:0];
            recognitionRequest = nil;
            recognitionTask = nil;
        }
    }];
    
    // Sets the recording format
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    // Starts the audio engine, i.e. it starts listening.
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"Say Something, I'm listening");
    self.regconizerStatus.text = @"ボタンを押して、サーバに出す";
}

- (IBAction) microPhoneTapped:(id)sender {
    if (audioEngine.isRunning) {
        [self stopListenSession];
    } else {
        [self startListenSession];
    }
}

- (void) startListenSession {
//    [self speechText:@"ご注文をどうぞ"];
    [self startListening];
    [self startSiriFakeAnimation];
}

- (void) stopListenSession {
    [audioEngine stop];
    [recognitionRequest endAudio];
//    self.regconizerStatus.text = @"ボタンを押してください";
    
    //    [self pushTextToAPI:inputText];
    self.regconizedText.text = inputText;
    [self requestLUISAPI:inputText];
    [self stopSiriFakeAnimation];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void) speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"Availability:%d",available);
}

- (void)startSiriFakeAnimation {
    if (siriWave) {
        siriWave.hidden = NO;
    } else {
        [self.view addSubview: [self createSiriFakeView]];
    }
    
    [self startSiriFakeAnimationTimer];
}

- (UIView *) createSiriFakeView {
    CGFloat siriWidth = self.view.frame.size.width;
    CGFloat siriHeight = 80;
    CGFloat siriFrameY = self.view.frame.size.height - siriHeight;
    
    siriWave = [[PXSiriWave alloc] initWithFrame: CGRectMake(0, siriFrameY, siriWidth, siriHeight)];
    siriWave.backgroundColor = [UIColor clearColor];
    siriWave.frequency = 1.5;
    siriWave.amplitude = 0.01;
    siriWave.intensity = 0.3;
    
    siriWave.colors = [NSArray arrayWithObjects: [UIColor redColor],
                       [UIColor colorWithRed:33 green:123 blue:237 alpha:0.92],
                       [UIColor colorWithRed:59 green:161 blue:149 alpha:1], nil];
    
    [siriWave configure];
    
    return siriWave;
}

- (void) startSiriFakeAnimationTimer {
    siriTimer = [NSTimer scheduledTimerWithTimeInterval: 0.001
                                             target:self
                                           selector: @selector(targetMethod:)
                                           userInfo: siriWave
                                            repeats:YES];
}

- (void) targetMethod:(NSTimer *)timer  {
    siriWave = [timer userInfo];
//    const double ALPHA = 0.05;
//    double peakPowerForChannel = pow(10, (0.05 * [audioEngine peakPowerForChannel:0]));
//    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
//    [audioEngine ]
    [siriWave updateWithLevel: [self _normalizedPowerLevelFromDecibels: .1]];
}

- (CGFloat) _normalizedPowerLevelFromDecibels:(CGFloat)decibels {
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

- (void) stopSiriFakeAnimation {
    [siriTimer invalidate];
    siriTimer = NULL;
    siriWave.hidden = YES;
}

- (void) pushTextToAPI:(NSString *)text {
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://eastasia.api.cognitive.microsoft.com/text/analytics/v2.0/keyPhrases"]];
    //    NSString *userUpdate =[NSString stringWithFormat:@"{'documents':[{'language': 'ja','id': '1','text':'%@'}]}'", text];
    //    {"documents":[{"language": "ja","id": "1","text": "私はコーヒーが欲しいです"}]}
    NSDictionary *textInfo= @{ @"language" : @"ja", @"id" : @"1", @"text" : text};
    NSDictionary *tranferData = @{ @"documents" : [NSArray arrayWithObjects:textInfo, nil] };
    
    NSString* apiKey = @"b86e20c8e2754b2093a19a7038d440d7";
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:apiKey forHTTPHeaderField:@"Ocp-Apim-Subscription-Key"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tranferData options:NSJSONWritingSortedKeys error:nil];
    
    NSLog(@"JSON = %@", [[NSString alloc] initWithData:postdata encoding:
                         NSUTF8StringEncoding]);
    
    [urlRequest setHTTPBody:postdata];
    
    __block NSString *responseText = @"";
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 200) {
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            NSArray *documents = responseDictionary[@"documents"];
            NSArray *keyPhrases = documents.firstObject[@"keyPhrases"];
            for (NSString *key in keyPhrases) {
                responseText = [responseText stringByAppendingString:[NSString stringWithFormat:@"%@｜", key]];
            }
            NSLog(@"The response is - %@", responseText);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.regconizerKeyResponse.text = responseText;
            });
        }
        else
        {
            NSLog(@"Error");
        }
    }];
    
    [dataTask resume];
}

- (void) requestLUISAPI:(NSString *)inputedRequest{
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", LUIS_API, [inputedRequest stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
    
    __block NSString *responseText = @"";
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 200) {
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            
            if (responseDictionary) {
                [self navigateRequest:responseDictionary];
            }
            
//            NSString *jsonString;
//            NSError *error;
//            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseDictionary
//                                                               options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
//                                                                 error:&error];
//
//            if (! jsonData) {
//                NSLog(@"Got an error: %@", error);
//            } else {
//                jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//            }
//
//            //            for (NSString *key in keyPhrases) {
//            //            responseText = [responseText stringByAppendingString:[NSString stringWithFormat:@"%@｜", key]];
//            //            }
//            NSLog(@"The response is - %@", responseText);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                //                self.regconizerKeyResponse.text = jsonString;
//                self.responseJson.text = jsonString;
//            });
        }
        else
        {
            NSLog(@"Error");
        }
    }];
    
    [dataTask resume];
}

- (void) navigateRequest:(NSDictionary *)responseDictionary {
    NSDictionary *topScoringIntentData = [responseDictionary valueForKey:KEY_RESPONSE_TOPSCOREINTENT];
    NSDictionary *topScoringIntentScore = [topScoringIntentData valueForKey:KEY_RESPONSE_TOPSCOREINTENT_SCORE];
    NSString *topScoringIntent = [topScoringIntentData valueForKey:KEY_RESPONSE_TOPSCOREINTENT_INTENT];
    
    NSDictionary *intents = [responseDictionary valueForKey:KEY_RESPONSE_INTENTS];
    NSDictionary *query = [responseDictionary valueForKey:KEY_RESPONSE_QUERY];
    NSDictionary *entities = [responseDictionary valueForKey:KEY_RESPONSE_ENTITIES];
    
//    [self stopListenSession];
    if ([topScoringIntent isEqualToString:KEY_ORDER]) {
        [self preparingOrderMenus:entities];
    } else if ([topScoringIntent isEqualToString:KEY_CANCEL_ORDER]) {
        [self cancelingOrderMenus:entities];
    } else if ([topScoringIntent isEqualToString:KEY_FINISH_ORDER]) {
        [self finishOrder];
    } else if ([topScoringIntent isEqualToString:KEY_NONE_ORDER]) {
        if (actionOfOrder == FinishingOrder) {
            if ([query isEqual:@"はい"]) {
                NSString *speechPhrase = @"注文を完了しました。";
                [self speechText:speechPhrase];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.redoOrder.hidden = NO;
                });
                actionOfOrder = StopOrder;
            } else {
                NSString *speechPhrase = @"ご注文をどうぞ";
                [self speechText:speechPhrase];
                actionOfOrder = OrderingFood;
            }
        } else {
            [self confirmOrder];
        }
    }
}

- (void) preparingOrderMenus:(NSDictionary *)entities {
    NSLog(@"%s", __func__);
    
    NSMutableArray *menus = [[NSMutableArray alloc] init];
    NSMutableArray *quantities = [[NSMutableArray alloc] init];
    
    for (NSDictionary *entity in entities) {
        if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_MENU]) {
            [menus addObject:[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT]];
        } else if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER]
                   || [[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_JP]
                   || [[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_ORDER_JP]) {
            if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_ORDER_JP]) {
                NSString* numberOfOrder = [[[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT] componentsSeparatedByString:@"個"] firstObject];
                [quantities addObject:numberOfOrder];
            } else if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_JP]) {
                NSString* numberOfOrder = [[[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT] componentsSeparatedByString:@"つ"] firstObject];
                [quantities addObject:numberOfOrder];
            } else {
                [quantities addObject:[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT]];
            }
        }
    }
    
    [self orderMenu:menus quantity:quantities];
}

- (void) cancelingOrderMenus:(NSDictionary *)entities {
    NSLog(@"%s", __func__);
    
    NSMutableArray *menus = [[NSMutableArray alloc] init];
    NSMutableArray *quantities = [[NSMutableArray alloc] init];
    
    for (NSDictionary *entity in entities) {
        if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_MENU]) {
            [menus addObject:[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT]];
        } else if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER]
                   || [[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_JP]
                   || [[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_ORDER_JP]) {
            if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_ORDER_JP]) {
                NSString* numberOfOrder = [[[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT] componentsSeparatedByString:@"個"] firstObject];
                [quantities addObject:numberOfOrder];
            } else if ([[entity objectForKey:KEY_RESPONSE_ENTITY_TYPE] isEqualToString:KEY_RESPONSE_ENTITY_TYPE_NUMBER_JP]) {
                NSString* numberOfOrder = [[[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT] componentsSeparatedByString:@"つ"] firstObject];
                [quantities addObject:numberOfOrder];
            } else {
                [quantities addObject:[entity objectForKey:KEY_RESPONSE_ENTITY_CONTENT]];
            }
        }
    }
    
    [self cancelMenu:menus quantity:quantities];
}

- (void) orderMenu:(NSArray *)foodName quantity:(NSArray *)quantity {
    NSString *food = [foodName count] != 0 ? [foodName firstObject] : @"";
    NSInteger number = [quantity count] != 0 ? [[quantity firstObject] integerValue] : 1;
    
    NSInteger foodQuantity = [[tableViewData objectForKey:food] integerValue];
    if (foodQuantity >= 0) {
        foodQuantity = foodQuantity + number;
        [tableViewData removeObjectForKey:food];
        [tableViewData setValue:[NSNumber numberWithInteger:foodQuantity]  forKey:food];
    } else {
        [tableViewData setValue:[NSNumber numberWithInteger:number]  forKey:food];
    }
    NSString *speechPhrase = [NSString stringWithFormat:@"%@を%ldですね。他にご注文・キャンセルはありますか？", food, (long)number];
    [self speechText:speechPhrase];
    actionOfOrder = OrderingFood;
}

- (void) cancelMenu:(NSArray *)foodName quantity:(NSArray *)quantity {
    NSString *food = [foodName count] != 0 ? [foodName firstObject] : @"";
    NSInteger number = [quantity count] != 0 ? [[quantity firstObject] integerValue] : 1;
    
    if ([food isEqualToString:@""]) {
        [self confirmOrder];
    } else {
        NSInteger foodQuantity = [[tableViewData objectForKey:food] integerValue];
        NSInteger numberOfOrderAfterCancel = foodQuantity - number;
        
        [tableViewData removeObjectForKey:food];
        if (numberOfOrderAfterCancel > 0) {
            [tableViewData setValue:[NSNumber numberWithInteger:numberOfOrderAfterCancel]  forKey:food];
        }
        NSString *speechPhrase = [NSString stringWithFormat:@"%@を%ldキャンセルですね。他にご注文・キャンセルはありますか？", food, (long)number];
        [self speechText:speechPhrase];
        actionOfOrder = CancelingFood;
    }
}

- (void) finishOrder {
    NSString *speechPhrase = [NSString stringWithFormat:@"表示されている注文内容をご確認ください。よろしければ”はい”と言ってください"];
    [self speechText:speechPhrase];
   
    actionOfOrder = FinishingOrder;
}

- (void) confirmOrder {
    NSString *speechPhrase = [NSString stringWithFormat:@"すみません、聞き取れませんでした。他にご注文は？"];
    [self speechText:speechPhrase];
    actionOfOrder = ConfirmingOrder;
}


- (void) donateRelevantShortcut {
    OrderAMenuIntent *intent = [[OrderAMenuIntent alloc] init];
    intent.food = @"cake";
    intent.drink = @"cheese";
    
    INShortcut *shortcut = [[INShortcut alloc] initWithIntent:intent];
    
    INRelevantShortcut *relevantShortcut = [[INRelevantShortcut alloc] initWithShortcut:shortcut];
    relevantShortcut.relevanceProviders = @[[[INDailyRoutineRelevanceProvider alloc] initWithSituation:INDailyRoutineSituationEvening]];
    [[INRelevantShortcutStore defaultStore] setRelevantShortcuts:@[relevantShortcut] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"error with donate relevant shortcut");
        } else {
            NSLog(@"succeed in donate relevant shortcut");
        }
        
    }];
    
}

- (void) donateDefaultSendMessageInteration {
    INSendMessageIntent *intent = [[INSendMessageIntent alloc] init];
    //    intent.food = @"cake";
    //    intent.drink = @"orange";
    intent.suggestedInvocationPhrase = @"Order coffee";
    
    INInteraction *interaction = [[INInteraction alloc] initWithIntent:intent response:nil];
    
    [interaction donateInteractionWithCompletion:^(NSError * _Nullable error) {
        //        if (error != nil) {
        if (error) {
            NSLog(@"error");
        } else {
            NSLog(@"success donated interaction");
        }
        //        }
    }];
}

- (void) donateSendMessageInteration {
    SendAnOrderMessageIntent *intent = [[SendAnOrderMessageIntent alloc] init];
    intent.food = @"cake";
    //    intent.drink = @"orange";
    //    intent.suggestedInvocationPhrase = @"Order time";
    
    INInteraction *interaction = [[INInteraction alloc] initWithIntent:intent response:nil];
    
    [interaction donateInteractionWithCompletion:^(NSError * _Nullable error) {
        //        if (error != nil) {
        if (error) {
            NSLog(@"error");
        } else {
            NSLog(@"success donated interaction");
        }
        //        }
    }];
}

- (void) donateInteraction {
    OrderAMenuIntent *intent = [[OrderAMenuIntent alloc] init];
    intent.food = @"cake";
    //    intent.drink = @"orange";
    //    intent.suggestedInvocationPhrase = @"Order time";
    
    INInteraction *interaction = [[INInteraction alloc] initWithIntent:intent response:nil];
    
    [interaction donateInteractionWithCompletion:^(NSError * _Nullable error) {
        //        if (error != nil) {
        if (error) {
            NSLog(@"error");
        } else {
            NSLog(@"success donated interaction");
        }
        //        }
    }];
}
- (IBAction)redoOrderTapped:(id)sender {
    [tableViewData removeAllObjects];
    [self.tableOrderedMenu reloadData];
    NSString *speechPhrase = @"ご注文をどうぞう";
    [self speechText:speechPhrase];
    actionOfOrder = OrderingFood;
    self.redoOrder.hidden = YES;
}


@end
