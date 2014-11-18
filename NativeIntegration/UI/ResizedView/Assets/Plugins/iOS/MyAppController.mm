#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "UI/UnityAppController+ViewHandling.h"
#import "UI/UnityView.h"
#import "UI/OrientationSupport.h"

#import "ScreenshotCreator.h"
#include <algorithm>


@interface MyAppController : UnityAppController
{
    @public UIViewController*   _unityViewController;
    @public UIImageView*        _screenshotView;
    @public UIViewController*   _screenshotViewController;
}
- (void)shouldAttachRenderDelegate;
- (UIViewController*)createAutorotatingUnityViewController;
- (void)willStartWithViewController:(UIViewController*)controller;
- (void)willTransitionToViewController:(UIViewController*)toController fromViewController:(UIViewController*)fromController;
@end

@implementation MyAppController

- (void)shouldAttachRenderDelegate;
{
    self.renderDelegate = [[ScreenshotCreator alloc] init];
}

- (UIViewController*)createAutorotatingUnityViewController
{
    NSAssert(false, @"This sample is not suited for autorotation");
    return nil;
}

- (void)setupViews:(UIViewController*)controller
{
    NSUInteger  supportOrient   = [controller supportedInterfaceOrientations];
    const bool  supportPortrait = (supportOrient & (1 << UIInterfaceOrientationPortrait)) || (supportOrient & (1 << UIInterfaceOrientationPortraitUpsideDown));
    const bool  supportLandscape= (supportOrient & (1 << UIInterfaceOrientationLandscapeLeft)) || (supportOrient & (1 << UIInterfaceOrientationLandscapeRight));

    NSAssert(supportLandscape != supportPortrait, @"This sample is not suited for autorotation");

    // the proper solution on that case would be subclass UIView and tweak stuff in layoutSubviews
    // but we want sample of tweaking viewcontroller contents

    float rootW   = [[UIScreen mainScreen] bounds].size.width;
    float rootH   = [[UIScreen mainScreen] bounds].size.height;
    if(supportPortrait == rootW > rootH)
        std::swap(rootW, rootH);

    const float viewW   = supportPortrait ? rootW : rootW * 0.5f;
    const float viewH   = supportPortrait ? rootH * 0.5f : rootH;
    const float imgX    = supportPortrait ? 0 : viewW;
    const float imgY    = supportPortrait ? viewH : 0;

    const CGRect rootRect   = CGRectMake(0, 0, rootW, rootH);
    const CGRect unityRect  = CGRectMake(0, 0, viewW, viewH);
    const CGRect imageRect  = CGRectMake(imgX, imgY, viewW, viewH);

    _rootView.frame         = rootRect;
    _unityView.frame        = unityRect;
    _screenshotView.frame   = imageRect;

    [_rootView addSubview:_unityViewController.view];
    [_rootView addSubview:_screenshotViewController.view];
    [_rootView bringSubviewToFront:_unityView];
}

- (void)willStartWithViewController:(UIViewController*)controller
{
    _rootView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    _unityViewController = [[UIViewController alloc] init];
    _unityViewController.view = _unityView;

    _screenshotView = [[UIImageView alloc] init];
    _screenshotView.hidden = YES;
    _screenshotView.userInteractionEnabled = NO;

    _screenshotViewController = [[UIViewController alloc] init];
    _screenshotViewController.view = _screenshotView;

    [self setupViews:controller];
    controller.view = _rootView;
}

- (void)willTransitionToViewController:(UIViewController*)toController fromViewController:(UIViewController*)fromController
{
    [_unityViewController.view removeFromSuperview];
    [_screenshotViewController.view removeFromSuperview];
    [_rootView removeFromSuperview];

    [super willTransitionToViewController:toController fromViewController:fromController];
    [self setupViews:toController];
    [_window addSubview:_rootView];
}

@end


IMPL_APP_CONTROLLER_SUBCLASS(MyAppController);

extern "C" void OnScreenshotDone(const char* filename)
{
    NSURL*  documents   = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    NSURL*  fileUrl     = [documents URLByAppendingPathComponent:[NSString stringWithUTF8String:filename]];
    NSData* imgData     = [NSData dataWithContentsOfURL:fileUrl];

    MyAppController* app = (MyAppController*)GetAppController();

    app->_screenshotView.image = [UIImage imageWithData:imgData];
    app->_screenshotView.hidden = NO;
    [app.rootView layoutSubviews];
}

extern "C" int UnityInterfaceOrientation()
{
    return (int)ConvertToUnityScreenOrientation(GetAppController().interfaceOrientation);
}

extern "C" void UnityChangeInterfaceOrientation(int orient)
{
    [GetAppController() orientInterface:ConvertToIosScreenOrientation((ScreenOrientation)orient)];
}
