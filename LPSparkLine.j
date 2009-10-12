/*
 * MenuBar.j
 * NewApplication
 *
 * Created by You on May 20, 2009.
 * Copyright 2009, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "CPArray+Additions.j"

@implementation LPSparkLine : CPView
{ 
	CALayer _rootLayer;
	
	CPArray data @accessors;
	CPColor lineColor;
	float lineWeight;
	
	CPColor shadowColor;
	CGSize shadowOffset;
	
	BOOL isEmpty;
} 

- (id)initWithFrame:(CGRect)aFrame 
{ 
	self = [super initWithFrame:aFrame];
    
	if (self) 
	{ 
	    lineWeight = 1.0;
	    lineColor = [CPColor blackColor];
	    
	    shadowColor = nil;
	    shadowOffset = CGSizeMake(0,1);
	    
		[self setWantsLayer:YES];
		_rootLayer = [CALayer layer];
		[self setLayer:_rootLayer];
        [_rootLayer setDelegate:self];
		[_rootLayer setNeedsDisplay];
	} 

	return self; 
} 

- (void)drawLayer:(CALayer)layer inContext:(CGContext)context 
{ 
	var bounds = [layer bounds],
	    height = CGRectGetHeight(bounds) - 2,
	    tickWidth = CGRectGetWidth(bounds) / ([data count] - 1),
	    maxValue = [data _LPmaxValue];

	CGContextBeginPath(context);
	
	var x,
	    y;
	
	// Just draw a single line in the middle if it's empty
	if (isEmpty)
	{
	    CGContextMoveToPoint(context, 0, height / 2);
    	CGContextAddLineToPoint(context, CGRectGetWidth(bounds), height / 2);
	}
	else
	{	
    	// Draw the path
    	for (var i = 0; i < [data count]; i++)
    	{
            x = i * tickWidth;
    	    y = 2 + (height - (([data objectAtIndex:i] / maxValue) * height));
	    
    	    if (i === 0)
    	        CGContextMoveToPoint(context, 0, y);
    	    else
    	        CGContextAddLineToPoint(context, x, y);
    	}
    }
	
    CGContextSetLineJoin(context, kCGLineJoinRound)
    CGContextSetLineWidth(context, lineWeight);
	CGContextSetStrokeColor(context, lineColor);
	CGContextSetShadowWithColor(context, shadowOffset, 0.0, shadowColor);
	CGContextStrokePath(context);
	CGContextClosePath(context);	
}

- (void)setData:(CPArray)aData
{
    isEmpty = YES;
    
    // If all values are 0, it's empty
    for (var i = 0; i < aData.length; i++)
        if ((aData[i] > 0) && (isEmpty))
            isEmpty = NO;
    
    data = aData;
    [_rootLayer setNeedsDisplay];
}

- (void)setLineColor:(CPColor)aColor
{
    lineColor = aColor;
    [_rootLayer setNeedsDisplay];
}

- (void)setLineWeight:(CPFloat)aFloat
{
    lineWeight = aFloat;
    [_rootLayer setNeedsDisplay];
}

- (void)setShadowColor:(CPColor)aColor
{
    shadowColor = aColor;
    [_rootLayer setNeedsDisplay];
}

- (void)setShadowOffset:(CGSize)aSize
{
    shadowOffset = aSize;
    [_rootLayer setNeedsDisplay];
}

@end