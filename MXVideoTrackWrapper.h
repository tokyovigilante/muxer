//
//  MXVideoTrackWrapper.h
//  Muxer
//
//  Created by Ryan Walklin on 12/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MXTrackWrapper.h"

@interface MXVideoTrackWrapper : MXTrackWrapper {
	uint8_t  **	sequenceParameterSet;
	uint32_t *	sequenceParameterSetSize;
	uint8_t  **	pictureParameterSet;
	uint32_t *	pictureParameterSetSize;
		
	uint16_t	frameWidth;
	uint16_t	frameHeight;
	
	BOOL	anamorphic;
	float	anamorphicWidth;
	float	anamorphicHeight;
	uint64_t	pixelHValue;
	uint64_t	pixelVValue;
	

}
@property (readonly) uint8_t **	sequenceParameterSet;
@property (readonly) uint32_t *	sequenceParameterSetSize;
@property (readonly) uint8_t **	pictureParameterSet;
@property (readonly) uint32_t *	pictureParameterSetSize;

@property (readonly) uint16_t	frameWidth;
@property (readonly) uint16_t	frameHeight;

@property (readonly) BOOL		anamorphic;
@property (readonly) float		anamorphicWidth;
@property (readonly) float		anamorphicHeight;
@property (readonly) uint64_t	pixelHValue;
@property (readonly) uint64_t	pixelVValue;

-(void)readTrackDescription;


@end
