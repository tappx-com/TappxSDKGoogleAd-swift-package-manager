//
//  TAPPXMediationBannerAd.m
//
//  Created by Tappx on 28/05/15.
//
//

#import "TappxMediationBannerAd.h"
#import <stdatomic.h>

@interface TappxMediationBannerAd () {
    TappxBannerView *bannerAd;
    
    GADMediationBannerLoadCompletionHandler _loadCompletionHandler;
    
    id <GADMediationBannerAdEventDelegate> _adEventDelegate;
}
@end

@implementation TappxMediationBannerAd

- (void)dealloc {
    if(bannerAd != nil){
        [bannerAd removeBanner];
        bannerAd = nil;
    }
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
      __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
          [completionHandler copy];

      _loadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
          _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
        // Only allow completion handler to be called once.
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
          return nil;
        }

        id<GADMediationBannerAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
          // Call original handler and hold on to its return value.
          delegate = originalCompletionHandler(ad, error);
        }

        // Release reference to handler. Objects retained by the handler will also
        // be released.
        originalCompletionHandler = nil;

        return delegate;
      };
    
    NSString* adUnit = adConfiguration.credentials.settings[@"parameter"];
    if ( adUnit != nil ) {
        
        NSArray *elements = [adUnit componentsSeparatedByString:@"|"];
        NSString* key = adUnit;
        NSString* isTest = nil;
        NSString* endpoint = nil;
        if ( [elements count]  > 1 ){
            key = [elements objectAtIndex: 0];
            if ( [elements count]  > 1 )
                isTest = [elements objectAtIndex: 1];
        }else{
            elements = [adUnit componentsSeparatedByString:@":"];
            if ( [elements count]  > 1 ){
                key = [elements objectAtIndex: 0];
                for(int i = 1; i < [elements count]; i++) {
                    NSArray *extraElements = [[elements objectAtIndex:i] componentsSeparatedByString:@"="];
                    if ( [extraElements count] > 1 ){
                        if([[extraElements objectAtIndex:0] isEqualToString:@"e"] && ![[extraElements objectAtIndex:1] isEqualToString:@""] && [[extraElements objectAtIndex:1] length] > 3)
                            endpoint = [extraElements objectAtIndex:1];
                        if([[extraElements objectAtIndex:0] isEqualToString:@"t"] && ![[extraElements objectAtIndex:1] isEqualToString:@""])
                            isTest = [extraElements objectAtIndex:1];
                    }
                }
            }
        }
        if ( isTest != nil && [isTest isEqualToString:@"1" ] )
            [TappxFramework addTappxKey:key testMode:YES];
        else {
            [TappxFramework addTappxKey:key fromNonNative:@"googleAd"];
        }
        if (endpoint != nil && ![endpoint isEqualToString:@""] && [endpoint length] > 3){
            [TappxFramework setEndpoint:endpoint];
        }
    }
    else{
        _adEventDelegate = _loadCompletionHandler(nil, [NSError errorWithDomain:GADErrorDomain code:GADErrorInvalidRequest userInfo:nil]);
        return;
    }

    
    TappxBannerSize size = TappxBannerSmartBanner;
    
    CGRect sizeFrame = CGRectMake(0, 0, (([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone) ? 320 : 728 ), (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? 50 : 90));
    if (adConfiguration.adSize.size.width == 320 && adConfiguration.adSize.size.height == 50 ){
        size = TappxBannerSize320x50;
        sizeFrame = CGRectMake(0, 0, 320, 50);
    }else if (adConfiguration.adSize.size.width == 728 && adConfiguration.adSize.size.height == 90 ){
        size = TappxBannerSize728x90;
        sizeFrame = CGRectMake(0, 0, 728, 90);
    }else if (adConfiguration.adSize.size.width == 300 && adConfiguration.adSize.size.height == 250 ){
        size = TappxBannerSize300x250;
        sizeFrame = CGRectMake(0, 0, 300, 250);
    }
    
    bannerAd = [[TappxBannerView alloc] initWithDelegate:self andSize:size];
    [bannerAd setRootViewController:adConfiguration.topViewController];
    [bannerAd load];
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


- (UIView *)view {
    return bannerAd;
}

//MARK: - TAPPXBannerDelegate

-(void) tappxBannerViewDidFinishLoad:(TappxBannerView*) vc {
    _adEventDelegate = _loadCompletionHandler(self, nil);
}

-(void) tappxBannerViewDidPress:(TappxBannerView*) vc {
    [_adEventDelegate reportClick];
}

-(void) tappxBannerViewDidFail:(TappxBannerView*) vc withError:(TappxErrorAd*) error {
    _adEventDelegate = _loadCompletionHandler(nil, [self convertError:error]);
    
    if(bannerAd != nil){
        [bannerAd removeBanner];
        bannerAd = nil;
    }
}
-(void) tappxBannerViewDidClose:(TappxBannerView*) vc {
    [_adEventDelegate didDismissFullScreenView];
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
