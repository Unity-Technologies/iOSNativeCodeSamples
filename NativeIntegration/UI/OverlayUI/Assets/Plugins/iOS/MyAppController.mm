#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "UnityAppController+ViewHandling.h"
#import "UI/UnityView.h"
#import "UI/OrientationSupport.h"


extern "C" typedef void (*DateSelectedCallback)(const char *);

@interface MyAppController : UnityAppController
{
    DateSelectedCallback    _dateSelected;
    UIDatePicker*           _datePicker;
}
@end

@implementation MyAppController

- (void)showDatePicker:(DateSelectedCallback)callback
{
    _dateSelected = callback;
    [self showDatePickerView];
}

- (void)showDatePickerView
{
    if(_datePicker == nil)
    {
        _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
        _datePicker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _datePicker.datePickerMode = UIDatePickerModeDate;
        _datePicker.frame = self.rootView.bounds;
        _datePicker.hidden = YES;

        [_datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    }

    _datePicker.hidden = NO;
    [self.rootView addSubview:_datePicker];
}

- (void)hideDatePicker
{
    [_datePicker removeFromSuperview];
    _datePicker.hidden = YES;
}

- (void)interfaceDidChangeOrientationFrom:(UIInterfaceOrientation)fromInterfaceOrientation
{
    _datePicker.frame = self.rootView.bounds;
}

- (void)dateChanged:(id)sender
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    _dateSelected([[dateFormatter stringFromDate:_datePicker.date] UTF8String]);
}
@end



extern "C" void ShowNativeDatePicker(DateSelectedCallback dateSelected)
{
    [(MyAppController*)GetAppController() showDatePicker:dateSelected];
}

extern "C" void HideNativeDatePicker()
{
    [(MyAppController*)GetAppController() hideDatePicker];
}

IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)
