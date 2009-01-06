//
//  MXVideoTrackWrapper.m
//  Muxer
//
//  Created by Ryan Walklin on 12/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MXVideoTrackWrapper.h"
#import "h264_raw.h"

@implementation MXVideoTrackWrapper

@synthesize sequenceParameterSet;
@synthesize sequenceParameterSetSize;
@synthesize pictureParameterSet;
@synthesize pictureParameterSetSize;

@synthesize	frameWidth;
@synthesize	frameHeight;
@synthesize anamorphic;
@synthesize anamorphicWidth;
@synthesize anamorphicHeight;
@synthesize pixelHValue;
@synthesize pixelVValue;

-(void)readTrackDescription
{
	// Override to read type-specific info
	MP4FileHandle *sourceHandle = MP4Read([trackSourcePath UTF8String], MP4_VERBOSITY);
	
	if (sourceHandle != MP4_INVALID_FILE_HANDLE)
	{
		MP4GetTrackH264SeqPictHeaders(sourceHandle, trackSourceID, &sequenceParameterSet, &sequenceParameterSetSize, &pictureParameterSet, &pictureParameterSetSize);
		
		frameWidth = MP4GetTrackVideoWidth(sourceHandle, trackSourceID);
		frameHeight = MP4GetTrackVideoHeight(sourceHandle, trackSourceID);
		
		anamorphic = FALSE;
		
		if (MP4HaveTrackAtom(sourceHandle, trackSourceID, "mdia.minf.stbl.stsd.mp4v.pasp"))
		{
			anamorphic = TRUE;
			MP4GetTrackIntegerProperty(sourceHandle, trackSourceID, "mdia.minf.stbl.stsd.mp4v.pasp.hSpacing", &pixelHValue);
			MP4GetTrackIntegerProperty(sourceHandle, trackSourceID, "mdia.minf.stbl.stsd.mp4v.pasp.vSpacing", &pixelVValue);		
			MP4GetTrackFloatProperty(sourceHandle, trackSourceID, "tkhd.width", &anamorphicWidth);
			MP4GetTrackFloatProperty(sourceHandle, trackSourceID, "tkhd.height", &anamorphicHeight);
		}
		else if (MP4HaveTrackAtom(sourceHandle, trackSourceID, "mdia.minf.stbl.stsd.avc1.pasp"))
		{
			anamorphic = TRUE;
			MP4GetTrackIntegerProperty(sourceHandle, trackSourceID, "mdia.minf.stbl.stsd.avc1.pasp.hSpacing", &pixelHValue);
			MP4GetTrackIntegerProperty(sourceHandle, trackSourceID, "mdia.minf.stbl.stsd.avc1.pasp.vSpacing", &pixelVValue);
			MP4GetTrackFloatProperty(sourceHandle, trackSourceID, "tkhd.width", &anamorphicWidth);
			MP4GetTrackFloatProperty(sourceHandle, trackSourceID, "tkhd.height", &anamorphicHeight);
		}
		
		MP4Close(sourceHandle);	
		trackDescription = [NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:MP4FileInfo([trackSourcePath UTF8String], trackSourceID)]
													   forKey:@"generic_track"];
	}
	
}

@end