/*
 * LPCalendarView.j
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
@import <LPKit/LPCalendarHeaderView.j>
@import <LPKit/LPCalendarMonthView.j>
@import <LPKit/LPSlideView.j>


@implementation LPCalendarView : CPView
{
    id headerView @accessors(readonly);
    id slideView;
    id currentMonthView;
    
    id firstMonthView;
    id secondMonthView;
    
    CPArray fullSelection @accessors(readonly);
    id _delegate @accessors(property=delegate);
}

+ (CPString)themeClass
{
    return @"lp-calendar-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
                                       forKeys:[@"background-color", @"grid-color",
                                                @"tile-font", @"tile-text-color", @"tile-text-shadow-color", @"tile-text-shadow-offset", @"tile-bezel-color",
                                                @"header-background-color", @"header-font", @"header-text-color", @"header-text-shadow-color", @"header-text-shadow-offset", @"header-alignment"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        fullSelection = [nil, nil];
        
        var bounds = [self bounds];
        
        headerView = [[LPCalendarHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), 40)];
        [[headerView prevButton] setTarget:self];
        [[headerView prevButton] setAction:@selector(didClickPrevButton:)];
        [[headerView nextButton] setTarget:self];
        [[headerView nextButton] setAction:@selector(didClickNextButton:)];
        [headerView setAutoresizingMask:CPViewWidthSizable];
        [self addSubview:headerView];
        
        slideView = [[LPSlideView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([headerView bounds]), CGRectGetWidth(bounds), CGRectGetHeight(bounds) - CGRectGetHeight([headerView bounds]))];
        [slideView setSlideDirection:LPSlideViewVerticalDirection];
        [slideView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinYMargin];
        [slideView setDelegate:self];
        [slideView setAnimationCurve:CPAnimationEaseOut];
        [slideView setAnimationDuration:0.2];
        [self addSubview:slideView];
        
        firstMonthView = [[LPCalendarMonthView alloc] initWithFrame:[slideView bounds] calendarView:self];
        [firstMonthView setDelegate:self];
        [slideView addSubview:firstMonthView];

        secondMonthView = [[LPCalendarMonthView alloc] initWithFrame:[slideView bounds] calendarView:self];
        [secondMonthView setDelegate:self];
        [slideView addSubview:secondMonthView];

        currentMonthView = firstMonthView;        

        // Default to today's date.
        [self setMonth:[CPDate date]];
                
        [self setNeedsLayout];
    }
    return self;
}

- (void)setMonth:(CPDate)aMonth
{
    [currentMonthView setDate:aMonth]
    [headerView setDate:aMonth];
}

- (void)availableMonthView
{
    return ([firstMonthView isHidden]) ? firstMonthView : secondMonthView;
}

- (id)monthViewForMonth:(CPDate)aMonth
{
    var availableMonthView = [self availableMonthView];
    [availableMonthView setDate:aMonth];
    [availableMonthView makeSelectionWithDate:[fullSelection objectAtIndex:0] end:[fullSelection lastObject]];

    return availableMonthView;
}

- (void)changeToMonth:(CPDate)aMonth
{   
    // Get the month view to slide to
    var slideToView = [self monthViewForMonth:aMonth],
        slideFromView = currentMonthView;
    
    var direction,
        startDelta;
    
    // Moving to a previous month
    if ([currentMonthView date].getTime() > aMonth.getTime())
    {
        direction = LPSlideViewPositiveDirection;
        startDelta = 0.335;
        [slideFromView setHiddenRows:[0,1]];
    }
    // Moving to a later month
    else
    {
        direction = LPSlideViewNegativeDirection;
        startDelta = 0.34;
        [slideFromView setHiddenRows:[4,5]];
    }
    
    // Set the previous months tiles as fillers, to make it look a bit better.
    [slideFromView setAllTilesAsFiller];
    
    // new current view
    currentMonthView = slideToView;
    
    [headerView setDate:aMonth];
    
    setTimeout(function(){
        [slideView slideToView:slideToView direction:direction animationProgress:startDelta];
    }, 1);
}

- (void)setAllowsMultipleSelection:(BOOL)shouldAllowMultipleSelection
{
    [firstMonthView setAllowsMultipleSelection:shouldAllowMultipleSelection];
    [secondMonthView setAllowsMultipleSelection:shouldAllowMultipleSelection];
}

- (void)setHighlightCurrentPeriod:(BOOL)shouldHighlightCurrentPeriod
{
    [firstMonthView setHighlightCurrentPeriod:shouldHighlightCurrentPeriod];
    [secondMonthView setHighlightCurrentPeriod:shouldHighlightCurrentPeriod];
}

- (void)setSelectionLengthType:(id)aSelectionType
{
    [firstMonthView setSelectionLengthType:aSelectionType];
    [secondMonthView setSelectionLengthType:aSelectionType];
}

- (void)setWeekStartsOnMonday:(BOOL)shouldWeekStartOnMonday
{
    [headerView setWeekStartsOnMonday:shouldWeekStartOnMonday]
    [firstMonthView setWeekStartsOnMonday:shouldWeekStartOnMonday];
    [secondMonthView setWeekStartsOnMonday:shouldWeekStartOnMonday];
}

- (void)layoutSubviews
{
    [slideView setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (void)didClickPrevButton:(id)sender
{
    [self changeToMonth:[currentMonthView previousMonth]];
}

- (void)didClickNextButton:(id)sender
{
    [self changeToMonth:[currentMonthView nextMonth]];
}

- (void)makeSelectionWithDate:(CPDate)aStartDate end:(CPDate)anEndDate
{
    [currentMonthView makeSelectionWithDate:aStartDate end:anEndDate];
}

- (void)didMakeSelection:(CPArray)aSelection
{
    fullSelection = [CPArray arrayWithArray:aSelection];
    
    if ([fullSelection count] <= 1)
        [fullSelection addObject:nil];

    // Keeps any delegate calls from locking up the UI
    setTimeout(function(){
        if ([_delegate respondsToSelector:@selector(calendarView:didMakeSelection:end:)])
            [_delegate calendarView:self didMakeSelection:[fullSelection objectAtIndex:0] end:[fullSelection lastObject]];
    }, 1);
}

@end

