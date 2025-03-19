//
//  TappxMediationRewarded.h
//  TappxFramework
//
//  Created by Yvan DL on 3/2/23.
//  Copyright © 2023 Tappx. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <TappxFramework/TappxAds.h>
#import <GoogleMobileAds/GoogleMobileAds.h>


@interface TappxMediationRewardedAd : NSObject <TappxRewardedAdDelegate, GADMediationAdapter, GADMediationRewardedAd>

@end
