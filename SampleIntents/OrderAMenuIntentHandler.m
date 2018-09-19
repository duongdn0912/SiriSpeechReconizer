//
//  OrderAMenuIntentHandler.m
//  SampleIntents
//
//  Created by admin on 2018/09/12.
//  Copyright © 2018年 Boris Polania. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderAMenuIntentHandler.h"

@interface OrderAMenuIntentHandler() <OrderAMenuIntentHandling>

@end

@implementation OrderAMenuIntentHandler


- (void)handleOrderAMenu:(nonnull OrderAMenuIntent *)intent completion:(nonnull void (^)(OrderAMenuIntentResponse * _Nonnull))completion {
    NSUserDefaults * usrInfo = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.boxyz.sirikit.SpeechTest"];
    [usrInfo setBool:YES forKey:@"ISNEWDATASENT"];  // This is the new data;
    [usrInfo setValue:@"コーヒー" forKey:@"siriInputedData"];
    [usrInfo synchronize];
    
    NSLog(@"%@ %@", intent.food, [[INObject alloc] displayString]);
    
    [[INObject alloc] displayString];
    
//    NSString *appUrlSchemes = @"com.boxyz.duong.SpeechTest://";
//    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appUrlSchemes]];
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([OrderAMenuIntent class])];
    OrderAMenuIntentResponse *response = [[OrderAMenuIntentResponse alloc] initWithCode:OrderAMenuIntentResponseCodeContinueInApp userActivity:userActivity];
    completion(response);
}

- (void)confirmOrderAMenu:(OrderAMenuIntent *)intent completion:(void (^)(OrderAMenuIntentResponse * _Nonnull))completion {
    NSLog(@"yo yo ye ye");
//    NSLog(@"%@ , %@ , % @ , , ", intent.food, intent.drink);
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([OrderAMenuIntent class])];
    OrderAMenuIntentResponse *response = [[OrderAMenuIntentResponse alloc] initWithCode:OrderAMenuIntentResponseCodeReady userActivity:userActivity];
    completion(response);
}

- (void)resolveOrderAMenu:(OrderAMenuIntent *)intent completion:(void (^)(OrderAMenuIntentResponse * _Nonnull))completion {
    NSLog(@"yes yes yes yes");
}

- (void)resolveContentForOrderAMenu:(OrderAMenuIntent *)intent withCompletion:(void (^)(INStringResolutionResult *resolutionResult))completion {
    NSLog(@"yes yes yes yes");
}

@end
