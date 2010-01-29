/*
 * LPViewAnimation.j
 * LPKit
 *
 * Created by Ludwig Pettersson on August 23, 2009.
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
@import <AppKit/CPAnimation.j>

LPViewAnimationUpdateXMask = 1;
LPViewAnimationUpdateYMask = 2;
 


@implementation LPViewAnimation : CPAnimation
{
    CPArray views;
    CPArray properties;
    id kindMask @accessors;
}

- (id)initWithDuration:(float)aDuration animationCurve:(id)anAnimationCurve
{
    if (self = [super initWithDuration:aDuration animationCurve:anAnimationCurve])
    {   
        views = [CPArray array];
        properties = [CPArray array];
        kindMask = LPViewAnimationUpdateXMask | LPViewAnimationUpdateYMask;
    }
    return self;
}

- (void)addView:(id)aView start:(CGRect)aStart end:(CGRect)anEnd
{
    if (!aStart)
        aStart = [aView frame];
    
    [views addObject:aView];
    [properties addObject:{'start': aStart, 'end': anEnd}];
}

- (void)setCurrentProgress:(float)progress
{
    [super setCurrentProgress:progress];
    
    // Get the progress with respect to the animationCurve
    progress = [self currentValue];
 
    for (var i = 0; i < views.length; i++)
    {   
        var property = properties[i],
            start = property['start'],
            end = property['end'];
        
        
        [self setFrame:CGRectMake((progress * (end.origin.x - start.origin.x)) + start.origin.x, (progress * (end.origin.y - start.origin.y)) + start.origin.y,
                                  (progress * (end.size.width - start.size.width)) + start.size.width, (progress * (end.size.height - start.size.height)) + start.size.height)
               forView:views[i]];
    }
}

- (void)setFrame:(CGRect)aFrame forView:(id)aView
{
    if (!(kindMask & LPViewAnimationUpdateXMask))
    {
        aFrame.origin.x = aView._frame.origin.x;
        aFrame.size.width = aView._frame.size.width;
    }
    
    if (!(kindMask & LPViewAnimationUpdateYMask))
    {
        aFrame.origin.y = aView._frame.origin.y;
        aFrame.size.height = aView._frame.size.height;
    }
    
    [aView setFrame:aFrame];
}

- (void)startAnimation
{
    for (var i = 0; i < views.length; i++)
        [self setFrame:properties[i]['start'] forView:views[i]];
    
    [super startAnimation];
}

@end