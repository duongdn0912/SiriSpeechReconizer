#import <UIKit/UIKit.h>
#import <Speech/Speech.h>

@interface ViewController : UIViewController <SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate, UITableViewDelegate, UITableViewDataSource> {
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    AVAudioEngine *audioEngine;
}

@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;



@end

