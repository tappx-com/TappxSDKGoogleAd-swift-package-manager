//
//  TappxGoogleAdManagerRewarded.m
//  TappxDemo
//
//  Created by Sara on 27/5/25.
//  Copyright © 2025 Tappx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TappxGoogleAdManagerRewarded.h"
 
#define ADAPTER_VERSION @"1.0.0"

@interface TappxGoogleAdManagerRewarded ()
@property (nonatomic, strong, nullable) GADRewardedAd *rewarded;
@property (nonatomic, strong, nullable) id <ITPXAdapterDelegate> adMediationDelegate;
@end

@implementation TappxGoogleAdManagerRewarded

-(void) initAdapterWithDelegate:(nonnull id<ITPXAdapterDelegate>)delegate {
    _adMediationDelegate = delegate;
}

-(NSString *) adapterVersion {
    return ADAPTER_VERSION;
}

-(void) loadRewardedAd:(nonnull NSString *)adUnit additionalData:(nullable NSDictionary*)additionalData completionHandler:(nonnull ITPXAdapterCompletionHandler)completionHandler {
    
    __weak typeof(self) selfB = self;
    __block typeof(completionHandler) completionHandlerB = completionHandler;
    
    GAMRequest* request = [GAMRequest request];
    
    if(additionalData) {
        request.customTargeting = additionalData;
    }
    
    [GADRewardedAd loadWithAdUnitID:adUnit request:request completionHandler:^(GADRewardedAd * _Nullable rewardedAd, NSError * _Nullable error) {
        if(error) {
            completionHandlerB(error);
            return;
        }
        
        selfB.rewarded = rewardedAd;
        selfB.rewarded.fullScreenContentDelegate = selfB;
        
        completionHandlerB(nil);
    }];
}

-(void) presentRewardedAd:(nonnull UIViewController *)viewController userDidEarnRewardHandler:(nonnull GADUserDidEarnRewardHandler)handler {
    [self.rewarded presentFromRootViewController:viewController userDidEarnRewardHandler:handler];
}

#pragma mark - GADRewardedDelegate methods

-(void) adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx ad manager: rewardedDidRecordImpression");
}

/// Tells the delegate that a click has been recorded for the ad.
-(void) adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx ad manager: rewardedDidRecordClick");
    
    [self.adMediationDelegate adDidPress];
}

/// Tells the delegate that the ad failed to present full screen content.
-(void) ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    NSLog(@"Tappx ad manager: rewarded:didFailToPresentAdWithError: %@", [error localizedDescription]);
    [self.adMediationDelegate didFailToReceiveAdWithError:error];
}

/// Tells the delegate that the ad presented full screen content.
-(void) adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx ad manager: rewardedDidPresentFullScreenContent");
}

/// Tells the delegate that the ad will dismiss full screen content.
-(void) adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx ad manager: rewardedWillDismissScreen");
}

/// Tells the delegate that the ad dismissed full screen content. Best practice: load another rewarded ad
-(void) adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx ad manager: rewardedDidDismissScreen");
    [self.adMediationDelegate adDidClose];
}


@end
