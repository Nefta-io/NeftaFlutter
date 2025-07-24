#import "Nefta.h"

@implementation Nefta

static Nefta *instance;
static FlutterMethodChannel *sharedChannel;

+(void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    sharedChannel = [FlutterMethodChannel methodChannelWithName: @"nefta" binaryMessenger: [registrar messenger]];
    Nefta *instance = [[Nefta alloc] init];
    [registrar addMethodCallDelegate: instance channel: sharedChannel];
}

+(Nefta *)shared {
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        instance = self;
    }
    return self;
}

-(void)initWithAppId:(NSString *)appId andNotify:(FlutterResult)result {
    if ([self isInitialized]) {
        result(@"already initilized");
        return;
    }
    
    self.isInitialized = YES;
    
    [self log: @"Initializing Nefta Flutter v%@...", NeftaPlugin.Version];
    
    if (appId == nil || appId.length == 0) {
        [self log: @"Unable to initialize Nefta SDK - missing appId"];
        return;
    }
    
    _plugin = [NeftaPlugin InitWithAppId: appId];
    _plugin.OnInsightsAsString = ^(NSInteger requestId, NSString * _Nullable insights) {
        [self OnInsights: (int)requestId insights: insights];
    };
    _plugin.OnReady = ^(NSDictionary<NSString *, Placement *> * placements) {
        result(@"initilized");
    };
}

