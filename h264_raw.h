/*
 *  h264_raw.h
 *  Muxer
 *
 *  Created by Ryan Walklin on 1/4/09.
 *  Copyright 2009 Ryan Walklin. All rights reserved.
 *  Based on H.264 raw stream support from MPEG4-IP
 *
 */

#import <Cocoa/Cocoa.h>
#import <mp4v2/mp4v2.h>
#include "mp4av_h264.h"

MP4TrackId H264Creator(MP4FileHandle mp4File, FILE* inFile, double VideoFrameRate, int Mp4TimeScale);
