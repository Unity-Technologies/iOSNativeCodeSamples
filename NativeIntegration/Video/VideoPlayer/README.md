# Using Unity VideoPlayer


## Description

This is a sample of iOS VideoPlayer playing video in UIView. It shows playback of both mp4 from StreamingAssets folders (local) and streaming mp4 from internet.


##Prerequisites

Unity: 4.2

iOS: any


## How does it work

There are two pieces of interest: TestVideoPlayer.cs and Plugins/iOS/VideoPlayerInterface.mm.

VideoPlayerInterface.mm contains the simple delegate for VideoPlayer.

Please notice that it also handles orientation, as we dont add to unity view controller:

	- (void)orientationDidChange:(NSNotification *)notification
	{
		CGRect bounds = UnityGetGLView().bounds;
		view.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
	}

and

	if(!player)
	{
		player = [[VideoPlayerScripting alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:player selector:@selector(orientationDidChange:) name:kUnityViewDidRotate object:nil];
	}

Also, playing video is 2-step process:

first we load it:

	if(!player)
	{
		player = [[VideoPlayer alloc] init];
		player.delegate = self;
	}

	[player loadVideo:url];

and start playing it only when it is ready:

	- (void)onPlayerReady
	{
		CGRect bounds = UnityGetGLView().bounds;

		if(!view)
			view = [[VideoPlayerView alloc] initWithFrame: bounds];

		view.bounds = CGRectMake(0,0, [player videoSize].width, [player videoSize].height);
		view.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);

		[UnityGetGLView() addSubview: view];
		[player playToView:view];
		[player setAudioVolume:0.5f];
	}

While in this sample we just center view, you have full control over this view.


## License Information

big_buck_bunny.mp4 is the first minute from the cc-by licenced “open movie” [Big Buck Bunny](http://bigbuckbunny.org/)
