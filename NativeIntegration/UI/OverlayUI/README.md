# Integrating Unity and iOS native UI
# Part 1:
# Overlay native UI


## Description

This sample shows how to overlay UIDatePicker on top of Unity app and send data back to Unity app.


##Prerequisites

Unity: 4.2

iOS: any


## How does it work

There are three pieces of interest: ShowDatePicker.cs, Plugins/iOS/MyAppController.mm and Plugins/iOS/MyViewController.mm.

In Plugins/iOS/MyAppController.mm we subclass Unity's AppController and provide our own view controller

	- (void)createViewHierarchyImpl;
	{
		_rootController = [[MyViewController alloc] init];
		_rootView = _unityView;
	}

Please note this line:

	IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)

You must add this, so Unity knows that you want your class as UIApplication delegate

In Plugins/iOS/MyViewController.mm we implement out view controller: it is subclassed from UnityViewController and adds UIDatePicker handling on top.

Please note, that in didRotateFromInterfaceOrientation we do call super's impl (so unity can handle the rotation) and tweak UIDatePicker's frame

	- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
	{
		[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
		_datePicker.frame = self.view.bounds;
	}

To pass date from obj-c to Unity we do these two things:
in ShowDatePicker.cs

	private delegate void StringParamDelegate(string str);
	[DllImport("__Internal")]
	private static extern void ShowNativeDatePicker(StringParamDelegate dateSelected);

	[MonoPInvokeCallback(typeof(StringParamDelegate))]
	public static void DateSelectedCallback(string str)
	{
		_CurDate = str;
	}

	...

	ShowNativeDatePicker(DateSelectedCallback);

and in Plugins/iOS/MyViewController.mm

	extern "C" typedef void (*DateSelectedCallback)(const char *);
	extern "C" void ShowNativeDatePicker(DateSelectedCallback dateSelected)
	{
		[(MyViewController*)UnityGetGLViewController() showDatePicker:dateSelected];
	}

	...

	- (void)showDatePicker:(DateSelectedCallback)callback
	{
		_dateSelected = callback;
		[self showDatePickerView];
	}

	...

	- (void)dateChanged:(id)sender
	{
		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];

		_dateSelected([[dateFormatter stringFromDate:_datePicker.date] UTF8String]);
	}

