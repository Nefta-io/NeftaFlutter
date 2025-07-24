#import <Flutter/Flutter.h>
#import <NeftaSDK/NeftaSDK-Swift.h>

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow

@interface Nefta : NSObject<FlutterPlugin>

@property (nonatomic, strong, readonly, class) Nefta *shared;
@property (nonatomic, weak, readonly) NeftaPlugin *plugin;
@property (nonatomic, assign) BOOL isInitialized;
-(void)OnInsights:(int)requestId insights:(NSString *)insights;
-(void)log:(NSString *)format, ...;
@end
