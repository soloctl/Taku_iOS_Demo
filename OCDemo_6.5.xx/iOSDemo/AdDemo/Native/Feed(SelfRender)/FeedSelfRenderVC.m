//
//  FeedSelfRenderVC.m
//  iOSDemo
//
//  Created by ltz on 2025/1/21.
//

#import "FeedSelfRenderVC.h"
 
#import <MJRefresh/MJRefresh.h>
#import "SelfRenderView.h"
#import "DemoOfferAdModel.h"
#import "AdCell.h"
#import "CustomCell.h"
#import "AdLoadConfigTool.h"
#import "AdSDKManager.h"

@interface FeedSelfRenderVC () <ATNativeADDelegate,UITableViewDelegate,UITableViewDataSource>
 
@property (nonatomic, strong) NSMutableArray <DemoOfferAdModel *> * dataSourceArray;
@property (nonatomic, strong) UITableView * feedTableView;

@end

@implementation FeedSelfRenderVC

//广告位ID
#define Feed_Native_SelfRender_PlacementID @"b5fa25023d0767"

//场景ID，可选，可在后台生成。没有可传入空字符串
#define Feed_Native_SelfRender_SceneID @""
 
- (void)dealloc {
    NSLog(@"FeedSelfRenderVC dealloc");
    //销毁没有释放的广告
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSourceArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.dataSourceArray[indexPath.row].isNativeAd) {
        //广告cell，动态高度
        return UITableViewAutomaticDimension;
    }
    //其他cell，自定义高度
    return 200;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DemoOfferAdModel *offerModel = self.dataSourceArray[indexPath.row];
    
    if (offerModel.isNativeAd) {
        // 存在新的广告，可以刷新
        ATNativeAdOffer *offer = [self getOfferAndLoadNext];
        if (offer) {
            offerModel.nativeADView = [self getNativeADViewWithOffer:offer];
            offerModel.offer = offer;
        }
        
        AdCell *cell = [[AdCell alloc] initWithStyle:0 reuseIdentifier:@"AdCell"];
        ATDemoLog(@"adView之前--%@",cell.adView);
        cell.adView = offerModel.nativeADView;
        ATDemoLog(@"adView之后--%@",cell.adView);
        return cell;
        
    }else{
        CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
        return cell;
    }
}
   
/// 通过广告offer获取ATNativeADView对象
/// - Parameter offer: 已获取到的广告offer
- (ATNativeADView *)getNativeADViewWithOffer:(ATNativeAdOffer *)offer {
   
    // 初始化config配置
    ATNativeADConfiguration *config = [[ATNativeADConfiguration alloc] init];
    // 给原生广告进行预布局
    config.ADFrame = CGRectMake(0, 0, SelfRenderViewWidth, SelfRenderViewHeight);
    config.delegate = self;
    config.rootViewController = self;
    //设置仅wifi模式才自动播放，部分广告平台有效
    config.videoPlayType = ATNativeADConfigVideoPlayOnlyWiFiAutoPlayType;
    
    //【手动布局方式】精确设置logo大小以及位置，与下方【Masonry方式】选择一种实现
//    config.logoViewFrame = CGRectMake(kScreenW-40-10-15, SelfRenderViewHeight-50-10, 40, 40);
    
    //设置广告平台logo位置偏好(部分广告平台无法进行精确设置，则通过下面代码设置，Demo示例中均演示为右下角的情况)
    //若素材offer中logoUrl或logo有值时，才可以通过SelfRenderView中布局进行设置，没有值请使用本方法中的示例进行精确控制或者偏好位置设置。
    [ATAPI sharedInstance].preferredAdLogoPosition = ATAdLogoPositionBottomRightCorner;
    
    // 设置广告标识坐标x和y,部分广告平台有效
    // config.adChoicesViewOrigin = CGPointMake(10, 10);
     
    // 打印素材组件
    NSDictionary *offerInfoDict = [Tools getOfferInfo:offer];
    ATDemoLog(@"🔥🔥🔥--自渲染广告素材，展示前：%@",offerInfoDict);
    
    // 创建自渲染视图view，同时根据offer信息内容去赋值
    SelfRenderView *selfRenderView = [[SelfRenderView alloc] initWithOffer:offer];
    
    // 创建广告nativeADView
    // 获取原生广告展示容器视图
    ATNativeADView *nativeADView = [[ATNativeADView alloc] initWithConfiguration:config currentOffer:offer placementID:Feed_Native_SelfRender_PlacementID];
    
    //创建可点击组件的容器数组
    NSMutableArray *clickableViewArray = [NSMutableArray array];
    
    // 获取mediaView，需要自行添加到自渲染视图上，必须调用
    UIView *mediaView = [nativeADView getMediaView];
    if (mediaView) {
        // 赋值并布局
        selfRenderView.mediaView = mediaView;
    }
    
    // 设置需要注册点击事件的UI控件，最好不要把信息流的父视图整体添加到点击事件中，不然可能会出现点击关闭按钮，还触发了点击信息流事件。
    [clickableViewArray addObjectsFromArray:@[selfRenderView.iconImageView,
                                              selfRenderView.titleLabel,
                                              selfRenderView.textLabel,
                                              selfRenderView.ctaLabel,
                                              selfRenderView.mainImageView]];
    
    // 给UI控件注册点击事件
    [nativeADView registerClickableViewArray:clickableViewArray];
    
    //绑定组件
    [self prepareWithNativePrepareInfo:selfRenderView nativeADView:nativeADView];
    
    //渲染广告
    [offer rendererWithConfiguration:config selfRenderView:selfRenderView nativeADView:nativeADView];
    
    //【Masonry方式】精确设置logo大小以及位置，与上方【手动布局方式】选择一种实现，请在渲染广告之后调用，请基于nativeADView操作
    [nativeADView.logoImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(nativeADView).offset(-25);
        make.width.height.equalTo(@15);
    }];
 
    //隐藏logo，谨慎使用，请阅读文档：自渲染广告注意事项
    //nativeADView.logoImageView.hidden = YES;
  
    return nativeADView;
}

