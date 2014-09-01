#import <UIKit/UIKit.h>
#import "UI/UnityViewControllerBase.h"

#if UNITY_VERSION < 450
    #import "iPhone_View.h"
#endif

@interface MyViewController : UnityDefaultViewController
{
}
@end
