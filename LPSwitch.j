/*
 * LPSwitch.j
 * LPKit
 *
 * Created by Ludwig Pettersson on November 7, 2009.
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
@import <LPKit/LPViewAnimation.j>


@implementation LPSwitch : CPControl
{
    BOOL on @accessors(readonly, getter=isOn);
    
    CGPoint dragStartPoint;
    
    LPSwitchKnob knob;
    CGPoint knobDragStartPoint;
    
    BOOL isDragging;
    
    float animationDuration;
    id animationCurve;
    
    CPView offBackgroundView;
    CPView onBackgroundView;
    
    CPTextField offLabel;
    CPTextField onLabel;
	
	LPViewAnimation animation;
}

+ (CPString)themeClass
{
    return @"lp-switch";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:[@"off-background-color", @"on-background-color", @"knob-background-color", @"knob-size", @"label-offset",
                                                @"off-label-font", @"off-label-text-color", @"off-label-text-shadow-color", @"off-label-text-shadow-offset",
                                                @"on-label-font", @"on-label-text-color", @"on-label-text-shadow-color", @"on-label-text-shadow-offset"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {   
        offBackgroundView = [[CPView alloc] initWithFrame:[self bounds]];
        [offBackgroundView setHitTests:NO];
        [self addSubview:offBackgroundView];
        
        onBackgroundView = [[CPView alloc] initWithFrame:CGRectMake(0,0,0,CGRectGetHeight([self bounds]))];
        [onBackgroundView setHitTests:NO];
        [self addSubview:onBackgroundView];
        
        knob = [[LPSwitchKnob alloc] initWithFrame:CGRectMakeZero()];
        [self addSubview:knob];
        
        offLabel = [CPTextField labelWithTitle:@"Off"];
        [self addSubview:offLabel];
        
        onLabel = [CPTextField labelWithTitle:@"On"];
        [self addSubview:onLabel];
        
        animationDuration = 0.2;
        animationCurve = CPAnimationEaseOut;
        
        // Need to call layoutSubviews directly to make sure
        // all theme attributes are set.
        // TODO: FIX THIS.
        [self layoutSubviews];
        
        [self setNeedsLayout];
    }
    return self;
}

- (void)setOn:(BOOL)shouldSetOn animated:(BOOL)shouldAnimate
{
   [self setOn:shouldSetOn animated:shouldAnimate sendAction:YES];
}

- (void)setOn:(BOOL)shouldSetOn animated:(BOOL)shouldAnimate sendAction:(BOOL)shouldSendAction
{
    // changed to stop the action firing if the user moved the switch to the inverse state, but then back to original state before releasing the mouse button
    if (shouldSendAction && on !== shouldSetOn)
    {
		on = shouldSetOn;
        [self sendAction:_action to:_target];
	}
	else
		on = shouldSetOn;
    
    var knobMinY = CGRectGetMinY([knob frame]),
        knobEndFrame = CGRectMake((on) ? [knob maxX] : [knob minX], knobMinY, CGRectGetWidth([knob frame]), CGRectGetHeight([knob frame])),
        onBackgroundEndFrame = CGRectMake(0,0, CGRectGetMinX(knobEndFrame) + CGRectGetMidX([knob bounds]), CGRectGetHeight([onBackgroundView bounds])),
        labelOffset = [self labelOffset],
        offLabelEndFrame = CGRectMake(CGRectGetMaxX(knobEndFrame) + labelOffset.width, labelOffset.height,
                                      CGRectGetWidth([offLabel bounds]), CGRectGetHeight([offLabel bounds])),
        onLabelEndFrame = CGRectMake(CGRectGetMinX(knobEndFrame) - labelOffset.width - CGRectGetWidth([onLabel bounds]), labelOffset.height,
                                     CGRectGetWidth([onLabel bounds]), CGRectGetHeight([onLabel bounds]));
	
	// added to counter a problem whereby changing the state more than once (i.e., ON -> OFF -> ON) before giving control to the run loop,
	// caused the control to not update properly
	if([animation isAnimating])
		[animation stopAnimation];
    
    if (shouldAnimate)
    {
        animation = [[LPViewAnimation alloc] initWithViewAnimations:[
                {
                    @"target": knob,
                    @"animations": [
                        [LPOriginAnimationKey, [knob frame].origin, knobEndFrame.origin]
                    ]
                },
                {
                    @"target": onBackgroundView,
                    @"animations": [
                        [LPFrameAnimationKey, [onBackgroundView frame], onBackgroundEndFrame]
                    ]
                },
                {
                    @"target": offLabel,
                    @"animations": [
                        [LPOriginAnimationKey, [offLabel frame].origin, offLabelEndFrame.origin]
                    ]
                },
                {
                    @"target": onLabel,
                    @"animations": [
                        [LPOriginAnimationKey, [onLabel frame].origin, onLabelEndFrame.origin]
                    ]
                }
            ]];
        [animation setAnimationCurve:animationCurve];
        [animation setDuration:animationDuration];
        [animation setDelegate:self];
        [animation startAnimation];
    }
    else
    {
        [knob setFrame:knobEndFrame];
        [onBackgroundView setFrame:onBackgroundEndFrame];
        [offLabel setFrame:offLabelEndFrame];
    }
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    dragStartPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    knobDragStartPoint = [knob frame].origin;
    
    isDragging = NO;
    
    // If the drag started on top of the knob, we highlight it
    var startPointX = [knob convertPoint:dragStartPoint fromView:self].x;
    if (startPointX > 0 && startPointX < CGRectGetWidth([knob bounds]))
    {
        [knob setHighlighted:YES];
        [self setNeedsLayout];
    } 
}

- (void)mouseDragged:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    // We are dragging
    isDragging = YES;
    
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        knobX = knobDragStartPoint.x + (point.x - dragStartPoint.x),
        knobMinX = [knob minX],
        knobMaxX = [knob maxX],
        height = CGRectGetHeight([self bounds]);
    
    // Limit X
    if (knobX < knobMinX)
        knobX = knobMinX;
    else if(knobX > knobMaxX)
        knobX = knobMaxX;
        
    // Resize background views
    [onBackgroundView setFrameSize:CGSizeMake(knobX + CGRectGetMidX([knob bounds]), height)];
    
    // Re-position knob
    [knob setFrameOrigin:CGPointMake(knobX, CGRectGetMinY([knob frame]))];
    
    [self setNeedsLayout];
}

- (void)mouseUp:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [self setOn:isDragging ? CGRectGetMidX([self bounds]) < CGRectGetMidX([knob frame]) : !on animated:YES];
    
    [knob setHighlighted:NO];
    [self setNeedsLayout];
}

- (CGSize)labelOffset
{
    // Provide a default size so that we can use switches even without themes.
    var labelOffset = [self currentValueForThemeAttribute:@"label-offset"];
    return (labelOffset) ? labelOffset : CGSizeMake(0,0);
}

- (void)layoutSubviews
{
    [offBackgroundView setBackgroundColor:[self currentValueForThemeAttribute:@"off-background-color"]];
    [onBackgroundView setBackgroundColor:[self currentValueForThemeAttribute:@"on-background-color"]];
    [knob setBackgroundColor:[self valueForThemeAttribute:@"knob-background-color" inState:[knob themeState]]];
    [knob setFrameSize:[self currentValueForThemeAttribute:@"knob-size"]];
    
    var labelOffset = [self labelOffset];
    
    [offLabel setFont:[self currentValueForThemeAttribute:@"off-label-font"]];
    [offLabel setTextColor:[self currentValueForThemeAttribute:@"off-label-text-color"]];
    [offLabel setTextShadowColor:[self currentValueForThemeAttribute:@"off-label-text-shadow-color"]];
    [offLabel setTextShadowOffset:[self currentValueForThemeAttribute:@"off-label-text-shadow-offset"]];
    [offLabel setFrameOrigin:CGPointMake(CGRectGetMaxX([knob frame]) + labelOffset.width, labelOffset.height)];
    [offLabel sizeToFit];
    
    [onLabel setFont:[self currentValueForThemeAttribute:@"on-label-font"]];
    [onLabel setTextColor:[self currentValueForThemeAttribute:@"on-label-text-color"]];
    [onLabel setTextShadowColor:[self currentValueForThemeAttribute:@"on-label-text-shadow-color"]];
    [onLabel setTextShadowOffset:[self currentValueForThemeAttribute:@"on-label-text-shadow-offset"]];
    [onLabel sizeToFit];
    
    [onLabel setFrameOrigin:CGPointMake(CGRectGetMinX([knob frame]) - labelOffset.width - CGRectGetWidth([onLabel bounds]), CGRectGetMinY([offLabel frame]))];
}

@end


@implementation LPSwitchKnob : CPView
{
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];
        //[self setBackgroundColor:[CPColor colorWithHexString:@"333"]];
    }
    return self;
}

- (void)setHighlighted:(BOOL)shouldBeHighlighted
{
    isHighlighted = shouldBeHighlighted;

    if (shouldBeHighlighted)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];
}

- (unsigned int)minX
{
    return 0;
}

- (unsigned int)maxX
{
    return CGRectGetWidth([[self superview] bounds]) - CGRectGetWidth([self bounds]);
}

@end