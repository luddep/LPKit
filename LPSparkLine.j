/*
 * LPSparkLine.j
 * LPKit
 *
 * Created by Ludwig Pettersson on May 20, 2009.
 * 
 * The MIT License
 * 
 * Copyright (c) 2009 Ludwig Pettersson
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
@import <Foundation/CPObject.j>

/*
    TODO: replace this with a wrapper around
    LPChartView & a simple draw view.
*/

@implementation LPSparkLine : CPView
{
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
    } 

    return self; 
}

- (void)drawRect:(CPRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        height = CGRectGetHeight(bounds) - (2 * lineWeight),
        tickWidth = CGRectGetWidth(bounds) / ([data count] - 1),
        maxValue = Math.max.apply(Math, data);

    CGContextBeginPath(context);
    
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
            var x = i * tickWidth,
                y = lineWeight + (height - (([data objectAtIndex:i] / maxValue) * height));
        
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
    [self setNeedsDisplay:YES];
}

- (void)setLineColor:(CPColor)aColor
{
    lineColor = aColor;
    [self setNeedsDisplay:YES];
}

- (void)setLineWeight:(CPFloat)aFloat
{
    lineWeight = aFloat;
    [self setNeedsDisplay:YES];
}

- (void)setShadowColor:(CPColor)aColor
{
    shadowColor = aColor;
    [self setNeedsDisplay:YES];
}

- (void)setShadowOffset:(CGSize)aSize
{
    shadowOffset = aSize;
    [self setNeedsDisplay:YES];
}

@end


var LPSparkLineDataKey         = @"LPSparkLineDataKey",
    LPSparkLineLineColorKey    = @"LPSparkLineLineColorKey",
    LPSparkLineLineWeightKey   = @"LPSparkLineLineWeightKey",
    LPSparkLineShadowColorKey  = @"LPSparkLineShadowColorKey",
    LPSparkLineShadowOffsetKey = @"LPSparkLineShadowOffsetKey",
    LPSparkLineIsEmptyKey      = @"LPSparkLineIsEmptyKey";

@implementation LPSparkLine (CPCoding)
 
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        data = [aCoder decodeObjectForKey:LPSparkLineDataKey];
        lineColor = [aCoder decodeObjectForKey:LPSparkLineLineColorKey];
        lineWeight = [aCoder decodeFloatForKey:LPSparkLineLineWeightKey];
        
        shadowColor = [aCoder decodeObjectForKey:LPSparkLineShadowColorKey];
        shadowOffset = [aCoder decodeSizeForKey:LPSparkLineShadowOffsetKey];
        
        isEmpty = ![aCoder containsValueForKey:LPSparkLineIsEmptyKey] || [aCoder decodeObjectForKey:LPSparkLineIsEmptyKey];
    }
    return self;
}
 
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:data forKey:LPSparkLineDataKey];
    [aCoder encodeObject:lineColor forKey:LPSparkLineLineColorKey];
    [aCoder encodeFloat:lineWeight forKey:LPSparkLineLineWeightKey];
    
    
    [aCoder encodeObject:shadowColor forKey:LPSparkLineShadowColorKey];
    [aCoder encodeSize:shadowOffset forKey:LPSparkLineShadowOffsetKey];

    [aCoder encodeBool:isEmpty forKey:LPSparkLineIsEmptyKey];
}
 
@end