#pragma mark - 绑定组件
- (void)prepareWithNativePrepareInfo:(SelfRenderView *)selfRenderView nativeADView:(ATNativeADView *)nativeADView {
    // 哪些组件需要绑定，哪些不需要，请参考文档：原生广告注意事项
    ATNativePrepareInfo *info = [ATNativePrepareInfo loadPrepareInfo:^(ATNativePrepareInfo * prepareInfo) {
        prepareInfo.textLabel = selfRenderView.textLabel;
        prepareInfo.advertiserLabel = selfRenderView.advertiserLabel;
        prepareInfo.titleLabel = selfRenderView.titleLabel;
        prepareInfo.ratingLabel = selfRenderView.ratingLabel;
        prepareInfo.iconImageView = selfRenderView.iconImageView;
        prepareInfo.mainImageView = selfRenderView.mainImageView;
        prepareInfo.ctaLabel = selfRenderView.ctaLabel;
        prepareInfo.dislikeButton = selfRenderView.dislikeButton;
        prepareInfo.mediaView = selfRenderView.mediaView;
    }];
    [nativeADView prepareWithNativePrepareInfo:info];
}

#pragma mark - 数据处理 data execute

/// 添加数据源
/// - Parameter isSuccess: 广告加载是否成功
- (void)setDataWithRequest:(BOOL)isSuccess {
    if (isSuccess) {
        //加载广告成功，获取offer并添加数据模型
        ATNativeAdOffer *offer = [self getOfferAndLoadNext];
        if (offer) {
            DemoOfferAdModel *offerModel = [[DemoOfferAdModel alloc] init];
            offerModel.nativeADView = [self getNativeADViewWithOffer:offer];
            offerModel.offer = offer;
            //标记为广告
            offerModel.isNativeAd = YES;
            [self.dataSourceArray addObject:offerModel];
        }
    }
    
    //添加非广告model，模拟开发者自己的业务Cell
    for (int i = 0; i < 3; i ++) {
        DemoOfferAdModel *offerModel1 = [[DemoOfferAdModel alloc] init];
        offerModel1.isNativeAd = NO;
        [self.dataSourceArray addObject:offerModel1];
    } 
    [self.feedTableView reloadData];
}

/// 获取offer并且发起下一次load
- (ATNativeAdOffer *)getOfferAndLoadNext {
    
    //场景统计功能，可选接入
    [[ATAdManager sharedManager] entryNativeScenarioWithPlacementID:Feed_Native_SelfRender_PlacementID scene:Feed_Native_SelfRender_SceneID];
    
    ATNativeAdOffer *offer = [[ATAdManager sharedManager] getNativeAdOfferWithPlacementID:Feed_Native_SelfRender_PlacementID];
    // load next
    [self loadNativeAd];
    
    return offer;
}

