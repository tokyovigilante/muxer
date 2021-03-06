//
//  MuxController.m
//  Muxer
//
//  Created by Ryan Walklin on 12/20/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import "Controller.h"

@implementation Controller

-(id)init
{
	if ((self = [super init]))
	{
		[NSApp setDelegate:self];
		muxer = [[Muxer alloc] init];
	}
	return self;
}

- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
	// register for status notifications
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateStatusFromMuxer:)
												 name: @"status" 
											   object: nil];
	
	[self openSource:window];
}

#pragma mark -
#pragma mark Source handling

- (IBAction)openSource:(id)sender
{
	NSOpenPanel * oPanel = [NSOpenPanel openPanel];
	
	NSArray *fileTypes = [NSArray arrayWithObjects:@"mp4", @"mov", @"h264", Nil];
	
	[oPanel setCanChooseFiles:TRUE];
	[oPanel setCanChooseDirectories:FALSE];
	[oPanel setAllowsMultipleSelection:TRUE];
	[oPanel setMessage:@"Import Tracks From:"];
	
	[oPanel beginSheetForDirectory:NSHomeDirectory()
							  file:nil
							 types:fileTypes
					modalForWindow:window
					 modalDelegate:self
					didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					   contextInfo:NULL];
	
}

-(void)scanSource:(NSString *)source
{
	[muxer scanSource:source];
	[TargetView reloadData];
}

-(IBAction)removeTrack:(id)sender
{
	[muxer removeTrackAtIndex:[TargetView selectedRow]];
	[TargetView reloadData];
	[TargetView deselectAll:self];
}

#pragma mark -
#pragma mark Interface

- (void)updateStatusFromMuxer:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(updateInterface:)
						   withObject:[notification userInfo]
						waitUntilDone:FALSE];
}

-(void)updateInterface:(NSDictionary *)status
{
	[StatusLabel setStringValue:[status objectForKey:@"status"]];
	[MuxProgress setDoubleValue:[[status objectForKey:@"progress"] doubleValue]];
	[MuxProgress setIndeterminate:[[status objectForKey:@"indeterminate"] boolValue]];
	if ([[status objectForKey:@"interface"] boolValue])
	{
		[MuxProgress stopAnimation:self];
	}
	else
	{
		[MuxProgress startAnimation:self];
	}
}


#pragma mark -
#pragma mark Muxer interface

-(IBAction)muxTarget:(id)sender
{
	NSSavePanel * sPanel = [NSSavePanel savePanel];
	
	NSArray *fileTypes = [NSArray arrayWithObject:@"mp4"];
	
	[sPanel setCanCreateDirectories:TRUE];
	[sPanel setAllowedFileTypes:fileTypes];
	[sPanel setAllowsOtherFileTypes:FALSE];
	[sPanel setMessage:@"Save MP4 As:"];
	
	[sPanel beginSheetForDirectory:NSHomeDirectory()
							  file:nil
					modalForWindow:window
					 modalDelegate:self
					didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
					   contextInfo:NULL];
	
}

#pragma mark -
#pragma mark Delegates

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(NSString *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		[panel close];
		for (NSString * filename in [panel filenames])
		{
			[self scanSource:filename];
		}
	}
}

- (void)savePanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(NSString *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		[panel close];
		[NSThread detachNewThreadSelector:@selector(muxTargetToFile:)
								 toTarget:self
							   withObject:[[panel filenames] objectAtIndex:0]];
	}
}

-(void)muxTargetToFile:(NSString *)outputFile
{
	[muxer muxTargetToFile:outputFile];
}

#pragma mark -
#pragma mark DataSource

