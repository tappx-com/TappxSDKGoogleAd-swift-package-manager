//
//  TappxMediation.h
//  TappxFramework
//
//  Created by Antonio Lai on 09/12/23.
//  Copyright © 2023 Tappx. All rights reserved.
//

#import <TappxFramework/TappxAds.h>
#import <GoogleMobileAds/GoogleMobileAds.h>


@interface TPXCrossPromotionAdapter: NSObject <ITPXCrossPromotionAdapter, GADBannerViewDelegate, GADFullScreenContentDelegate>

@end
