#import "Nefta.h"

@implementation Nefta

static Nefta *instance;
static FlutterMethodChannel *sharedChannel;

NSString *const _provider = @"applovin-max";

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
    _plugin.OnInsightsAsString = ^(NSInteger requestId, NSInteger adapterResponseType, NSString * _Nullable adapterResponse) {
        [self OnInsights: (int)requestId adapterResponseType: (int)adapterResponseType adapterResponse: adapterResponse];
    };
    _plugin.OnReady = ^(InitConfiguration * initConfig) {
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
    } else if ([@"onExternalMediationRequest" isEqualToString: methodName]) {
        int adType = ((NSNumber *)call.arguments[@"adType"]).intValue;
        NSString *id0 = nil;
        id id0Box = call.arguments[@"id"];
        if ([id0Box isKindOfClass: [NSString class]]) {
            id0 = id0Box;
        }
        NSString *requestedAdUnitId = nil;
        id requestedAdUnitIdBox = call.arguments[@"requestedAdUnitId"];
        if ([requestedAdUnitIdBox isKindOfClass: [NSString class]]) {
            requestedAdUnitId = requestedAdUnitIdBox;
        }
        double requestedFloorPrice = ((NSNumber *)call.arguments[@"requestedFloorPrice"]).doubleValue;
        int adOpportunityId = ((NSNumber *)call.arguments[@"adOpportunityId"]).intValue;
        [NeftaPlugin OnExternalMediationRequest: _provider adType: adType id: id0 requestedAdUnitId: requestedAdUnitId requestedFloorPrice: requestedFloorPrice adOpportunityId: adOpportunityId];
    } else if ([@"onExternalMediationResponse" isEqualToString: methodName]) {
        NSString *id0 = call.arguments[@"id"];
        double revenue = ((NSNumber *)call.arguments[@"revenue"]).doubleValue;
        NSString *precision = nil;
        id precisionBox = call.arguments[@"precision"];
        if ([precisionBox isKindOfClass: [NSString class]]) {
            precision = precisionBox;
        }
        int status = ((NSNumber *)call.arguments[@"status"]).intValue;
        NSString *providerStatus = nil;
        id providerStatusBox = call.arguments[@"providerStatus"];
        if ([providerStatusBox isKindOfClass: [NSString class]]) {
            providerStatus = providerStatusBox;
        }
        [NeftaPlugin OnExternalMediationResponse: _provider id: id0 id2: nil revenue: revenue precision: precision status: status providerStatus: providerStatus networkStatus: nil];
    } else if ([@"onExternalMediationImpression" isEqualToString: methodName]) {
        bool isClick = call.arguments[@"isClick"];
        NSString *data = call.arguments[@"data"];
        NSString *id0 = call.arguments[@"id"];
        [NeftaPlugin OnExternalMediationImpressionAsString: isClick provider: _provider data: data id: id0 id2: nil];
    } else if ([@"getInsights" isEqualToString: methodName]) {
        int requestId = ((NSNumber *)call.arguments[@"requestId"]).intValue;
        int previousAdOpportunity = ((NSNumber *)call.arguments[@"adOpportunityId"]).intValue;
        int insights = ((NSNumber *)call.arguments[@"insights"]).intValue;
        int timeout = ((NSNumber *)call.arguments[@"timeout"]).intValue;
        [_plugin GetInsightsBridge: requestId insights: insights previousAdOpportunityId: previousAdOpportunity timeout: timeout];
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

- (void)OnInsights:(int)requestId adapterResponseType:(int)adapterResponseType adapterResponse:(NSString *)adapterResponse {
    dispatch_async(dispatch_get_main_queue(), ^{
        [sharedChannel invokeMethod: @"onInsights"
                          arguments: @{@"requestId": @(requestId),
                                       @"adapterResponseType": @(adapterResponseType),
                                       @"adapterResponse": adapterResponse }];
    });
}

- (void)log:(NSString *)format, ... {
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
    va_end(valist);
    
    NSLog(@"NeftaFlutter %@", message);
}

@end