- (int)numberOfRowsInTableView:(NSTableView *)aTable
{
	if (aTable == TargetView && muxer)
	{
		return [muxer sourceTrackCount];
	}
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	id rowObject;
	if (aTableView == TargetView && muxer)
	{
		NSParameterAssert(rowIndex >= 0 && (unsigned)rowIndex < [muxer sourceTrackCount]);
		rowObject = [muxer trackWithIndex:rowIndex];
		if ([rowObject isKindOfClass:[NSString class]])
		{
			return rowObject;
		}
		if ([rowObject isKindOfClass:[MXTrackWrapper class]])
		{
			return [[rowObject trackDescription] objectForKey:@"generic_track"];
		}
	}
	return NULL;
}

-(BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    return [muxer isTrackGroupRow:row];
}

- (BOOL) tableView: (NSTableView *) tableView shouldSelectRow: (NSInteger) row
{
    return ![muxer isTrackGroupRow:row];
}


#pragma mark -
#pragma mark mp4v2 Interface

#if 0

void AddIPodUUID(MP4FileHandle, MP4TrackId);

struct hb_mux_object_s
{
    HB_MUX_COMMON;
	
    hb_job_t * job;
	
    /* libmp4v2 handle */
    MP4FileHandle file;
	
    /* Cumulated durations so far, in output & input timescale units (see MP4Mux) */
    int64_t sum_dur;        // duration in output timescale units
    int64_t sum_dur_in;     // duration in input 90KHz timescale units
	
    // bias to keep render offsets in ctts atom positive (set up by encx264)
    int64_t init_delay;
	
    /* Chapter state information for muxing */
    MP4TrackId chapter_track;
    int current_chapter;
    uint64_t chapter_duration;
	
    /* Sample rate of the first audio track.
     * Used for the timescale
     */
    int samplerate;
};

struct hb_mux_data_s
{
    MP4TrackId track;
};


/**********************************************************************
 * MP4Init
 **********************************************************************
 * Allocates hb_mux_data_t structures, create file and write headers
 *********************************************************************/
