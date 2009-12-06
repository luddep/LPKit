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


// TODO: These should be ivars, or more likely, theme settings.
var labelViewHeight = 20,
    drawViewPadding = 5;

@implementation LPChartView : CPView
{
    id dataSource @accessors;
    id drawView @accessors;
    
    BOOL displayLabels @accessors;
    LPChartLabelView labelView;
    
    CPArray _data;
    int _maxValue;
    
    CPArray _framesSet;
    CGSize _currentSize;
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        //[self setBackgroundColor:[CPColor colorWithWhite:0 alpha:0.1]];

        labelView = [[LPChartLabelView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(aFrame) - labelViewHeight, CGRectGetWidth(aFrame), labelViewHeight)];
        [self addSubview:labelView];
        
        _currentSize = CGSizeMake(0,0);
    }
    return self;
}

- (void)setDataSource:(id)aDataSource
{
    dataSource = aDataSource;
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
    
    // Resize the drawview to the correct size
    var drawViewFrame = CGRectInset([self bounds], drawViewPadding, drawViewPadding);
    
    if (labelView)
        drawViewFrame.size.height -= CGRectGetHeight([labelView bounds]);
    
    [drawView setFrame:drawViewFrame];
    
    [self reloadData];
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

- (CPArray)itemFrames
{
    if (_data && _maxValue >= 0)
        return [self calculateItemFramesWithSets:_data maxValue:_maxValue];
    else
        return nil;
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
    
    // Update Label view
    [labelView reloadData];
    
    // Update Draw view
    [drawView setNeedsDisplay:YES];
}

- (CPArray)calculateItemFramesWithSets:(CPArray)sets maxValue:(int)aMaxValue
{
    drawViewSize = [drawView bounds].size;
    
    //if (_currentSize && CGSizeEqualToSize(_currentSize, drawViewSize))
    //    return _framesSet;  
    //_currentSize = drawViewSize;

    // Reset frames set
    _framesSet = [CPArray array];
    
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

@end


var LPChartViewDataSourceKey    = @"LPChartViewDataSourceKey",
    LPChartViewDrawViewKey      = @"LPChartViewDrawViewKey",
    LPChartViewDisplayLabelsKey = @"LPChartViewDisplayLabelsKey",
    LPChartViewLabelViewKey     = @"LPChartViewLabelViewKey",
    LPChartViewDataKey          = @"LPChartViewDataKey",
    LPChartViewMaxValueKey      = @"LPChartViewMaxValueKey",
    LPChartViewFramesSetKey     = @"LPChartViewFramesSetKey",
    LPChartViewCurrentSizeKey   = @"LPChartViewCurrentSizeKey";

@implementation LPChartView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        dataSource = [aCoder decodeObjectForKey:LPChartViewDataSourceKey];
        drawView = [aCoder decodeObjectForKey:LPChartViewDrawViewKey];
        
        displayLabels = ![aCoder containsValueForKey:LPChartViewDisplayLabelsKey] || [aCoder decodeObjectForKey:LPChartViewDisplayLabelsKey];
        labelView = [aCoder decodeObjectForKey:LPChartViewLabelViewKey];
        
        _data = [aCoder decodeObjectForKey:LPChartViewDataKey];
        _maxValue = [aCoder decodeIntForKey:LPChartViewMaxValueKey];
        
        _framesSet = [aCoder decodeObjectForKey:LPChartViewFramesSetKey];
        _currentSize = [aCoder decodeSizeForKey:LPChartViewCurrentSizeKey];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:dataSource forKey:LPChartViewDataSourceKey];
    [aCoder encodeObject:drawView forKey:LPChartViewDrawViewKey];
    
    [aCoder encodeBool:displayLabels forKey:LPChartViewDisplayLabelsKey];
    [aCoder encodeObject:labelView forKey:LPChartViewLabelViewKey];
    
    [aCoder encodeObject:_data forKey:LPChartViewDataKey];
    [aCoder encodeInt:_maxValue forKey:LPChartViewMaxValueKey];
    
    [aCoder encodeObject:_framesSet forKey:LPChartViewFramesSetKey];
    if (_currentSize)
        [aCoder encodeSize:_currentSize forKey:LPChartViewCurrentSizeKey];
}

@end


@implementation LPChartDrawView : CPView
{
}

- (void)init
{
    if (self = [super initWithFrame:CGRectMakeZero()])
    {
        [self setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
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
}
 
- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
        [self setHitTests:NO];
        
        //[self setBackgroundColor:[CPColor redColor]];
    }
    return self;
}

- (void)reloadData
{
    var subviews = [self subviews];

    // Clear any previous labels
	if (numberOfSubviews = subviews.length)
		while (numberOfSubviews--)
			[subviews[numberOfSubviews] removeFromSuperview];
	
	//var chart = [self superview];
	
	// Insert new subviews
	if (itemFrames = [chart itemFrames][0])
	{
	    for (var i = 0, length = itemFrames.length; i < length; i++)
	    {
	        if (label = [chart horizontalLabelForIndex:i])
	            [self addSubview:[LPChartLabel labelWithItemIndex:i]];
	    }
    }
    
    // Layout subviews
    [self setNeedsLayout];
}

- (void)viewDidMoveToSuperview
{
    chart = [self superview];
}

- (void)layoutSubviews
{
    var subviews = [self subviews],
        numberOfSubviews = subviews.length,
        bounds = [self bounds],
        itemFrames = [chart itemFrames][0],
        drawViewPadding = CGRectGetMinX([[chart drawView] frame])

    while (numberOfSubviews--)
    {
        var subview = subviews[numberOfSubviews];
    
        if (label = [chart horizontalLabelForIndex:[subview itemIndex]])
        {
            [subview setLabel:label];
            [subview setCenter:CGPointMake(CGRectGetMidX(itemFrames[numberOfSubviews]) + drawViewPadding, CGRectGetMidY(bounds))];
        }
    }
}
 
@end


var LPChartLabelViewChartKey = @"LPChartLabelViewChartKey";

@implementation LPChartLabelView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        chart = [aCoder decodeIntForKey:LPChartLabelViewChartKey];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInt:chart forKey:LPChartLabelViewChartKey];
}

@end


@implementation LPChartLabel : CPTextField
{
    int _itemIndex @accessors(property=itemIndex);
}
 
+ (id)labelWithItemIndex:(int)anItemIndex
{
    return [[self alloc] initWithItemIndex:anItemIndex];
}
 
- (id)initWithItemIndex:(int)anItemIndex
{
    if (self = [super initWithFrame:CGRectMakeZero()])
    {
        _itemIndex = anItemIndex;
        
        [self setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
        [self setFont:[CPFont boldFontWithName:@"Lucida Grande" size:10]];
        [self setTextColor:[CPColor colorWithHexString:@"333"]];
        //[self setBackgroundColor:[CPColor colorWithWhite:0 alpha:0.1]]
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