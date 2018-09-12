#import "ApiClients.h"
#import "AFNetworking.h"
#import "AppDelegate.h"

#define API_TEXT_ANALYTIC @"https://eastasia.api.cognitive.microsoft.com/text/analytics/v2.0/keyPhrases"

@implementation ApiClients

+ (AFHTTPSessionManager*)addBasicAuth:(AFHTTPSessionManager*)manager {
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
//    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:BASIC_AUTH_ID password:BASIC_AUTH_PW];
    
    NSString* apiKey = @"b86e20c8e2754b2093a19a7038d440d7";
    [manager.requestSerializer setValue:apiKey forHTTPHeaderField:@"Ocp-Apim-Subscription-Key"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    return manager;
}

+ (AFHTTPSessionManager*)getManager {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 10;
    manager.responseSerializer             = [AFJSONResponseSerializer serializer];
    NSMutableSet* acceptableContentTypes = [[NSMutableSet alloc] initWithSet:[manager.responseSerializer acceptableContentTypes]];
    [acceptableContentTypes addObject:@"application/json"];
//    [acceptableContentTypes addObject:@"text/plain"];
    
    manager.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    
    return manager;
}

+ (void)sentTextToAnalyticServer:(NSString *)text
             success:(void (^)(id responseObject))success
             failure:(void (^)(id responseObject))failure {
    
    AFHTTPSessionManager* manager = [self getManager];
    manager = [self addBasicAuth:manager];
    NSMutableDictionary* params = [NSMutableDictionary new];
    NSMutableDictionary* data = [NSMutableDictionary new];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    [params setObject:@"ja" forKey:@"language"];
    [params setObject:@"1" forKey:@"id"];
    [params setObject:text forKey:@"text"];
    [data setObject:params forKey:@"documents"];
    
    
    [manager POST:API_TEXT_ANALYTIC parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(failure) {
            failure(error);
        }
    }];
    
}

@end
