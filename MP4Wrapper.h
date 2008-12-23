//
//  MP4Wrapper.h
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//
//  Model-layer wrapper around mp4v2 (MP4 file representation)

#import <Cocoa/Cocoa.h>

#import <mp4v2/mp4v2.h>

#define MP4_INPUT 0
#define MP4_OUTPUT 1

#define MP4_VERBOSITY 0x600

@interface MP4Wrapper : NSObject {
	
	/* libmp4v2 handle */
    MP4FileHandle fileHandle;

}

- (id)initWithExistingMP4File:(NSString *)mp4File;
- (id)initWithNewMP4File:(NSString *)mp4File;


@end
