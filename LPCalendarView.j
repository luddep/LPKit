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
    LPCalendarHeaderView headerView @accessors(readonly);
    LPSlideView          slideView;
    
    LPCalendarMonthView  currentMonthView;
    LPCalendarMonthView  firstMonthView;
    LPCalendarMonthView  secondMonthView;

    CPArray              fullSelection @accessors(readonly);
    id                   _delegate @accessors(property=delegate);

    id                  _target @accessors(property=target);
    SEL                 _doubleAction @accessors(property=doubleAction);
}

+ (CPString)themeClass
{
    return @"lp-calendar-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], CGSizeMake(0,0), [CPNull null], [CPNull null], 40, [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], 30, [CPNull null], [CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:[@"background-color", @"grid-color",
                                                @"tile-size", @"tile-font", @"tile-text-color", @"tile-text-shadow-color", @"tile-text-shadow-offset", @"tile-bezel-color",
                                                @"header-button-offset", @"header-prev-button-image", @"header-next-button-image", @"header-height", @"header-background-color", @"header-font", @"header-text-color", @"header-text-shadow-color", @"header-text-shadow-offset", @"header-alignment",
                                                @"header-weekday-offset", @"header-weekday-label-font", @"header-weekday-label-color", @"header-weekday-label-shadow-color", @"header-weekday-label-shadow-offset"]];

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
        [self addSubview:headerView];

        slideView = [[LPSlideView alloc] initWithFrame:CGRectMake(0, 40, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - 40)];
        [slideView setSlideDirection:LPSlideViewVerticalDirection];
        //[slideView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable | CPViewMinYMargin];
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

- (void)selectDate:(CPDate)aDate
{
    [self setMonth:aDate];
    [self makeSelectionWithDate:aDate end:aDate];
}

- (void)setMonth:(CPDate)aMonth
{
    [currentMonthView setDate:aMonth]
    [headerView setDate:aMonth];
}

- (id)monthViewForMonth:(CPDate)aMonth
{
    var availableMonthView = [firstMonthView isHidden] ? firstMonthView : secondMonthView;
    [availableMonthView setHiddenRows:[]];
    [availableMonthView setDate:aMonth];
    [availableMonthView makeSelectionWithDate:fullSelection[0] end:[fullSelection lastObject]];

    return availableMonthView;
}

- (void)changeToMonth:(CPDate)aMonth
{
    // Get the month view to slide to
    var slideToView = [self monthViewForMonth:aMonth],
        slideFromView = currentMonthView;

    // Moving to a previous month
    if ([currentMonthView date].getTime() > aMonth.getTime())
    {
        var direction = LPSlideViewPositiveDirection,
            startDelta = 0.335,
            hiddenRows = [0,1];
    }
    // Moving to a later month
    else
    {
        var direction = LPSlideViewNegativeDirection,
            startDelta = 0.34,
            hiddenRows = [4,5];
    }

    // new current view
    currentMonthView = slideToView;
    
    // Display it way off,
    // because cappuccino wont draw
    // CGGraphics stuff unless it's visible
    // due to a recent change.
    [currentMonthView setFrameOrigin:CGPointMake(-500,-500)];
    [currentMonthView setHidden:NO];
    [currentMonthView setNeedsDisplay:YES];

    [headerView setDate:aMonth];

    setTimeout(function(){
        [slideFromView setHiddenRows:hiddenRows];
        [slideView slideToView:slideToView direction:direction animationProgress:startDelta];
    }, 10);
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
    var width = CGRectGetWidth([self bounds]),
        headerHeight = [self currentValueForThemeAttribute:@"header-height"];
        
    [headerView setFrameSize:CGSizeMake(width, headerHeight)];
    [slideView setFrame:CGRectMake(0, headerHeight, width, CGRectGetHeight([self bounds]) - headerHeight)];
    
    [slideView setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];
}

- (void)didClickPrevButton:(id)sender
{
    // We can only slide one month in at a time.
    if ([slideView isSliding])
        return;
    
    [self changeToMonth:[currentMonthView previousMonth]];
}

- (void)didClickNextButton:(id)sender
{
    // We can only slide one month in at a time.
    if ([slideView isSliding])
        return;
    
    [self changeToMonth:[currentMonthView nextMonth]];
}

- (void)makeSelectionWithDate:(CPDate)aStartDate end:(CPDate)anEndDate
{
    [currentMonthView makeSelectionWithDate:aStartDate end:anEndDate];
}

- (void)didMakeSelection:(CPArray)aSelection
{
    // Make sure we have an end to the selection
    if ([aSelection count] <= 1)
        [aSelection addObject:nil];
    
    // The selection didn't change
    if ([fullSelection isEqualToArray:aSelection])
        return;
    
    // Copy the selection
    fullSelection = [CPArray arrayWithArray:aSelection];

    // Call the delegate
    if (_delegate && [_delegate respondsToSelector:@selector(calendarView:didMakeSelection:end:)])
        [_delegate calendarView:self didMakeSelection:[fullSelection objectAtIndex:0] end:[fullSelection lastObject]];
}

@end

