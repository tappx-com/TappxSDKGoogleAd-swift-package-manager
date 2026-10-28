//
//  TappxGoogleAdManagerInterstitial.m
//  TappxDemo
//
//  Created by Sara on 27/5/25.
//  Copyright © 2025 Tappx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TappxGoogleAdManagerInterstitial.h"
 
#define ADAPTER_VERSION @"1.0.0"

@interface TappxGoogleAdManagerInterstitial ()
@property (nonatomic, strong, nullable) GAMInterstitialAd *interstitial;
@property (nonatomic, strong, nullable) id <ITPXAdapterDelegate> adMediationDelegate;
@end

@implementation TappxGoogleAdManagerInterstitial

-(void) initAdapterWithDelegate:(nonnull id<ITPXAdapterDelegate>)delegate {
    _adMediationDelegate = delegate;
}

-(NSString *) adapterVersion {
    return ADAPTER_VERSION;
}

-(void) loadInterstitialAd:(nonnull NSString *)adUnit additionalData:(nullable NSDictionary*)additionalData completionHandler:(nonnull ITPXAdapterCompletionHandler)completionHandler {
    
    __weak typeof(self) selfB = self;
    __block typeof(completionHandler) completionHandlerB = completionHandler;
    
    GAMRequest* request = [GAMRequest request];
    
    if(additionalData) {
        request.customTargeting = additionalData;
    }
    
    [GAMInterstitialAd loadWithAdManagerAdUnitID:adUnit request:request completionHandler:^(GAMInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
        if(error) {
            completionHandlerB(error);
            return;
        }
        
        selfB.interstitial = interstitialAd;
        selfB.interstitial.fullScreenContentDelegate = selfB;
        
        completionHandlerB(nil);
    }];
}

-(void) presentInterstitialAd:(nonnull UIViewController *)viewController {
    [self.interstitial presentFromRootViewController:viewController];
}

#pragma mark - GADInterstitialDelegate methods

-(void) adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad { }

/// Tells the delegate that a click has been recorded for the ad.
-(void) adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    [self.adMediationDelegate adDidPress];
}

/// Tells the delegate that the ad failed to present full screen content.
-(void) ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    [self.adMediationDelegate didFailToReceiveAdWithError:error];
}

/// Tells the delegate that the ad presented full screen content.
-(void) adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad { }

/// Tells the delegate that the ad will dismiss full screen content.
-(void) adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad { }

/// Tells the delegate that the ad dismissed full screen content.
-(void) adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    [self.adMediationDelegate adDidClose];
}

@end
