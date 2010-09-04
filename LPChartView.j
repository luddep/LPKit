/*
 * LPChartView.j
 * LPKit
 *
 * Created by Ludwig Pettersson on December 6, 2009.
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

// TODO: These should be ivars, or more likely, theme settings.
var labelViewHeight = 20,
    drawViewPadding = 5;


@implementation LPChartView : CPView
{
    id               dataSource @accessors;
    id               delegate @accessors;
    id               drawView @accessors;
    
    LPChartGridView  gridView @accessors;
    
    LPChartLabelView labelView @accessors(readonly);
    BOOL             displayLabels @accessors;
    
    CPArray          _data;
    int              _maxValue;
    
    CPArray          _framesSet;
    CGSize           _currentSize;
    
    float            _maxValuePosition;
    float            _minValuePosition;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _setup];
    }
    return self;
}

- (void)_setup
{
    _maxValuePosition = 1.0;
    _minValuePosition = 0.0;
    
    gridView = [[LPChartGridView alloc] initWithFrame:CGRectMakeZero()];
    [gridView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [self addSubview:gridView];
    
    var bounds = [self bounds];
    
    labelView = [[LPChartLabelView alloc] initWithFrame:CGRectMake(drawViewPadding, CGRectGetHeight(bounds) - labelViewHeight, CGRectGetWidth(bounds) - (2 * drawViewPadding), labelViewHeight)];
    [self addSubview:labelView];
    
    _currentSize = CGSizeMake(0,0);
}

- (void)setDataSource:(id)aDataSource
{
    dataSource = aDataSource;
}

- (void)setDrawView:(id)aDrawView
{
    if (aDrawView === drawView)
        return;
    
    if (drawView)
        [drawView removeFromSuperview];
    
    [self addSubview:aDrawView positioned:CPWindowAbove relativeTo:gridView];
    
    // Got a new drawView
    drawView = aDrawView;
    
    // Resize the drawview to the correct size
    var drawViewFrame = CGRectInset([self bounds], drawViewPadding, drawViewPadding);
    
    // Don't let it draw over the labelView
    if (labelView)
        drawViewFrame.size.height -= CGRectGetHeight([labelView bounds]);
    
    // Update drawView frame & autoresizingmask
    [drawView setFrame:drawViewFrame];
    [drawView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    // Make drawView 1px higher, so the bottom line can be seen
    drawViewFrame.size.height += 1;
    
    // Update gridview as well
    [gridView setFrame:drawViewFrame];
    
    // Re-draw
    if ([self window])
        [self reloadData];
}

- (void)setGridView:(CPView)aGridView
{
    if (gridView === aGridView)
        return;
    
    [aGridView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [self replaceSubview:gridView with:aGridView];
    
    gridView = aGridView;
}

- (void)setDisplayLabels:(BOOL)shouldDisplayLabels
{
    // Already have labels, and should remove them
    if (!displayLabels && labelView)
    {
        // Resize drawView
        var drawViewSize = [drawView frame];
        drawViewSize.size.height += CGRectGetHeight([labelView bounds]);
        [drawView setFrame:drawViewSize];
        
        // Remove labelview
        [labelView removeFromSuperview];
    }
    // We should create labels
    else
    {
        labelView = [[LPChartLabelView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(aFrame) - labelViewHeight, CGRectGetWidth(aFrame), labelViewHeight)];
        [self addSubview:labelView];
    }
    
    displayLabels = shouldDisplayLabels;
}

- (void)setDisplayGrid:(BOOL)shouldDisplayGrid
{
    [gridView setHidden:!shouldDisplayGrid];
}

- (void)setMaxValuePosition:(float)aMaxValuePosition minValuePosition:(float)aMinValuePosition
{
    _maxValuePosition = aMaxValuePosition;
    _minValuePosition = aMinValuePosition;
    
    [[self drawView] setNeedsDisplay:YES];
}

- (CPArray)itemFrames
{
    return (dataSource && drawView && _data) ? [self calculateItemFramesWithSets:_data maxValue:_maxValue] : [CPArray array];
}

- (void)reloadData
{
    if (!dataSource || !drawView)
        return;
    
    // Reset data & max value
    _data = [CPArray array];
    _maxValue = 0;
    
    var numberOfSets = [dataSource numberOfSetsInChart:self];
    
    for (var setIndex = 0; setIndex < numberOfSets; setIndex++)
    {
        var row = [],
            numberOfItems = [dataSource chart:self numberOfValuesInSet:setIndex];
        
        for (var itemIndex = 0; itemIndex < numberOfItems; itemIndex++)
        {
            var value = [dataSource chart:self valueForIndex:itemIndex set:setIndex];
            
            if (value > _maxValue)
                _maxValue = value;
            
            row.push(value);
        }
        
        _data.push(row);
    }
    
    // Clear the current size of the chart
    // this will force the re-calculation of item frames.
    _currentSize = nil;
    
    // Update grid view
    [gridView setNeedsDisplay:YES];
    
    // Update Label view
    [labelView reloadData];
    
    // Update Draw view
    [drawView setNeedsDisplay:YES];
}

- (CPArray)calculateItemFramesWithSets:(CPArray)sets maxValue:(int)aMaxValue
{
    var drawViewSize = [drawView bounds].size,
        maxValueHeightDelta = (1.0 - _maxValuePosition) * drawViewSize.height;
    
    // Restrict drawViewSize according to min value positions
    if (_minValuePosition !== 0.0)
        drawViewSize.height -= _minValuePosition * drawViewSize.height;

    if (_maxValuePosition !== 1.0)
        drawViewSize.height -= maxValueHeightDelta;

    // Make sure we don't do unnecessary word
    if (_currentSize && CGSizeEqualToSize(_currentSize, drawViewSize))
        return _framesSet;
        
    _currentSize = drawViewSize;

    // Reset frames set
    _framesSet = [CPArray array];
    
    if (!sets.length)
        return _framesSet;
        
    // If the chart has no data to display,
    // we set the max value to 1 so that it will
    // at least draw an empty line at the bottom of the chart.
    if (aMaxValue === 0)
        aMaxValue = 1;
    
    var width = drawViewSize.width,
        height = drawViewSize.height - (2 * drawViewPadding),
        numberOfItems = sets[0].length,
        itemWidth = width / numberOfItems,
        unusedWidth = width - (numberOfItems * itemWidth);

    for (var setIndex = 0; setIndex < sets.length; setIndex++)
    {
        var items = sets[setIndex],
            currentItemOriginX = 0,
            row = [];
        
        for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
        {
            var value = items[itemIndex],
                itemFrame = CGRectMake(currentItemOriginX, 0, itemWidth, 0);
            
            // Pad the width of the item if we have any unused width
            if (unusedWidth > 0)
            {
                itemFrame.size.width++;
                unusedWidth--;
            }
            
            // Set the height
            itemFrame.size.height = ROUND((value / aMaxValue) * height);
            
            // Set Y Origin
            itemFrame.origin.y = height - CGRectGetHeight(itemFrame) + drawViewPadding;
            
            // Make up for _maxValuePosition if it's set
            if (_maxValuePosition !== 1.0)
                itemFrame.origin.y += maxValueHeightDelta;
            
            // Save it
            row.push(itemFrame);
            
            // Set the X origin for the next item
            currentItemOriginX += CGRectGetWidth(itemFrame);
        }
        
        _framesSet.push(row);
    }
    
    return _framesSet;
}

- (CPString)horizontalLabelForIndex:(int)anIndex
{
    return [dataSource chart:self labelValueForIndex:anIndex];
}

- (void)mouseMoved:(CPEvent)anEvent
{
    if (delegate && [delegate respondsToSelector:@selector(chart:didMouseOverItemAtIndex:)])
    {
        var itemFrames = [self itemFrames];
        
        if (!itemFrames.length)
            return;
            
        var firstSet = itemFrames[0],
            locationInDrawView = [drawView convertPoint:[anEvent locationInWindow] fromView:nil];
    
        for (var i = 0; i < firstSet.length; i++)
        {
            var itemFrame = firstSet[i];
        
            if (itemFrame.origin.x <= locationInDrawView.x && (itemFrame.origin.x + itemFrame.size.width) > locationInDrawView.x)
            {
                [delegate chart:self didMouseOverItemAtIndex:i];
                return;
            }
        }
    }
}

- (void)mouseExited:(CPEvent)anEvent
{
    if (delegate && [delegate respondsToSelector:@selector(chart:didMouseOverItemAtIndex:)])
        [delegate chart:self didMouseOverItemAtIndex:-1];
}

- (void)viewDidMoveToWindow
{
    [self reloadData];
}

@end


var LPChartViewDataSourceKey       = @"LPChartViewDataSourceKey",
    LPChartViewDrawViewKey         = @"LPChartViewDrawViewKey",
    LPChartViewGridViewKey         = @"LPChartViewGridViewKey",
    LPChartViewDisplayLabelsKey    = @"LPChartViewDisplayLabelsKey",
    LPChartViewLabelViewKey        = @"LPChartViewLabelViewKey",
    LPChartViewDataKey             = @"LPChartViewDataKey",
    LPChartViewMaxValueKey         = @"LPChartViewMaxValueKey",
    LPChartViewFramesSetKey        = @"LPChartViewFramesSetKey",
    LPChartViewCurrentSizeKey      = @"LPChartViewCurrentSizeKey",
    LPChartViewMaxValuePositionKey = @"LPChartViewMaxValuePositionKey",
    LPChartViewMinValuePositionKey = @"LPChartViewMinValuePositionKey";

@implementation LPChartView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        dataSource = [aCoder decodeObjectForKey:LPChartViewDataSourceKey];
        
        gridView = [aCoder decodeObjectForKey:LPChartViewGridViewKey];
        drawView = [aCoder decodeObjectForKey:LPChartViewDrawViewKey];
        
        displayLabels = ![aCoder containsValueForKey:LPChartViewDisplayLabelsKey] || [aCoder decodeObjectForKey:LPChartViewDisplayLabelsKey];
        labelView = [aCoder decodeObjectForKey:LPChartViewLabelViewKey];
        
        _data = [aCoder decodeObjectForKey:LPChartViewDataKey];
        _maxValue = [aCoder decodeIntForKey:LPChartViewMaxValueKey];
        
        _framesSet = [aCoder decodeObjectForKey:LPChartViewFramesSetKey];
        _currentSize = [aCoder decodeSizeForKey:LPChartViewCurrentSizeKey];
        
        _maxValuePosition = [aCoder decodeIntForKey:LPChartViewMaxValuePositionKey];
        _minValuePosition = [aCoder decodeFloatForKey:LPChartViewMinValuePositionKey];
        
        [self _setup];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:dataSource forKey:LPChartViewDataSourceKey];
    [aCoder encodeObject:drawView forKey:LPChartViewDrawViewKey];
    
    [aCoder encodeObject:gridView forKey:LPChartViewGridViewKey];
    
    [aCoder encodeBool:displayLabels forKey:LPChartViewDisplayLabelsKey];
    [aCoder encodeObject:labelView forKey:LPChartViewLabelViewKey];
    
    [aCoder encodeObject:_data forKey:LPChartViewDataKey];
    [aCoder encodeInt:_maxValue forKey:LPChartViewMaxValueKey];
    
    [aCoder encodeObject:_framesSet forKey:LPChartViewFramesSetKey];
    
    if (_currentSize)
        [aCoder encodeSize:_currentSize forKey:LPChartViewCurrentSizeKey];
    
    [aCoder encodeFloat:_maxValuePosition forKey:LPChartViewMaxValuePositionKey];
    [aCoder encodeFloat:_minValuePosition forKey:LPChartViewMinValuePositionKey];
}

@end


@implementation LPChartGridView : CPView
{
    CPColor gridColor @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        gridColor = [CPColor colorWithWhite:0 alpha:0.05];
        [self setHitTests:NO];
    }
    return self;
}

- (void)setGridColor:(CPColor)aColor
{
    gridColor = aColor;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    if (itemFrames = [[self superview] itemFrames])
    {
        var context = [[CPGraphicsContext currentContext] graphicsPort],
            bounds = [self bounds],
            width = CGRectGetWidth(bounds),
            height = CGRectGetHeight(bounds),
            lineWidth = 1;
    
        CGContextSetFillColor(context, gridColor);
        
        // Vertical lines
        if (itemFrames.length)
        {
            for (var i = 0; i < itemFrames[0].length; i++)
            {
                CGContextFillRect(context, CGRectMake(FLOOR(itemFrames[0][i].origin.x), 0, lineWidth, height));
            }
        }
        else
            CGContextFillRect(context, CGRectMake(0, 0, lineWidth, height));
    
        // Right most line
        CGContextFillRect(context, CGRectMake(width - lineWidth, 0, lineWidth, height));
    
        // Bottom & middle line
        CGContextFillRect(context, CGRectMake(0, height - lineWidth, width, lineWidth));
        CGContextFillRect(context, CGRectMake(0, FLOOR(height / 2), width, lineWidth));
    }
}

@end


@implementation LPChartDrawView : CPView
{
}

- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];
    }
    return self;
}

- (void)drawRect:(CGRect)aRect
{
    if (itemFrames = [[self superview] itemFrames])
    {
        var context = [[CPGraphicsContext currentContext] graphicsPort];
        [self drawSetWithFrames:itemFrames inContext:context];
    }
}

- (void)drawSetWithFrames:(CPArray)aFramesSet inContext:(CGContext)context
{
    // Overwrite this method in your subclass
    // to get complete control of the drawing.
    
    CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"4379ca"]);
    CGContextSetLineWidth(context, 2.0);
    
    for (var setIndex = 0; setIndex < aFramesSet.length; setIndex++)
    {
        var items = aFramesSet[setIndex];
        
        // Start path
        CGContextBeginPath(context);
        
        for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
        {
            var itemFrame = items[itemIndex],
                point = CGPointMake(CGRectGetMidX(itemFrame), CGRectGetMinY(itemFrame));
            
            // Begin path
            if (itemIndex == 0)
                CGContextMoveToPoint(context, point.x, point.y);
            
            // Add point
            else
                CGContextAddLineToPoint(context, point.x, point.y);
        }
        
        // Stroke path
        CGContextStrokePath(context);
        
        // Close path
        CGContextClosePath(context);
    }
}

@end


@implementation LPChartLabelView : CPView
{
    LPChartView chart;
    
    id _labelPrototype;
    CPData _labelData;
    CPArray _cachedLabels;
}
 
- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
        [self setHitTests:NO];

        [self setLabelPrototype:[LPChartLabel labelWithItemIndex:-1]];
    }
    return self;
}

- (void)setLabelPrototype:(id)aLabelPrototype
{
    _labelPrototype = aLabelPrototype;
    _labelData = nil;
    _cachedLabels = [CPArray array];
    
    [self reloadData];
}

- (id)newLabelWithItemIndex:(int)anItemIndex
{
    if (_cachedLabels.length)
        var label = _cachedLabels.pop();
    else
    {
        if (!_labelData)
            if (_labelPrototype)
                _labelData = [CPKeyedArchiver archivedDataWithRootObject:_labelPrototype];
        
        var label = [CPKeyedUnarchiver unarchiveObjectWithData:_labelData];
    }
    
    [label setItemIndex:anItemIndex];
    
    return label;
}

- (void)reloadData
{
    if (chart)
    {
        var subviews = [self subviews];
        
        // Clear any previous labels
        if (numberOfSubviews = subviews.length)
        {
            while (numberOfSubviews--)
            {
                [subviews[numberOfSubviews] removeFromSuperview];
                
                if (_labelData)
                    _cachedLabels.push(subviews[numberOfSubviews]);
            }
        }
        
        // Insert new subviews
        var itemFrames = [chart itemFrames];
        
        if (itemFrames && itemFrames.length)
        {
            itemFrames = itemFrames[0];
            for (var i = 0, length = itemFrames.length; i < length; i++)
            {
                var label = [self newLabelWithItemIndex:i];
                [label setLabel:[chart horizontalLabelForIndex:i]];
                [self addSubview:label];
            }
        }
        
        // Layout subviews
        [self setNeedsLayout];
    }
}

- (void)viewDidMoveToSuperview
{
    chart = [self superview];
}

- (void)layoutSubviews
{
    var itemFrames = [chart itemFrames];
    
    if (!itemFrames)
        return;
    
    var subviews = [self subviews],
        numberOfSubviews = subviews.length,
        bounds = [self bounds],
        itemFrames = itemFrames[0],
        drawViewPadding = CGRectGetMinX([[chart drawView] frame]),
        midY = CGRectGetMidY(bounds);

    while (numberOfSubviews--)
    {
        var subview = subviews[numberOfSubviews];
        [subview setCenter:CGPointMake(CGRectGetMidX(itemFrames[numberOfSubviews]) + drawViewPadding, midY)];
        
        var subviewFrame = [subview frame];
        
        // Make sure the label stays within the rame
        if (subviewFrame.origin.x < 0)
        {
            frameIsDirty = YES;
            subviewFrame.origin.x = 0;
            [subview setFrame:subviewFrame];
        }
        else if (CGRectGetMaxX(subviewFrame) > bounds.size.width)
        {
            frameIsDirty = YES;
            subviewFrame.origin.x -= CGRectGetMaxX(subviewFrame) - bounds.size.width;
            [subview setFrame:subviewFrame];
        }
    }
}
 
@end


var LPChartLabelViewChartKey          = @"LPChartLabelViewChartKey",
    LPChartLabelViewLabelPrototypeKey = @"LPChartLabelViewLabelPrototypeKey";

@implementation LPChartLabelView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        chart = [aCoder decodeObjectForKey:LPChartLabelViewChartKey];
        _labelPrototype = [aCoder decodeObjectForKey:LPChartLabelViewLabelPrototypeKey];
        _cachedLabels = [CPArray array];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:chart forKey:LPChartLabelViewChartKey];
    [aCoder encodeObject:_labelPrototype forKey:LPChartLabelViewLabelPrototypeKey];
}

@end


@implementation LPChartLabel : CPTextField
{
    int _itemIndex @accessors(property=itemIndex);
}
 
+ (id)labelWithItemIndex:(int)anItemIndex
{
    var label = [[self alloc] initWithFrame:CGRectMakeZero()];
    [label setItemIndex:anItemIndex];
    return label;
}
 
- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];
    }
    return self;
}

- (void)setLabel:(CPString)aLabel
{
    if (aLabel !== [self stringValue])
    {
        [self setStringValue:aLabel];
        [self sizeToFit];
    }
}

@end


var LPChartLabelItemIndexKey = @"LPChartLabelItemIndexKey";

@implementation LPChartLabel (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _itemIndex = [aCoder decodeIntForKey:LPChartLabelItemIndexKey];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInt:_itemIndex forKey:LPChartLabelItemIndexKey];
}

@end