-(void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *methodName = call.method;
    if ([@"init" isEqualToString: methodName]) {
        NSString *appId = call.arguments[@"appId"];
        [self initWithAppId: appId andNotify: result];
    } else if ([@"enableLogging" isEqualToString: methodName]) {
        bool enableLogging = ((NSNumber *)call.arguments[@"enable"]).boolValue;
        [NeftaPlugin EnableLogging: enableLogging];
    } else if ([@"record" isEqualToString: methodName]) {
        int type = ((NSNumber *)call.arguments[@"type"]).intValue;
        int category = ((NSNumber *)call.arguments[@"category"]).intValue;
        int subCategory = ((NSNumber *)call.arguments[@"subCategory"]).intValue;
        NSString *name = nil;
        id nameBox = call.arguments[@"name"];
        if ([nameBox isKindOfClass: [NSString class]]) {
            name = nameBox;
        }
        long value = ((NSNumber *)call.arguments[@"value"]).longValue;
        NSString *customPayload = nil;
        id customPayloadBox = call.arguments[@"customPayload"];
        if ([customPayloadBox isKindOfClass: [NSString class]]) {
            customPayload = customPayloadBox;
        }
        [_plugin RecordWithType: type category: category subCategory: subCategory name: name value: value customPayload: customPayload];
    } else if ([@"onExternalMediationRequestLoaded" isEqualToString: methodName]) {
        int adType = ((NSNumber *)call.arguments[@"adType"]).intValue;
        NSString *recommendedAdUnitId = nil;
        id recommendedAdUnitIdBox = call.arguments[@"recommendedAdUnitId"];
        if ([recommendedAdUnitIdBox isKindOfClass: [NSString class]]) {
            recommendedAdUnitId = recommendedAdUnitIdBox;
        }
        double calculatedFloorPrice = ((NSNumber *)call.arguments[@"calculatedFloorPrice"]).doubleValue;
        NSString *adUnitId = call.arguments[@"adUnitId"];
        double revenue = ((NSString*)call.arguments[@"revenue"]).doubleValue;
        NSString *precision = call.arguments[@"precision"];
        [self onExternalMediationRequest: adType recommendedAdUnitId: recommendedAdUnitId calculatedFloorPrice: calculatedFloorPrice adUnitId: adUnitId revenue: revenue precision: precision status: 1 providerStatus: nil networkStatus: nil];
    } else if ([@"onExternalMediationRequestFailed" isEqualToString: methodName]) {
        int adType = ((NSNumber *)call.arguments[@"adType"]).intValue;
        NSString *recommendedAdUnitId = nil;
        id recommendedAdUnitIdBox = call.arguments[@"recommendedAdUnitId"];
        if ([recommendedAdUnitIdBox isKindOfClass: [NSString class]]) {
            recommendedAdUnitId = recommendedAdUnitIdBox;
        }
        double calculatedFloorPrice = ((NSNumber *)call.arguments[@"calculatedFloorPrice"]).doubleValue;
        NSString *adUnitId = call.arguments[@"adUnitId"];
        int errorCode = ((NSNumber *)call.arguments[@"errorCode"]).intValue;
        int networkErrorCode = ((NSNumber *)call.arguments[@"networkErrorCode"]).intValue;
        NSString *providerStatus = [NSString stringWithFormat:@"%d", errorCode];
        NSString *networkStatus = [NSString stringWithFormat:@"%d", networkErrorCode];
        [self onExternalMediationRequest: adType recommendedAdUnitId: recommendedAdUnitId calculatedFloorPrice: calculatedFloorPrice adUnitId: adUnitId revenue: 0 precision: nil status: errorCode == 204 ? 2 : 0 providerStatus: providerStatus networkStatus: networkStatus];
    } else if ([@"onExternalMediationImpression" isEqualToString: methodName]) {
        NSString *data = call.arguments[@"data"];
        int adType = ((NSNumber *)call.arguments[@"adType"]).intValue;
        double revenue = ((NSString*)call.arguments[@"revenue"]).doubleValue;
        NSString *precision = call.arguments[@"precision"];
        [NeftaPlugin OnExternalMediationImpressionAsString: @"applovin-max" data: data adType: adType revenue: revenue precision: precision];
    } else if ([@"getInsights" isEqualToString: methodName]) {
        int requestId = ((NSNumber *)call.arguments[@"requestId"]).intValue;
        int insights = ((NSNumber *)call.arguments[@"insights"]).intValue;
        int timeout = ((NSNumber *)call.arguments[@"timeout"]).intValue;
        [_plugin GetInsightsBridge: requestId insights: insights timeout: timeout];
    } else if ([@"getNuid" isEqualToString: methodName]) {
        BOOL present = ((NSNumber *)call.arguments[@"present"]).boolValue;
        __unused NSString *nuid = [_plugin GetNuidWithPresent: present];
    } else if ([@"setOverride" isEqualToString: methodName]) {
        NSString *override = nil;
        id overrideBox = call.arguments[@"override"];
        if ([overrideBox isKindOfClass: [NSString class]]) {
            override = overrideBox;
        }
        [NeftaPlugin SetOverrideWithUrl: override];
    } else {
        [self log: @"unrecognized method: %@", methodName];
    }
}

-(void)onExternalMediationRequest:(int)adType recommendedAdUnitId:(NSString *)recommendedAdUnitId calculatedFloorPrice:(double)calculatedFloorPrice adUnitId:(NSString *)adUnitId revenue:(double)revenue precision:(NSString *)precision status:(int) status providerStatus:(NSString *)providerStatus networkStatus:(NSString *)networkStatus {
    [NeftaPlugin OnExternalMediationRequest: @"applovin-max" adType: adType recommendedAdUnitId: recommendedAdUnitId requestedFloorPrice: -1 calculatedFloorPrice: calculatedFloorPrice adUnitId: adUnitId revenue: revenue precision: precision status: status providerStatus: providerStatus networkStatus: networkStatus];
}

-(void)OnInsights:(int)requestId insights:(NSString *)insights {
    dispatch_async(dispatch_get_main_queue(), ^{
        [sharedChannel invokeMethod: @"onInsights" arguments: @{@"requestId": @(requestId), @"insights": insights}];
    });
}

-(void)log:(NSString *)format, ... {
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
    va_end(valist);
    
    NSLog(@"NeftaFlutter %@", message);
}
@end
