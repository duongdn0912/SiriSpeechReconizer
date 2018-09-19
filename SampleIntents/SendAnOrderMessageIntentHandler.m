//
//  SendAOrderMessageIntentHandler.m
//  SampleIntents
//
//  Created by admin on 2018/09/13.
//  Copyright © 2018年 Boris Polania. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import "SendAnOrderMessageIntentHandler.h"

@interface SendAnOrderMessageIntentHandler() <SendAnOrderMessageIntentHandling>

@end

@implementation SendAnOrderMessageIntentHandler


//- (void)handleOrderAMenu:(nonnull OrderAMenuIntent *)intent completion:(nonnull void (^)(OrderAMenuIntentResponse * _Nonnull))completion {
//    NSUserDefaults * usrInfo = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.boxyz.sirikit.SpeechTest"];
//    [usrInfo setBool:YES forKey:@"ISNEWDATASENT"];  // This is the new data;
//    [usrInfo setValue:@"コーヒー" forKey:@"siriInputedData"];
//    [usrInfo synchronize];
//
//    NSLog(@"%@ %@", intent.food, intent.drink);
//
//    //    NSString *appUrlSchemes = @"com.boxyz.duong.SpeechTest://";
//    //    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appUrlSchemes]];
//
//    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([OrderAMenuIntent class])];
//    OrderAMenuIntentResponse *response = [[OrderAMenuIntentResponse alloc] initWithCode:OrderAMenuIntentResponseCodeContinueInApp userActivity:userActivity];
//    completion(response);
//}
//
//- (void)confirmOrderAMenu:(OrderAMenuIntent *)intent completion:(void (^)(OrderAMenuIntentResponse * _Nonnull))completion {
//    NSLog(@"yo yo ye ye");
//    //    NSLog(@"%@ , %@ , % @ , , ", intent.food, intent.drink);
//    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([OrderAMenuIntent class])];
//    OrderAMenuIntentResponse *response = [[OrderAMenuIntentResponse alloc] initWithCode:OrderAMenuIntentResponseCodeReady userActivity:userActivity];
//    completion(response);
//}
//
//- (void)resolveOrderAMenu:(OrderAMenuIntent *)intent completion:(void (^)(OrderAMenuIntentResponse * _Nonnull))completion {
//    NSLog(@"yes yes yes yes");
//}
//
//- (void)resolveContentForOrderAMenu:(OrderAMenuIntent *)intent withCompletion:(void (^)(INStringResolutionResult *resolutionResult))completion {
//    NSLog(@"yes yes yes yes");
//}

- (void)handleSendAnOrderMessage:(nonnull SendAnOrderMessageIntent *)intent
                      completion:(nonnull void (^)(SendAnOrderMessageIntentResponse * _Nonnull))completion {
    NSLog(@"%s is going", [[INObject alloc] displayString]);
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([SendAnOrderMessageIntent class])];
    SendAnOrderMessageIntentResponse *response = [[SendAnOrderMessageIntentResponse alloc] initWithCode:SendAnOrderMessageIntentResponseCodeSuccess userActivity:userActivity];
    completion(response);
}

- (void)confirmSendAnOrderMessage:(SendAnOrderMessageIntent *)intent
                       completion:(void (^)(SendAnOrderMessageIntentResponse * _Nonnull))completion {
    NSLog(@"%s is going", __func__);
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([SendAnOrderMessageIntent class])];
    SendAnOrderMessageIntentResponse *response = [[SendAnOrderMessageIntentResponse alloc] initWithCode:SendAnOrderMessageIntentResponseCodeReady userActivity:userActivity];
    completion(response);
}

//- (void)sendaorder
@end
