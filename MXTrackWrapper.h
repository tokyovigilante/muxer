//
//  MXTrackWrapper.h
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "config.h"
#import <mp4v2/mp4v2.h>

@interface MXTrackWrapper : NSObject 
{
	NSString * trackSourcePath;
	NSInteger trackSourceID;
	NSInteger trackTargetID;
	char * trackType;
	NSMutableDictionary * trackDescription;
	
	NSInteger samplerate; 
	double bitrate; // kbit/sec
	double duration; // seconds
	
}
@property (readonly, copy) NSString * trackSourcePath;
@property (readonly) NSInteger trackSourceID;
@property (readwrite) NSInteger trackTargetID;
@property (readonly, copy) NSMutableDictionary * trackDescription;

@property (readonly) NSInteger samplerate;
@property (readonly) double bitrate;
@property (readonly) double duration;

-(id)initWithSourcePath:(NSString *)source trackID:(NSInteger)trackID;
-(void)readTrackType;
-(void)readTrackDescription;

@end
