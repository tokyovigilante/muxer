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

#import "h264_raw.h"

typedef enum { TRACK_DISABLED = 0x0, TRACK_ENABLED = 0x1, TRACK_IN_MOVIE = 0x2, TRACK_IN_PREVIEW = 0x4, TRACK_IN_POSTER = 0x8}  track_header_flags;

@implementation Muxer

#pragma mark -
#pragma mark Init

-(id)init
{
	if ((self = [super init]))
	{
		videoTrackArray = [NSMutableArray arrayWithObject:@"Video"]; 
		audioTrackArray = [NSMutableArray arrayWithObject:@"Audio"];
	}
	return self;
}

#pragma mark -
#pragma mark Source handling

-(NSInteger)scanSource:(NSString *)source
{
	NSInteger numTracks = 0;
	
	if ([[source pathExtension] isEqualToString:@"h264"])
	{
		// treat as raw H.264
		numTracks = 1;
		
		MP4FileHandle *tempHandle = MP4Create([[[source stringByDeletingPathExtension] stringByAppendingPathExtension:@"mp4"] UTF8String], MP4_DETAILS_ERROR, MP4_CREATE_64BIT_DATA);
		MP4SetTimeScale(tempHandle, 48000);
		if (H264Creator(tempHandle, fopen([source UTF8String], "r"), 23.976216, 48000) == MP4_INVALID_TRACK_ID)
		{
			NSLog(@"Unable to parse %@ as raw H.264 stream", [source lastPathComponent]);
			MP4Close(tempHandle);
			return 0;
		}

		MP4Close(tempHandle);
		MP4Optimize([source UTF8String], NULL, MP4_VERBOSITY);
	}
	
	else if ([[source pathExtension] isEqualToString:@"ac3"])
	{
		// AC3 raw stream
	}
	
	else // MP4 source
	{
		MP4FileHandle *sourceHandle = MP4Read([source UTF8String], MP4_VERBOSITY);
		if (sourceHandle == MP4_INVALID_FILE_HANDLE) return -1;
		
		numTracks = MP4GetNumberOfTracks(sourceHandle, NULL, 0);
		NSLog(@"Scanning %@, found %i tracks", [source lastPathComponent], numTracks);
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
	}

	return numTracks;
}

-(NSInteger)sourceTrackCount
{
	return [videoTrackArray count] + [audioTrackArray count];
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

#pragma mark -
#pragma mark Interface queries

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

-(void)broadcastNotification:(NSString *)status progress:(double)progress isIndeterminate:(BOOL)indeterminate enableInterface:(BOOL)interface
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	NSDictionary *notificationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:status, @"status",
											[NSNumber numberWithDouble:progress], @"progress",
											[NSNumber numberWithBool:indeterminate], @"indeterminate",
											[NSNumber numberWithBool:interface], @"interface", nil];
											
	[notificationCenter postNotificationName:@"status" object:self userInfo:notificationDictionary];
}

#pragma mark -
#pragma mark Muxer control

