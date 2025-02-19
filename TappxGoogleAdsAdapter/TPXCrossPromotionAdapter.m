//
//  TappxMediation.m
//  TappxDemo
//
//  Created by Antonio Lai on 09/12/23.
//  Copyright © 2023 Tappx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPXCrossPromotionAdapter.h"

#define ADAPTER_VERSION @"1.0.0"

@interface TPXCrossPromotionAdapter ()
@property (nonatomic, strong, nullable) GADBannerView *bannerView;
@property (nonatomic, strong, nullable) GADInterstitialAd *interstitial;
@property (nonatomic, weak, nullable) id <ITPXCrossPromotionAdapterDelegate> adMediationDelegate;
@end

@implementation TPXCrossPromotionAdapter

- (void)initAdapterWithDelegate:(nonnull id<ITPXCrossPromotionAdapterDelegate>)delegate {
    _adMediationDelegate = delegate;
}

- (NSString *)adapterVersion {
    return ADAPTER_VERSION;
}

- (nullable UIView *)getBannerView {
    return _bannerView;
}

- (void)initBannerView:(nonnull NSString *)adUnit bannerSize:(CGSize)bannerSize {
    self.bannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(bannerSize)];
    self.bannerView.adUnitID = adUnit;
    self.bannerView.delegate = self;
}

- (void)loadBannerAd { 
    [self.bannerView loadRequest:[GADRequest request]];
}

- (void)loadInterstitialAd:(nonnull NSString *)adUnit completionHandler:(nonnull ITPXCrossPromotionAdapterCompletionHandler)completionHandler {
    
    __weak typeof(self) selfB = self;
    __block typeof(completionHandler) completionHandlerB = completionHandler;
    
    [GADInterstitialAd loadWithAdUnitID:adUnit request:[GADRequest request] completionHandler:^(GADInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
        if(error) {
            completionHandlerB(error);
            return;
        }
        
        selfB.interstitial = interstitialAd;
        selfB.interstitial.fullScreenContentDelegate = selfB;
        
        completionHandlerB(nil);
    }];
}

- (void)presentInterstitialAd:(nonnull UIViewController *)viewController { 
    [self.interstitial presentFromRootViewController:viewController];
}

- (void)setAdRootViewController:(nonnull UIViewController *)viewController {
    self.bannerView.rootViewController = viewController;
}

#pragma mark - GADBannerViewDelegate methods

/// Tells the delegate that an ad request successfully received an ad. The delegate may want to add
/// the banner view to the view hierarchy if it hasn't been added yet.
- (void)bannerViewDidReceiveAd:(nonnull GADBannerView *)bannerView {
    NSLog(@"Tappx: bannerViewDidReceiveAd");
    [self.adMediationDelegate adDidLoad];
}

/// Tells the delegate that an ad request failed. The failure is normally due to network
/// connectivity or ad availablility (i.e., no fill).
- (void)bannerView:(nonnull GADBannerView *)bannerView didFailToReceiveAdWithError:(nonnull NSError *)error {
    NSLog(@"Tappx:bannerView:didFailToReceiveAdWithError: %@", [error localizedDescription]);
    [self.adMediationDelegate didFailToReceiveAdWithError:error];
}

/// Tells the delegate that an impression has been recorded for an ad.
- (void)bannerViewDidRecordImpression:(nonnull GADBannerView *)bannerView {
    NSLog(@"Tappx: bannerViewDidRecordImpression");
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)bannerViewDidRecordClick:(nonnull GADBannerView *)bannerView {
    NSLog(@"Tappx: bannerViewDidRecordClick");
    [self.adMediationDelegate adDidPress];
}

#pragma mark Click-Time Lifecycle Notifications

/// Tells the delegate that a full screen view will be presented in response to the user clicking on
/// an ad. The delegate may want to pause animations and time sensitive interactions.
- (void)bannerViewWillPresentScreen:(nonnull GADBannerView *)bannerView {
    NSLog(@"Tappx: bannerViewWillPresentScreen");
}

/// Tells the delegate that the full screen view will be dismissed.
- (void)bannerViewWillDismissScreen:(nonnull GADBannerView *)bannerView {
    NSLog(@"Tappx: bannerViewWillDismissScreen");
}

/// Tells the delegate that the full screen view has been dismissed. The delegate should restart
/// anything paused while handling bannerViewWillPresentScreen:.
- (void)bannerViewDidDismissScreen:(nonnull GADBannerView *)bannerView {
    NSLog(@"Tappx: bannerViewDidDismissScreen");
    [self.adMediationDelegate adDidClose];
}

#pragma mark - GADInterstitialDelegate methods

- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx: interstitialDidRecordImpression");
}

/// Tells the delegate that a click has been recorded for the ad.
- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx: interstitialDidRecordClick");
    
    [self.adMediationDelegate adDidPress];
}

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    NSLog(@"Tappx: interstitial:didFailToPresentAdWithError: %@", [error localizedDescription]);
    [self.adMediationDelegate didFailToReceiveAdWithError:error];
}

/// Tells the delegate that the ad presented full screen content.
- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx: interstitialDidPresentFullScreenContent");
}

/// Tells the delegate that the ad will dismiss full screen content.
- (void)adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx: interstitialWillDismissScreen");
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Tappx: interstitialDidDismissScreen");
    [self.adMediationDelegate adDidClose];
}


@end