/// 用户点击close，从列表中移除广告
/// - Parameter nativeADView: 广告adView
- (void)removeAd:(ATNativeADView *)nativeADView {
    for (int i=0; i<self.dataSourceArray.count; i++) {
        DemoOfferAdModel *offerModel = self.dataSourceArray[i];
        if (offerModel.isNativeAd && offerModel.nativeADView == nativeADView) {
            
            if (nativeADView && nativeADView.superview) {
                [nativeADView removeFromSuperview];
            }
            //销毁广告视图
            [nativeADView destroyNative];
            //销毁offer
            offerModel.offer = nil;
            offerModel.nativeADView = nil;
            
            [self.dataSourceArray removeObject:offerModel];
            [self.feedTableView reloadData];
             
            break;
        }
    }
}
  
/// 用于测试时打印相关信息
/// - Parameters:
///   - offer: 广告素材
///   - nativeADView: 广告对象view
- (void)printNativeAdInfoAfterRendererWithOffer:(ATNativeAdOffer *)offer nativeADView:(ATNativeADView *)nativeADView {
    ATNativeAdRenderType nativeAdRenderType = [nativeADView getCurrentNativeAdRenderType];
    if (nativeAdRenderType == ATNativeAdRenderExpress) {
        ATDemoLog(@"⚠️⚠️⚠️--这是原生模板了");
    } else {
        ATDemoLog(@"✅✅✅--这是原生自渲染");
    }
    BOOL isVideoContents = [nativeADView isVideoContents];
    
    //打印所有素材内容
    [Tools printNativeAdOffer:offer];
    ATDemoLog(@"🔥--是否为原生视频广告：%d",isVideoContents);
}

#pragma mark - 广告位代理回调
/// 广告位加载完成
/// - Parameter placementID: 广告位ID
- (void)didFinishLoadingADWithPlacementID:(NSString *)placementID {
    [AdSDKManager notifySDM66LossAfterLoad:placementID];
    BOOL isReady = [[ATAdManager sharedManager] nativeAdReadyForPlacementID:placementID];
    [self showLog:[NSString stringWithFormat:@"didFinishLoadingADWithPlacementID:%@ SelfRender 是否准备好:%@", placementID,isReady ? @"YES":@"NO"]];
    
    if (self.feedTableView.mj_footer.refreshing == YES) {
        [self.feedTableView.mj_footer endRefreshing];
        //请求成功，传入YES可以获取广告数据
        [self setDataWithRequest:YES];
    }
}
 
/// 广告位加载失败
/// - Parameters:
///   - placementID: 广告位ID
///   - error: 错误信息
- (void)didFailToLoadADWithPlacementID:(NSString *)placementID error:(NSError *)error {
    [AdSDKManager notifySDM66LossAfterLoad:placementID];
    ATDemoLog(@"didFailToLoadADWithPlacementID:%@ error:%@", placementID, error);
    [self showLog:[NSString stringWithFormat:@"didFailToLoadADWithPlacementID:%@ errorCode:%ld", placementID, error.code]];
    
    if (self.feedTableView.mj_footer.refreshing == YES) {
        [self.feedTableView.mj_footer endRefreshing];
        //请求失败
        [self setDataWithRequest:NO];
    }
}

/// 获得展示收益
/// - Parameters:
///   - placementID: 广告位ID
///   - extra: 额外信息字典
- (void)didRevenueForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didRevenueForPlacementID:%@ with extra: %@", placementID,extra);
    [self showLog:[NSString stringWithFormat:@"didRevenueForPlacementID:%@", placementID]];
}

#pragma mark - 原生广告事件回调

/// 原生广告已展示
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息
- (void)didShowNativeAdInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didShowNativeAdInAdView:%@ extra:%@",placementID,extra);
    [self showLog:[NSString stringWithFormat:@"didShowNativeAdInAdView:%@", placementID]];
    
    
}

/// 原生广告点击了关闭按钮
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息
- (void)didTapCloseButtonInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didTapCloseButtonInAdView:%@ extra:%@", placementID, extra);
    [self showLog:[NSString stringWithFormat:@"didTapCloseButtonInAdView:%@", placementID]];
    
    //从列表移除
    [self removeAd:adView];
}

/// 原生广告开始播放视频
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息字典
- (void)didStartPlayingVideoInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didStartPlayingVideoInAdView:%@ extra: %@", placementID,extra);
    [self showLog:[NSString stringWithFormat:@"didStartPlayingVideoInAdView:%@", placementID]];
}

/// 原生广告视频播放结束
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息字典
- (void)didEndPlayingVideoInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didEndPlayingVideoInAdView:%@ extra: %@", placementID,extra);
    [self showLog:[NSString stringWithFormat:@"didEndPlayingVideoInAdView:%@", placementID]];
}

/// 原生广告用户已点击
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息字典
- (void)didClickNativeAdInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didClickNativeAdInAdView:%@ extra:%@",placementID,extra);
    [self showLog:[NSString stringWithFormat:@"didClickNativeAdInAdView:%@", placementID]];
}
 
