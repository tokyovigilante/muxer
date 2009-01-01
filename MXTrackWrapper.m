//
//  MXTrackWrapper.m
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import "MXTrackWrapper.h"

@implementation MXTrackWrapper
@synthesize trackSourcePath;
@synthesize trackSourceID;
@synthesize trackTargetID;
@synthesize trackDescription;

@synthesize samplerate;
@synthesize bitrate;
@synthesize duration;


-(id)initWithSourcePath:(NSString *)source trackID:(NSInteger)trackID
{
	if ((self = [super init]))
	{
		trackSourcePath = source;
		trackSourceID = trackID;
	}
	[self readTrackType];
	
		return self;
}

-(void)readTrackType
{
	// Override to read type-specific info
	MP4FileHandle *sourceHandle = MP4Read([trackSourcePath UTF8String], MP4_VERBOSITY);
	
	if (sourceHandle != MP4_INVALID_FILE_HANDLE)
	{
		trackType = (char *)MP4GetTrackType(sourceHandle, trackSourceID);
		bitrate = (double)MP4GetTrackBitRate(sourceHandle, trackSourceID) / 1024;
		duration = (double)MP4ConvertFromTrackDuration(sourceHandle, trackSourceID, MP4GetTrackDuration(sourceHandle, trackSourceID), MP4_MSECS_TIME_SCALE) / 1000;
		samplerate = MP4GetTrackTimeScale(sourceHandle, trackSourceID);
		MP4Close(sourceHandle);
		[self readTrackDescription];
	}
	
}

-(void)readTrackDescription
{
	trackDescription = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:MP4FileInfo([trackSourcePath UTF8String], trackSourceID)]
												   forKey:@"generic_track"];
}

-(void)finalize
{
	free(trackType);
	[super finalize];
}

@end
