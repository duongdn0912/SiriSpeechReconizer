#import "ViewController.h"
#import "PXSiriWave.h"
#import "ApiClients.h"

@interface ViewController ()
    @property (weak, nonatomic) IBOutlet UILabel *regconizedText;
    @property (weak, nonatomic) IBOutlet UILabel *regconizerStatus;
    @property (weak, nonatomic) IBOutlet UILabel *regconizerKeyResponse;
    @end

@implementation ViewController

    NSTimer *timer;
    PXSiriWave *siriWave;
    NSString *inputText;
    
- (void)viewDidLoad {
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
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSUserDefaults * usrInfo = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.boxyz.sirikit.SpeechTest"];
    [usrInfo synchronize];// This is the new data;
    BOOL isNewDataSent = [usrInfo boolForKey:@"ISNEWDATASENT"];
    NSString *siriInputedData = [usrInfo valueForKey:@"siriInputedData"];
    
    if (isNewDataSent) {
        self.regconizedText.text = siriInputedData;
        [self pushTextToAPI:siriInputedData];
        [usrInfo setBool:NO forKey:@"ISNEWDATASENT"];  // This is the new data;
        [usrInfo synchronize];
    }
}

/*!
 * @brief Starts listening and recognizing user input through the phone's microphone
 */

- (void)startListening {
    
    // Initialize the AVAudioEngine
    audioEngine = [[AVAudioEngine alloc] init];
    
    // Make sure there's not a recognition task already running
    if (recognitionTask) {
        [recognitionTask cancel];
        recognitionTask = nil;
    }
    
    // Starts an AVAudio Session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    // Starts a recognition process, in the block it logs the input or stops the audio
    // process if there's an error.
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    recognitionRequest.shouldReportPartialResults = YES;
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result) {
            // Whatever you say in the mic after pressing the button should be being logged
            // in the console.
            NSString* resultText = result.bestTranscription.formattedString;
            NSLog(@"RESULT:%@",resultText);
            self.regconizedText.text = resultText;
            inputText = resultText;
            isFinal = !result.isFinal;
        }
        if (error) {
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

- (IBAction)microPhoneTapped:(id)sender {
    if (audioEngine.isRunning) {
        [self stopListenSession];
    } else {
        [self startListenSession];
    }
}

- (void)startListenSession {
    [self startListening];
    [self startSiriFakeAnimation];
}
    
- (void)stopListenSession {
    [audioEngine stop];
    [recognitionRequest endAudio];
    self.regconizerStatus.text = @"ボタンを押してください";
    
    [self pushTextToAPI:inputText];
    [self stopSiriFakeAnimation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
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

- (UIView *)createSiriFakeView {
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
    
- (void)startSiriFakeAnimationTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval: 0.001
                                             target:self
                                           selector: @selector(targetMethod:)
                                           userInfo: siriWave
                                            repeats:YES];
}

- (void)targetMethod:(NSTimer *)timer  {
    siriWave = [timer userInfo];
    [siriWave updateWithLevel: [self _normalizedPowerLevelFromDecibels: .1]];
}
    
- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels {
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

- (void)stopSiriFakeAnimation {
    [timer invalidate];
    timer = NULL;
    siriWave.hidden = YES;
}
    
- (void)pushTextToAPI:(NSString *)text {    
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

@end