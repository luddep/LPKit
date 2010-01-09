/*
 * LPPieChartView.j
 * LPKit
 *
 * Created by Ludwig Pettersson on January 9, 2010.
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
@import <AppKit/CPView.j>


@implementation LPPieChartView : CPView
{
    id dataSource @accessors;
    id delegate @accessors;
    id drawView @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        // Default draw view
        [self setDrawView:[[LPPieChartDrawView alloc] initWithFrame:CGRectMakeZero()]];
    }
    return self;
}

- (void)setDataSource:(id)aDataSource
{
    dataSource = aDataSource;
    [self reloadData];
}

- (void)setDelegate:(id)aDelegate
{
    delegate = aDelegate;
    [self reloadData];
}

- (void)setDrawView:(id)aDrawView
{
    if (!drawView)
        [self addSubview:aDrawView];
    else
        [self replaceSubview:drawView with:aDrawView];
    
    // Got a new drawView
    drawView = aDrawView;
    
    // Update drawView frame & autoresizingmask
    [drawView setFrame:[self bounds]];
    [drawView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    // Re-draw
    [self reloadData];
}

- (void)reloadData
{
    if (delegate && dataSource && drawView)
    {
        var numberOfItems = [dataSource numberOfItemsInPieChartView:self],
            values = [CPArray array],
            sum = 0.0,
            colors = [CPArray array];
        
        for (var i = 0; i < numberOfItems; i++)
        {
            var value = [dataSource pieChartView:self floatValueForIndex:i];
            [values addObject:value];
            sum += value;
            
            [colors addObject:[delegate pieChartView:self colorForFillAtIndex:i]];
        }
    
        // Update Draw view
        [drawView setSum:sum];
        [drawView setValues:values];
        [drawView setColors:colors];
        [drawView setNeedsDisplay:YES];
    }
}

@end


var LPPieChartViewDrawViewKey = @"LPPieChartViewDrawViewKey";

@implementation LPPieChartView (CPCoding)
 
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        drawView = [aCoder decodeObjectForKey:LPPieChartViewDrawViewKey];
    }
 
    return self;
}
 
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:drawView forKey:LPPieChartViewDrawViewKey];
}
 
@end


@implementation LPPieChartDrawView : CPView
{
    float sum @accessors;
    CPArray values @accessors;
    CPArray colors @accessors;
    
    int lineWidth @accessors;
    CPColor strokeColor @accessors;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        radius = MIN(CGRectGetWidth(bounds), CGRectGetHeight(bounds)) / 2,
        midX = CGRectGetMidX(bounds),
        midY = CGRectGetMidY(bounds),
        current_angle = 0.0;
    
    CGContextSetLineWidth(context, lineWidth || 1.0);
    CGContextSetStrokeColor(context, strokeColor || [CPColor clearColor]);
    
    for (var i = 0; i < [values count]; i++)
    {
        var value = [values objectAtIndex:i],
            end_angle = (value / sum) * 360.0;
        
        CGContextBeginPath(context);
        
        CGContextMoveToPoint(context, midX, midY);
        CGContextAddArc(context, midX, midY, radius, current_angle / (180 / PI), (current_angle + end_angle) / (180 / PI), YES);
        CGContextAddLineToPoint(context, midX, midY);
        
        CGContextSetFillColor(context, [colors objectAtIndex:i]);
        CGContextFillPath(context);
        CGContextStrokePath(context);
        CGContextClosePath(context);
        
        current_angle += end_angle;
    }
}

@end


var LPPieChartDrawViewSumKey    = @"LPPieChartDrawViewSumKey",
    LPPieChartDrawViewValuesKey = @"LPPieChartDrawViewValuesKey",
    LPPieChartDrawViewColorsKey = @"LPPieChartDrawViewColorsKey",
    LPPieChartDrawViewLineWidthKey = @"LPPieChartDrawViewLineWidthKey",
    LPPieChartDrawViewStrokeColorKey = @"LPPieChartDrawViewStrokeColorKey";

@implementation LPPieChartDrawView (CPCoding)
 
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        sum = [aCoder decodeFloatForKey:LPPieChartDrawViewSumKey];
        values = [aCoder decodeObjectForKey:LPPieChartDrawViewValuesKey];
        colors = [aCoder decodeObjectForKey:LPPieChartDrawViewColorsKey];
        lineWidth = [aCoder decodeIntForKey:LPPieChartDrawViewLineWidthKey];
        strokeColor = [aCoder decodeObjectForKey:LPPieChartDrawViewStrokeColorKey];
    }
 
    return self;
}
 
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeFloat:sum forKey:LPPieChartDrawViewSumKey];
    [aCoder encodeObject:values forKey:LPPieChartDrawViewValuesKey];
    [aCoder encodeObject:colors forKey:LPPieChartDrawViewColorsKey];
    [aCoder encodeInt:lineWidth forKey:LPPieChartDrawViewLineWidthKey];
    [aCoder encodeObject:strokeColor forKey:LPPieChartDrawViewStrokeColorKey];
}
 
@end
