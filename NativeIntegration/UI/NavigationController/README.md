# Integrating Unity and iOS native UI
# Part 2:
# Inserting Unity inside NavigationController


## Description

This sample shows how to insert Unity view inside UINavigationController.


##Prerequisites

Unity: 4.2

iOS: any


## How does it work

All the code goes into Plugins/iOS/MyAppController.mm

First we subclass Unity's AppController and create our own view hierarchy.

	_rootController	= [[UnityDefaultViewController alloc] init];
	_rootView		= [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

Please note, that as we make root view controller to be default unity one, we shouldnt care about proper unity orientation (as it will be done automatically).
Check UnityAppController.mm in trampoline:

	- (void)createViewHierarchy
	{
		[self createViewHierarchyImpl];
		[...]
		_rootController.wantsFullScreenLayout = TRUE;
		_rootController.view = _rootView;
		if([_rootController isKindOfClass: [UnityViewControllerBase class]])
			[(UnityViewControllerBase*)_rootController assignUnityView:_unityView];
	}

we will assign unity view and UnityDefaultViewController will take care of correct rotation.

The creation of navigation conroller is straigforward

	_embedController1 = [[UIViewController alloc] init];
	_embedController1.view = _unityView;
	[...]
	_embedController2 = [[UIViewController alloc] init];
	_embedController2.view = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[...]

	_rootController.view = _rootView;
	_navController = [[UINavigationController alloc] initWithRootViewController:_embedController1];
	[_rootView addSubview:_navController.view];

We create two controllers: one with unity content and other with UIWebView, and add former to navigation controller.

Please note this line:

	IMPL_APP_CONTROLLER_SUBCLASS(MyAppController)

You must add this, so Unity knows that you want your class as UIApplication delegate


