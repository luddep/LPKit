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
@import <AppKit/CPControl.j>
@import <AppKit/CPView.j>
@import <Foundation/CPDate.j>


var immutableDistantFuture = [CPDate distantFuture];

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
    CPArray         dayTiles;
    CPDate          date @accessors;
    CPDate          previousMonth @accessors(readonly);
    CPDate          nextMonth @accessors(readonly);
    BOOL            _dataIsDirty;

    BOOL            allowsMultipleSelection @accessors;
    int             startSelectionIndex;
    int             currentSelectionIndex;
    id              selectionLengthType @accessors;
    CPArray         selection;

    BOOL            highlightCurrentPeriod @accessors;
    BOOL            weekStartsOnMonday @accessors;
    
    id              _delegate @accessors(property=delegate);
    LPCalendarView  calendarView @accessors;
    CPArray         hiddenRows @accessors;
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

- (id)initWithFrame:(CGRect)aFrame calendarView:(LPCalendarView)aCalendarView
{
    if (self = [super initWithFrame:aFrame])
    {
        calendarView = aCalendarView;
        selectionLengthType = LPCalendarDayLength;
        selection = [CPArray array];
        weekStartsOnMonday = YES;
        hiddenRows = [];

        // Create tiles
        for (var i = 0; i < 42; i++)
            [self addSubview:[LPCalendarDayView dayViewWithCalendarView:aCalendarView]];
    }
    return self;
}

- (void)setAllTilesAsFiller
{
    [self setDate:[CPDate distantFuture]];
}

- (void)setDate:(CPDate)aDate
{
    // No need to reloadData if the new date is the same as before.
    // ==
    // Future note: Do not use UTC comparison here,
    // since we reset the date to the relative midnight later on. 
    if (date && date.getFullYear() === aDate.getFullYear() && date.getMonth() === aDate.getMonth())
        return;
    
    date = [aDate copy];

    if (![aDate isEqualToDate:immutableDistantFuture])
    {
        // Reset the date to the first day of the month & midnight
        date.setDate(1);
        [date resetToMidnight];

        // There must be a better way to do this.
        _firstDay = [date copy];
        _firstDay.setDate(1);

        previousMonth = new Date(_firstDay.getTime() - 86400000);
        nextMonth = new Date(_firstDay.getTime() + (([date daysInMonth] + 1) * 86400000));
    }
    
    [self reloadData];
}

- (void)setSelectionLengthType:(id)aSelectionType
{
    if (selectionLengthType === aSelectionType)
        return;
    
    selectionLengthType = aSelectionType;
    
    [self reloadData];
}

