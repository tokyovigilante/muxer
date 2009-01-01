//
//  MXAudioTrackWrapper.m
//  Muxer
//
//  Created by Ryan Walklin on 12/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MXAudioTrackWrapper.h"


@implementation MXAudioTrackWrapper

@synthesize trackName;
@synthesize esConfig;
@synthesize esConfigSize;
@synthesize channelCount;
@synthesize language;

-(void)readTrackDescription
{
	// Override to read type-specific info
	MP4FileHandle *sourceHandle = MP4Read([trackSourcePath UTF8String], MP4_VERBOSITY);
	
	if (sourceHandle != MP4_INVALID_FILE_HANDLE)
	{
		samplerate = MP4GetTrackTimeScale(sourceHandle, trackSourceID);
		
		uint8_t byteProperty[1024];
		uint32_t bytePropertySize;
		if (MP4GetTrackBytesProperty(sourceHandle, trackSourceID, "udta.name.value", (uint8_t**)&byteProperty, &bytePropertySize))
		{
			if (bytePropertySize > 0)
			{
				byteProperty[bytePropertySize] = '\0';
				trackName = [NSString stringWithCharacters:(const unichar *)byteProperty length:bytePropertySize];
			}
			else trackName = @"Default audio";
		}
		else trackName = @"Default audio";
		
		MP4GetTrackESConfiguration(sourceHandle, trackSourceID, &esConfig, &esConfigSize);		
		
		channelCount = MP4GetTrackAudioChannels(sourceHandle, trackSourceID);
		MP4GetTrackIntegerProperty(sourceHandle, trackSourceID, "mdia.mdhd.language", (uint64_t *)&language);

		MP4Close(sourceHandle);	
		
		trackDescription = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:MP4FileInfo([trackSourcePath UTF8String], trackSourceID)]
													   forKey:@"generic_track"];
	}
	
}


@end
