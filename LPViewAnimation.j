/*
 * LPViewAnimation.j
 *
 * Created by Ludwig Pettersson on April 3, 2010.
 * 
 * The MIT License
 * 
 * Copyright (c) 2010 Ludwig Pettersson
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

@import <Foundation/CPObject.j>

LPCSSAnimationsAreAvailable = NO;

var _browserPrefixes = [@"webkit", @"Moz", @"moz", @"o", @"ms"],
    _tmpDOMElement = nil;

LPFadeAnimationKey   = @"LPFadeAnimation";
LPFrameAnimationKey  = @"LPFrameAnimation";
LPOriginAnimationKey = @"LPOriginAnimation";


LPTestCSSFeature = function(/*CPString*/aFeature)
{
    if (typeof document === "undefined")
        return NO;
    
    if (!_tmpDOMElement)
        _tmpDOMElement = document.createElement("div");
    
    var properties = [aFeature];
    
    for (var i = 0; i < _browserPrefixes.length; i++)
        properties.push(_browserPrefixes[i] + aFeature);
    
    for (var i = 0; i < properties.length; i++)
    {
        if (typeof _tmpDOMElement.style[properties[i]] !== "undefined")
            return YES;
    }
    
    return NO;
}

// Check if we can do CSS Animations
LPCSSAnimationsAreAvailable = LPTestCSSFeature(@"AnimationName");

var appendCSSValueToKey = function(/*DOMElement*/ anElement, /*CPString*/aValue, /*CPString*/aKey, /*BOOL*/ shouldAppend)
{
    if (shouldAppend)
        anElement.style[aKey] = anElement.style[aKey] + @", " + aValue;
    else
        anElement.style[aKey] = aValue;
}


@implementation LPViewAnimation : CPAnimation
{
    BOOL        _isAnimating;
    
    CPArray     _viewAnimations @accessors(property=viewAnimations);
    id          _animationDidEndTimeout;
    
    BOOL        _shouldUseCSSAnimations @accessors(property=shouldUseCSSAnimations);
    
    // Curve
    CPArray     _c1;
    CPArray     _c2;
}

- (void)initWithViewAnimations:(CPArray)viewAnimations
{
    if (self = [self initWithDuration:1.0 animationCurve:CPAnimationLinear])
    {
        _isAnimating = NO;
        
        _viewAnimations = viewAnimations;
        _shouldUseCSSAnimations = NO;
    }
    return self;
}

- (void)setAnimationCurve:(id)anAnimationCurve
{
    [super setAnimationCurve:anAnimationCurve];
    
    _c1 = [];
    _c2 = [];
    
    [_timingFunction getControlPointAtIndex:1 values:_c1];
    [_timingFunction getControlPointAtIndex:2 values:_c2];
}

