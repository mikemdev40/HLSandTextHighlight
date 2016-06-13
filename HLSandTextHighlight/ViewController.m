//
//  AudioPlayerViewController.m
//  objectiveCapp1
//
//  Created by Michael Miller on 6/12/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

#import "ViewController.h"
@import AVFoundation;

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@end

@implementation ViewController {
    AVPlayer *player;
    AVPlayerItem *playerItem;
    CMTime duration;
    int myContext;
    NSUInteger previousIndex;
    NSRange previousRange;
}

-(void)setTextView:(UITextView *)textView {
    NSLog(@"did set");
    textView.editable = NO; //NOT self.textView.editable!!!!  we want to set the property on the argument, "textView", NOT the property/outlet on the class, which isn't yet fully connected yet, and will not set (trying to set a nil to NO!)
    _textView = textView;
}

- (IBAction)playButton:(UIButton *)sender {
    [player play];
}

- (IBAction)pauseButton:(UIButton *)sender {
    [player pause];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        if (change[@"new"]) {
            if ([change[@"new"] integerValue] == 1) {
                NSLog(@"a 1 detected");
                
                self.playButton.enabled = YES;
                duration = playerItem.duration;
                NSLog(@"%lld -- %d",duration.value, duration.timescale);
            }
        } else {
            NSLog(@"some other status change");
        }
    } else if ([keyPath isEqualToString:@"tracks"]) {
        //NSLog(@"track updated");
    }
}

- (void)highlightTextAtTime:(CMTime)currentTime {
    if (duration.value > 0) {
        
        double durationSeconds = duration.value / duration.timescale;
        double currentTimeSeconds = currentTime.value / currentTime.timescale;
        double fraction = currentTimeSeconds / durationSeconds;
        
        NSUInteger textLength = self.textView.textStorage.length;
        NSUInteger currentIndex = fraction * textLength;
        NSUInteger lengthOfRange = currentIndex - previousIndex;
        
        NSRange rangeToHighlight = NSMakeRange(previousIndex, lengthOfRange);
        
        //    NSLog(@"%f   %ld    %ld", fraction, textLength, currentIndex);
        
        //unhighlight previous range
        [self.textView.textStorage addAttribute:NSBackgroundColorAttributeName value:[UIColor yellowColor] range:rangeToHighlight];
        
        //highlight new range
        [self.textView.textStorage addAttribute:NSBackgroundColorAttributeName value:[UIColor clearColor] range:previousRange];
        
        previousIndex = currentIndex;
        previousRange = rangeToHighlight;
    }
}

- (void)setupPlayerTimers {
    
    CMTime timeInterval = CMTimeMake(1, 1);
    
    ViewController * __weak weakSelf = self;
    
    [player addPeriodicTimeObserverForInterval:timeInterval
                                         queue:dispatch_get_main_queue()
                                    usingBlock:^(CMTime time) {
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [weakSelf highlightTextAtTime:time];
                                        });
                                    }];
}

- (void)loadText {
    NSString *textFileURL = [[NSBundle mainBundle] pathForResource:@"testtext" ofType:@".txt"];
    
    NSError *error;
    NSString *loadedText = [[NSString alloc] initWithContentsOfFile:textFileURL encoding:NSUTF8StringEncoding error:&error];
    
    if (error == nil) {
        self.textView.text = loadedText;
    } else {
        NSLog(@"%@", error);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadText];
    
    NSURL *playerItemURL = [[NSURL alloc] initWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
    
    playerItem = [[AVPlayerItem alloc] initWithURL:playerItemURL];
    player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    self.playButton.enabled = NO;
    
    myContext = 0;
    previousIndex = 0;
    
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:&myContext];
    
    [playerItem addObserver:self
                 forKeyPath:@"tracks"
                    options:NSKeyValueObservingOptionNew
                    context:&myContext];
    
    [self setupPlayerTimers];
    
}

- (void)dealloc {
    [playerItem removeObserver:self forKeyPath:@"status" context:&myContext];
    [playerItem removeObserver:self forKeyPath:@"tracks" context:&myContext];
}

@end
