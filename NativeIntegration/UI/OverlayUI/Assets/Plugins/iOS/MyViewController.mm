#import "MyViewController.h"
#if UNITY_VERSION < 450
    #import "iPhone_View.h"
#endif

extern "C" typedef void (*DateSelectedCallback)(const char *);

@implementation MyViewController
{
    DateSelectedCallback    _dateSelected;
    UIDatePicker*           _datePicker;
}
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

        _datePicker.frame = self.view.bounds;
        _datePicker.hidden = YES;

        [_datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    }

    _datePicker.hidden = NO;
    [self.view addSubview:_datePicker];
}

- (void)hideDatePicker
{
    [_datePicker removeFromSuperview];
    _datePicker.hidden = YES;
}

- (void)dateChanged:(id)sender
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    _dateSelected([[dateFormatter stringFromDate:_datePicker.date] UTF8String]);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    _datePicker.frame = self.view.bounds;
}
@end

extern "C" void ShowNativeDatePicker(DateSelectedCallback dateSelected)
{
    [(MyViewController*)UnityGetGLViewController() showDatePicker:dateSelected];
}

extern "C" void HideNativeDatePicker()
{
    [(MyViewController*)UnityGetGLViewController() hideDatePicker];
}
