#import <AssetsLibrary/AssetsLibrary.h>

static NSMutableArray *collector = nil;
static bool done = false;
static ALAssetsLibrary* al = nil;

extern "C" void RequestImages()
{
    if (collector != nil)
        return;

    collector = [[NSMutableArray alloc] initWithCapacity: 0];

    NSLog(@"ListGalleryImages\n");

    if (!al)
        al = [[ALAssetsLibrary alloc] init];

    [al enumerateGroupsWithTypes: ALAssetsGroupSavedPhotos
     usingBlock:^(ALAssetsGroup *group, BOOL *stop)
    {
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop)
        {
            if (asset)
            {
                [collector addObject: asset];
                NSLog(@"Found asset: %@ !\n", [[asset defaultRepresentation] url]);
            }
        }];

        done = true;
    }
     failureBlock:^(NSError *error) { done = true; NSLog(@"Image gallery scanning failed: %@!\n", error); }
    ];
}

extern "C" bool GetGalleryLoadingFinished()
{
    NSLog(@"Finished? %@\n", done ? @"YES" : @"NO");
    return done;
}

extern "C" int GetGalleryImageCount()
{
    return [collector count];
}

extern "C" void* GetGalleryImage(int idx, int* sz)
{
    if (collector == nil || idx >= [collector count])
        return NULL;

    ALAsset* theAsset = [collector objectAtIndex: idx];

    long long sizeOfRawDataInBytes = [[[collector objectAtIndex: idx] defaultRepresentation] size];
    *sz = (int)sizeOfRawDataInBytes;

    NSMutableData* rawData = [[NSMutableData alloc]initWithCapacity: sizeOfRawDataInBytes];
    uint8_t* bufferPointer = (uint8_t*)[rawData mutableBytes];

    NSError* error = nil;
    [[theAsset defaultRepresentation] getBytes: bufferPointer fromOffset: 0 length: sizeOfRawDataInBytes error: &error];
    if (error)
    {
        NSLog(@"Getting bytes failed with error: %@\n", error);
        return NULL;
    }

    return (__bridge_retained void*)rawData;
}

extern "C" void* GetImageBuffer(NSMutableData * rawData)
{
    return [rawData mutableBytes];
}

extern "C" void ReleaseImage(NSMutableData* rawData)
{
    CFRelease((CFTypeRef)rawData);
}