- (void)startAnimation
{
    if (LPCSSAnimationsAreAvailable && _shouldUseCSSAnimations)
    {
        if (_isAnimating)
            return;
        
        _isAnimating = YES;
        
        var i = _viewAnimations.length;
        while (i--)
        {
            var viewAnimation = _viewAnimations[i],
                target = viewAnimation[@"target"];
            
            // Prepare target with general animation stuff.
            [self target:target setCSSAnimationDuration:_duration];
            [self target:target setCSSAnimationCurve:_animationCurve];
            
            var x = viewAnimation[@"animations"].length;
            while (x--)
            {
                var animation = viewAnimation[@"animations"][x],
                    kind = animation[0],
                    start = animation[1],
                    end = animation[2];
                
                if (kind === LPFadeAnimationKey)
                {
                    [target setAlphaValue:start];
                    
                    // Prepare target for this specific animation.
                    [self target:target addCSSAnimationPropertyForKey:kind append:x !== 0];
                    
                    // Needs to be wrapped.
                    setTimeout(function(_target, _end){
                        _target._DOMElement.style["-webkit-transform"] = "translate3d(0px, 0px, 0px)";
                        [_target setAlphaValue:_end];
                    }, 0, target, end);
                    
                }
                else if(kind === LPOriginAnimationKey)
                {
                    if (!CGPointEqualToPoint(start, end))
                    {
                        [target setFrameOrigin:start];
                        
                        // Prepare target for this specific animation.
                        [self target:target addCSSAnimationPropertyForKey:kind append:x !== 0];
                        
                        // Need to call it later for the animation to work.
                        setTimeout(function(_target, _start, _end){
                            
                            var x = _end.x - _start.x,
                                y = _end.y - _start.y;
                            
                            _target._DOMElement.style["-webkit-transform"] = "translate3d(" + x +"px, " + y + "px, 0px)";
                            
                            // Need to match the new position with the actual frame 
                            setTimeout(function(){
                                
                                // Make sure we got rid of the animation specific css
                                [self _clearCSS];
                                
                                // Reset the translate
                                _target._DOMElement.style["-webkit-transform"] = "translate3d(0px, 0px, 0px)";
                                
                                // Set the real frame
                                [_target setFrameOrigin:_end];
                            }, (1000 * _duration) + 100);
                            
                        }, 0, target, start, end);
                    }
                }
                else if(kind === LPFrameAnimationKey)
                {
                    CPLog.error("LPViewAnimation does not currently support CSS frame animations. This should fall back to the regular javascript animation.")
                }
            }
        }
        
        if (_animationDidEndTimeout)
            clearTimeout(_animationDidEndTimeout);
        
        _animationDidEndTimeout = setTimeout(function(animation){
            _isAnimating = NO;
            
            // Clear CSS
            [animation _clearCSS];
            
            if ([_delegate respondsToSelector:@selector(animationDidEnd:)])
                [_delegate animationDidEnd:animation];
        
        // We delay it by 100 extra mseconds to make sure that all css animations have finished,
        // it's not always *exactly* 1000 * duration.
        }, (1000 * _duration) + 100, self);
        
    }
    else
    {
        // Set the start value for each animation on the target view
        var i = _viewAnimations.length;
        while (i--)
        {
            var viewAnimation = _viewAnimations[i],
                target = viewAnimation[@"target"];
            
            var x = viewAnimation[@"animations"].length;
            while (x--)
            {
                var animation = viewAnimation[@"animations"][x],
                    kind = animation[0],
                    start = animation[1],
                    end = animation[2];
                
                switch (kind)
                {
                    case LPFadeAnimationKey:   [target setAlphaValue:start];
                                               break;
                    
                    case LPOriginAnimationKey: [target setFrameOrigin:start];
                                               break;
                    
                    case LPFrameAnimationKey:  [target setFrame:start];
                                               break;
                }
            }
        }
        
        [super startAnimation];
    }
}

/*
    This is used when CSS animations are not available,
    or have been turned off.
*/
- (void)setCurrentProgress:(float)aProgress
{
	_progress = aProgress;
 
    var value = CubicBezierAtTime(_progress, _c1[0], _c1[1], _c2[0], _c2[1], _duration),
        i = _viewAnimations.length;
    
    while (i--)
    {
        var viewAnimation = _viewAnimations[i],
            target = viewAnimation["target"],
            x = viewAnimation["animations"].length;
        
        while (x--)
        {
            var animation = viewAnimation["animations"][x],
                kind = animation[0],
                start = animation[1],
                end = animation[2];
            
            switch (kind)
            {
                case LPFadeAnimationKey:   [target setAlphaValue:(value * (end - start)) + start];
                                           break;
                                         
                case LPOriginAnimationKey: [target setFrameOrigin:CGPointMake(start.x + (value * (end.x - start.x)),
                                                                              start.y + (value * (end.y - start.y)))];
                                           break;
                                           
                case LPFrameAnimationKey:  [target setFrame:CGRectMake(start.origin.x + (value * (end.origin.x - start.origin.x)),
                                                                       start.origin.y + (value * (end.origin.y - start.origin.y)),
                                                                       start.size.width + (value * (end.size.width - start.size.width)),
                                                                       start.size.height + (value * (end.size.height - start.size.height)))]
            }
        }
    }
}

- (BOOL)isAnimating
{
    if (LPCSSAnimationsAreAvailable && _shouldUseCSSAnimations)
        return _isAnimating;
    else
        return [super isAnimating];
}

- (void)stopAnimation
{
    if (LPCSSAnimationsAreAvailable && _shouldUseCSSAnimations)
    {
        //_isAnimating = NO;
        
        //if (_animationDidEndTimeout)
        //    window.clearTimeout(_animationDidEndTimeout);
        
        //[self _stopCSSAnimation];
        
        //if ([_delegate respondsToSelector:@selector(animationDidStop:)])
        //    [_delegate animationDidStop:self];
    }
    else
        [super stopAnimation];
}

