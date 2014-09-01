#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "ScreenshotCreator.h"

@interface MyAppController : UnityAppController
{
}
- (void)shouldAttachRenderDelegate;
@end

@implementation MyAppController

- (void)shouldAttachRenderDelegate;
{
    self.renderDelegate = [[ScreenshotCreator alloc] init];
}
@end


IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)