/// 原生广告已打开或跳转深链接页面
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息
///   - success: 是否成功
- (void)didDeepLinkOrJumpInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra result:(BOOL)success {
    ATDemoLog(@"didDeepLinkOrJumpInAdView:placementID:%@ with extra: %@, success:%@", placementID,extra, success ? @"YES" : @"NO");
    [self showLog:[NSString stringWithFormat:@"didDeepLinkOrJumpInAdView:%@, success:%@", placementID, success ? @"YES" : @"NO"]];
}
 
/// 原生广告已进入全屏视频播放，通常是点击视频meidaView后自动跳转至一个播放落地页
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息
- (void)didEnterFullScreenVideoInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra{
    ATDemoLog(@"didEnterFullScreenVideoInAdView:%@", placementID);
    [self showLog:[NSString stringWithFormat:@"didEnterFullScreenVideoInAdView:%@", placementID]];
}

/// 原生广告已退出全屏视频播放
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息
- (void)didExitFullScreenVideoInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didExitFullScreenVideoInAdView:%@", placementID);
    [self showLog:[NSString stringWithFormat:@"didExitFullScreenVideoInAdView:%@", placementID]];
}
 
/// 原生广告已退出详情页面
/// - Parameters:
///   - adView: 广告视图对象
///   - placementID: 广告位ID
///   - extra: 额外信息
- (void)didCloseDetailInAdView:(ATNativeADView *)adView placementID:(NSString *)placementID extra:(NSDictionary *)extra {
    ATDemoLog(@"didCloseDetailInAdView:%@ extra:%@", placementID, extra);
    [self showLog:[NSString stringWithFormat:@"didCloseDetailInAdView:%@", placementID]];
}

#pragma mark - TableView Data Refresh
- (void)footerRefresh {
    self.feedTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(upFreshLoadMoreData)];
    [self.feedTableView.mj_footer beginRefreshing];
}

/// 加载更多
- (void)upFreshLoadMoreData {
    [self loadNativeAd];
}
 
/// 加载广告
- (void)loadNativeAd {
    NSMutableDictionary * loadConfigDict = [NSMutableDictionary dictionary];
    
    //设置请求广告的尺寸
    [loadConfigDict setValue:[NSValue valueWithCGSize:CGSizeMake(SelfRenderViewWidth, SelfRenderViewHeight)] forKey:kATExtraInfoNativeAdSizeKey];
    //请求自适应尺寸的原生广告(部分广告平台可用)（可选接入）
    [AdLoadConfigTool native_loadExtraConfigAppend_SizeToFit:loadConfigDict];
    
    // 给视频播放器设置frame
    [loadConfigDict setValue:[NSValue valueWithCGRect:CGRectMake(0, 0, SelfRenderViewMediaViewWidth, SelfRenderViewMediaViewHeight)] forKey:kATExtraInfoMediaViewFrameKey];
    
    //快手原生广告滑一滑和点击相关控制
//    [AdLoadConfigTool native_loadExtraConfigAppend_KuaiShou_SlideOrClickAble:loadConfigDict];
    
    [[ATAdManager sharedManager] loadADWithPlacementID:Feed_Native_SelfRender_PlacementID extra:loadConfigDict delegate:self];
}
 
#pragma mark - getter
- (UITableView *)feedTableView {
    if (!_feedTableView) {
        _feedTableView = [[UITableView alloc] init];
        _feedTableView.delegate = self;
        _feedTableView.dataSource = self;
        _feedTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        //绑定cell
        [_feedTableView registerNib:[UINib nibWithNibName:@"CustomCell" bundle:nil] forCellReuseIdentifier:@"CustomCell"];
        [_feedTableView registerClass:[AdCell class] forCellReuseIdentifier:@"AdCell"];
        
        //给一个合理的高度预估值
        _feedTableView.estimatedRowHeight = SelfRenderViewHeight; // 设置一个合理的预估值
        _feedTableView.rowHeight = UITableViewAutomaticDimension;
    }
    return _feedTableView;
}

- (NSMutableArray *)dataSourceArray {
    if (_dataSourceArray) return _dataSourceArray;
    NSMutableArray *dataSourceArray = [NSMutableArray array];
    return _dataSourceArray = dataSourceArray;
}
 
#pragma mark - Demo UI
- (void)viewDidLoad {
    [super viewDidLoad];
     
    [self.view addSubview:self.feedTableView];
    [self.feedTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nbar.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
    [self footerRefresh];
}
 
@end
