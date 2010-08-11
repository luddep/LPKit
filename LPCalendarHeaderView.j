/*
 * LPCalendarHeaderView.j
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
@import <AppKit/CPButton.j>
@import <AppKit/CPControl.j>

var LPMonthNames = [@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"],
    LPDayNamesShort = [@"mon", @"tue", @"wed", @"thu", @"fri", @"sat", @"sun"],
    LPDayNamesShortUS = [@"sun", @"mon", @"tue", @"wed", @"thu", @"fri", @"sat"];


@implementation LPCalendarHeaderView : CPControl
{
    CPDate      representedDate;
    
    CPTextField monthLabel;
    id          prevButton @accessors(readonly);
    id          nextButton @accessors(readonly);
    CPArray     dayLabels;
    
    BOOL        weekStartsOnMonday @accessors;
}

+ (CPString)themeClass
{
    return @"lp-calendar-header-view";
}

- (id)initWithFrame:(CGRect)aFrame
{
    if(self = [super initWithFrame:aFrame])
    {
        monthLabel = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [monthLabel setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
        [self addSubview:monthLabel];
        
        prevButton = [[LPCalendarHeaderArrowButton alloc] initWithFrame:CGRectMake(6, 9, 0, 0)];
        [prevButton sizeToFit];
        [self addSubview:prevButton];
        
        nextButton = [[LPCalendarHeaderArrowButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX([self bounds]) - 21, 9, 0, 0)];
        [nextButton sizeToFit];
        [nextButton setAutoresizingMask:CPViewMinXMargin];
        [self addSubview:nextButton];
        
        dayLabels = [CPArray array];
        
        for (var i = 0; i < [LPDayNamesShort count]; i++)
        {
            var label = [LPCalendarLabel labelWithTitle:[LPDayNamesShort objectAtIndex:i]];
            [dayLabels addObject:label];
            [self addSubview:label];
        }
        
        [self setBackgroundColor:[CPColor lightGrayColor]];
    }
    return self;
}

- (void)setDate:(CPDate)aDate
{
    if ([representedDate isEqualToDate:aDate])
        return;
    
    representedDate = [aDate copy];
    
    [monthLabel setStringValue:[CPString stringWithFormat:@"%s %i", LPMonthNames[representedDate.getUTCMonth()], representedDate.getUTCFullYear()]];
    [monthLabel sizeToFit];
    [monthLabel setCenter:CGPointMake(CGRectGetMidX([self bounds]), 16)];
}

- (void)setWeekStartsOnMonday:(BOOL)shouldWeekStartOnMonday
{
    weekStartsOnMonday = shouldWeekStartOnMonday;
    
    var dayNames = (shouldWeekStartOnMonday) ? LPDayNamesShort : LPDayNamesShortUS;
    
    for (var i = 0; i < [dayLabels count]; i++)
        [[dayLabels objectAtIndex:i] setTitle:[dayNames objectAtIndex:i]];

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        superview = [self superview],
        themeState = [self themeState];
    
    // Title
    [self setBackgroundColor:[superview valueForThemeAttribute:@"header-background-color" inState:themeState]];
    [monthLabel setFont:[superview valueForThemeAttribute:@"header-font" inState:themeState]];
    [monthLabel setTextColor:[superview valueForThemeAttribute:@"header-text-color" inState:themeState]];
    [monthLabel setTextShadowColor:[superview valueForThemeAttribute:@"header-text-shadow-color" inState:themeState]];
    [monthLabel setTextShadowOffset:[superview valueForThemeAttribute:@"header-text-shadow-offset" inState:themeState]];
    
    // Arrows
    var buttonOrigin = [superview valueForThemeAttribute:@"header-button-offset" inState:themeState];
    [prevButton setFrameOrigin:CGPointMake(buttonOrigin.width, buttonOrigin.height)];
    [prevButton setValue:[superview valueForThemeAttribute:@"header-prev-button-image" inState:themeState] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [nextButton setFrameOrigin:CGPointMake(width - 16 - buttonOrigin.width, buttonOrigin.height)];
    [nextButton setValue:[superview valueForThemeAttribute:@"header-next-button-image" inState:themeState] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    
    // Weekday labels
    var numberOfLabels = [dayLabels count],
        labelWidth = width / numberOfLabels,
        labelHeight = CGRectGetHeight([[[self subviews] objectAtIndex:3] bounds]),
        labelOffset = [superview valueForThemeAttribute:@"header-weekday-offset" inState:themeState],
        height = CGRectGetHeight(bounds);

    for (var i = 0; i < numberOfLabels; i++)
        [dayLabels[i] setFrame:CGRectMake(i * labelWidth, labelOffset, labelWidth, labelHeight)];
}

@end

@implementation LPCalendarLabel : CPTextField
{
}

+ labelWithTitle:(CPString)aTitle
{
    var label = [[LPCalendarLabel alloc] initWithFrame:CGRectMakeZero()];
    [label setTitle:aTitle];
    return label;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
    }
    return self;
}

- (void)setTitle:(CPString)aTitle
{
    [self setStringValue:aTitle];
    [self sizeToFit];
}

- (void)didMoveToSuperview
{
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    var calendarView = [[self superview] superview],
        themeState = [self themeState];
    
    [self setFont:[calendarView valueForThemeAttribute:@"header-weekday-label-font" inState:themeState]];
    [self setTextColor:[calendarView valueForThemeAttribute:@"header-weekday-label-color" inState:themeState]];
    [self setTextShadowColor:[calendarView valueForThemeAttribute:@"header-weekday-label-shadow-color" inState:themeState]];
    [self setTextShadowOffset:[calendarView valueForThemeAttribute:@"header-weekday-label-shadow-offset" inState:themeState]];
    
    [super layoutSubviews];
}

@end


@implementation LPCalendarHeaderArrowButton : CPButton 
{
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setValue:CGSizeMake(16.0, 16.0) forThemeAttribute:@"min-size"];
        [self setValue:CGSizeMake(16.0, 16.0) forThemeAttribute:@"max-size"];
    }
    return self;
}

/*
    TODO: move this into theming some how.
*/

- (void)incrementOriginBy:(int)anInt
{
    var currentOrigin = [self frame].origin;
    currentOrigin.y += anInt;
    [self setFrameOrigin:currentOrigin];
}

- (void)trackMouse:(CPEvent)anEvent
{
    var type = [anEvent type];
 
    if (type === CPLeftMouseDown)
        [self incrementOriginBy:1]
    else if (type === CPLeftMouseUp)
        [self incrementOriginBy:-1]
    
    [super trackMouse:anEvent];
}

@end