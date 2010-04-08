/*
 * LPURLPostRequest.j
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

@import <Foundation/CPURLRequest.j>

@implementation LPURLPostRequest : CPURLRequest
{
} 

+ (id)requestWithURL:(CPURL)aURL
{
    return [[self alloc] initWithURL:aURL];
}

- (void)initWithURL:(CPURL)aURL
{
    if (self = [super initWithURL:aURL])
    {
        [self setHTTPMethod:@"POST"];
        [self setValue:"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    return self;
}

- (void)setContent:(id)anObject
{
    [self setContent:anObject escape:YES];
}

- (void)setContent:(id)anObject escape:(BOOL)shouldEscape
{
    var content = @"";
    
    for (key in anObject)
        content = [content stringByAppendingString:[CPString stringWithFormat:@"%s=%s&", key, shouldEscape ? encodeURIComponent(anObject[key]) : anObject[key]]];
    
    // Remove trailing &
    content = [content substringToIndex:[content length] - 1];

    [self setHTTPBody:content];
}

@end