# Using Unity VideoPlayer: render video to texture.


## Description

This is a sample of iOS VideoPlayer playing video into unity texture.


##Prerequisites

Unity: 4.2

iOS: 5.0


## How does it work

First of all, playing video into a texture have certain limitations:
* OpenGL ES 2 must be used.
* Only local video can be played.


There are two pieces of interest: VideoPlayerInterface.cs and Plugins/iOS/VideoPlayerInterface.mm.

VideoPlayerInterface.mm contains the simple delegate for VideoPlayer, and several functions that allows to query video information.

Playing video is 2-step process:

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
		playerReady = YES;

		[player playToTexture];
		[player setAudioVolume:1.0f];
	}

VideoPlayerInterface.cs contains c# interface to native VideoPlayer. The main work is done inside videoTexture getter:

	public Texture2D videoTexture
	{
		get
		{
			if(videoReady)
			{
				int nativeTex = VideoPlayer_CurFrameTexture();
				if(_videoTexture == null)
				{
					_videoTexture = Texture2D.CreateExternalTexture(videoWidth, videoHeight, TextureFormat.BGRA32, false, false, (System.IntPtr)nativeTex);
					_videoTexture.filterMode = FilterMode.Bilinear;
					_videoTexture.wrapMode = TextureWrapMode.Repeat;
				}

				_videoTexture.UpdateExternalTexture((System.IntPtr)nativeTex);
			}
			else
			{
				_videoTexture = null;
			}

			return _videoTexture;
		}
	}

Please note, that Texture2D.UpdateExternalTexture must be used, so video playback to texture can be used only with Unity PRO.


## License Information

big_buck_bunny.mp4 is the first minute from the cc-by licenced “open movie” [Big Buck Bunny](http://bigbuckbunny.org/)
