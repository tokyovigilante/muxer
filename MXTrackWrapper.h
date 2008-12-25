//
//  MXTrackWrapper.h
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "config.h"

@interface MXTrackWrapper : NSObject 
{
	NSString * trackSourcePath;
	NSInteger trackSourceID;
	char * trackType;
	NSMutableDictionary * trackDescription;
}
@property (readwrite, retain) NSString * trackSourcePath;
@property (readwrite) NSInteger trackSourceID;
@property (readwrite, retain) NSMutableDictionary * trackDescription;

-(id)initWithSourcePath:(NSString *)source trackID:(NSInteger)trackID;
-(void)readTrackData;

@end