-(BOOL)muxTargetToFile:(NSString *)outputFile
{
	[self broadcastNotification:@"Muxing..."
					   progress:0.0
				isIndeterminate:TRUE 
				enableInterface:FALSE];
	
	MP4TrackId videoTrack;
	MXVideoTrackWrapper * videoTrackWrapper = [videoTrackArray objectAtIndex:1];
	
	// get timescale from first audio track
	/* When using the standard 90000 timescale, QuickTime tends to have
	 synchronization issues (audio not playing at the correct speed).
	 To workaround this, we use the audio samplerate as the
	 timescale */
	
	if ([audioTrackArray count] > 1)
	{
		timescale = [[audioTrackArray objectAtIndex:1] samplerate];
	}
	else timescale = 90000;
	
	if ([self calculateOutputSize] > 4000)
	{
		targetMP4 = MP4Create([outputFile UTF8String], MP4_DETAILS_ERROR, MP4_CREATE_64BIT_DATA );
		NSLog(@"Enabling 64 bit file support");
	}
	else
	{
		targetMP4 = MP4Create([outputFile UTF8String], MP4_DETAILS_ERROR, 0 );
	}
	
	if (targetMP4 == MP4_INVALID_FILE_HANDLE)
    {
		NSLog(@"Muxer: MP4Create failed!");
        return -1;
    }
	
	if (!(MP4SetTimeScale(targetMP4, timescale)))
    {
        NSLog(@"Muxer: MP4SetTimeScale failed!");
        return 0;
    }
		
    if(1)// job->vcodec == HB_VCODEC_X264 )
    {
        /* Stolen from mp4creator */
        MP4SetVideoProfileLevel( targetMP4, 0x7F );
		
		
		uint8_t **sequenceParameterSet = [videoTrackWrapper sequenceParameterSet];
		uint32_t *sequenceParameterSetSize = [videoTrackWrapper sequenceParameterSetSize];
		uint8_t sps[4];
		if (*sequenceParameterSetSize >= 4)
		{
			memcpy(&sps, *sequenceParameterSet, 4);
		}
		videoTrack = MP4AddH264VideoTrack(targetMP4, timescale,
													 MP4_INVALID_DURATION, [videoTrackWrapper frameWidth], 
													 [videoTrackWrapper	frameHeight],
													 sps[1], /* AVCProfileIndication */
													 sps[2], /* profile_compat */
													 sps[3], /* AVCLevelIndication */
													 3);      /* 4 bytes length before each NAL unit */
		[videoTrackWrapper setTrackTargetID:videoTrack];
		 		
        MP4AddH264SequenceParameterSet(targetMP4, videoTrack, *sequenceParameterSet, *sequenceParameterSetSize);
		
		uint8_t **pictureParameterSet = [videoTrackWrapper pictureParameterSet];
		uint32_t *pictureParameterSetSize = [videoTrackWrapper pictureParameterSetSize];
        MP4AddH264PictureParameterSet(targetMP4, videoTrack, *pictureParameterSet, *pictureParameterSetSize);
		
		//if( job->h264_level == 30 || job->ipod_atom)
		{
			NSLog(@"muxmp4: adding iPod atom");
			MP4AddIPodUUID(targetMP4, videoTrack);
		}
		
        //m->init_delay = job->config.h264.init_delay;
    }
#if 0
    else /* FFmpeg or XviD */
    {
        MP4SetVideoProfileLevel( m->file, MPEG4_SP_L3 );
        mux_data->track = MP4AddVideoTrack( m->file, m->samplerate,
										   MP4_INVALID_DURATION, job->width, job->height,
										   MP4_MPEG4_VIDEO_TYPE );
        if (mux_data->track == MP4_INVALID_TRACK_ID)
        {
            hb_error("muxmp4.c: MP4AddVideoTrack failed!");
            *job->die = 1;
            return 0;
        }
		
		
        /* VOL from FFmpeg or XviD */
        if (!(MP4SetTrackESConfiguration( m->file, mux_data->track,
										 job->config.mpeg4.bytes, job->config.mpeg4.length )))
        {
            hb_error("muxmp4.c: MP4SetTrackESConfiguration failed!");
            *job->die = 1;
            return 0;
        }
	}
#endif
	
    // COLR atom for color and gamma correction.
    // Per the notes at:
    //   http://developer.apple.com/quicktime/icefloe/dispatch019.html#colr
    //   http://forum.doom9.org/showthread.php?t=133982#post1090068
    
	if ([videoTrackWrapper frameWidth] >= 1280 || [videoTrackWrapper frameHeight] >= 720)
    {
        // we guess that 720p or above is ITU BT.709 HD content
        MP4AddColr(targetMP4, videoTrack, 1, 1, 1);
    }
    else
    {
        // ITU BT.601 DVD or SD TV content
        MP4AddColr(targetMP4, videoTrack, 6, 1, 6);
    }

	// Anamorphic support
    if([videoTrackWrapper anamorphic])
    {
        MP4AddPixelAspectRatio(targetMP4, videoTrack, (uint32_t)[videoTrackWrapper pixelHValue], (uint32_t)[videoTrackWrapper pixelVValue]);
		MP4SetTrackFloatProperty(targetMP4, videoTrack, "tkhd.width", [videoTrackWrapper anamorphicWidth]);
    }
	
	// Audio tracks	
	for (NSInteger i=1; i < [audioTrackArray count]; i++)
	{
		MXAudioTrackWrapper * audioTrackWrapper = [audioTrackArray objectAtIndex:i];
		MP4TrackId audioTrack;
		
		if (0) // AC3
		{
#if 0
			/* add the audio tracks */
			for( i = 0; i < hb_list_count( title->list_audio ); i++ )
			{
				static uint8_t reserved2[16] = {
					0x00, 0x00, 0x00, 0x00,
					0x00, 0x00, 0x00, 0x00,
					0x00, 0x02, 0x00, 0x10,
					0x00, 0x00, 0x00, 0x00,
				};
				
				audio = hb_list_item( title->list_audio, i );
				mux_data = malloc( sizeof( hb_mux_data_t ) );
				audio->priv.mux_data = mux_data;
				
				if( audio->config.out.codec == HB_ACODEC_AC3 )
				{
					uint8_t fscod = 0;
					uint8_t bsid = audio->config.in.version;
					uint8_t bsmod = audio->config.in.mode;
					uint8_t acmod = audio->config.flags.ac3 & 0x7;
					uint8_t lfeon = (audio->config.flags.ac3 & A52_LFE) ? 1 : 0;
					uint8_t bit_rate_code = 0;
					
					/*
					 * Rewrite AC3 information into correct format for dac3 atom
					 */
					switch( audio->config.in.samplerate )
					{
						case 48000:
							fscod = 0;
							break;
						case 44100:
							fscod = 1;
							break;
						case 32000:
							fscod = 2;
							break;
						default:
							/*
							 * Error value, tells decoder to not decode this audio.
							 */
							fscod = 3;
							break;
					}
					
					switch( audio->config.in.bitrate )
					{
						case 32000:
							bit_rate_code = 0;
							break;
						case 40000:
							bit_rate_code = 1;
							break;
						case 48000:
							bit_rate_code = 2;
							break;
						case 56000:
							bit_rate_code = 3;
							break;
						case 64000:
							bit_rate_code = 4;
							break;
						case 80000:
							bit_rate_code = 5;
							break;
						case 96000:
							bit_rate_code = 6;
							break;
						case 112000:
							bit_rate_code = 7;
							break;
						case 128000:
							bit_rate_code = 8;
							break;
						case 160000:
							bit_rate_code = 9;
							break;
						case 192000:
							bit_rate_code = 10;
							break;
						case 224000:
							bit_rate_code = 11;
							break;
						case 256000:
							bit_rate_code = 12;
							break;
						case 320000:
							bit_rate_code = 13;
							break;
						case 384000:
							bit_rate_code = 14;
							break;
						case 448000:
							bit_rate_code = 15;
							break;
						case 512000:
							bit_rate_code = 16;
							break;
						case 576000:
							bit_rate_code = 17;
							break;
						case 640000:
							bit_rate_code = 18;
							break;
						default:
							hb_error("Unknown AC3 bitrate");
							bit_rate_code = 0;
							break;
					}
					
					mux_data->track = MP4AddAC3AudioTrack(
														  m->file,
														  m->samplerate, 
														  fscod,
														  bsid,
														  bsmod,
														  acmod,
														  lfeon,
														  bit_rate_code);
					
					if (audio->config.out.name == NULL) {
						MP4SetTrackBytesProperty(
												 m->file, mux_data->track,
												 "udta.name.value",
												 (const uint8_t*)"Surround", strlen("Surround"));
					}
					else
					{
						MP4SetTrackBytesProperty(
												 m->file, mux_data->track,
												 "udta.name.value",
												 (const uint8_t*)(audio->config.out.name),
												 strlen(audio->config.out.name));
					}
				}
			}
		
#endif
		}
		else // MP4
		{
			audioTrack = MP4AddAudioTrack(targetMP4, timescale, 1024, MP4_MPEG4_AUDIO_TYPE);
			[audioTrackWrapper setTrackTargetID:audioTrack];
			
			MP4SetTrackBytesProperty(targetMP4, 
									 audioTrack, 
									 "udta.name.value", 
									 (const uint8_t *)[[audioTrackWrapper trackName] UTF8String], 
									 [[audioTrackWrapper trackName] length]);
			
			MP4SetAudioProfileLevel(targetMP4, 0x0F);
			MP4SetTrackESConfiguration(targetMP4, audioTrack, [audioTrackWrapper esConfig], [audioTrackWrapper esConfigSize]);
			
			/* Set the correct number of channels for this track */
			MP4SetTrackIntegerProperty(targetMP4, audioTrack, "mdia.minf.stbl.stsd.mp4a.channels", [audioTrackWrapper channelCount]);
		}
		
		/* Set the language for this track */
		/* The language is stored as 5-bit text - 0x60 */
		MP4SetTrackIntegerProperty(targetMP4, audioTrack, "mdia.mdhd.language", [audioTrackWrapper language]);
		
		
		if (i == 1)
		{
			/* Enable the first audio track */
			MP4SetTrackIntegerProperty(targetMP4, audioTrack, "tkhd.flags", (TRACK_ENABLED | TRACK_IN_MOVIE));
		}
		else
		{
			/* Set the audio track alternate group */
			MP4SetTrackIntegerProperty(targetMP4, audioTrack, "tkhd.alternate_group", 1);
			
			/* Disable the other audio tracks so QuickTime doesn't play them all at once. */
			MP4SetTrackIntegerProperty(targetMP4, audioTrack, "tkhd.flags", (TRACK_DISABLED | TRACK_IN_MOVIE));
		}
	}
	
			
#if 0

    if (job->chapter_markers)
    {
        /* add a text track for the chapters. We add the 'chap' atom to track
		 one which is usually the video track & should never be disabled.
		 The Quicktime spec says it doesn't matter which media track the
		 chap atom is on but it has to be an enabled track. */
        MP4TrackId textTrack;
        textTrack = MP4AddChapterTextTrack(m->file, 1, 0);
		
        m->chapter_track = textTrack;
        m->chapter_duration = 0;
        m->current_chapter = job->chapter_start;
    }
	
    /* Add encoded-by metadata listing version and build date */
    char *tool_string;
    tool_string = (char *)malloc(80);
    snprintf( tool_string, 80, "HandBrake %s %i", HB_VERSION, HB_BUILD);
    MP4SetMetadataTool(m->file, tool_string);
    free(tool_string);
	
    return 0;
#endif
	MXTrackWrapper * currentTrack = [videoTrackArray objectAtIndex:1];
	
	MP4FileHandle sourceMP4 = MP4Read([[currentTrack trackSourcePath] UTF8String], MP4_VERBOSITY);
			
	MP4SampleId numSamples = MP4GetTrackNumberOfSamples(sourceMP4, [currentTrack trackSourceID]);
	
	MP4Timestamp	startTime;
    MP4Duration		duration;
    MP4Duration		renderingOffset;
    bool			isSyncSample;
	
    for (MP4SampleId sampleId = 1; sampleId <= numSamples; sampleId++ ) 
	{
        // signals to ReadSample() that it should malloc a buffer for us
        uint8_t* pSample = NULL;
        uint32_t sampleSize = 0;
		
        if (!MP4ReadSample(sourceMP4, [currentTrack trackSourceID], sampleId, &pSample, &sampleSize, &startTime, &duration, &renderingOffset, &isSyncSample))
		{
            fprintf(stderr, "Read sample %u for %s failed\n", sampleId, [[currentTrack trackSourcePath] UTF8String]);
            break;
        }
		if (!MP4WriteSample(targetMP4, [currentTrack trackTargetID], pSample, sampleSize, duration, renderingOffset, isSyncSample))
		{
            fprintf(stderr, "Write to %s failed (%s)\n", [outputFile UTF8String], strerror(errno));
            break;
        }
		
		free( pSample );
	}
	MP4Close(sourceMP4);
	
	currentTrack = [audioTrackArray objectAtIndex:1];
	sourceMP4 = MP4Read([[currentTrack trackSourcePath] UTF8String], MP4_VERBOSITY);
	numSamples = MP4GetTrackNumberOfSamples(sourceMP4, [currentTrack trackSourceID]);

	for (MP4SampleId sampleId = 1; sampleId <= numSamples; sampleId++ ) 
	{
        // signals to ReadSample() that it should malloc a buffer for us
        uint8_t* pSample = NULL;
        uint32_t sampleSize = 0;
		
        if (!MP4ReadSample(sourceMP4, [currentTrack trackSourceID], sampleId, &pSample, &sampleSize, &startTime, &duration, &renderingOffset, &isSyncSample))
		{
            fprintf(stderr, "Read sample %u for %s failed\n", sampleId, [[currentTrack trackSourcePath] UTF8String]);
            break;
        }
		if (!MP4WriteSample(targetMP4, [currentTrack trackTargetID], pSample, sampleSize, duration, renderingOffset, isSyncSample))
		{
            fprintf(stderr, "Write to %s failed (%s)\n", [outputFile UTF8String], strerror(errno));
            break;
        }
		
		free( pSample );
	}
	MP4Close(sourceMP4);
	
	MP4Close(targetMP4);

	MP4Optimize([outputFile UTF8String], NULL, MP4_DETAILS_ERROR );
	
	[self broadcastNotification:[NSString stringWithFormat:@"Muxed MP4 to %@", [outputFile lastPathComponent]]
					   progress:100.0
				isIndeterminate:FALSE 
				enableInterface:TRUE];
    
	return 0;
	
}

-(uint64_t)calculateOutputSize
{
	outputSize = 0;
	
	for (int i=0; i < [self sourceTrackCount]; i++)
	{
		if ([[self trackWithIndex:i] isKindOfClass:[MXTrackWrapper class]])
			outputSize += ([[self trackWithIndex:i] bitrate] * [[self trackWithIndex:i] duration]) / 8096;
	}
	return outputSize;
}

@end
