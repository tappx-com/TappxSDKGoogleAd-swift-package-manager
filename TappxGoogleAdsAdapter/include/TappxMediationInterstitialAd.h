//
//  TAPPXMediationInterstitialAd.h
//
//  Created by Tappx on 28/05/15.
//
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <TappxFramework/TappxAds.h>


@interface TappxMediationInterstitialAd : NSObject<GADMediationInterstitialAd, GADMediationAdapter, TappxInterstitialViewControllerDelegate>

@end
