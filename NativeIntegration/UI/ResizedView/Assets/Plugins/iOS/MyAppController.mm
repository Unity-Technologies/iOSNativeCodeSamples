#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "UI/UnityView.h"
#import "UI/UnityViewControllerBase.h"

#import "ScreenshotCreator.h"

@interface MyAppController : UnityAppController
{
    @public UIViewController*   _unityViewController;
    @public UIImageView*        _screenshotView;
    @public UIViewController*   _screenshotViewController;
}
- (void)shouldAttachRenderDelegate;
- (void)createViewHierarchyImpl;
@end

@implementation MyAppController

- (void)shouldAttachRenderDelegate;
{
    self.renderDelegate = [[ScreenshotCreator alloc] init];
}

- (void)createViewHierarchyImpl;
{
    _rootController = [[UnityDefaultViewController alloc] init];
    _rootView       = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    const float w = [_rootView frame].size.width * 0.5f;
    const float h = [_rootView frame].size.height;

    const CGRect unityRect = CGRectMake(0, 0, w, h);
    const CGRect imageRect = CGRectMake(w, 0, w, h);

    _unityView.frame = unityRect;
    _unityView.userInteractionEnabled = YES;
    _unityViewController = [[UIViewController alloc] init];
    _unityViewController.view = _unityView;


    _screenshotView = [[UIImageView alloc] initWithFrame:imageRect];
    _screenshotView.hidden = YES;
    _screenshotView.userInteractionEnabled = NO;

    _screenshotViewController = [[UIViewController alloc] init];
    _screenshotViewController.view = _screenshotView;

    _rootController.view = _rootView;
    [_rootView addSubview:_unityViewController.view];
    [_rootView addSubview:_screenshotViewController.view];

    [_rootView bringSubviewToFront:_unityView];

}
@end


IMPL_APP_CONTROLLER_SUBCLASS(MyAppController);


extern "C" void OnScreenshotDone(const char* filename)
{
    NSURL*  documents   = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject retain];
    NSURL*  fileUrl     = [[documents URLByAppendingPathComponent:[NSString stringWithUTF8String:filename]] retain];
    NSData* imgData     = [NSData dataWithContentsOfURL:fileUrl];

    MyAppController* app = (MyAppController*)GetAppController();
    
    app->_screenshotView.image = [[UIImage imageWithData:imgData] retain];
    app->_screenshotView.hidden = NO;
    [app.rootView layoutSubviews];
}
