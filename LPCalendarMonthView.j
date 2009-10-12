/*
 * LPCalendarMonthView.j
 * LPKit
 *
 * Created by Ludwig Pettersson on September 21, 2009.
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

@implementation CPDate (DaysInMonth)

- (int)daysInMonth
{
    return 32 - new Date(self.getFullYear(), self.getMonth(), 32).getDate();
}

- (void)resetToMidnight
{
    self.setHours(0);
    self.setMinutes(0);
    self.setSeconds(0);
    self.setMilliseconds(0);
}

@end

LPCalendarDayLength = 1;
LPCalendarWeekLength = 2;

var _startAndEndOfWeekCache = {};

@implementation LPCalendarMonthView : CPView
{
    CPArray dayTiles;
    CPDate date @accessors;
    CPDate previousMonth @accessors(readonly);
    CPDate nextMonth @accessors(readonly);
    BOOL _dataIsDirty;
    
    BOOL allowsMultipleSelection @accessors;
    int startSelectionIndex;
    int currentSelectionIndex;
    id selectionLengthType @accessors;
    CPArray selection;
    
    BOOL highlightCurrentPeriod @accessors;
    
    BOOL weekStartsOnMonday @accessors;
    
    id _delegate @accessors(property=delegate);
}

+ (CPString)themeClass
{
    return @"lp-calendar-month-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[nil]
                                       forKeys:[@"grid-color"]];
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        selectionLengthType = LPCalendarDayLength;
        selection = [CPArray array];
        
        weekStartsOnMonday = YES;
        
        [self setValue:[CPColor colorWithWhite:0.8 alpha:1] forThemeAttribute:@"grid-color" inState:CPThemeStateNormal];
        
        // Create tiles
        for (var i = 0; i < 42; i++)
            [self addSubview:[LPCalendarDayView dayView]];

        [self setNeedsLayout];
    }
    return self;
}

- (void)setDate:(CPDate)aDate
{
    // Make a copy of the date
    date = new Date(aDate.getTime());
    
    // Reset the date to the first day of the month & midnight
    date.setDate(1);
    [date resetToMidnight];
    
    // There must be a better way to do this.
    _firstDay = new Date((new Date(date)).setDate(1));
    
    previousMonth = new Date(_firstDay.getTime() - 86400000);
    nextMonth = new Date(_firstDay.getTime() + (([date daysInMonth] + 1) * 86400000));
    [self reloadData];
}

- (void)tileSize
{
    var bounds = [self bounds];
    
    // I need pixel level precision
    if (CGRectGetWidth(bounds) == 195)
        return CGSizeMake(28, 22);
    else
        return CGSizeMake(CGRectGetWidth(bounds) / 7, CGRectGetHeight(bounds) / 6);
}

- (int)startOfWeekForDate:(CPDate)aDate
{
    var day = aDate.getDay();
    
    if (weekStartsOnMonday)
    {
        if (day == 0)
            day = 6
        else if(day > 0)
            day -= 1
    }
    
    return day;
}

- (CPArray)startAndEndOfWeekForDate:(CPDate)aDate
{
    _cached = _startAndEndOfWeekCache[aDate.toString()];
    
    if (_cached)
        return _cached;
    
    var startOfWeek = new Date(aDate.getTime() - ([self startOfWeekForDate:aDate] * 86400000)),
        endOfWeek = new Date(startOfWeek.getTime() + (6 * 86400000));
    
    // Cache it
    _startAndEndOfWeekCache[aDate.toString()] = [startOfWeek, endOfWeek];
    
    return [startOfWeek, endOfWeek];
}

- (BOOL)dateIsWithinCurrentPeriod:(CPDate)aDate
{
    var currentPeriod = [CPDate date];
    [currentPeriod resetToMidnight];
    
    if (selectionLengthType === LPCalendarDayLength)
        return (currentPeriod.getDate() === aDate.getDate() &&
                currentPeriod.getMonth() === aDate.getMonth() &&
                currentPeriod.getFullYear() === aDate.getFullYear());
    
    if (selectionLengthType === LPCalendarWeekLength)
    {
        var startAndEnd = [self startAndEndOfWeekForDate:currentPeriod];
        
        return (([startAndEnd objectAtIndex:0] <= aDate) && ([startAndEnd objectAtIndex:1] >= aDate));
    }
    
    return NO;
}

- (void)reloadData
{
    if (!date)
        return;

    var currentMonth = date,
        startOfMonthDay = [self startOfWeekForDate:currentMonth],
        daysInMonth = [currentMonth daysInMonth];

    var daysInPreviousMonth = [previousMonth daysInMonth],
        firstDayToShowInPreviousMonth = daysInPreviousMonth - startOfMonthDay;

    var tiles = [self subviews],
        tileIndex = 0;

    var currentDate = new Date(previousMonth.getFullYear(), previousMonth.getMonth(), firstDayToShowInPreviousMonth);

    for (var weekIndex = 0; weekIndex < 6; weekIndex++)
    {
        for (var dayIndex = 0; dayIndex < 7; dayIndex++)
        {
            var dayTile = [tiles objectAtIndex:tileIndex],
                currentDate = new Date(currentDate.getTime() + 90000000);
            
            [currentDate resetToMidnight];
            
            [dayTile setIsFillerTile:(currentDate.getMonth() != currentMonth.getMonth())];
            [dayTile setDate:currentDate];
            [dayTile setHighlighted:[self dateIsWithinCurrentPeriod:currentDate]];
            
            tileIndex += 1;
        }
    }
}

- (void)tile
{
    var tiles = [self subviews],
        tileSize = [self tileSize],
        tileIndex = 0;
    
    if ([tiles count] > 0)
    {
        for (var weekIndex = 0; weekIndex < 6; weekIndex++)
        {
            for (var dayIndex = 0; dayIndex < 7; dayIndex++)
            {
                // CGRectInset() mucks up the frame for some reason.
                var tileFrame = CGRectMake((dayIndex * tileSize.width), weekIndex * tileSize.height + 1, tileSize.width - 1, tileSize.height -1);
            
                [[tiles objectAtIndex:tileIndex] setFrame:tileFrame];
                tileIndex += 1;
            }
        }
    }
}

- (void)setNeedsLayout
{
    [self tile];
}

- (CGPoint)locationInViewForEvent:(CPEvent)anEvent
{
    return [self convertPoint:[anEvent locationInWindow] fromView:[[self window] contentView]];
}

- (int)indexOfTileAtPoint:(CGPoint)aPoint
{
    var tileSize = [self tileSize];
    
    // Get the week row
    var rowIndex = FLOOR(aPoint.y / tileSize.height),
        columnIndex = FLOOR(aPoint.x / tileSize.width);
    
    // Limit the column index, there are only 7
    if (columnIndex > 6)
        columnIndex = 6;
    else if (columnIndex < 0)
        columnIndex = 0;
    
    // Limit the row index, there are only 6
    if (rowIndex > 5)
        rowIndex = 5;
    else if (rowIndex < 0)
        rowIndex = 0;
    
    var tileIndex = (rowIndex * 7) + columnIndex;
    
    // There are only 42 tiles
    if (tileIndex > 41)
        return 41;
    
    return tileIndex;
}

- (void)mouseDown:(CPEvent)anEvent
{
    var locationInView = [self locationInViewForEvent:anEvent],
        tileIndex = [self indexOfTileAtPoint:locationInView],
        tile = [[self subviews] objectAtIndex:tileIndex];
    
    startSelectionIndex = tileIndex;
    [self makeSelectionWithIndex:startSelectionIndex end:nil];
}

- (void)mouseDragged:(CPevent)anEvent
{
    var locationInView = [self locationInViewForEvent:anEvent],
        tileIndex = [self indexOfTileAtPoint:locationInView];
    
    if (currentSelectionIndex == tileIndex)
        return;
    
    currentSelectionIndex = tileIndex;
    
    if (!allowsMultipleSelection)
        startSelectionIndex = currentSelectionIndex;
    
    [self makeSelectionWithIndex:startSelectionIndex end:currentSelectionIndex];
}

- (void)mouseUp:(CPEvent)anEvent
{
    // Clicked a date
    if (!currentSelectionIndex || startSelectionIndex == currentSelectionIndex)
    {
        var calendarView = [[self superview] superview],
            tile = [[self subviews] objectAtIndex:startSelectionIndex],
            tileDate = [tile date],
            tileMonth = tileDate.getMonth();

        // Clicked within the current month
        //if (tileMonth == date.getMonth())
        //    console.log('same month')
        
        // Clicked the Previous month
        if (tileMonth == previousMonth.getMonth())
            [calendarView changeToMonth:previousMonth];
        
        // Clicked the Next month
        if (tileMonth == nextMonth.getMonth())
            [calendarView changeToMonth:nextMonth];
        
    }
    // Made a selection
    else
        currentSelectionIndex = nil;
}

- (void)makeSelectionWithDate:(CPDate)aStartDate end:(CPDate)anEndDate
{
    if (!allowsMultipleSelection)
        anEndDate = nil;
    
    if (selectionLengthType === LPCalendarWeekLength)
    {
        var startAndEnd = [self startAndEndOfWeekForDate:aStartDate];
        
        aStartDate = [startAndEnd objectAtIndex:0];
        anEndDate = [startAndEnd objectAtIndex:1];
    }
    
    // Replace hours / minutes / seconds
    var _dates = [aStartDate, anEndDate];
    for (var i = 0; i < 2; i++)
    {
        if ([_dates objectAtIndex:i])
            [[_dates objectAtIndex:i] resetToMidnight];
    }
    
    // Swap the dates if startDate is bigger than endDate
    if (aStartDate > anEndDate && anEndDate != nil)
    {
        // Make a copy of startDate
        var _aStartDateCopy = aStartDate;
        
        aStartDate = anEndDate;
        anEndDate = _aStartDateCopy;
    }
    
    // Reset selection data
    [selection removeAllObjects];
    
    var tiles = [self subviews];

    for (var i = 0; i < [tiles count]; i++)
    {
        var tile = [tiles objectAtIndex:i],
            tileDate = [tile date];

        [tileDate resetToMidnight];
        
        if (aStartDate && ((tileDate >= aStartDate && tileDate <= anEndDate) || tileDate.getTime() == aStartDate.getTime()))
        {
            [selection addObject:[tile date]];
            [tile setSelected:YES];
        }
        else
            [tile setSelected:NO];
    }
    
    if ([selection count] > 0 && [_delegate respondsToSelector:@selector(didMakeSelection:)])
        [_delegate didMakeSelection:selection];
}

- (void)makeSelectionWithIndex:(int)aStartIndex end:(int)anEndIndex
{
    var tiles = [self subviews];
    
    [self makeSelectionWithDate:(aStartIndex > -1) ? [[tiles objectAtIndex:aStartIndex] date] : nil
                            end:(anEndIndex > -1) ? [[tiles objectAtIndex:anEndIndex] date] : nil];
}

- (void)drawRect:(CGRect)aRect
{
	var context = [[CPGraphicsContext currentContext] graphicsPort],
	    bounds = [self bounds],
	    width = CGRectGetWidth(bounds),
	    height = CGRectGetHeight(bounds),
	    tileSize = [self tileSize];
	
	CGContextSetFillColor(context, [self currentValueForThemeAttribute:@"grid-color"]);
    
    // Horizontal lines
    for (var i = 0; i < 6; i++)
        CGContextFillRect(context, CGRectMake(0, i * tileSize.height, width, 1));

    // Vertical lines
    for (var i = 0; i < 7; i++)
        CGContextFillRect(context, CGRectMake(i * tileSize.width - 1, 0, 1, height));
}

@end


@implementation LPCalendarDayView : CPControl
{
    CPDate date @accessors;
    CPTextField textField;
    BOOL isFillerTile @accessors;
    BOOL isSelected @accessors(setter=setSelected:);
    BOOL isHighlighted @accessors(setter=setHighlighted:);
}

+ (CPString)themeClass
{
    return @"lp-calendar-day-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[nil, nil]
                                       forKeys:[@"background-color", @"bezel-color"]];
}

+ (id)dayView
{
    return [[self alloc] initWithFrame:CGRectMakeZero()];
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];
        
        textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [textField setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        
        // Normal
        [self setValue:[CPFont boldSystemFontOfSize:11.0] forThemeAttribute:@"font" inState:CPThemeStateNormal];
        [self setValue:[CPColor colorWithHexString:@"333"] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
        [self setValue:[CPColor colorWithWhite:1 alpha:0.8] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [self setValue:CGSizeMake(1.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    
        [self setValue:[CPColor clearColor] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    
        // Highlighted (The highlighted day, default is the current day)
        [self setValue:[CPColor colorWithHexString:@"a0c1ed"] forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted];        
        [self setValue:[CPColor colorWithHexString:@"555"] forThemeAttribute:@"text-color" inState:CPThemeStateHighlighted];
        
        // Selected
        [self setValue:[CPColor colorWithHexString:@"fff"] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
        [self setValue:[CPColor colorWithWhite:0 alpha:0.4] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
        [self setValue:[CPColor colorWithWhite:0 alpha:0.2] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    
        // Selected & Highlighted (The highlighted day, default is the current day)
        [self setValue:[CPColor colorWithHexString:@"719edb"] forThemeAttribute:@"bezel-color" inState:CPThemeStateHighlighted | CPThemeStateSelected];
    
        // Disabled
        [self setValue:[CPColor colorWithWhite:0 alpha:0.3] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
        
        // Disabled & Selected (Next and previous month tiles)
        [self setValue:[CPColor colorWithWhite:0 alpha:0.25] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
        [self setValue:[CPColor colorWithWhite:0 alpha:0.4] forThemeAttribute:@"text-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
        [self setValue:[CPColor clearColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected | CPThemeStateDisabled];
    
        //[self setIsFillerTile:NO];
        [self addSubview:textField];
    }
    return self;
}

- (void)setSelected:(BOOL)shouldBeSelected
{
    isSelected = shouldBeSelected;
    
    if (shouldBeSelected)
        [self setThemeState:CPThemeStateSelected];
    else
        [self unsetThemeState:CPThemeStateSelected];
}

- (void)setIsFillerTile:(BOOL)shouldBeFillerTile
{
    isFillerTile = shouldBeFillerTile;
    
    if (isFillerTile)
        [self setThemeState:CPThemeStateDisabled];
    else
        [self unsetThemeState:CPThemeStateDisabled];
}

- (void)setHighlighted:(BOOL)shouldBeHighlighted
{
    isHighlighted = shouldBeHighlighted;

    if (shouldBeHighlighted)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];
}

- (void)setDate:(CPDate)aDate
{
    date = aDate;
    
    [textField setStringValue:[date.getDate() stringValue]];
    [textField sizeToFit];
    
    var bounds = [self bounds];
    [textField setCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
}

- (void)layoutSubviews
{
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]]
    
    [textField setFont:[self currentValueForThemeAttribute:@"font"]];
    [textField setTextColor:[self currentValueForThemeAttribute:@"text-color"]];
    [textField setTextShadowColor:[self currentValueForThemeAttribute:@"text-shadow-color"]];
    [textField setTextShadowOffset:[self currentValueForThemeAttribute:@"text-shadow-offset"]];
}

@end