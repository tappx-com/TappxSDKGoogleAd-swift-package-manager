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
    TappxRewardedAd *rewardedAd;

    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

    /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
    id <GADMediationRewardedAdEventDelegate> _adEventDelegate;
}
@end

@implementation TappxMediationRewardedAd

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
            [TappxFramework addTappxKey:key fromNonNative:@"googleAd"];
        }
    } else {
        _adEventDelegate = _loadCompletionHandler(nil, [NSError errorWithDomain:GADErrorDomain code:GADErrorInvalidRequest userInfo:nil]);
        return;
    }
    
    rewardedAd = [[TappxRewardedAd alloc] initWithDelegate:self];
    
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

- (void) tappxRewardedAdDidFinishLoad:(nonnull TappxRewardedAd*) rewardedAd {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void) tappxRewardedAdDidFail:(nonnull TappxRewardedAd*) rewardedAd withError:(nonnull TappxErrorAd*) error {
    _adEventDelegate = _loadCompletionHandler(nil, [self convertError:error]);
}

- (void) tappxRewardedAdClicked:(nonnull TappxRewardedAd*) rewardedAd {
    [_adEventDelegate reportClick];
}

- (void) tappxRewardedAdPlaybackFailed:(nonnull TappxRewardedAd*) rewardedAd {
    [_adEventDelegate didFailToPresentWithError:[NSError errorWithDomain:GADErrorDomain code:GADErrorInternalError userInfo:nil]];
}

- (void) tappxRewardedAdVideoClosed:(nonnull TappxRewardedAd*) rewardedAd {
    [_adEventDelegate didEndVideo];
    [_adEventDelegate willDismissFullScreenView];
}

- (void) tappxRewardedAdVideoCompleted:(nonnull TappxRewardedAd*) rewardedAd {
    [_adEventDelegate didEndVideo];
}

- (void) tappxRewardedAdDidAppear:(nonnull TappxRewardedAd *)rewardedAd {
    [_adEventDelegate didStartVideo];
    [_adEventDelegate reportImpression];
}

- (void) tappxRewardedAdDismissed:(nonnull TappxRewardedAd *) rewardedAd {
    [_adEventDelegate didDismissFullScreenView];
}

- (void) tappxRewardedAdUserDidEarnReward:(nonnull TappxRewardedAd*) rewardedAd {
    [_adEventDelegate didRewardUser];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if([rewardedAd isReady]) {
        [_adEventDelegate willPresentFullScreenView];
        [rewardedAd showFrom:viewController];
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
