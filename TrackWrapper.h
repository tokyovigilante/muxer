//
//  TrackWrapper.h
//  Muxer
//
//  Created by Ryan Walklin on 12/23/08.
//  Copyright 2008 Ryan Walklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrackWrapper : NSObject 
{
	NSString * pathToSource;
	NSInteger trackID;
	char * type;	
}

@end
