/*
 * LPLocationController.j
 * LPKit
 *
 * Created by Ludwig Pettersson on November 21, 2009.
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
@import <Foundation/CPObject.j>

var sharedLocationControllerInstance = nil;

@implementation LPLocationController : CPObject
{
    CPString currentHash;
    CPArray observers;
} 

+ (id)sharedLocationController
{
    if (!sharedLocationControllerInstance)
        sharedLocationControllerInstance = [[self alloc] init];
    
    return sharedLocationControllerInstance;
}

- (id)init
{
    if (self = [super init])
    {
        observers = [CPArray array];
        currentHash = window.location.hash;
        
        // Use onhashchange if that is available
        if (typeof window.onhashchange !== "undefined")
        {
            window.onhashchange = function() {
              [self updateLocation:nil];
            };
        }
        
        // If not, use the ol' interval
        else
        {
            [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLocation:) userInfo:nil repeats:YES];
        }
    }
    return self;
}

- (CPString)formattedHash
{
    return [window.location.hash substringFromIndex:1];
}

- (void)setLocation:(CPString)aLocation
{
    window.location.hash = aLocation;
    [self updateLocation:nil];
}

- (void)updateLocation:(id)sender
{
    if (currentHash !== window.location.hash)
    {
        currentHash = window.location.hash;

        var _formattedHash = [self formattedHash];
    
        // Post notifications
        for (var i = 0, length = observers.length; i < length; i++)
            [observers[i][0] performSelector:observers[i][1] withObject:_formattedHash];
    }
}

- (void)addObserver:(id)anObserver selector:(id)aSelector
{
    // Save the observer
    [observers addObject:[anObserver, aSelector]];
    
    // Post a notification right away
    [anObserver performSelector:aSelector withObject:[self formattedHash]];
}

@end
