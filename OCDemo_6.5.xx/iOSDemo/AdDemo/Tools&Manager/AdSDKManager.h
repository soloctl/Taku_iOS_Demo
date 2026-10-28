//
//  AdSDKManager.h
//  iOSDemo
//
//  Created by ltz on 2025/3/26.
//

#import <Foundation/Foundation.h>
#import <AnyThinkSDK/AnyThinkSDK.h> 

///初始化完成回调
typedef void (^AdManagerInitFinishBlock)(void);

//在后台的应用ID
#define kTakuAppID  @"a5b0e8491845b3"

//在后台的应用维度AppKey，或者是账号维度AppKey
#define kTakuAppKey @"7eae0567827cfe2b22874061763f30c9"

//冷启动开屏超时时间
#define FirstAppOpen_Timeout 8

//冷启动开屏广告位ID
#define FirstAppOpen_PlacementID @"b5fa25036683d2"

@interface AdSDKManager : NSObject

+ (instancetype)sharedManager;
 
/// 应用若在欧盟地区发行，使用本方法初始化
- (void)initSDK_EU:(AdManagerInitFinishBlock)block;

/// 初始化SDK
- (void)initSDK;

/// 66 notifyLoss after each mediation load callback (no setSeatId)
+ (void)notifySDM66LossAfterLoad:(NSString *)placementID;

#pragma mark - 开屏广告相关

/// 启动开屏广告
- (void)startSplashAd;
 
@end