- (void)tileSize
{
    var tileSize = [calendarView currentValueForThemeAttribute:@"tile-size"];
    
    if (tileSize)
        return tileSize
    else
    {
        var bounds = [self bounds];
        return CGSizeMake(CGRectGetWidth(bounds) / 7, CGRectGetHeight(bounds) / 6);
    }
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

- (void)setHiddenRows:(CPArray)hiddenRowsArray
{
    if ([hiddenRows isEqualToArray:hiddenRowsArray])
        return;
    
    hiddenRows = hiddenRowsArray;
    
    var tiles = [self subviews],
        tileIndex = 0,
        showAllRows = !hiddenRowsArray
    
    for (var weekIndex = 0; weekIndex < 6; weekIndex++)
    {
        var shouldHideRow = showAllRows || [hiddenRows indexOfObject:weekIndex] > -1;

        for (var dayIndex = 0; dayIndex < 7; dayIndex++)
        {
            [tiles[tileIndex] setHidden:shouldHideRow];
            tileIndex += 1;
        }
    }
}

- (void)reloadData
{   
    if (!date)
        return;

    var entireMonthIsFiller = date.getTime() == immutableDistantFuture.getTime(),
        currentMonth = date,
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
            var dayTile = tiles[tileIndex];

            // Increment to next day
            currentDate.setTime(currentDate.getTime() + 90000000);
            [currentDate resetToMidnight];

            if (!dayTile._isHidden)
            {
                [dayTile setIsFillerTile:(entireMonthIsFiller) ? YES : currentDate.getMonth() != currentMonth.getMonth()];
                [dayTile setDate:currentDate];

                if (!entireMonthIsFiller)
                    [dayTile setHighlighted:[self dateIsWithinCurrentPeriod:currentDate]];
            }

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
                var tileFrame = CGRectMake((dayIndex * tileSize.width) + dayIndex, weekIndex * tileSize.height, tileSize.width, tileSize.height -1);

                [tiles[tileIndex] setFrame:tileFrame];
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
    return [self convertPoint:[anEvent locationInWindow] fromView:nil]
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

        // Double clicked a date in the current month.
        if (tileMonth == date.getMonth() && [[CPApp currentEvent] clickCount] === 2 && [calendarView doubleAction])
            [CPApp sendAction:[calendarView doubleAction] to:[calendarView target] from:calendarView];

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
    // Avoid having the manipulation below affect the original instance.
    aStartDate = [aStartDate copy];
    anEndDate = [anEndDate copy];

    if (!allowsMultipleSelection || anEndDate === nil)
        anEndDate = aStartDate;

    if (selectionLengthType === LPCalendarWeekLength)
    {
        var startAndEnd = [self startAndEndOfWeekForDate:aStartDate];

        aStartDate = startAndEnd[0];
        anEndDate = startAndEnd[1];
    }

    // Replace hours / minutes / seconds
    var _dates = [aStartDate, anEndDate];
    for (var i = 0; i < 2; i++)
    {
        if (_dates[i])
            [_dates[i] resetToMidnight];
    }

    // Swap the dates if startDate is bigger than endDate
    if (aStartDate > anEndDate)
    {
        // Make a copy of startDate
        var _aStartDateCopy = aStartDate;

        aStartDate = anEndDate;
        anEndDate = _aStartDateCopy;
    }

    // Reset selection data
    [selection removeAllObjects];

    var tiles = [self subviews],
        tilesCount = [tiles count];

    for (var i = 0; i < tilesCount; i++)
    {
        var tile = tiles[i],
            tileDate = [tile date];

        [tileDate resetToMidnight];

        if (aStartDate && tileDate >= aStartDate && tileDate <= anEndDate)
        {
            [selection addObject:[[tile date] copy]];
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

    CGContextSetFillColor(context, [calendarView currentValueForThemeAttribute:@"grid-color"]);

    // Horizontal lines
    for (var i = 1; i < 6; i++)
        CGContextFillRect(context, CGRectMake(0, i * tileSize.height - 1, width, 1));

    // Vertical lines
    for (var i = 0; i < 7; i++)
        CGContextFillRect(context, CGRectMake((i - 1) + (i * tileSize.width), 0, 1, height));
}

@end


@implementation LPCalendarDayView : CPControl
{
    CPDate date @accessors;
    CPTextField textField;
    BOOL isFillerTile @accessors;
    BOOL isSelected @accessors(setter=setSelected:);
    BOOL isHighlighted @accessors(setter=setHighlighted:);

    LPCalendarView calendarView @accessors;
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

+ (id)dayViewWithCalendarView:(LPCalendarView)aCalendarView
{
    var dayView = [[self alloc] initWithFrame:CGRectMakeZero()];
    [dayView setCalendarView:aCalendarView];
    return dayView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];
        date = [CPDate date];

        textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [textField setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];

        //[self setIsFillerTile:NO];
        [self addSubview:textField];
    }
    return self;
}

- (void)setSelected:(BOOL)shouldBeSelected
{
    if (isSelected === shouldBeSelected)
        return;

    isSelected = shouldBeSelected;

    if (shouldBeSelected)
        [self setThemeState:CPThemeStateSelected];
    else
        [self unsetThemeState:CPThemeStateSelected];
}

- (void)setIsFillerTile:(BOOL)shouldBeFillerTile
{
    if (isFillerTile === shouldBeFillerTile)
        return;

    isFillerTile = shouldBeFillerTile;

    if (isFillerTile)
        [self setThemeState:CPThemeStateDisabled];
    else
        [self unsetThemeState:CPThemeStateDisabled];
}

- (void)setHighlighted:(BOOL)shouldBeHighlighted
{
    if (isHighlighted === shouldBeHighlighted)
        return;

    isHighlighted = shouldBeHighlighted;

    if (shouldBeHighlighted)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];
}

- (void)setDate:(CPDate)aDate
{
    if (date.getTime() === aDate.getTime())
        return;
    
    // Update date
    date.setTime(aDate.getTime());

    // Update & Position the new label
    [textField setStringValue:[date.getDate() stringValue]];
    [textField sizeToFit];

    var bounds = [self bounds];
    [textField setCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
}

- (void)layoutSubviews
{
    var themeState = [self themeState];
    
    [self setBackgroundColor:[calendarView valueForThemeAttribute:@"tile-bezel-color" inState:themeState]]

    [textField setFont:[calendarView valueForThemeAttribute:@"tile-font" inState:themeState]];
    [textField setTextColor:[calendarView valueForThemeAttribute:@"tile-text-color" inState:themeState]];
    [textField setTextShadowColor:[calendarView valueForThemeAttribute:@"tile-text-shadow-color" inState:themeState]];
    [textField setTextShadowOffset:[calendarView valueForThemeAttribute:@"tile-text-shadow-offset" inState:themeState]];
}

@end