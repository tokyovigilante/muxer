//
//  MXAudioTrackWrapper.m
//  Muxer
//
//  Created by Ryan Walklin on 12/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MXAudioTrackWrapper.h"


@implementation MXAudioTrackWrapper


-(void)readTrackData
{
	// Override to read type-specific info
	MP4FileHandle *sourceHandle = MP4Read([trackSourcePath UTF8String], MP4_VERBOSITY);
	
	if (sourceHandle != MP4_INVALID_FILE_HANDLE)
	{
		trackType = (char *)MP4GetTrackType(sourceHandle, trackSourceID);
		MP4Close(sourceHandle);	
		trackDescription = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:MP4FileInfo([trackSourcePath UTF8String], trackSourceID)]
													   forKey:@"generic_track"];
	}
	
}


@end
