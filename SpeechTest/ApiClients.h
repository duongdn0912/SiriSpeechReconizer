#import <Foundation/Foundation.h>

@interface ApiClients : NSObject

+ (void)sentTextToAnalyticServer:(NSString *)text
                         success:(void (^)(id responseObject))success
                         failure:(void (^)(id responseObject))failure;
    
@end

