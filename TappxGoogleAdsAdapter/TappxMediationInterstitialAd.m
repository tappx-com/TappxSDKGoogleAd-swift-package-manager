//
//  TAPPXMediationInterstitialAd.m
//
//  Created by Tappx on 28/05/15.
//
//

#import "TappxMediationInterstitialAd.h"
#import <stdatomic.h>

@interface TappxMediationInterstitialAd () {
    TappxInterstitialViewController *interstitialAd;
    
    GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;
    
    id <GADMediationInterstitialAdEventDelegate> _adEventDelegate;
}
@end

@implementation TappxMediationInterstitialAd
static UIViewController* rootVC;

+ (UIViewController *) _getRootVC {
    return rootVC;
}
+ (void) _setRootVC:(UIViewController *)vc {
    rootVC = vc;
}

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
        NSString* key = [elements objectAtIndex: 0];
        
        NSString* isTest = nil;
        if ( [elements count]  > 1 )
            isTest = [elements objectAtIndex: 1];
        
        if ( isTest != nil && [isTest isEqualToString:@"1" ] )
            [TappxFramework addTappxKey:key testMode:YES];
        else {
            [TappxFramework addTappxKey:key];
        }
    } else {
        _adEventDelegate = _loadCompletionHandler(nil, [NSError errorWithDomain:GADErrorDomain code:GADErrorInvalidRequest userInfo:nil]);
        return;
    }
        
    
    interstitialAd = [[TappxInterstitialViewController alloc] initWithDelegate:self];
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


- (void)present:(nonnull UIViewController *)viewController {
    [[TappxMediationInterstitialAd _getRootVC] presentViewController:viewController animated:false completion:nil];
}

-(UIViewController*)presentViewController{
    return [TappxMediationInterstitialAd _getRootVC];
}

- (void)tappxInterstitialViewControllerDidFinishLoad:(nonnull TappxInterstitialViewController *)viewController{
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)tappxInterstitialViewControllerDidPress:(nonnull TappxInterstitialViewController *)viewController{
    [_adEventDelegate reportClick];
}

- (void)tappxInterstitialViewControllerDidClose:(nonnull TappxInterstitialViewController *)viewController{
    [_adEventDelegate didDismissFullScreenView];
}

- (void)tappxInterstitialViewControllerDidFail:(nonnull TappxInterstitialViewController *)viewController withError:(nonnull TappxErrorAd *)error{
    _adEventDelegate = _loadCompletionHandler(nil, [self convertError:error]);
}

- (void)tappxInterstitialViewControllerDidAppear:(nonnull TappxInterstitialViewController *)viewController {
    [_adEventDelegate reportImpression];
}

- (void)onTappxInterstitialDismissed:(nonnull TappxInterstitialViewController *)viewController {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if([interstitialAd isReady]) {
        [TappxMediationInterstitialAd _setRootVC:viewController];
        [_adEventDelegate willPresentFullScreenView];
        [interstitialAd show];
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
