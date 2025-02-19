//
//  TappxMedationRewarded.m
//  TappxFramework
//
//  Created by Yvan DL on 3/2/23.
//  Copyright © 2023 Tappx. All rights reserved.
//

#import "TappxMediationRewardedAd.h"
#import <stdatomic.h>

@interface TappxMediationRewardedAd () {
    /// The sample rewarded ad.
    TappxRewardedViewController *rewardedAd;

    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

    /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
    id <GADMediationRewardedAdEventDelegate> _adEventDelegate;
}
@end

@implementation TappxMediationRewardedAd
static UIViewController* rootVC;

+ (UIViewController *) _getRootVC {
    return rootVC;
}

+ (void) _setRootVC:(UIViewController *) vc {
    rootVC = vc;
}

- (void)dealloc {
    if(rewardedAd != nil){
        rewardedAd = nil;
    }
}


- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
    [completionHandler copy];
    
    _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
        _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
      // Only allow completion handler to be called once.
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }

      id<GADMediationRewardedAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        // Call original handler and hold on to its return value.
        delegate = originalCompletionHandler(ad, error);
      }

      // Release reference to handler. Objects retained by the handler will also be released.
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
    
    rewardedAd = [[TappxRewardedViewController alloc] initWithDelegate:self];
    
    [rewardedAd load];
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


#pragma mark TappxRewardedViewControllerDelegate implementation
- (void)present:(nonnull UIViewController *)viewController {
    [[TappxMediationRewardedAd _getRootVC] presentViewController:viewController animated:false completion:nil];
}

- (nonnull UIViewController *)presentViewController {
    return [TappxMediationRewardedAd _getRootVC];
}

- (void) tappxRewardedViewControllerDidFinishLoad:(nonnull TappxRewardedViewController*) viewController {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void) tappxRewardedViewControllerDidFail:(nonnull TappxRewardedViewController*) viewController withError:(nonnull TappxErrorAd*) error {
    _adEventDelegate = _loadCompletionHandler(nil, [self convertError:error]);
}

- (void) tappxRewardedViewControllerClicked:(nonnull TappxRewardedViewController*) viewController {
    [_adEventDelegate reportClick];
}

- (void) tappxRewardedViewControllerPlaybackFailed:(nonnull TappxRewardedViewController*) viewController {
    [_adEventDelegate didFailToPresentWithError:[NSError errorWithDomain:GADErrorDomain code:GADErrorInternalError userInfo:nil]];
}

- (void) tappxRewardedViewControllerVideoClosed:(nonnull TappxRewardedViewController*) viewController {
    [_adEventDelegate didEndVideo];
    [_adEventDelegate willDismissFullScreenView];
}

- (void) tappxRewardedViewControllerVideoCompleted:(nonnull TappxRewardedViewController*) viewController {
    [_adEventDelegate didEndVideo];
}

- (void) tappxRewardedViewControllerDidAppear:(nonnull TappxRewardedViewController *)viewController {
    [_adEventDelegate didStartVideo];
    [_adEventDelegate reportImpression];
}

- (void) tappxRewardedViewControllerDismissed:(nonnull TappxRewardedViewController *) viewController {
    [_adEventDelegate didDismissFullScreenView];
}

- (void) tappxRewardedViewControllerUserDidEarnReward:(nonnull TappxRewardedViewController*) viewController {
    [_adEventDelegate didRewardUser];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if([rewardedAd isReady]) {
        [TappxMediationRewardedAd _setRootVC:viewController];
        [_adEventDelegate willPresentFullScreenView];
        [rewardedAd show];
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
