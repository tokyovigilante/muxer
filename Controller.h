//
//  MuxController.h
//  Muxer
//
//  Created by Ryan Walklin on 12/20/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MXMP4Wrapper.h"
#import "Muxer.h"

@interface Controller : NSObject {
	

	IBOutlet id SourceButton;
	IBOutlet id RemoveStreamButton;
	IBOutlet id MuxButton;
	IBOutlet id TargetView;
	IBOutlet id MuxProgress;
	IBOutlet id toolbar;
	IBOutlet id window;
	
	MXMP4Wrapper *output;
	Muxer *muxer;
	
	
    
	
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
}

-(id)init;
-(void)applicationDidFinishLaunching: (NSNotification *) notification;
-(BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row;


-(IBAction)openSource:(id)sender;
-(IBAction)muxTarget:(id)sender;

-(void)scanSource:(NSString *)source;

-(void)extractTrackFromFile:(MP4FileHandle)mp4File withTrackId:(MP4TrackId)trackId toDestinationFile:(char*)dstFileName;


-(void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(NSString *)contextInfo;



@end
