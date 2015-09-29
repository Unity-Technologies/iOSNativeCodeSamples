#ifndef UnityReplayKit_h
#define UnityReplayKit_h


@interface UnityReplayKit : NSObject<RPPreviewViewControllerDelegate, RPScreenRecorderDelegate>
{
}

@property(nonatomic, readonly, getter=getLastError)  NSString* lastError;

@property(nonatomic, readonly, getter=getPreviewController) RPPreviewViewController* previewController;

- (BOOL)screenRecordingAvailable;

- (NSString*)getLastError;
- (RPPreviewViewController*)getPreviewController;
- (BOOL)startRecoring:(BOOL)enableMicrophone;
- (BOOL)recording;
- (BOOL)stopRecording;
- (void)screenRecorder:(nonnull RPScreenRecorder*)screenRecorder didStopRecordingWithError:(nonnull NSError*)error previewViewController:(nullable RPPreviewViewController*)previewViewController;
- (BOOL)preview;
- (BOOL)discard;
- (void)previewControllerDidFinish:(RPPreviewViewController*)previewController;
@end



#endif /* UnityReplayKit_h */