static int MP4Init( hb_mux_object_t * m )
{
    hb_job_t   * job   = m->job;
    hb_title_t * title = job->title;
	
    hb_audio_t    * audio;
    hb_mux_data_t * mux_data;
    int i;
    uint16_t language_code;
	
    /* Flags for enabling/disabling tracks in an MP4. */
    typedef enum { TRACK_DISABLED = 0x0, TRACK_ENABLED = 0x1, TRACK_IN_MOVIE = 0x2, TRACK_IN_PREVIEW = 0x4, TRACK_IN_POSTER = 0x8}  track_header_flags;
	
    if( (audio = hb_list_item(title->list_audio, 0)) != NULL )
    {
        /* Need the sample rate of the first audio track to use as the timescale. */
        m->samplerate = audio->config.out.samplerate;
        audio = NULL;
    }
    else
    {
        m->samplerate = 90000;
    }
	
    /* Create an empty mp4 file */
    if (job->largeFileSize)
    /* Use 64-bit MP4 file */
    {
        m->file = MP4Create( job->file, MP4_DETAILS_ERROR, MP4_CREATE_64BIT_DATA );
        hb_deep_log( 2, "muxmp4: using 64-bit MP4 formatting.");
    }
    else
    /* Limit MP4s to less than 4 GB */
    {
        m->file = MP4Create( job->file, MP4_DETAILS_ERROR, 0 );
    }
	
    if (m->file == MP4_INVALID_FILE_HANDLE)
    {
        hb_error("muxmp4.c: MP4Create failed!");
        *job->die = 1;
        return 0;
    }
	
    /* Video track */
    mux_data      = malloc( sizeof( hb_mux_data_t ) );
    job->mux_data = mux_data;
	
    /* When using the standard 90000 timescale, QuickTime tends to have
	 synchronization issues (audio not playing at the correct speed).
	 To workaround this, we use the audio samplerate as the
	 timescale */
    if (!(MP4SetTimeScale( m->file, m->samplerate )))
    {
        hb_error("muxmp4.c: MP4SetTimeScale failed!");
        *job->die = 1;
        return 0;
    }
	
    if( job->vcodec == HB_VCODEC_X264 )
    {
        /* Stolen from mp4creator */
        MP4SetVideoProfileLevel( m->file, 0x7F );
		mux_data->track = MP4AddH264VideoTrack( m->file, m->samplerate,
											   MP4_INVALID_DURATION, job->width, job->height,
											   job->config.h264.sps[1], /* AVCProfileIndication */
											   job->config.h264.sps[2], /* profile_compat */
											   job->config.h264.sps[3], /* AVCLevelIndication */
											   3 );      /* 4 bytes length before each NAL unit */
		
		
        MP4AddH264SequenceParameterSet( m->file, mux_data->track,
									   job->config.h264.sps, job->config.h264.sps_length );
        MP4AddH264PictureParameterSet( m->file, mux_data->track,
									  job->config.h264.pps, job->config.h264.pps_length );
		
		if( job->h264_level == 30 || job->ipod_atom)
		{
			hb_deep_log( 2, "muxmp4: adding iPod atom");
			MP4AddIPodUUID(m->file, mux_data->track);
		}
		
        m->init_delay = job->config.h264.init_delay;
    }
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
	
    // COLR atom for color and gamma correction.
    // Per the notes at:
    //   http://developer.apple.com/quicktime/icefloe/dispatch019.html#colr
    //   http://forum.doom9.org/showthread.php?t=133982#post1090068
    // the user can set it from job->color_matrix, otherwise by default
    // we say anything that's likely to be HD content is ITU BT.709 and
    // DVD, SD TV & other content is ITU BT.601.  We look at the title height
    // rather than the job height here to get uncropped input dimensions.
    if( job->color_matrix == 1 )
    {
        // ITU BT.601 DVD or SD TV content
        MP4AddColr(m->file, mux_data->track, 6, 1, 6);
    }
    else if( job->color_matrix == 2 )
    {
        // ITU BT.709 HD content
        MP4AddColr(m->file, mux_data->track, 1, 1, 1);        
    }
    else if ( job->title->width >= 1280 || job->title->height >= 720 )
    {
        // we guess that 720p or above is ITU BT.709 HD content
        MP4AddColr(m->file, mux_data->track, 1, 1, 1);
    }
    else
    {
        // ITU BT.601 DVD or SD TV content
        MP4AddColr(m->file, mux_data->track, 6, 1, 6);
    }
	
    if( job->pixel_ratio )
    {
        /* PASP atom for anamorphic video */
        float width, height;
		
        width = job->pixel_aspect_width;
		
        height = job->pixel_aspect_height;
		
        MP4AddPixelAspectRatio(m->file, mux_data->track, (uint32_t)width, (uint32_t)height);
		
        MP4SetTrackFloatProperty(m->file, mux_data->track, "tkhd.width", job->width * (width / height));
    }
	
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
            else {
                MP4SetTrackBytesProperty(
										 m->file, mux_data->track,
										 "udta.name.value",
										 (const uint8_t*)(audio->config.out.name),
										 strlen(audio->config.out.name));
            }
        } else {
            mux_data->track = MP4AddAudioTrack(
											   m->file,
											   m->samplerate, 1024, MP4_MPEG4_AUDIO_TYPE );
            if (audio->config.out.name == NULL) {
                MP4SetTrackBytesProperty(
										 m->file, mux_data->track,
										 "udta.name.value",
										 (const uint8_t*)"Stereo", strlen("Stereo"));
            }
            else {
                MP4SetTrackBytesProperty(
										 m->file, mux_data->track,
										 "udta.name.value",
										 (const uint8_t*)(audio->config.out.name),
										 strlen(audio->config.out.name));
            }
			
            MP4SetAudioProfileLevel( m->file, 0x0F );
            MP4SetTrackESConfiguration(
									   m->file, mux_data->track,
									   audio->priv.config.aac.bytes, audio->priv.config.aac.length );
			
            /* Set the correct number of channels for this track */
			MP4SetTrackIntegerProperty(m->file, mux_data->track, "mdia.minf.stbl.stsd.mp4a.channels", (uint16_t)HB_AMIXDOWN_GET_DISCRETE_CHANNEL_COUNT(audio->config.out.mixdown));
        }
		
        /* Set the language for this track */
        /* The language is stored as 5-bit text - 0x60 */
        language_code = audio->config.lang.iso639_2[0] - 0x60;   language_code <<= 5;
        language_code |= audio->config.lang.iso639_2[1] - 0x60;  language_code <<= 5;
        language_code |= audio->config.lang.iso639_2[2] - 0x60;
        MP4SetTrackIntegerProperty(m->file, mux_data->track, "mdia.mdhd.language", language_code);
		
        if( hb_list_count( title->list_audio ) > 1 )
        {
            /* Set the audio track alternate group */
            MP4SetTrackIntegerProperty(m->file, mux_data->track, "tkhd.alternate_group", 1);
        }
		
        if (i == 0) {
            /* Enable the first audio track */
            MP4SetTrackIntegerProperty(m->file, mux_data->track, "tkhd.flags", (TRACK_ENABLED | TRACK_IN_MOVIE));
        }
        else
		/* Disable the other audio tracks so QuickTime doesn't play
		 them all at once. */
        {
            MP4SetTrackIntegerProperty(m->file, mux_data->track, "tkhd.flags", (TRACK_DISABLED | TRACK_IN_MOVIE));
            hb_deep_log( 2, "muxp4: disabled extra audio track %i", mux_data->track-1);
        }
		
    }
	
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
}

