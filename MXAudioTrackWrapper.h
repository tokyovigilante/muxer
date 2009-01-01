//
//  MXAudioTrackWrapper.h
//  Muxer
//
//  Created by Ryan Walklin on 12/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MXTrackWrapper.h"

@interface MXAudioTrackWrapper : MXTrackWrapper {
	NSString * trackName;
	uint8_t *esConfig;
	uint32_t esConfigSize;
	uint16_t channelCount;
	uint16_t language;
}
@property (readonly, copy) NSString *trackName;
@property (readonly) uint8_t *esConfig;
@property (readonly) uint32_t esConfigSize;
@property (readonly) uint16_t channelCount;
@property (readonly) uint16_t language;

-(void)readTrackDescription;


@end
