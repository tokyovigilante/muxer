//
//  Muxer.h
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

// Controller layer 

#import <Cocoa/Cocoa.h>

#import "MXMP4Wrapper.h"
#import "MXTrackWrapper.h"

@interface Muxer : NSObject {
	
	MP4FileHandle *		targetMP4;
	NSMutableArray *	videoTrackArray;
	NSMutableArray *	audioTrackArray;
	
	NSInteger timescale;
	uint64_t outputSize; 
	BOOL use64BitMode;

}

-(id)init;
-(NSInteger)scanSource:(NSString *)source;
-(BOOL)muxTargetToFile:(NSString *)outputFile;

-(NSInteger)sourceTrackCount;
-(MXTrackWrapper *)trackWithIndex:(NSInteger)index;
-(BOOL)isTrackGroupRow:(NSInteger)row;
-(void)removeTrackAtIndex:(NSInteger)index;
-(uint64_t)calculateOutputSize;



//-(NSMutableArray *)sourceTrackArray;

@end
