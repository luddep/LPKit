/*
 * AppController.j
 * LPKit
 *
 * Created by Ludwig Pettersson on October 12, 2009.
 * Copyright 2009, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <LPKit/LPSlideView.j>
@import <LPKit/LPCalendarView.j>
@import <LPKit/LPSparkLine.j>

@implementation AppController : CPObject
{
    LPSlideView slideView;
    CPTextField calendarSelectionLabel;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    /*
    
        LPSlideView
    
    */

    var slideViewLabel = [CPTextField labelWithTitle:@"LPSlideView"];
    [slideViewLabel setFrameOrigin:CGPointMake(100, 70)];
    [contentView addSubview:slideViewLabel];

    slideView = [[LPSlideView alloc] initWithFrame:CGRectMake(100,100,200,100)];
    //[slideView setSlideDirection:LPSlideViewVerticalDirection];
    [contentView addSubview:slideView];
    
    var greenView = [[CPView alloc] initWithFrame:[slideView bounds]];
    [greenView setBackgroundColor:[CPColor colorWithHexString:@"c2e890"]];
    [slideView addSubview:greenView];
    
    var blueView = [[CPView alloc] initWithFrame:[slideView bounds]];
    [blueView setBackgroundColor:[CPColor colorWithHexString:@"90c8e8"]];
    [slideView addSubview:blueView];
    
    var redView = [[CPView alloc] initWithFrame:[slideView bounds]];
    [redView setBackgroundColor:[CPColor colorWithHexString:@"e89090"]];
    [slideView addSubview:redView];
    
    var segmentedControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(CGRectGetMinX([slideView frame]), CGRectGetMaxY([slideView frame]) + 5, 124, 24)];
    [segmentedControl setSegmentCount:3];
    [segmentedControl setLabel:@"First" forSegment:0];
    [segmentedControl setTag:0 forSegment:0];
    [segmentedControl setLabel:@"Second" forSegment:1];
    [segmentedControl setTag:1 forSegment:1];
    [segmentedControl setLabel:@"Third" forSegment:2];
    [segmentedControl setTag:2 forSegment:2];
    [segmentedControl setTarget:self];
    [segmentedControl setAction:@selector(didClickSegmented:)];
    [segmentedControl setSelectedSegment:0];
    
    [contentView addSubview:segmentedControl];

    /*
    
        LPCalendarView
    
    */

    var slideViewLabel = [CPTextField labelWithTitle:@"LPCalendarView"];
    [slideViewLabel setFrameOrigin:CGPointMake(400, 70)];
    [contentView addSubview:slideViewLabel];

    var calendarView = [[LPCalendarView alloc] initWithFrame:CGRectMake(400, 100, 180, 160)];
    [calendarView setMonth:[CPDate date]];
    [calendarView setDelegate:self];
    [contentView addSubview:calendarView];
    
    calendarSelectionLabel = [CPTextField labelWithTitle:@""];
    [calendarSelectionLabel setFrameOrigin:CGPointMake(400,270)]
    [contentView addSubview:calendarSelectionLabel];

    /*
    
        LPCalendarView
    
    */

    var slideViewLabel = [CPTextField labelWithTitle:@"LPSparkLine"];
    [slideViewLabel setFrameOrigin:CGPointMake(680, 70)];
    [contentView addSubview:slideViewLabel];
    
    var sparkLine = [[LPSparkLine alloc] initWithFrame:CGRectMake(680, 100, 100, 30)];
    [sparkLine setLineWeight:2.0];
    [sparkLine setLineColor:[CPColor colorWithHexString:@"aad8ff"]];
    [sparkLine setShadowColor:[CPColor colorWithHexString:@"999"]];
    [sparkLine setData:[10,25,30,42,10,30,22,70,30,21,44,21,77,55,88,54]];
    [contentView addSubview:sparkLine];

    /*
        --
    */
    
    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)didClickSegmented:(id)sender
{
    var index = [sender tagForSegment:[sender selectedSegment]];
    
    [slideView slideToView:[[slideView subviews] objectAtIndex:index]];
}

-(void)calendarView:(LPCalendarView)aCalendarView didMakeSelection:(CPDate)aStartDate end:(CPDate)anEndDate
{
    [calendarSelectionLabel setStringValue:[CPString stringWithFormat:@"Selected: %s", aStartDate]];
    [calendarSelectionLabel sizeToFit];
}

@end
