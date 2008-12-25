//
//  MXWindow.m
//  Muxer
//
//  Created by Ryan Walklin on 12/25/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MXWindow.h"


@implementation MXWindow

- (id)initWithContentRect:(NSRect)contentRect 
				styleMask:(NSUInteger)windowStyle 
				  backing:(NSBackingStoreType)bufferingType 
					defer:(BOOL)deferCreation
{
	self = [super initWithContentRect:contentRect styleMask:windowStyle 
							  backing:bufferingType defer:deferCreation];
	
	if (self) 
	{
		[self setContentBorderThickness:30.0 forEdge:NSMinYEdge];
	}
	
	return self;
}

@end
