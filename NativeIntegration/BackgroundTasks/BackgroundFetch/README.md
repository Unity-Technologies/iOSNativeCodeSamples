# Basic support for background execution


## Description

This sample shows how to add support for background executions (in this case - fetching data from internet).


##Prerequisites

Unity: 2022

iOS: iOS 13+


#Caveats

Background fetch happens at "random" intervals (it is up to iOS to call you), so for debugging you want to use Debug -> Simulate Simulate Background Fetch


## How does it work

All the code goes into Plugins/iOS/MyAppController.mm

All we need to do is just subclass unity AppController and implement

	-(void)application:(UIApplication*)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;


After fetching data, we do call UnityBatchPlayerLoop which will run one unity loop iteration, which will in turn call Update on scripts.

In our case Update looks like that:

	void Update()
	{
		if (fetchedText == null)
		{
			fetchedText = QueryFetchedText();
			if (fetchedText != null)
			if (fetchedText != null)
			{
				Debug.Log("Just Fetched: " + fetchedText);
				text.text = fetchedText;
			}
		}
	}

so you will see it logged immediately (even though app is in background)

Note that we have enabled "Enable Custom Background Behaviors" and "Background fetch" in Player Settings.
