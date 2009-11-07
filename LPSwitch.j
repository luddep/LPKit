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
@import <LPKit/LPSlideView.j>


@implementation LPSwitch : CPControl
{
    BOOL on @accessors(readonly, getter=isOn);
    
    CGPoint dragStartPoint;
    
    LPSwitchKnob knob;
    CGPoint knobDragStartPoint;
    
    BOOL isDragging;
    
    float animationDuration;
    id animationCurve;
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:CGRectMakeZero()])
    {
        [self setFrameOrigin:CGPointMake(CGRectGetMinX(aFrame), CGRectGetMinY(aFrame))];
        [self setFrameSize:CGSizeMake(50,20)];
        [self setBackgroundColor:[CPColor greenColor]];
        
        knob = [[LPSwitchKnob alloc] initWithFrame:CGRectMake(0,0,20,20)];
        [self addSubview:knob];
        
        animationDuration = 0.2;
        animationCurve = CPAnimationEaseOut;
    }
    return self;
}

- (void)setOn:(BOOL)shouldSetOn animated:(BOOL)shouldAnimate
{
    on = shouldSetOn;
    
    // Send action
    [self sendAction:_action to:_target];
    
    var knobMinY = CGRectGetMinY([knob frame]),
        knobEndOrigin = CGPointMake((on) ? [knob maxX] : [knob minX], knobMinY) 
    
    if (shouldAnimate)
    {
        var animation = [[LPSlideViewAnimation alloc] initWithDuration:animationDuration animationCurve:animationCurve];
        [animation addView:knob start:[knob frame].origin end:knobEndOrigin];
        [animation setDelegate:self];
        [animation startAnimation];
    }
    else
        [knob setFrameOrigin:knobEndOrigin];
}

- (void)mouseDown:(CPEvent)anEvent
{
    dragStartPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    knobDragStartPoint = [knob frame].origin;
    
    isDragging = NO;
}

- (void)mouseDragged:(CPEvent)anEvent
{
    // We are dragging
    isDragging = YES;
    
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        knobX = knobDragStartPoint.x + (point.x - dragStartPoint.x),
        knobMinX = [knob minX],
        knobMaxX = [knob maxX];
    
    // Limit X
    if (knobX < knobMinX)
        knobX = knobMinX;
    else if(knobX > knobMaxX)
        knobX = knobMaxX;
    
    // Re-position knob
    [knob setFrameOrigin:CGPointMake(knobX, CGRectGetMinY([knob frame]))];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [self setOn:(isDragging) ? CGRectGetMidX([self bounds]) < CGRectGetMidX([knob frame]) : !on animated:YES];
}

@end

@implementation LPSwitchKnob : CPView
{
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setHitTests:NO];
        [self setBackgroundColor:[CPColor colorWithWhite:0 alpha:0.3]];
    }
    return self;
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