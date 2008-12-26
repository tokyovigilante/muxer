//
//  Muxer.m
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import "Muxer.h"

#import "MXMP4Wrapper.h"
#import "MXVideoTrackWrapper.h"
#import "MXAudioTrackWrapper.h"


@implementation Muxer

-(id)init
{
	if ((self = [super init]))
	{
		videoTrackArray = [NSMutableArray arrayWithObject:@"Video"]; 
		audioTrackArray = [NSMutableArray arrayWithObject:@"Audio"];
	}
	return self;
}

-(NSInteger)scanSource:(NSString *)source
{
	MP4FileHandle *sourceHandle = MP4Read([source UTF8String], MP4_VERBOSITY);
	if (sourceHandle == MP4_INVALID_FILE_HANDLE) return -1;
	
	NSInteger numTracks = MP4GetNumberOfTracks(sourceHandle, NULL, 0);
	for (NSInteger i=0; i < numTracks; i++)
	{
		NSInteger selectedTrack = MP4FindTrackId(sourceHandle, i, NULL, 0);
		
		const char *trackType = MP4GetTrackType(sourceHandle, selectedTrack);
		
		if (trackType)
		{
			if (strcmp(trackType, MP4_VIDEO_TRACK_TYPE) == 0)
			{
				[videoTrackArray addObject:[[MXVideoTrackWrapper alloc] initWithSourcePath:source trackID:selectedTrack]];
			}
			else if (strcmp(trackType, MP4_AUDIO_TRACK_TYPE) == 0)
			{
				[audioTrackArray addObject:[[MXAudioTrackWrapper alloc] initWithSourcePath:source trackID:selectedTrack]];
			}
			else if (strcmp(trackType, MP4_TEXT_TRACK_TYPE) == 0	)
			{
				// placeholder
			}
			else
			{
				NSLog(@"Ignoring unsupported track (type %s)", trackType);
				continue;
				
			}
		}
	}	
	MP4Close(sourceHandle);
	return numTracks;
}

-(void)muxTarget;
{
	//NSInteger selectedTrack = [TargetView selectedRow];
	
	// iterate through tracks
	// 	MP4FileHandle mp4File = MP4Read("", 0x600);
	
	//MP4SampleId sampleId = MP4_INVALID_SAMPLE_ID;
	
	
	//if ( !mp4File )
	{
	//	return;
	}
	
    //if ( selectedTrack == -1 )
	{
       // uint32_t numTracks = MP4GetNumberOfTracks( mp4File, NULL, 0);
		
        //for ( uint32_t i = 0; i < numTracks; i++ ) 
		{
       //     selectedTrack = MP4FindTrackId( mp4File, i, NULL, 0);
			//[self extractTrackFromFile:mp4File withTrackId:selectedTrack toDestinationFile:NULL];       
		}
    }
    //else 
	{
	//	[self extractTrackFromFile:mp4File withTrackId:selectedTrack toDestinationFile:NULL];
    }
	
    //MP4Close( mp4File );
}

-(void)extractTrackFromFile:(MP4FileHandle)mp4File 
				withTrackId:(MP4TrackId)trackId 
		  toDestinationFile:(char*)dstFileName
{
	// TODO-KB: test io::StdioFile
    char *outMode = "w";
    char outName[1024];
    char *Mp4FileName = "";
	
	if( !dstFileName )
		snprintf( outName, sizeof( outName ), "%s.t%u", Mp4FileName, trackId );
	else
		snprintf( outName, sizeof( outName ), "%s", dstFileName );
	
	FILE *outputHandle = fopen(outName, outMode);
	if (!outputHandle)
	{
		fprintf( stderr, "can't open %s (%s)\n", outName, strerror(errno));
		return;
	}
	
    MP4SampleId numSamples = MP4GetTrackNumberOfSamples( mp4File, trackId );
	
    for (MP4SampleId sampleId = 1; sampleId <= numSamples; sampleId++ ) 
	{
        // signals to ReadSample() that it should malloc a buffer for us
        uint8_t* pSample = NULL;
        uint32_t sampleSize = 0;
		
        if (!MP4ReadSample(mp4File, trackId, sampleId, &pSample, &sampleSize, NULL, NULL, NULL, NULL))
		{
            fprintf(stderr, "Read sample %u for %s failed\n", sampleId, outName);
            break;
        }
		if (!fwrite(pSample, sampleSize, 1, outputHandle))
		{
            fprintf(stderr, "Write to %s failed (%s)\n", outName, strerror(errno));
            break;
        }
		
		free( pSample );
	}
	
	
	fclose(outputHandle);
	
}

-(NSInteger)sourceTrackCount
{
	return [videoTrackArray count] + [audioTrackArray count];
}

-(MXTrackWrapper *)trackWithIndex:(NSInteger)index
{
	NSInteger offset = index;
	if (offset < [videoTrackArray count])
	{
		return [videoTrackArray objectAtIndex:offset];
	} 
	offset -= [videoTrackArray count];
	return [audioTrackArray objectAtIndex:offset];
}

-(BOOL)isTrackGroupRow:(NSInteger)row
{
	NSInteger offset = row;
	if (offset < [videoTrackArray count])
	{
		return [[videoTrackArray objectAtIndex:offset] isKindOfClass:[NSString class]];
	}
	offset -= [videoTrackArray count];
	return [[audioTrackArray objectAtIndex:offset] isKindOfClass:[NSString class]];
}

-(void)removeTrackAtIndex:(NSInteger)index
{
	NSInteger offset = index;
	if (offset < [videoTrackArray count])
	{
		[videoTrackArray removeObjectAtIndex:offset];
		return;
	}
	offset -= [videoTrackArray count];
	[audioTrackArray removeObjectAtIndex:offset];
	return;
}

@end
