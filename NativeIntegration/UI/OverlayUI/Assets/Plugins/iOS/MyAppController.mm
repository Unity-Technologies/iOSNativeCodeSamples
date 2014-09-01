#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "UI/UnityView.h"
#import "MyViewController.h"

@interface MyAppController : UnityAppController
{
}
- (void)createViewHierarchyImpl;
@end
@implementation MyAppController
- (void)createViewHierarchyImpl;
{
    _rootController = [[MyViewController alloc] init];
    _rootView = _unityView;
}
@end

IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)
