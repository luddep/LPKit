/*
 * LPSlideView.j
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

@import <AppKit/CPView.j>
@import <LPKit/LPViewAnimation.j>

LPSlideViewHorizontalDirection = 0;
LPSlideViewVerticalDirection   = 1;
LPSlideViewPositiveDirection   = 2;
LPSlideViewNegativeDirection   = 4;


@implementation LPSlideView : CPView
{
    int slideDirection @accessors;
    id currentView @accessors;
    id previousView @accessors;
    
    float animationDuration @accessors;
    id animationCurve @accessors;
    BOOL isSliding @accessors(readonly);
    
    id _delegate @accessors(property=delegate);
}

- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        animationCurve = CPAnimationEaseOut;
        slideDirection = LPSlideViewHorizontalDirection;
        animationDuration = 0.2;
        isSliding = NO;
    }
    return self;
}

- (void)addSubview:(id)aView
{
    if (!currentView)
        currentView = aView;
    else
        [aView setHidden:YES];
    
    [aView setFrame:[self bounds]];
    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [super addSubview:aView];
}

- (void)slideToView:(id)aView
{
    [self slideToView:aView direction:nil animationProgress:nil]
}

- (void)slideToView:(id)aView direction:(id)aDirection
{
    [self slideToView:aView direction:aDirection animationProgress:nil]
}

- (void)slideToView:(id)aView direction:(id)aDirection animationProgress:(int)aProgress
{
    if (aView == currentView || isSliding)
        return;
    
    isSliding = YES;
    
    if(_delegate && [_delegate respondsToSelector:@selector(slideView:willMoveToView:)])
        [_delegate slideView:self willMoveToView:aView];
    
    var viewIndex = [[self subviews] indexOfObject:aView],
        currentViewIndex = [[self subviews] indexOfObject:currentView],
        size = [self frame].size;
    
    // Unhide the view
    [aView setHidden:NO];
    
    var showViewStart = CGPointMake(0,0),
        hideViewEnd = CGPointMake(0,0);
    
    // Horizontal sliding
    if (slideDirection == LPSlideViewHorizontalDirection)
    {
        var showSlideFromX,
            hideSlideToX;
        
        // Showing a view to the left
        if ((aDirection && aDirection == LPSlideViewNegativeDirection) || (!aDirection && viewIndex < currentViewIndex))
        {
            showSlideFromX = -size.width;
            hideSlideToX = size.width;
        }
        
        // Showing a view to the right
        if ((aDirection && aDirection == LPSlideViewPositiveDirection) || (!aDirection && viewIndex > currentViewIndex))
        {
            showSlideFromX = size.width;
            hideSlideToX = -size.width;
        }
        
        showViewStart.x = showSlideFromX;
        hideViewEnd.x = hideSlideToX;
    }

    // Vertical sliding
    else if (slideDirection == LPSlideViewVerticalDirection)
    {
        var showSlideFromY,
            hideSlideToY;
        
        // Showing a view from the top
        if ((aDirection && aDirection == LPSlideViewNegativeDirection) || (!aDirection && viewIndex > currentViewIndex))
        {
            showSlideFromY = size.height;
            hideSlideToY = -size.height;
        }
        
        // Showing a view from the bottom
        if ((aDirection && aDirection == LPSlideViewPositiveDirection) || (!aDirection && viewIndex < currentViewIndex))
        {
            showSlideFromY = -size.height;
            hideSlideToY = size.height;
        }
        
        showViewStart.y = showSlideFromY;
        hideViewEnd.y = hideSlideToY;
        
        // We've got a forced start progress
        if (aProgress)
        {
            showViewStart.y -= (aProgress * showViewStart.y)
            hideViewEnd.y -= (aProgress * hideViewEnd.y)
        }
    }
    
    var animation = [[LPViewAnimation alloc] initWithViewAnimations:[
            {
                @"target": aView,
                @"animations": [
                    [LPOriginAnimationKey, showViewStart, CGPointMake(0,0)]
                ]
            },
            {
                @"target": currentView,
                @"animations": [
                    [LPOriginAnimationKey, CGPointMakeZero(), hideViewEnd]
                ]
            }
        ]];
    [animation setAnimationCurve:animationCurve];
    [animation setDuration:animationDuration];
    [animation setDelegate:self];
    [animation startAnimation];
    
    previousView = currentView;
    currentView = aView;
}

- (void)animationDidEnd
{
    if(_delegate && [_delegate respondsToSelector:@selector(slideView:didMoveToView:)])
        [_delegate slideView:self didMoveToView:currentView];

    [previousView setHidden:YES];
    isSliding = NO;
}

- (void)animationDidEnd:(CPAnimation)anAnimation
{
    [self animationDidEnd];
}

- (void)animationDidStop:(CPAnimation)anAnimation
{
    [self animationDidEnd];
}

@end