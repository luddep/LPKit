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
    
    CPArray values;
    float sum;
    CPArray paths @accessors(readonly);
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        // Default draw view
        [self setDrawView:[[LPPieChartDrawView alloc] initWithFrame:CGRectMakeZero()]];
        
        paths = [CPArray array];
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
    var _newDrawView = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:aDrawView]];
    
    if (!drawView)
        [self addSubview:_newDrawView];
    else
        [self replaceSubview:drawView with:_newDrawView];
    
    // Got a new drawView
    drawView = _newDrawView;
    
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
            colors = [CPArray array];
            
        values = [CPArray array];
        sum = 0.0;
        
        for (var i = 0; i < numberOfItems; i++)
        {
            var value = [dataSource pieChartView:self floatValueForIndex:i];
            [values addObject:value];
            sum += value;
        }

        // Update paths
        [self setNeedsLayout];
    
        // Update Draw view
        [drawView setNeedsDisplay:YES];
    }
}

- (void)layoutSubviews
{   
    var bounds = [drawView bounds],
        radius = MIN(CGRectGetWidth(bounds), CGRectGetHeight(bounds)) / 2,
        midX = CGRectGetMidX(bounds),
        midY = CGRectGetMidY(bounds),
        current_angle = 0.0;
        
    paths = [CPArray array];
    
    for (var i = 0; i < values.length; i++)
    {
        var value = values[i],
            end_angle = (value / sum) * 360.0;
        
        var path = CGPathCreateMutable();
        CGPathMoveToPoint(path, nil, midX, midY);
        CGPathAddArc(path, nil, midX, midY, radius, current_angle / (180 / PI), (current_angle + end_angle) / (180 / PI), YES);
        CGPathAddLineToPoint(path, nil, midX, midY);
        
        paths.push(path);
        
        current_angle += end_angle;
    }
}

- (id)indexOfValueAtPoint:(CGPoint)aPoint
{
    var context = CGBitmapGraphicsContextCreate();
    
    if (context.isPointInPath)
    {    
        for (var i = 0; i < paths.length; i++)
        {
            CGContextBeginPath(context);
            CGContextAddPath(context, paths[i]);
            CGContextClosePath(context);
        
            if (context.isPointInPath(aPoint.x, aPoint.y))
                return i;
        }
    }
    
    return -1;
}

- (void)mouseMoved:(CPEvent)anEvent
{   
    if ([delegate respondsToSelector:@selector(pieChartView:mouseMovedOverIndex:)])
    {
        var locationInView = [self convertPoint:[anEvent locationInWindow] fromView:nil];
        [delegate pieChartView:self mouseMovedOverIndex:[self indexOfValueAtPoint:locationInView]];
    }
}

- (void)mouseExited:(CPEvent)anEvent
{
    if ([delegate respondsToSelector:@selector(pieChartView:mouseMovedOverIndex:)])
        [delegate pieChartView:self mouseMovedOverIndex:-1];
}

@end


var LPPieChartViewDrawViewKey = @"LPPieChartViewDrawView",
    LPPieChartViewValuesKey   = @"LPPieChartViewValues",
    LPPieChartViewSumKey      = @"LPPieChartViewSum",
    LPPieChartViewPathsKey    = @"LPPieChartViewPaths";

@implementation LPPieChartView (CPCoding)
 
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self)
    {
        drawView = [aCoder decodeObjectForKey:LPPieChartViewDrawViewKey];
        
        values = [aCoder decodeObjectForKey:LPPieChartViewValuesKey];
        sum = [aCoder decodeFloatForKey:LPPieChartViewSumKey];
        paths = [aCoder decodeObjectForKey:LPPieChartViewPathsKey];
    }
 
    return self;
}
 
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:drawView forKey:LPPieChartViewDrawViewKey];
    
    [aCoder encodeObject:values forKey:LPPieChartViewValuesKey];
    [aCoder encodeFloat:sum forKey:LPPieChartViewSumKey];
    [aCoder encodeObject:paths forKey:LPPieChartViewPathsKey];
}
 
@end


@implementation LPPieChartDrawView : CPView
{
}

+ (CPString)themeClass
{
    return @"lp-piechart-drawview";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[[CPColor grayColor]], 1.0, [CPColor whiteColor]]
                                       forKeys:[@"fill-colors", @"line-width", @"stroke-color"]];
}

- (void)drawRect:(CGRect)aRect
{    
    // Should superview really be used?
    if ([self superview])
    {
        [self drawInContext:[[CPGraphicsContext currentContext] graphicsPort]
                      paths:[[self superview] paths]];
    }
}

- (void)drawInContext:(CGContext)context paths:(CPArray)paths
{
    /*
        Overwrite this method in your subclass.
    */
    CGContextSetLineWidth(context, [self currentValueForThemeAttribute:@"line-width"]);
    CGContextSetStrokeColor(context, [self currentValueForThemeAttribute:@"stroke-color"]);
    
    var fillColors = [self currentValueForThemeAttribute:@"fill-colors"];
    
    for (var i = 0; i < paths.length; i++)
    {
        CGContextBeginPath(context);
        CGContextAddPath(context, paths[i]);
        CGContextClosePath(context);

        CGContextSetFillColor(context, fillColors[i]);

        CGContextFillPath(context);
        CGContextStrokePath(context);
    }
}

@end
