#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "UI/UnityView.h"
#import "UI/UnityViewControllerBase.h"

#if UNITY_VERSION < 450
    #import "iPhone_View.h"
#endif

@interface MyAppController : UnityAppController
{
    UINavigationController*     _navController;
    UIViewController*           _embedController1;
    UIViewController*           _embedController2;
}
- (void)createViewHierarchyImpl;
@end

@implementation MyAppController
- (void)createViewHierarchyImpl;
{
    _rootController = [[UnityViewControllerBase alloc] init];
    _rootView       = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    _embedController1 = [[UIViewController alloc] init];
    _embedController1.view = _unityView;
    _embedController1.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Right" style:UIBarButtonItemStyleBordered target:self action:@selector(moveRight:)];

    _embedController2 = [[UIViewController alloc] init];
    _embedController2.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Left" style:UIBarButtonItemStyleBordered target:self action:@selector(moveLeft:)];

    _embedController2.view = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [(UIWebView*)_embedController2.view loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.unity3d.com"]]];

    _rootController.view = _rootView;

    _navController = [[UINavigationController alloc] initWithRootViewController:_embedController1];
    [_rootView addSubview:_navController.view];
}
- (void)moveRight:(id)sender
{
    [_navController pushViewController:_embedController2 animated:NO];
}
- (void)moveLeft:(id)sender
{
    [_navController popViewControllerAnimated:NO];
}

@end

IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)