static int MP4Mux( hb_mux_object_t * m, hb_mux_data_t * mux_data,
				  hb_buffer_t * buf )
{
    hb_job_t * job = m->job;
    int64_t duration;
    int64_t offset = 0;
	
    if( mux_data == job->mux_data )
    {
        /* Video */
		
        // if there are b-frames compute the render offset
        // (we'll need it for both the video frame & the chapter track)
        if ( m->init_delay )
        {
            offset = ( buf->start + m->init_delay ) * m->samplerate / 90000 -
			m->sum_dur;
        }
		
        /* Add the sample before the new frame.
		 It is important that this be calculated prior to the duration
		 of the new video sample, as we want to sync to right after it.
		 (This is because of how durations for text tracks work in QT) */
        if( job->chapter_markers && buf->new_chap )
        {    
            hb_chapter_t *chapter = NULL;
			
            // this chapter is postioned by writing out the previous chapter.
            // the duration of the previous chapter is the duration up to but
            // not including the current frame minus the duration of all
            // chapters up to the previous.
            duration = m->sum_dur - m->chapter_duration + offset;
            if ( duration <= 0 )
            {
                /* The initial & final chapters can have very short durations
                 * (less than the error in our total duration estimate) so
                 * the duration calc above can result in a negative number.
                 * when this happens give the chapter a short duration (1/3
                 * of an ntsc frame time). */
                duration = 1000 * m->samplerate / 90000;
            }
			
            chapter = hb_list_item( m->job->title->list_chapter,
								   buf->new_chap - 2 );
			
            MP4AddChapter( m->file,
						  m->chapter_track,
						  duration,
						  (chapter != NULL) ? chapter->title : NULL);
			
            m->current_chapter = buf->new_chap;
            m->chapter_duration += duration;
        }
		
        // since we're changing the sample rate we need to keep track of
        // the truncation bias so that the audio and video don't go out
        // of sync. m->sum_dur_in is the sum of the input durations so far.
        // m->sum_dur is the sum of the output durations. Their difference
        // (in output sample rate units) is the accumulated truncation bias.
        int64_t bias = ( m->sum_dur_in * m->samplerate / 90000 ) - m->sum_dur;
        int64_t dur_in = buf->stop - buf->start;
        duration = dur_in * m->samplerate / 90000 + bias;
        if ( duration <= 0 )
        {
            /* We got an illegal mp4/h264 duration. This shouldn't
			 be possible and usually indicates a bug in the upstream code.
			 Complain in the hope that someone will go find the bug but
			 try to fix the error so that the file will still be playable. */
            hb_log("MP4Mux: illegal duration %lld, bias %lld, start %lld (%lld),"
                   "stop %lld (%lld), sum_dur %lld",
                   duration, bias, buf->start * m->samplerate / 90000, buf->start,
                   buf->stop * m->samplerate / 90000, buf->stop, m->sum_dur );
            /* we don't know when the next frame starts so we can't pick a
			 valid duration for this one so we pick something "short"
			 (roughly 1/3 of an NTSC frame time) and rely on the bias calc
			 for the next frame to correct things (a duration underestimate
			 just results in a large bias on the next frame). */
            duration = 1000 * m->samplerate / 90000;
        }
        m->sum_dur += duration;
        m->sum_dur_in += dur_in;
    }
    else
    {
        /* Audio */
        duration = MP4_INVALID_DURATION;
    }
	
    // Here's where the sample actually gets muxed.
    if( !MP4WriteSample( m->file,
						mux_data->track,
						buf->data,
						buf->size,
						duration,
						offset,
						((buf->frametype & HB_FRAME_KEY) != 0) ) )
    {
        hb_error("Failed to write to output file, disk full?");
        *job->die = 1;
    }
	
    return 0;
}

