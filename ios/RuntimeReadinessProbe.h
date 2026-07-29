#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NSDictionary<NSString*, id>* SporeBridgeRunRuntimeReadinessProbe(void);
NSString* SporeBridgeRuntimeReadinessSummary(
    NSDictionary<NSString*, id>* report);

NS_ASSUME_NONNULL_END
