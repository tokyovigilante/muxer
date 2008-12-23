//
//  MP4Wrapper.m
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import "MP4Wrapper.h"


@implementation MP4Wrapper

- (id)initWithExistingMP4File:(NSString *)mp4File
{
    if ((self = [super init]))
	{
		fileHandle = MP4Read([mp4File UTF8String], MP4_VERBOSITY);
		
		if (!fileHandle)
			return NULL;
	}
	return self;
}

- (id)initWithNewMP4File:(NSString *)mp4File
{
	if ((self = [super init]))
	{
		fileHandle = MP4Create([mp4File UTF8String], MP4_VERBOSITY, 0);		
	}

	return self;
}

@end