static int MP4End( hb_mux_object_t * m )
{
    hb_job_t   * job   = m->job;
    hb_title_t * title = job->title;
	
    /* Write our final chapter marker */
    if( m->job->chapter_markers )
    {
        hb_chapter_t *chapter = NULL;
        int64_t duration = m->sum_dur - m->chapter_duration;
        /* The final chapter can have a very short duration - if it's less
         * than a second just skip it. */
        if ( duration >= m->samplerate )
        {
			
            chapter = hb_list_item( m->job->title->list_chapter,
								   m->current_chapter - 1 );
			
            MP4AddChapter( m->file,
						  m->chapter_track,
						  duration,
						  (chapter != NULL) ? chapter->title : NULL);
        }
    }
	
    if (job->areBframes)
    {
		// Insert track edit to get A/V back in sync.  The edit amount is
		// the init_delay.
		int64_t edit_amt = m->init_delay * m->samplerate / 90000;
		MP4AddTrackEdit(m->file, 1, MP4_INVALID_EDIT_ID, edit_amt,
						MP4GetTrackDuration(m->file, 1), 0);
		if ( m->job->chapter_markers )
		{
			// apply same edit to chapter track to keep it in sync with video
			MP4AddTrackEdit(m->file, m->chapter_track, MP4_INVALID_EDIT_ID,
							edit_amt,
							MP4GetTrackDuration(m->file, m->chapter_track), 0);
		}
	}
	
    /*
     * Write the MP4 iTunes metadata if we have any metadata
     */
    if( title->metadata )
    {
        hb_metadata_t *md = title->metadata;
		
        hb_deep_log( 2, "Writing Metadata to output file...");
		
        MP4SetMetadataName( m->file, md->name );
        MP4SetMetadataArtist( m->file, md->artist );
        MP4SetMetadataComposer( m->file, md->composer );
        MP4SetMetadataComment( m->file, md->comment );
        MP4SetMetadataReleaseDate( m->file, md->release_date );
        MP4SetMetadataAlbum( m->file, md->album );
        MP4SetMetadataGenre( m->file, md->genre );
        if( md->coverart )
        {
            MP4SetMetadataCoverArt( m->file, md->coverart, md->coverart_size);
        }
    }
	
    MP4Close( m->file );
	
    if ( job->mp4_optimize )
    {
        hb_log( "muxmp4: optimizing file" );
        char filename[1024]; memset( filename, 0, 1024 );
        snprintf( filename, 1024, "%s.tmp", job->file );
        MP4Optimize( job->file, filename, MP4_DETAILS_ERROR );
        remove( job->file );
        rename( filename, job->file );
    }
	
    return 0;
}

#endif

@end
