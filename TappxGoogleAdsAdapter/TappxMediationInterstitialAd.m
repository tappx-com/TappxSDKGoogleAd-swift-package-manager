//
//  TAPPXMediationInterstitialAd.m
//
//  Created by Tappx on 28/05/15.
//
//

#import "TappxMediationInterstitialAd.h"
#import <stdatomic.h>

@interface TappxMediationInterstitialAd () {
    TappxInterstitialAd *interstitialAd;
    
    GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;
    
    id <GADMediationInterstitialAdEventDelegate> _adEventDelegate;
}
@end

@implementation TappxMediationInterstitialAd

- (void)dealloc {
    if(interstitialAd != nil){
        interstitialAd = nil;
    }
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
      __block GADMediationInterstitialLoadCompletionHandler
          originalCompletionHandler = [completionHandler copy];

      _loadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
          _Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error) {
        // Only allow completion handler to be called once.
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
          return nil;
        }

        id<GADMediationInterstitialAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
          // Call original handler and hold on to its return value.
          delegate = originalCompletionHandler(ad, error);
        }

        // Release reference to handler. Objects retained by the handler will also
        // be released.
        originalCompletionHandler = nil;

        return delegate;
      };
    
    NSString *adUnit = adConfiguration.credentials.settings[@"parameter"];
    
    if ( adUnit != nil ) {
        
        NSArray *elements = [adUnit componentsSeparatedByString:@"|"];
        NSString* key = adUnit;
        NSString* isTest = nil;
        NSString* endpoint = nil;
        if ( [elements count]  > 1 ){
            key = [elements objectAtIndex: 0];
            if ( [elements count]  > 1 )
                isTest = [elements objectAtIndex: 1];
        }else{
            elements = [adUnit componentsSeparatedByString:@":"];
            if ( [elements count]  > 1 ){
                key = [elements objectAtIndex: 0];
                for(int i = 1; i < [elements count]; i++) {
                    NSArray *extraElements = [[elements objectAtIndex:i] componentsSeparatedByString:@"="];
                    if ( [extraElements count] > 1 ){
                        if([[extraElements objectAtIndex:0] isEqualToString:@"e"] && ![[extraElements objectAtIndex:1] isEqualToString:@""] && [[extraElements objectAtIndex:1] length] > 3)
                            endpoint = [extraElements objectAtIndex:1];
                        if([[extraElements objectAtIndex:0] isEqualToString:@"t"] && ![[extraElements objectAtIndex:1] isEqualToString:@""])
                            isTest = [extraElements objectAtIndex:1];
                    }
                }
            }
        }
        if ( isTest != nil && [isTest isEqualToString:@"1" ] )
            [TappxFramework addTappxKey:key testMode:YES];
        else {
            [TappxFramework addTappxKey:key fromNonNative:@"googleAd"];
        }
        if (endpoint != nil && ![endpoint isEqualToString:@""] && [endpoint length] > 3){
            [TappxFramework setEndpoint:endpoint];
        }
    } else {
        _adEventDelegate = _loadCompletionHandler(nil, [NSError errorWithDomain:GADErrorDomain code:GADErrorInvalidRequest userInfo:nil]);
        return;
    }
        
    
    interstitialAd = [[TappxInterstitialAd alloc] initWithDelegate:self];
    [interstitialAd load];
}

+ (GADVersionNumber)adSDKVersion {
    NSArray *versionComponents = [TappxFramework.versionSDK componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count >= 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}


+ (GADVersionNumber)adapterVersion {
    NSArray *versionComponents = [TappxFramework.versionSDK componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count >= 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}


+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

- (void)tappxInterstitialAdDidFinishLoad:(nonnull TappxInterstitialAd *)interstitialAd{
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)tappxInterstitialAdDidPress:(nonnull TappxInterstitialAd *)interstitialAd{
    [_adEventDelegate reportClick];
}

- (void)tappxInterstitialAdDidClose:(nonnull TappxInterstitialAd *)interstitialAd{
    [_adEventDelegate didDismissFullScreenView];
}

- (void)tappxInterstitialAdDidFail:(nonnull TappxInterstitialAd *)interstitialAd withError:(nonnull TappxErrorAd *)error{
    _adEventDelegate = _loadCompletionHandler(nil, [self convertError:error]);
}

- (void)tappxInterstitialAdDidAppear:(nonnull TappxInterstitialAd *)interstitialAd {
    [_adEventDelegate reportImpression];
}

- (void)tappxInterstitialAdDismissed:(nonnull TappxInterstitialAd *)interstitialAd {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if([interstitialAd isReady]) {
        [_adEventDelegate willPresentFullScreenView];
        [interstitialAd showFrom:viewController];
    } else {
        [_adEventDelegate didFailToPresentWithError:[NSError errorWithDomain:GADErrorDomain code:GADErrorInternalError userInfo:nil]];
    }
}

- (NSError *) convertError:(TappxErrorAd *)error {
    switch ( error.errorCode ) {
        case DEVELOPER_ERROR:
            return [NSError errorWithDomain:GADErrorDomain code:GADErrorInternalError userInfo:nil];
            break;
        case NO_CONNECTION:
            return [NSError errorWithDomain:GADErrorDomain code:GADErrorServerError userInfo:nil];
            break;
        case NO_FILL:
        default:
            return [NSError errorWithDomain:GADErrorDomain code:GADErrorNoFill userInfo:nil];
            break;
    }
}

@end
