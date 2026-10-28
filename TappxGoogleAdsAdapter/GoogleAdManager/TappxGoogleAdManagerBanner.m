//
//  TappxGoogleAdManagerBanner.m
//  TappxDemo
//
//  Created by Sara on 27/5/25.
//  Copyright © 2025 Tappx. All rights reserved.
//
 
#import <Foundation/Foundation.h>
#import "TappxGoogleAdManagerBanner.h"

#define ADAPTER_VERSION @"1.0.0"

@interface TappxGoogleAdManagerBanner ()
@property (nonatomic, strong, nullable) GAMBannerView *bannerView;
@property (nonatomic, assign) CGSize bannerSize;
@property (nonatomic, strong, nullable) id <ITPXAdapterDelegate> adMediationDelegate;
@end

@implementation TappxGoogleAdManagerBanner

-(void) initAdapterWithDelegate:(nonnull id<ITPXAdapterDelegate>)delegate {
    _adMediationDelegate = delegate;
}

-(NSString *) adapterVersion {
    return ADAPTER_VERSION;
}

-(nullable UIView *) getBannerView {
    return _bannerView;
}

-(void) initBannerView:(nonnull NSString *)adUnit bannerSize:(CGSize)bannerSize {
    self.bannerSize = bannerSize;
    self.bannerView = [[GAMBannerView alloc] initWithAdSize:GADAdSizeFromCGSize(bannerSize)];
    self.bannerView.adUnitID = adUnit;
    self.bannerView.delegate = self;
}

-(void) loadBannerAdWithAdditionalData:(NSDictionary *)additionalData {
    
    GAMRequest* request = [GAMRequest request];
    
    if(additionalData) {
        request.customTargeting = additionalData;
    }
    
    [self.bannerView loadRequest:request];
}

-(void) setAdRootViewController:(nonnull UIViewController *)viewController {
    self.bannerView.rootViewController = viewController;
}

- (void)destroyAd {
    if(self.bannerView) {
        [self.bannerView removeFromSuperview];
    }
    
    self.bannerView = nil;
}

#pragma mark - GADBannerViewDelegate methods

/// Tells the delegate that an ad request successfully received an ad. The delegate may want to add
/// the banner view to the view hierarchy if it hasn't been added yet.
-(void) bannerViewDidReceiveAd:(nonnull GADBannerView *)bannerView {
    [self.adMediationDelegate adDidLoad];
}


/// Tells the delegate that an ad request failed. The failure is normally due to network
/// connectivity or ad availablility (i.e., no fill).
-(void) bannerView:(nonnull GADBannerView *)bannerView didFailToReceiveAdWithError:(nonnull NSError *)error {
    [self.adMediationDelegate didFailToReceiveAdWithError:error];
}

/// Tells the delegate that an impression has been recorded for an ad.
-(void) bannerViewDidRecordImpression:(nonnull GADBannerView *)bannerView { }

#pragma mark Click-Time Lifecycle Notifications

/// Tells the delegate that a full screen view will be presented in response to the user clicking on
/// an ad. The delegate may want to pause animations and time sensitive interactions.
-(void) bannerViewWillPresentScreen:(nonnull GADBannerView *)bannerView { }

/// Tells the delegate that the full screen view will be dismissed.
-(void) bannerViewWillDismissScreen:(nonnull GADBannerView *)bannerView { }

/// Tells the delegate that the full screen view has been dismissed. The delegate should restart
/// anything paused while handling bannerViewWillPresentScreen:.
-(void) bannerViewDidDismissScreen:(nonnull GADBannerView *)bannerView {
    [self.adMediationDelegate adDidClose];
}

- (void)adLoader:(nonnull GADAdLoader *)adLoader didFailToReceiveAdWithError:(nonnull NSError *)error {
    [self.adMediationDelegate didFailToReceiveAdWithError:error];
}

- (void)adLoader:(nonnull GADAdLoader *)adLoader didReceiveGAMBannerView:(nonnull GAMBannerView *)bannerView {
    [self.adMediationDelegate adDidLoad];
}

- (nonnull NSArray<NSValue *> *)validBannerSizesForAdLoader:(nonnull GADAdLoader *)adLoader { 
    return @[[NSValue valueWithCGSize:self.bannerSize]];
}

@end