- (void)_clearCSS
{
    // Reset the css on each target
    for (var i = 0; i < _viewAnimations.length; i++)
        _viewAnimations[i][@"target"]._DOMElement.style[@"-webkit-transition-property"] = @"none";
}

- (void)target:(id)aTarget setCSSAnimationDuration:(CPTimeInterval)aDuration
{
    aTarget._DOMElement.style["-webkit-transition-duration"] = aDuration + @"s";
}

- (void)target:(id)aTarget setCSSAnimationCurve:(id)anAnimationCurve
{
    var curve = nil;
    
    switch (anAnimationCurve)
    {
        case CPAnimationLinear:    curve = @"linear";
                                   break;

        case CPAnimationEaseIn:    curve = @"ease-in";
                                   break;

        case CPAnimationEaseOut:   curve = @"ease-out";
                                   break;

        case CPAnimationEaseInOut: curve = @"ease-in-out";
                                   break;
    }
    
    aTarget._DOMElement.style["-webkit-transition-timing-function"] = curve;
}

- (void)target:(id)aTarget addCSSAnimationPropertyForKey:(CPString)aKey append:(BOOL)shouldAppend
{
    var CSSValue = nil;
    
    switch(aKey)
    {
        case LPFadeAnimationKey:   CSSValue = @"-webkit-transform, opacity";
                                   break;
        
        case LPOriginAnimationKey: CSSValue = @"-webkit-transform";
                                   break;

        case LPFrameAnimationKey:  CSSValue = @"top, left, width, height";
                                   break;
        
        default:                   CSSValue = @"none";
    }
    
    appendCSSValueToKey(aTarget._DOMElement, CSSValue, @"-webkit-transition-property", shouldAppend);
}

@end

/*
    
    Inlined this, because I managed to crank out a few more fps by doing that. I think.
    
*/

// currently used function to determine time
// 1:1 conversion to js from webkit source files
// UnitBezier.h, WebCore_animation_AnimationBase.cpp
var CubicBezierAtTime = function CubicBezierAtTime(t,p1x,p1y,p2x,p2y,duration)
{
    var ax=0,bx=0,cx=0,ay=0,by=0,cy=0;
    // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
    function sampleCurveX(t) {return ((ax*t+bx)*t+cx)*t;};
    function sampleCurveY(t) {return ((ay*t+by)*t+cy)*t;};
    function sampleCurveDerivativeX(t) {return (3.0*ax*t+2.0*bx)*t+cx;};
    // The epsilon value to pass given that the animation is going to run over |duration| seconds. The longer the animation, the more precision is needed in the timing function result to avoid ugly discontinuities.
    function solveEpsilon(duration) {return 1.0/(200.0*duration);};
    function solve(x,epsilon) {return sampleCurveY(solveCurveX(x,epsilon));};
    // Given an x value, find a parametric value it came from.
    function solveCurveX(x,epsilon) {var t0,t1,t2,x2,d2,i;
        function fabs(n) {if(n>=0) {return n;}else {return 0-n;}}; 
        // First try a few iterations of Newton's method -- normally very fast.
        for(t2=x, i=0; i<8; i++) {x2=sampleCurveX(t2)-x; if(fabs(x2)<epsilon) {return t2;} d2=sampleCurveDerivativeX(t2); if(fabs(d2)<1e-6) {break;} t2=t2-x2/d2;}
        // Fall back to the bisection method for reliability.
        t0=0.0; t1=1.0; t2=x; if(t2<t0) {return t0;} if(t2>t1) {return t1;}
        while(t0<t1) {x2=sampleCurveX(t2); if(fabs(x2-x)<epsilon) {return t2;} if(x>x2) {t0=t2;}else {t1=t2;} t2=(t1-t0)*.5+t0;}
        return t2; // Failure.
    };
    // Calculate the polynomial coefficients, implicit first and last control points are (0,0) and (1,1).
    cx=3.0*p1x; bx=3.0*(p2x-p1x)-cx; ax=1.0-cx-bx; cy=3.0*p1y; by=3.0*(p2y-p1y)-cy; ay=1.0-cy-by;
    // Convert from input time to parametric value in curve, then from that to output time.
    return solve(t, solveEpsilon(duration));
}